"""Transcription automatique des morceaux (faster-whisper), utilisée par les tests de tools/tests/.

Chaque morceau est découpé exactement comme dans l'application (mêmes trames, mêmes fondus).
Les transcriptions sont gardées en cache dans tools/.cache/whisper/ : une relance ne retranscrit
que les morceaux dont l'audio a changé.

    python tools/verify_pieces.py 2:255   # écrit aussi les extraits dans tools/reports/2_255/ pour l'écoute
"""

import hashlib
import os
import json
import subprocess
import sys
from functools import cache
from pathlib import Path

import numpy as np

import audio

TOOLS = Path(__file__).resolve().parent
CACHE = TOOLS / ".cache" / "whisper"
REPORTS = TOOLS / "reports"
MODEL = "small"

# Le transfert « Xet » de Hugging Face passe par des hôtes souvent bloqués ; le téléchargement classique suffit.
os.environ.setdefault("HF_HUB_DISABLE_XET", "1")

FADE_IN_SECONDS = 0.010
FADE_OUT_SECONDS = 0.030


class WhisperUnavailable(Exception):
    pass


def piece_samples(samples: np.ndarray, clip: dict) -> np.ndarray:
    """Mêmes fondus linéaires que Fades.apply dans ShadowingCore."""
    piece = samples[clip["startFrame"]:clip["endFrame"]].copy()
    fade_in = min(len(piece), round(FADE_IN_SECONDS * audio.SAMPLE_RATE))
    fade_out = min(len(piece), round(FADE_OUT_SECONDS * audio.SAMPLE_RATE))
    piece[:fade_in] *= np.arange(fade_in, dtype=np.float32) / max(1, fade_in)
    if fade_out:
        piece[len(piece) - fade_out:] *= (np.arange(fade_out, dtype=np.float32) / fade_out)[::-1]
    return piece


def _resample_16k(samples: np.ndarray) -> np.ndarray:
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-f", "f32le", "-ar", str(audio.SAMPLE_RATE), "-ac", "1", "-i", "-",
         "-f", "f32le", "-ar", "16000", "-ac", "1", "-"],
        input=samples.astype(np.float32).tobytes(), capture_output=True, check=True,
    ).stdout
    return np.frombuffer(raw, dtype=np.float32)


@cache
def _load_model():
    """Charge le modèle une seule fois ; en cas d'échec, l'erreur est gardée pour ne pas retenter à chaque morceau."""
    try:
        from faster_whisper import WhisperModel

        return WhisperModel(MODEL, device="cpu", compute_type="int8"), None
    except Exception as error:  # modèle introuvable ou téléchargement bloqué
        return None, f"modèle Whisper « {MODEL} » indisponible ({type(error).__name__})"


def _model():
    model, failure = _load_model()
    if failure:
        raise WhisperUnavailable(failure)
    return model


def transcribe(samples: np.ndarray) -> str:
    key = hashlib.sha1(samples.astype(np.float32).tobytes() + MODEL.encode()).hexdigest()
    cached = CACHE / f"{key}.txt"
    if cached.exists():
        return cached.read_text(encoding="utf-8")
    segments, _ = _model().transcribe(_resample_16k(samples), language="ar", beam_size=5,
                                      vad_filter=False, condition_on_previous_text=False)
    heard = " ".join(segment.text.strip() for segment in segments).strip()
    CACHE.mkdir(parents=True, exist_ok=True)
    cached.write_text(heard, encoding="utf-8")
    return heard


def export_mp3(samples: np.ndarray, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(audio.SAMPLE_RATE), "-ac", "1", "-i", "-",
         "-c:a", "libmp3lame", "-b:a", "96k", str(target)],
        input=samples.astype(np.float32).tobytes(), check=True,
    )


def export_clips(content_id: str) -> Path:
    """Extraits audio de chaque morceau, pour l'écoute."""
    library = json.loads((TOOLS.parent / "Talaqqi" / "Talaqqi" / "Resources" / "Content" / "library.json").read_text(encoding="utf-8"))
    content = next(c for c in library["contents"] if c["id"] == content_id)
    folder = REPORTS / content_id.replace(":", "_")
    decoded: dict[str, np.ndarray] = {}
    for piece in content["pieces"]:
        clip = piece["audio"]
        if clip["file"] not in decoded:
            decoded[clip["file"]] = audio.decode(TOOLS.parent / "Talaqqi" / "Talaqqi" / "Resources" / "Audio" / clip["file"])
        export_mp3(piece_samples(decoded[clip["file"]], clip), folder / f"{piece['index']}.mp3")
    return folder


if __name__ == "__main__":
    print(f"Extraits audio dans {export_clips(sys.argv[1])}")
