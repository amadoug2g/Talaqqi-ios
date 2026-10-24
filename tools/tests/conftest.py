"""Tests du contenu embarqué. Chaque test est paramétré sur les contenus de library.json.

    tools/.venv/bin/python -m pytest tools/tests                    # tout
    tools/.venv/bin/python -m pytest tools/tests --content 114      # un seul contenu
"""

import json
import sys
from functools import cache
from pathlib import Path

import pytest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))

import audio  # noqa: E402
import build_content  # noqa: E402


def pytest_addoption(parser):
    parser.addoption("--content", action="append", default=[], help="identifiant du contenu à tester (« 2:255 », « 114 »)")


def library() -> dict:
    return json.loads(build_content.LIBRARY.read_text(encoding="utf-8"))


def selected_contents(config) -> list[dict]:
    wanted = config.getoption("content")
    return [c for c in library()["contents"] if not wanted or c["id"] in wanted]


def spec(content_id: str) -> dict:
    return next(s for s in build_content.specs() if s["id"] == content_id)


@cache
def decoded(path: Path):
    return audio.decode(path)


def embedded(file: str) -> Path:
    return build_content.RESOURCES / "Audio" / file


def pytest_generate_tests(metafunc):
    contents = selected_contents(metafunc.config)
    if "piece" in metafunc.fixturenames:
        cases = [(c, p) for c in contents for p in c["pieces"]]
        metafunc.parametrize("content,piece", cases, ids=[f"{c['id']}-morceau{p['index']}" for c, p in cases])
    elif "verse" in metafunc.fixturenames:
        cases = [(c, v) for c in contents for v in c["verses"]]
        metafunc.parametrize("content,verse", cases, ids=[f"{c['id']}-verset{v['number']}" for c, v in cases])
    elif "content" in metafunc.fixturenames:
        metafunc.parametrize("content", contents, ids=[c["id"] for c in contents])
