import re
import unicodedata


def normalize(text: str) -> str:
    text = text.lower()
    text = unicodedata.normalize("NFD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return text


def _regex_for(term: str) -> str:
    words = [re.escape(w) for w in term.split()]
    joined = r"\s+".join(words)
    return r"(?<!\w)" + joined + r"(?!\w)"


def find_matches(text: str, terms: list[tuple[str, object]]) -> list[tuple[object, int, int]]:
    normalized_text = normalize(text)
    found: list[tuple[object, int, int]] = []
    for normalized, obj in terms:
        pattern = _regex_for(normalized)
        for m in re.finditer(pattern, normalized_text):
            found.append((obj, m.start(), m.end()))
    found.sort(key=lambda x: (x[2] - x[1]), reverse=True)
    kept: list[tuple[object, int, int]] = []
    occupied: list[tuple[int, int]] = []
    for obj, start, end in found:
        if any(start < o_end and end > o_start for o_start, o_end in occupied):
            continue
        kept.append((obj, start, end))
        occupied.append((start, end))
    kept.sort(key=lambda x: x[1])
    return kept
