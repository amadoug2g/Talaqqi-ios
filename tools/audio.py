"""Outils audio partagés : conversion, décodage, profil de volume, silences, bornes de la voix."""

import subprocess
from dataclasses import dataclass
from pathlib import Path

import numpy as np

SAMPLE_RATE = 44_100
WINDOW_SECONDS = 0.01

# Seuils relatifs au niveau de la voix (99e centile du profil), en dB.
SILENCE_BELOW_DB = 35
# Un silence plus court n'est pas une pause du récitant (consonne, respiration brève).
MIN_PAUSE_SECONDS = 0.5
# Marges autour de la voix : on garde la fin du souffle, on démarre juste avant l'attaque.
LEAD_IN_SECONDS = 0.05
TAIL_SECONDS = 0.08


def to_m4a(source: Path, target: Path) -> None:
    """MP3 → AAC mono en .m4a. Le .m4a indique son décalage de début, qu'AVFoundation respecte."""
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", str(source), "-map_metadata", "-1",
         "-ac", "1", "-ar", str(SAMPLE_RATE), "-c:a", "aac", "-b:a", "96k", str(target)],
        check=True,
    )


def decode(path: Path) -> np.ndarray:
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", str(SAMPLE_RATE), "-"],
        capture_output=True, check=True,
    ).stdout
    return np.frombuffer(raw, dtype=np.float32)


def loudness_profile(samples: np.ndarray) -> np.ndarray:
    """Niveau en dB par tranches de 10 ms."""
    window = int(SAMPLE_RATE * WINDOW_SECONDS)
    count = len(samples) // window
    frames = samples[: count * window].reshape(count, window)
    return 20 * np.log10(np.sqrt((frames ** 2).mean(axis=1)) + 1e-9)


@dataclass
class Span:
    start: float
    end: float

    @property
    def duration(self) -> float:
        return self.end - self.start


def silences(profile: np.ndarray, min_seconds: float = MIN_PAUSE_SECONDS) -> list[Span]:
    threshold = np.percentile(profile, 99) - SILENCE_BELOW_DB
    quiet = profile < threshold
    spans, i = [], 0
    while i < len(quiet):
        if not quiet[i]:
            i += 1
            continue
        j = i
        while j < len(quiet) and quiet[j]:
            j += 1
        if (j - i) * WINDOW_SECONDS >= min_seconds:
            spans.append(Span(i * WINDOW_SECONDS, j * WINDOW_SECONDS))
        i = j
    return spans


def voice_segments(samples: np.ndarray) -> list[Span]:
    """Passages de voix séparés par les pauses du récitant, resserrés sur la voix avec une petite marge."""
    profile = loudness_profile(samples)
    duration = len(samples) / SAMPLE_RATE
    pauses = silences(profile, min_seconds=0)
    pauses = [p for p in pauses if p.duration >= MIN_PAUSE_SECONDS or p.start == 0 or p.end >= duration - WINDOW_SECONDS]
    # Bornes de voix : entre les silences (y compris ceux du début et de la fin du fichier).
    edges = [0.0]
    for pause in pauses:
        edges += [pause.start, pause.end]
    edges.append(duration)
    segments = []
    for start, end in zip(edges[0::2], edges[1::2]):
        if end - start > WINDOW_SECONDS:
            segments.append(Span(max(0.0, start - LEAD_IN_SECONDS), min(duration, end + TAIL_SECONDS)))
    return segments


def frames(seconds: float) -> int:
    return int(round(seconds * SAMPLE_RATE))
