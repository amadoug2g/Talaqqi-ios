"""Découpe des textes sources, sans jamais en modifier les mots."""

import re

# Signes de pause (waqf) du texte ottoman : ۖ ۗ ۘ ۙ ۚ ۛ
WAQF_MARKS = "ۖۗۘۙۚۛ"


def strip_footnote_refs(text: str) -> str:
    """Retire les appels de note « [112] » de la traduction ; le reste est recopié tel quel."""
    return re.sub(r"\[\d+\]", "", text).strip()


def waqf_phrases(arabic: str) -> list[str]:
    """Coupe le verset après chaque mot portant un signe de pause. Le signe reste attaché au mot."""
    phrases, current = [], []
    for word in arabic.split():
        current.append(word)
        if word[-1] in WAQF_MARKS:
            phrases.append(" ".join(current))
            current = []
    if current:
        phrases.append(" ".join(current))
    return phrases


def transliteration_phrases(text: str) -> list[str]:
    """La translittération QUL (Tajweed) marque chaque arrêt par « ,(u) », « :(i) », « ; » ou une simple virgule."""
    return [part for part in re.split(r"(?<=[);,])\s+", text.strip()) if part]


def sentences(text: str) -> list[str]:
    return [part for part in re.split(r"(?<=[.?!])\s+(?=[A-ZÀ-ÖØ-Þ«])", text.strip()) if part]


def join(parts: list[str], span: list[int]) -> str:
    """`span` = [première, dernière], numérotées à partir de 1."""
    first, last = span
    return " ".join(parts[first - 1:last])


_DIACRITICS = re.compile("[ؐ-ًؚ-ٰٟۖ-ۭـ]")


def normalize_arabic(text: str) -> str:
    """Pour comparer avec la transcription : sans voyelles, signes coraniques ni variantes de alif."""
    text = _DIACRITICS.sub("", text)
    for variants, base in (("ٱأإآ", "ا"), ("ى", "ي"), ("ة", "ه"), ("ؤ", "و"), ("ئ", "ي")):
        for variant in variants:
            text = text.replace(variant, base)
    return re.sub(r"[^ء-ي]", "", text)
