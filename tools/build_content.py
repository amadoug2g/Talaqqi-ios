"""Construit le contenu embarqué : audio .m4a et library.json, à partir de tools/sources/ et tools/content/.

    python tools/build_content.py

Chaque fichier de tools/content/ décrit un contenu (sourate ou verset seul) et, pour les versets
longs, comment les phrases (coupées aux signes de pause) se regroupent en morceaux. Le nombre de
morceaux doit correspondre aux pauses réelles du récitant, sinon le script s'arrête.
"""

import json
import sys
from pathlib import Path

import audio
import text

TOOLS = Path(__file__).resolve().parent
SOURCES = TOOLS / "sources"
RESOURCES = TOOLS.parent / "Talaqqi" / "Talaqqi" / "Resources"

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


def verse_sources(surah: int, ayah: int) -> tuple[dict, str]:
    key = f"{surah:03d}{ayah:03d}"
    quranenc = load(SOURCES / "quranenc" / TRANSLATION_KEY / f"{key}.json")["data"]
    transliteration = load(SOURCES / "qul" / TRANSLITERATION / f"{key}.json")["data"]["text"]
    return quranenc, transliteration


def audio_clip(name: str) -> tuple[str, list[audio.Span]]:
    """Convertit l'audio source et renvoie le nom du fichier embarqué et ses passages de voix."""
    file = f"{RECITER['id']}_{name}.m4a"
    target = RESOURCES / "Audio" / file
    audio.to_m4a(SOURCES / "audio" / RECITER_FOLDER / f"{name}.mp3", target)
    return file, audio.voice_segments(audio.decode(target))


def clip(file: str, span: audio.Span) -> dict:
    return {
        "file": file,
        "startFrame": audio.frames(span.start),
        "endFrame": audio.frames(span.end),
        "sampleRate": audio.SAMPLE_RATE,
    }


def whole(segments: list[audio.Span]) -> audio.Span:
    return audio.Span(segments[0].start, segments[-1].end)


def basmala_piece() -> dict:
    quranenc, transliteration = verse_sources(1, 1)
    file, segments = audio_clip("bismillah")
    return {
        "index": 0,
        "arabic": quranenc["arabic_text"],
        "phonetic": transliteration,
        "translation": text.strip_footnote_refs(quranenc["translation"]),
        "audio": clip(file, whole(segments)),
    }


def verse_pieces(surah: int, verse: dict, first_index: int) -> tuple[list[dict], dict]:
    number = verse["number"]
    quranenc, transliteration = verse_sources(surah, number)
    translation = text.strip_footnote_refs(quranenc["translation"])
    file, segments = audio_clip(f"{surah:03d}{number:03d}")
    groups = verse.get("pieces")

    if not groups:
        pieces = [{
            "arabic": quranenc["arabic_text"],
            "phonetic": transliteration,
            "translation": translation,
            "audio": clip(file, whole(segments)),
        }]
    else:
        arabic = text.waqf_phrases(quranenc["arabic_text"])
        phonetic = text.transliteration_phrases(transliteration)
        french = text.sentences(translation)
        if len(arabic) != len(phonetic):
            sys.exit(f"{surah}:{number} : {len(arabic)} phrases en arabe mais {len(phonetic)} en phonétique")
        if len(segments) != len(groups):
            found = ", ".join(f"{s.start:.2f}-{s.end:.2f}" for s in segments)
            sys.exit(f"{surah}:{number} : {len(groups)} morceaux attendus, {len(segments)} passages de voix trouvés ({found})")
        pieces = [{
            "arabic": text.join(arabic, group["phrases"]),
            "phonetic": text.join(phonetic, group["phrases"]),
            "translation": text.join(french, group["sentences"]),
            "audio": clip(file, span),
        } for group, span in zip(groups, segments)]

    for offset, piece in enumerate(pieces):
        piece["index"] = first_index + offset
        piece["verse"] = number
    return pieces, {
        "number": number,
        "translation": translation,
        "firstPiece": first_index,
        "lastPiece": first_index + len(pieces) - 1,
    }


def build(config: dict) -> dict:
    pieces = [basmala_piece()] if config.get("basmala") else []
    verses = []
    for verse in config["verses"]:
        new_pieces, verse_entry = verse_pieces(config["surah"], verse, len(pieces))
        pieces += new_pieces
        verses.append(verse_entry)
    return {
        "id": config["id"],
        "kind": config["kind"],
        "title": config["title"],
        "subtitle": config["subtitle"],
        "arabicName": config["arabicName"],
        "surah": config["surah"],
        "verseCount": len(verses),
        "verses": verses,
        "pieces": pieces,
    }


def main() -> None:
    contents = [build(load(path)) for path in sorted((TOOLS / "content").glob("*.json"))]
    verses = [c["id"] for c in contents if c["kind"] == "verse"]
    surahs = sorted((c for c in contents if c["kind"] == "surah"), key=lambda c: c["surah"])
    sections = [{"title": "Versets", "items": verses}, {"title": "Juz ‘Amma", "items": [c["id"] for c in surahs]}]
    library = {
        "reciter": RECITER,
        "sources": LIBRARY_SOURCES,
        "sections": [s for s in sections if s["items"]],
        "contents": contents,
    }
    target = RESOURCES / "Content" / "library.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(library, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for content in contents:
        print(f"{content['id']} : {len(content['pieces'])} morceaux")


if __name__ == "__main__":
    main()
