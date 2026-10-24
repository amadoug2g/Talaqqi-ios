"""Vérifie chaque morceau par transcription automatique (faster-whisper) et écrit un rapport.

    python tools/verify_pieces.py 2:255
    python tools/verify_pieces.py 2:255 --clips-only   # extraits audio seulement, sans transcription

Chaque morceau est découpé exactement comme dans l'application (mêmes trames, mêmes fondus),
transcrit en arabe, puis comparé au texte attendu sans voyelles. Le rapport signale les
morceaux dont la transcription s'écarte du texte ou déborde sur le morceau suivant.
"""

import difflib
import json
import subprocess
import sys
from pathlib import Path

import numpy as np

import audio
import text

TOOLS = Path(__file__).resolve().parent
RESOURCES = TOOLS.parent / "Talaqqi" / "Talaqqi" / "Resources"
REPORTS = TOOLS / "reports"

FADE_IN_SECONDS = 0.010
FADE_OUT_SECONDS = 0.030
MIN_SIMILARITY = 0.75


def piece_samples(samples: np.ndarray, clip: dict) -> np.ndarray:
    """Mêmes fondus linéaires que Fades.apply dans ShadowingCore."""
    piece = samples[clip["startFrame"]:clip["endFrame"]].copy()
    fade_in = min(len(piece), round(FADE_IN_SECONDS * audio.SAMPLE_RATE))
    fade_out = min(len(piece), round(FADE_OUT_SECONDS * audio.SAMPLE_RATE))
    piece[:fade_in] *= np.arange(fade_in, dtype=np.float32) / max(1, fade_in)
    if fade_out:
        piece[len(piece) - fade_out:] *= (np.arange(fade_out, dtype=np.float32) / fade_out)[::-1]
    return piece


def export_mp3(samples: np.ndarray, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(audio.SAMPLE_RATE), "-ac", "1", "-i", "-",
         "-c:a", "libmp3lame", "-b:a", "96k", str(target)],
        input=samples.astype(np.float32).tobytes(), check=True,
    )


def to_16k(samples: np.ndarray) -> np.ndarray:
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-f", "f32le", "-ar", str(audio.SAMPLE_RATE), "-ac", "1", "-i", "-",
         "-f", "f32le", "-ar", "16000", "-ac", "1", "-"],
        input=samples.astype(np.float32).tobytes(), capture_output=True, check=True,
    ).stdout
    return np.frombuffer(raw, dtype=np.float32)


def main(content_id: str, transcribe: bool) -> None:
    library = json.loads((RESOURCES / "Content" / "library.json").read_text(encoding="utf-8"))
    content = next(c for c in library["contents"] if c["id"] == content_id)
    from faster_whisper import WhisperModel

    model = WhisperModel("small", device="cpu", compute_type="int8") if transcribe else None
    decoded: dict[str, np.ndarray] = {}
    slug = content_id.replace(":", "_")
    rows, problems = [], 0

    for piece in content["pieces"]:
        clip = piece["audio"]
        if clip["file"] not in decoded:
            decoded[clip["file"]] = audio.decode(RESOURCES / "Audio" / clip["file"])
        samples = piece_samples(decoded[clip["file"]], clip)
        export_mp3(samples, REPORTS / slug / f"{piece['index']}.mp3")
        if model is None:
            continue
        segments, _ = model.transcribe(to_16k(samples), language="ar", beam_size=5, vad_filter=False,
                                       condition_on_previous_text=False)
        heard = " ".join(segment.text.strip() for segment in segments)
        expected = text.normalize_arabic(piece["arabic"])
        similarity = difflib.SequenceMatcher(None, expected, text.normalize_arabic(heard)).ratio()
        ok = similarity >= MIN_SIMILARITY
        problems += not ok
        rows.append((piece, clip, heard, similarity, ok))
        print(f"morceau {piece['index']} : {similarity:.0%} {'ok' if ok else 'À VÉRIFIER'}")

    if model is None:
        print(f"Extraits audio dans {REPORTS / slug}")
        return
    lines = [f"# Vérification : {content['title']}", "",
             f"Transcription faster-whisper `small`, seuil {MIN_SIMILARITY:.0%}. "
             f"Extraits audio découpés comme dans l'application : `{slug}/<morceau>.mp3`.", "",
             "| Morceau | Début | Fin | Durée | Ressemblance | Texte attendu | Transcription |",
             "|---|---|---|---|---|---|---|"]
    for piece, clip, heard, similarity, ok in rows:
        start, end = clip["startFrame"] / audio.SAMPLE_RATE, clip["endFrame"] / audio.SAMPLE_RATE
        lines.append(f"| {piece['index']} | {start:.2f} s | {end:.2f} s | {end - start:.2f} s | "
                     f"{similarity:.0%}{'' if ok else ' (à vérifier)'} | {piece['arabic']} | {heard} |")
    lines += ["", f"{len(rows) - problems} morceaux sur {len(rows)} au-dessus du seuil."]
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / f"{slug}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main(sys.argv[1], transcribe="--clips-only" not in sys.argv)
