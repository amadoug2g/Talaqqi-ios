"""Télécharge les sources brutes d'un ou plusieurs versets dans tools/sources/.

Chaque fichier garde l'URL d'origine et la date de téléchargement. Rien n'est modifié :
la mise en forme pour l'application se fait dans build_content.py.

    python tools/fetch_sources.py 1:1 2:255   # versets
    python tools/fetch_sources.py 114         # sourate entière, avec la Basmala
"""

import datetime
import hashlib
import html
import json
import re
import sys
from pathlib import Path

import requests

SOURCES = Path(__file__).resolve().parent / "sources"

RECITER_FOLDER = "Hudhaify_128kbps"
AUDIO_URL = "https://everyayah.com/data/{folder}/{name}.mp3"
QURANENC_AYA_URL = "https://quranenc.com/api/v1/translation/aya/{key}/{surah}/{ayah}"
QURANENC_SURA_URL = "https://quranenc.com/api/v1/translation/sura/{key}/{surah}"
QURANENC_BROWSE_URL = "https://quranenc.com/fr/browse/french_mokhtasar/{surah}"
QURANCOM_CHAPTERS_URL = "https://api.quran.com/api/v4/chapters?language=fr"
QUL_TRANSLITERATION_URL = "https://qul.tarteel.ai/resources/transliteration/{resource}?ayah={surah}:{ayah}"

TRANSLATION_KEY = "french_hameedullah"
# QUL « English Transliteration (Tajweed) » : lecture telle qu'on la récite, avec les arrêts.
QUL_TRANSLITERATION_RESOURCE = 469


def now() -> str:
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")


def get(url: str) -> requests.Response:
    response = requests.get(url, timeout=60)
    response.raise_for_status()
    return response


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def fetch_audio(name: str) -> None:
    """name : « 002255 » pour un verset, « bismillah » pour la Basmala."""
    url = AUDIO_URL.format(folder=RECITER_FOLDER, name=name)
    target = SOURCES / "audio" / RECITER_FOLDER / f"{name}.mp3"
    data = get(url).content
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    write_json(target.with_suffix(".json"), {
        "url": url,
        "fetched_at": now(),
        "sha256": hashlib.sha256(data).hexdigest(),
    })


def fetch_quranenc(key: str, surah: int, ayah: int) -> None:
    url = QURANENC_AYA_URL.format(key=key, surah=surah, ayah=ayah)
    write_json(SOURCES / "quranenc" / key / f"{surah:03d}{ayah:03d}.json", {
        "url": url,
        "fetched_at": now(),
        "data": get(url).json()["result"],
    })


def fetch_quranenc_surah(key: str, surah: int) -> int:
    """Tous les versets d'une sourate en un appel, rangés verset par verset comme fetch_quranenc."""
    url = QURANENC_SURA_URL.format(key=key, surah=surah)
    verses = get(url).json()["result"]
    fetched_at = now()
    for verse in verses:
        write_json(SOURCES / "quranenc" / key / f"{surah:03d}{int(verse['aya']):03d}.json", {
            "url": url,
            "fetched_at": fetched_at,
            "data": verse,
        })
    write_json(SOURCES / "quranenc" / key / "index" / f"{surah:03d}.json", {
        "url": url,
        "fetched_at": fetched_at,
        "verseCount": len(verses),
    })
    return len(verses)


def fetch_surah_info(surah: int) -> None:
    """« Parmi les objectifs de la sourate » (Al-Mukhtasar) : seulement sur la page publique de QuranEnc."""
    url = QURANENC_BROWSE_URL.format(surah=surah)
    page = get(url).text
    match = re.search(r"Parmi les objectifs de la sourate.*?<div class=\"rtl[^\"]*\">(.*?)</div>.*?"
                      r"<div class=\"aligner\">\s*<span>(.*?)</span>", page, re.S)
    if not match:
        print(f"{surah} : pas d'objectifs de sourate dans la source, pas de fiche")
        return
    arabic, french = (html.unescape(re.sub(r"\s+", " ", part)).strip() for part in match.groups())
    write_json(SOURCES / "quranenc" / "french_mokhtasar" / "objectives" / f"{surah:03d}.json", {
        "url": url,
        "fetched_at": now(),
        "data": {"arabic": arabic, "french": french},
    })


def fetch_surah_names() -> None:
    """Noms des sourates traduits en français (Quran.com), pour les 114 sourates."""
    chapters = get(QURANCOM_CHAPTERS_URL).json()["chapters"]
    write_json(SOURCES / "qurancom" / "chapters_fr.json", {
        "url": QURANCOM_CHAPTERS_URL,
        "fetched_at": now(),
        "data": {str(c["id"]): c["translated_name"]["name"] for c in chapters},
    })


def fetch_qul_transliteration(surah: int, ayah: int) -> None:
    """QUL ne propose le téléchargement en bloc qu'avec un compte : on lit la page publique du verset."""
    url = QUL_TRANSLITERATION_URL.format(resource=QUL_TRANSLITERATION_RESOURCE, surah=surah, ayah=ayah)
    page = get(url).text
    match = re.search(r'<div class="english[^"]*">\s*(.*?)\s*</div>', page, re.S)
    if not match:
        raise RuntimeError(f"Translittération introuvable dans {url}")
    text = html.unescape(re.sub(r"\s+", " ", match.group(1))).strip()
    write_json(SOURCES / "qul" / f"transliteration_{QUL_TRANSLITERATION_RESOURCE}" / f"{surah:03d}{ayah:03d}.json", {
        "url": url,
        "fetched_at": now(),
        "data": {"text": text},
    })


def fetch_verse(surah: int, ayah: int) -> None:
    fetch_quranenc(TRANSLATION_KEY, surah, ayah)
    fetch_qul_transliteration(surah, ayah)
    if (surah, ayah) == (1, 1):
        fetch_audio("bismillah")
    else:
        fetch_audio(f"{surah:03d}{ayah:03d}")


def fetch_surah(surah: int) -> None:
    fetch_verse(1, 1)
    count = fetch_quranenc_surah(TRANSLATION_KEY, surah)
    fetch_surah_info(surah)
    for ayah in range(1, count + 1):
        fetch_qul_transliteration(surah, ayah)
        fetch_audio(f"{surah:03d}{ayah:03d}")


def main(keys: list[str]) -> None:
    if not (SOURCES / "qurancom" / "chapters_fr.json").exists():
        fetch_surah_names()
    for key in keys:
        if ":" in key:
            surah, ayah = (int(part) for part in key.split(":"))
            fetch_verse(surah, ayah)
        else:
            fetch_surah(int(key))
        print(f"{key} : sources téléchargées")


if __name__ == "__main__":
    main(sys.argv[1:])
