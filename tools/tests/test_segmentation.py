"""Non-régression de l'algorithme de découpe sur des coupes validées à l'oreille.

Référence : le prototype (docs/prototype/), récitation d'Al-Ghamidi, dont les coupes ont été
vérifiées une par une. On ne garde que les coupes où le récitant fait une vraie pause : celle entre
« ḥifẓuhumā » et « wa huwa » n'en a pas, ces deux morceaux sont donc fusionnés ici.
"""

import json
from pathlib import Path

import pytest

import audio
import build_content
import text

GOLDEN = Path(__file__).resolve().parent / "golden" / "ghamidi_2255.json"
TOLERANCE_SECONDS = 0.15


def test_finds_the_prototype_cuts():
    golden = json.loads(GOLDEN.read_text(encoding="utf-8"))
    samples = audio.decode(build_content.TOOLS.parent / golden["audio"])
    basmala = build_content.verse_sources(1, 1)["arabic"]
    phrases = [basmala] + text.waqf_phrases(build_content.verse_sources(2, 255)["arabic"])
    segmentation = audio.segment(samples, [len(text.normalize_arabic(p)) for p in phrases], golden["groupEnds"])
    found = [cut.middle for cut in segmentation.cuts]
    assert found == pytest.approx(golden["cuts"], abs=TOLERANCE_SECONDS)
