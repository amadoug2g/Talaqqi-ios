"""Seconde oreille : la transcription de chaque morceau correspond au texte attendu, du premier au dernier mot."""

import difflib

import pytest

import text
import verify_pieces
from conftest import decoded, embedded

MIN_SIMILARITY = 0.75
MIN_WORD_SIMILARITY = 0.6


def words(arabic: str) -> list[str]:
    return [w for w in (text.normalize_arabic(word) for word in arabic.split()) if w]


def similar(a: str, b: str) -> float:
    return difflib.SequenceMatcher(None, a, b).ratio()


def test_transcription_matches_the_piece(content, piece):
    clip = piece["audio"]
    samples = verify_pieces.piece_samples(decoded(embedded(clip["file"])), clip)
    try:
        heard = verify_pieces.transcribe(samples)
    except verify_pieces.WhisperUnavailable as error:
        pytest.skip(f"non exécuté : {error}")
    expected, got = words(piece["arabic"]), words(heard)
    assert got, "rien n'a été entendu"
    overall = similar("".join(expected), "".join(got))
    detail = f"attendu « {piece['arabic']} », entendu « {heard} »"
    assert overall >= MIN_SIMILARITY, f"ressemblance {overall:.0%} : {detail}"
    assert similar(expected[0], got[0]) >= MIN_WORD_SIMILARITY, f"le début ne correspond pas : {detail}"
    assert similar(expected[-1], got[-1]) >= MIN_WORD_SIMILARITY, f"la fin ne correspond pas : {detail}"
