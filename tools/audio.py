"""Outils audio partagés : conversion, décodage, profil de volume, pauses et découpe en morceaux.

Découpe d'un fichier (un verset) en morceaux, guidée par la spécification :
1. on repère les pauses du récitant (creux du volume lissé) ;
2. on estime où tombe chaque frontière de morceau, au prorata du nombre de lettres ;
3. on attribue à chaque frontière la pause réelle la plus proche, dans l'ordre et une seule fois ;
4. chaque morceau est resserré sur la voix, avec une petite marge.
Les pauses non retenues sont rendues aussi : une longue pause ignorée doit être tranchée par un humain.
"""

import subprocess
from dataclasses import dataclass
from pathlib import Path

import numpy as np

SAMPLE_RATE = 44_100
WINDOW_SECONDS = 0.01

# Repérage des pauses : volume lissé sur 100 ms, sous le niveau de la voix (99e centile) moins 20 dB.
PAUSE_SMOOTHING_WINDOWS = 10
PAUSE_BELOW_DB = 20
MIN_PAUSE_SECONDS = 0.2
# Bornes précises de la voix : volume brut sous le niveau de la voix moins 35 dB.
SILENCE_BELOW_DB = 35
# Marges autour de la voix : on démarre juste avant l'attaque, on garde la fin du souffle.
LEAD_IN_SECONDS = 0.05
TAIL_SECONDS = 0.08


@dataclass(frozen=True)
class Span:
    start: float
    end: float

    @property
    def duration(self) -> float:
        return self.end - self.start

    @property
    def middle(self) -> float:
        return (self.start + self.end) / 2


class SegmentationError(Exception):
    pass


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


def duration(samples: np.ndarray) -> float:
    return len(samples) / SAMPLE_RATE


def frames(seconds: float) -> int:
    return int(round(seconds * SAMPLE_RATE))


def loudness_profile(samples: np.ndarray) -> np.ndarray:
    """Niveau en dB par tranches de 10 ms."""
    window = int(SAMPLE_RATE * WINDOW_SECONDS)
    count = len(samples) // window
    blocks = samples[: count * window].reshape(count, window)
    return 20 * np.log10(np.sqrt((blocks ** 2).mean(axis=1)) + 1e-9)


def voice_level(profile: np.ndarray) -> float:
    return float(np.percentile(profile, 99))


def silence_threshold(profile: np.ndarray) -> float:
    return voice_level(profile) - SILENCE_BELOW_DB


def _runs(mask: np.ndarray) -> list[Span]:
    spans, i = [], 0
    while i < len(mask):
        if not mask[i]:
            i += 1
            continue
        j = i
        while j < len(mask) and mask[j]:
            j += 1
        spans.append(Span(i * WINDOW_SECONDS, j * WINDOW_SECONDS))
        i = j
    return spans


def voice_bounds(samples: np.ndarray) -> Span:
    """Du premier au dernier instant où l'on entend la voix."""
    profile = loudness_profile(samples)
    loud = np.flatnonzero(profile >= silence_threshold(profile))
    if len(loud) == 0:
        raise SegmentationError("aucune voix détectée")
    return Span(loud[0] * WINDOW_SECONDS, (loud[-1] + 1) * WINDOW_SECONDS)


def pauses(samples: np.ndarray) -> list[Span]:
    """Pauses du récitant à l'intérieur de la voix (creux du volume lissé)."""
    profile = loudness_profile(samples)
    kernel = np.ones(PAUSE_SMOOTHING_WINDOWS) / PAUSE_SMOOTHING_WINDOWS
    smoothed = np.convolve(profile, kernel, mode="same")
    voice = voice_bounds(samples)
    quiet = smoothed < voice_level(profile) - PAUSE_BELOW_DB
    return [run for run in _runs(quiet)
            if run.duration >= MIN_PAUSE_SECONDS and run.start > voice.start and run.end < voice.end]


def _assign(candidates: list[Span], targets: list[float]) -> list[Span]:
    """Choisit une pause par frontière, dans l'ordre, en minimisant l'écart total à l'estimation."""
    m, k = len(candidates), len(targets)
    if k > m:
        raise SegmentationError(f"{k} coupes attendues mais seulement {m} pauses trouvées")
    inf = float("inf")
    cost = [[0.0] * (m + 1)] + [[inf] * (m + 1) for _ in range(k)]
    take = [[False] * (m + 1) for _ in range(k + 1)]
    for i in range(1, k + 1):
        for j in range(i, m + 1):
            with_pause = cost[i - 1][j - 1] + abs(candidates[j - 1].middle - targets[i - 1])
            if with_pause <= cost[i][j - 1]:
                cost[i][j], take[i][j] = with_pause, True
            else:
                cost[i][j] = cost[i][j - 1]
    chosen, i, j = [], k, m
    while i > 0:
        if take[i][j]:
            chosen.append(candidates[j - 1])
            i -= 1
        j -= 1
    return chosen[::-1]


@dataclass
class Segmentation:
    pieces: list[Span]
    cuts: list[Span]
    ignored_pauses: list[Span]


def segment(samples: np.ndarray, unit_lengths: list[int], group_ends: list[int]) -> Segmentation:
    """Découpe un fichier en morceaux.

    `unit_lengths` : nombre de lettres de chaque phrase du fichier, dans l'ordre.
    `group_ends` : numéro (à partir de 1) de la dernière phrase de chaque morceau.
    """
    voice = voice_bounds(samples)
    total = sum(unit_lengths)
    targets, cumulated = [], 0
    for index, length in enumerate(unit_lengths, start=1):
        cumulated += length
        if index in group_ends[:-1]:
            targets.append(voice.start + cumulated / total * voice.duration)
    candidates = pauses(samples)
    cuts = _assign(candidates, targets)

    profile = loudness_profile(samples)
    loud = profile >= silence_threshold(profile)
    file_end = duration(samples)

    def last_voice_before(t: float) -> float:
        index = np.flatnonzero(loud[: int(t / WINDOW_SECONDS)])
        return (index[-1] + 1) * WINDOW_SECONDS

    def first_voice_after(t: float) -> float:
        start = int(t / WINDOW_SECONDS)
        return (start + np.flatnonzero(loud[start:])[0]) * WINDOW_SECONDS

    edges = [voice.start] + [x for cut in cuts for x in (last_voice_before(cut.middle), first_voice_after(cut.middle))] + [voice.end]
    pieces = [Span(max(0.0, start - LEAD_IN_SECONDS), min(file_end, end + TAIL_SECONDS))
              for start, end in zip(edges[0::2], edges[1::2])]
    return Segmentation(pieces, cuts, [p for p in candidates if p not in cuts])
