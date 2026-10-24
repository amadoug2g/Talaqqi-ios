"""Télécharge les sources brutes d'un ou plusieurs versets dans tools/sources/.

Chaque fichier garde l'URL d'origine et la date de téléchargement. Rien n'est modifié :
la mise en forme pour l'application se fait dans build_content.py.

    python tools/fetch_sources.py 1:1 2:255
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


def main(keys: list[str]) -> None:
    for key in keys:
        surah, ayah = (int(part) for part in key.split(":"))
        fetch_verse(surah, ayah)
        print(f"{key} : sources téléchargées")


if __name__ == "__main__":
    main(sys.argv[1:])
