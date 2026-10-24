"""Les coupes audio sont nettes, plausibles et fidèles à la source."""

import numpy as np

import audio
import build_content
import text
from conftest import decoded, embedded, spec

# Silence exigé de part et d'autre de chaque morceau : rien du morceau voisin ne doit déborder.
SILENCE_AROUND_SECONDS = 0.15
# Débit d'Al-Hudhaify mesuré sur Ayat al-Kursî : de 0,19 à 0,38 s par lettre. Deux phrases fusionnées
# ou une phrase manquante sortent de cette plage.
SECONDS_PER_LETTER = (0.12, 0.60)
# Une pause aussi longue qui ne sert pas de coupe doit être tranchée par un humain.
LONG_PAUSE_SECONDS = 0.8
# Une trame AAC.
AAC_FRAME = 1024


def test_clips_are_well_formed(content):
    previous_end: dict[str, int] = {}
    for piece in content["pieces"]:
        clip = piece["audio"]
        path = embedded(clip["file"])
        assert path.exists(), f"fichier manquant : {clip['file']}"
        assert clip["sampleRate"] == audio.SAMPLE_RATE
        assert 0 <= clip["startFrame"] < clip["endFrame"] <= len(decoded(path))
        assert clip["startFrame"] >= previous_end.get(clip["file"], 0), "morceaux d'un même fichier dans l'ordre, sans chevauchement"
        previous_end[clip["file"]] = clip["endFrame"]


def test_no_overflow_around_the_piece(content, piece):
    clip = piece["audio"]
    samples = decoded(embedded(clip["file"]))
    profile = audio.loudness_profile(samples)
    threshold = audio.silence_threshold(profile)
    windows = int(round(SILENCE_AROUND_SECONDS / audio.WINDOW_SECONDS))
    start = clip["startFrame"] // int(audio.SAMPLE_RATE * audio.WINDOW_SECONDS)
    end = -(-clip["endFrame"] // int(audio.SAMPLE_RATE * audio.WINDOW_SECONDS))
    before = profile[max(0, start - windows):start]
    after = profile[end:end + windows]
    assert (before < threshold).all(), f"voix juste avant le début ({clip['startFrame'] / audio.SAMPLE_RATE:.2f} s)"
    assert (after < threshold).all(), f"voix juste après la fin ({clip['endFrame'] / audio.SAMPLE_RATE:.2f} s)"


def test_duration_is_plausible(content, piece):
    clip = piece["audio"]
    seconds = (clip["endFrame"] - clip["startFrame"]) / audio.SAMPLE_RATE
    letters = len(text.normalize_arabic(piece["arabic"]))
    low, high = SECONDS_PER_LETTER
    assert low <= seconds / letters <= high, f"{seconds:.2f} s pour {letters} lettres ({seconds / letters:.2f} s par lettre)"


def test_conversion_keeps_sample_alignment(content):
    names = {build_content.audio_name(1, 1) if p.get("verse") is None else build_content.audio_name(content["surah"], p["verse"])
             for p in content["pieces"]}
    for name in sorted(names):
        source = audio.decode(build_content.source_audio(name))
        converted = decoded(build_content.embedded_audio(name))
        assert abs(len(converted) - len(source)) <= AAC_FRAME, f"{name} : longueur différente"
        start, length = audio.SAMPLE_RATE, min(2 * audio.SAMPLE_RATE, len(source) - audio.SAMPLE_RATE)
        a = source[start:start + length].astype(np.float64)
        b = converted[start:start + length].astype(np.float64)
        correlation = np.fft.irfft(np.fft.rfft(a, 2 * length) * np.conj(np.fft.rfft(b, 2 * length)))
        lag = int(np.argmax(correlation))
        lag = lag - 2 * length if lag > length else lag
        assert lag == 0, f"{name} : décalage de {lag} échantillons après conversion"


def test_library_matches_the_segmentation(content, verse):
    """library.json est à jour, et aucune longue pause du récitant n'est laissée sans coupe."""
    groups = build_content.piece_groups(spec(content["id"]), verse["number"])
    sources = build_content.verse_sources(content["surah"], verse["number"])
    samples = decoded(build_content.embedded_audio(build_content.audio_name(content["surah"], verse["number"])))
    segmentation = build_content.verse_segmentation(sources, groups, samples)
    pieces = content["pieces"][verse["firstPiece"]:verse["lastPiece"] + 1]
    assert [(p["audio"]["startFrame"], p["audio"]["endFrame"]) for p in pieces] == \
           [(audio.frames(s.start), audio.frames(s.end)) for s in segmentation.pieces], "relancer build_content.py"
    long_pauses = [p for p in segmentation.ignored_pauses if p.duration >= LONG_PAUSE_SECONDS]
    assert not long_pauses, "pause longue sans coupe, à trancher : " + ", ".join(
        f"{p.start:.2f}-{p.end:.2f} s" for p in long_pauses)
