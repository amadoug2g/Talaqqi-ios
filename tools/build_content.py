"""Construit le contenu embarqué : audio .m4a et library.json, à partir de tools/sources/ et tools/content/.

    python tools/build_content.py

Chaque fichier de tools/content/ est la spécification d'un contenu. Pour une sourate, il suffit du
nom et du numéro : les versets sont lus dans les sources, un morceau par verset. Pour un verset long,
`pieces` dit comment les phrases (coupées aux signes de pause) se regroupent en morceaux.
"""

import json
from pathlib import Path

import audio
import text

TOOLS = Path(__file__).resolve().parent
SOURCES = TOOLS / "sources"
CONTENT = TOOLS / "content"
RESOURCES = TOOLS.parent / "Talaqqi" / "Talaqqi" / "Resources"
LIBRARY = RESOURCES / "Content" / "library.json"

RECITER = {"id": "hudhaify", "name": "Ali Al-Hudhaify"}
RECITER_FOLDER = "Hudhaify_128kbps"
TRANSLATION_KEY = "french_hameedullah"
TRANSLITERATION = "transliteration_469"

LIBRARY_SOURCES = {
    "audio": "Récitation d’Ali Al-Hudhaify, everyayah.com",
    "arabic": "Texte ottoman (Hafs) du Complexe du Roi Fahd, QuranEnc",
    "phonetic": "English Transliteration (Tajweed), Quranic Universal Library (QUL, Tarteel)",
    "translation": "Traduction de Muhammad Hamidullah, QuranEnc",
    "surahInfo": "Al-Mukhtasar fi Tafsir al-Qur’an, Markaz Tafsir · QuranEnc",
}


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def specs() -> list[dict]:
    return [load(path) for path in sorted(CONTENT.glob("*.json"))]


def verse_sources(surah: int, ayah: int) -> dict:
    """Textes bruts d'un verset : arabe, traduction (sans appels de note), phonétique."""
    key = f"{surah:03d}{ayah:03d}"
    quranenc = load(SOURCES / "quranenc" / TRANSLATION_KEY / f"{key}.json")["data"]
    return {
        "arabic": quranenc["arabic_text"],
        "translation": text.strip_footnote_refs(quranenc["translation"]),
        "phonetic": load(SOURCES / "qul" / TRANSLITERATION / f"{key}.json")["data"]["text"],
    }


def verse_numbers(spec: dict) -> list[int]:
    if "verses" in spec:
        return [verse["number"] for verse in spec["verses"]]
    count = load(SOURCES / "quranenc" / TRANSLATION_KEY / "index" / f"{spec['surah']:03d}.json")["verseCount"]
    return list(range(1, count + 1))


def piece_groups(spec: dict, number: int) -> list[dict] | None:
    for verse in spec.get("verses", []):
        if verse["number"] == number:
            return verse.get("pieces")
    return None


def surah_info_source(surah: int) -> Path:
    return SOURCES / "quranenc" / "french_mokhtasar" / "objectives" / f"{surah:03d}.json"


def source_audio(name: str) -> Path:
    return SOURCES / "audio" / RECITER_FOLDER / f"{name}.mp3"


def embedded_audio(name: str) -> Path:
    return RESOURCES / "Audio" / f"{RECITER['id']}_{name}.m4a"


def audio_name(surah: int, ayah: int) -> str:
    return "bismillah" if (surah, ayah) == (1, 1) else f"{surah:03d}{ayah:03d}"


def verse_texts(sources: dict, groups: list[dict] | None) -> list[dict]:
    """Textes de chaque morceau d'un verset, recopiés des sources et regroupés selon la spécification."""
    if not groups:
        return [dict(sources)]
    arabic = text.waqf_phrases(sources["arabic"])
    phonetic = text.transliteration_phrases(sources["phonetic"])
    french = text.sentences(sources["translation"])
    return [{
        "arabic": text.join(arabic, group["phrases"]),
        "phonetic": text.join(phonetic, group["phrases"]),
        "translation": text.join(french, group["sentences"]),
    } for group in groups]


def verse_segmentation(sources: dict, groups: list[dict] | None, samples) -> audio.Segmentation:
    if not groups:
        return audio.segment(samples, [len(text.normalize_arabic(sources["arabic"]))], [1])
    phrases = text.waqf_phrases(sources["arabic"])
    return audio.segment(samples, [len(text.normalize_arabic(p)) for p in phrases],
                         [group["phrases"][1] for group in groups])


def clip(file: Path, span: audio.Span) -> dict:
    return {
        "file": file.name,
        "startFrame": audio.frames(span.start),
        "endFrame": audio.frames(span.end),
        "sampleRate": audio.SAMPLE_RATE,
    }


def build_verse(surah: int, number: int, groups: list[dict] | None) -> list[dict]:
    name = audio_name(surah, number)
    target = embedded_audio(name)
    audio.to_m4a(source_audio(name), target)
    sources = verse_sources(surah, number)
    segmentation = verse_segmentation(sources, groups, audio.decode(target))
    return [dict(texts, audio=clip(target, span))
            for texts, span in zip(verse_texts(sources, groups), segmentation.pieces)]


def build(spec: dict) -> dict:
    pieces = build_verse(1, 1, None) if spec.get("basmala") else []
    verses = []
    for number in verse_numbers(spec):
        first = len(pieces)
        for piece in build_verse(spec["surah"], number, piece_groups(spec, number)):
            pieces.append(dict(piece, verse=number))
        verses.append({
            "number": number,
            "translation": verse_sources(spec["surah"], number)["translation"],
            "firstPiece": first,
            "lastPiece": len(pieces) - 1,
        })
    for index, piece in enumerate(pieces):
        piece["index"] = index
    content = {
        "id": spec["id"],
        "kind": spec["kind"],
        "title": spec["title"],
        "subtitle": spec.get("subtitle", f"Sourate {spec['surah']}"),
        "arabicName": spec["arabicName"],
        "surah": spec["surah"],
        "verseCount": len(verses),
        "verses": verses,
        "pieces": pieces,
    }
    info = surah_info_source(spec["surah"])
    if spec["kind"] == "surah" and info.exists():
        content["info"] = {"objectives": load(info)["data"]["french"], "source": LIBRARY_SOURCES["surahInfo"]}
    return content


def main() -> None:
    contents = [build(spec) for spec in specs()]
    verses = [c["id"] for c in contents if c["kind"] == "verse"]
    surahs = [c["id"] for c in sorted((c for c in contents if c["kind"] == "surah"), key=lambda c: c["surah"])]
    sections = [{"title": "Versets", "items": verses}, {"title": "Juz ‘Amma", "items": surahs}]
    library = {
        "reciter": RECITER,
        "sources": LIBRARY_SOURCES,
        "sections": [s for s in sections if s["items"]],
        "contents": contents,
    }
    LIBRARY.parent.mkdir(parents=True, exist_ok=True)
    LIBRARY.write_text(json.dumps(library, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for content in contents:
        print(f"{content['id']} : {len(content['pieces'])} morceaux")


if __name__ == "__main__":
    main()
