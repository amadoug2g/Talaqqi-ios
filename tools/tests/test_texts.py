"""Les textes affichés sont exactement ceux des sources : aucun mot ajouté, retiré ou changé."""

import re

import build_content
import text
from conftest import spec

EM_DASH = "—"
EMOJI = re.compile("[\U0001f300-\U0001faff☀-➿]")


def verse_pieces(content: dict, verse: dict) -> list[dict]:
    return content["pieces"][verse["firstPiece"]:verse["lastPiece"] + 1]


def test_pieces_reproduce_the_sources(content, verse):
    sources = build_content.verse_sources(content["surah"], verse["number"])
    pieces = verse_pieces(content, verse)
    for field in ("arabic", "phonetic", "translation"):
        rebuilt = " ".join(piece[field] for piece in pieces)
        assert rebuilt == sources[field], f"{field} : le texte des morceaux ne redonne pas la source"
    assert verse["translation"] == sources["translation"]


def test_basmala_reproduces_its_source(content):
    if not spec(content["id"]).get("basmala"):
        return
    basmala = content["pieces"][0]
    sources = build_content.verse_sources(1, 1)
    assert basmala.get("verse") is None
    for field in ("arabic", "phonetic", "translation"):
        assert basmala[field] == sources[field]


def test_only_footnote_references_are_removed(content, verse):
    raw = build_content.load(build_content.SOURCES / "quranenc" / build_content.TRANSLATION_KEY
                             / f"{content['surah']:03d}{verse['number']:03d}.json")["data"]["translation"]
    assert re.sub(r"\[\d+\]", "", raw).strip() == verse["translation"]
    assert not re.search(r"\[\d+\]", verse["translation"])


def test_split_sources_agree(content, verse):
    groups = build_content.piece_groups(spec(content["id"]), verse["number"])
    if not groups:
        return
    sources = build_content.verse_sources(content["surah"], verse["number"])
    phrases = text.waqf_phrases(sources["arabic"])
    stops = text.transliteration_phrases(sources["phonetic"])
    sentences = text.sentences(sources["translation"])
    assert len(phrases) == len(stops), "autant de signes de pause en arabe que d'arrêts dans la phonétique"
    for key, total in (("phrases", len(phrases)), ("sentences", len(sentences))):
        expected_start = 1
        for group in groups:
            first, last = group[key]
            assert first == expected_start and last >= first, f"{key} : chaque élément utilisé une fois, dans l'ordre"
            expected_start = last + 1
        assert expected_start == total + 1, f"{key} : tous les éléments de la source sont utilisés"


def test_labels_have_no_em_dash_or_emoji(content):
    for label in (content["title"], content["subtitle"]):
        assert EM_DASH not in label
        assert not EMOJI.search(label)


def test_pieces_and_verses_are_consistent(content):
    assert [p["index"] for p in content["pieces"]] == list(range(len(content["pieces"])))
    expected_first = 1 if spec(content["id"]).get("basmala") else 0
    for verse in content["verses"]:
        assert verse["firstPiece"] == expected_first
        assert all(p["verse"] == verse["number"] for p in verse_pieces(content, verse))
        expected_first = verse["lastPiece"] + 1
    assert expected_first == len(content["pieces"])
    assert content["verseCount"] == len(content["verses"])


def test_surah_info_reproduces_its_source(content):
    path = build_content.surah_info_source(content["surah"])
    if content["kind"] != "surah" or not path.exists():
        assert content.get("info") is None, "pas de fiche sans source"
        return
    source = build_content.load(path)["data"]["french"]
    assert content["info"] == {"objectives": source, "source": build_content.LIBRARY_SOURCES["surahInfo"]}


def test_translated_name_reproduces_its_source(content):
    names = build_content.load(build_content.surah_names_source())["data"]
    assert content["translatedName"] == names[str(content["surah"])]
