import re
import time
from dataclasses import dataclass, field
from urllib.parse import unquote

import httpx
from bs4 import BeautifulSoup

from ..models import Generation, Term
from ..services.matcher import normalize

DEFAULT_USING_GENERATIONS = ["genz", "genalpha"]

SLENGO_BROWSE_URL = "https://slengo.it/browse"
SLENGO_DEFINE_URL = "https://slengo.it/define/{slug}"

_HEADERS = {
    "User-Agent": "Mozilla/5.0 (DizGen/0.1; +slang dictionary aggregator)",
    "Accept-Encoding": "gzip",
}


def _fetch(url: str, timeout: int = 30) -> tuple[str, int]:
    response = httpx.get(url, timeout=timeout, headers=_HEADERS, follow_redirects=True)
    return response.text, response.status_code


@dataclass
class RawTerm:
    language: str
    term: str
    definition: str
    example: str = ""
    source: str = "web"
    source_url: str = ""
    using_generations: list[str] = field(default_factory=lambda: list(DEFAULT_USING_GENERATIONS))


def _fetch_urban_dictionary() -> list[RawTerm]:
    url = "https://api.urbandictionary.com/v0/random"
    response = httpx.get(url, timeout=15, headers=_HEADERS)
    response.raise_for_status()
    data = response.json()
    out: list[RawTerm] = []
    for entry in data.get("list", [])[:20]:
        out.append(
            RawTerm(
                language="en",
                term=entry.get("word", "").strip(),
                definition=(entry.get("definition", "") or "").strip()[:1000],
                example=(entry.get("example", "") or "").strip()[:500],
                source="urban-dictionary",
                source_url=entry.get("permalink", ""),
            )
        )
    return out


def get_slengo_term_list() -> list[str]:
    content, _status = _fetch(SLENGO_BROWSE_URL, timeout=60)
    terms = re.findall(r'href="/define/([^"]+)"', content)
    seen: dict[str, None] = {}
    result: list[str] = []
    for raw in terms:
        slug = raw.strip()
        if not slug or slug in seen:
            continue
        seen[slug] = None
        result.append(slug)
    return result


def fetch_slengo_term(slug: str) -> RawTerm | None:
    url = SLENGO_DEFINE_URL.format(slug=slug)
    content, status = _fetch(url)
    if status != 200:
        return None
    soup = BeautifulSoup(content, "html.parser")
    card = soup.select_one("article.definition-card")
    if card is None:
        return None

    definition_el = card.select_one("div.word-definition")
    if definition_el is None:
        return None
    definition = definition_el.get_text(" ", strip=True)
    definition = re.sub(r"\s*Cfr\..*$", "", definition, flags=re.DOTALL).strip()
    definition = definition[:1000]

    examples = [li.get_text(" ", strip=True) for li in card.select(".word-examples li")]
    example = examples[0][:500] if examples else ""

    title_el = card.select_one("header p")
    word = title_el.get_text(strip=True) if title_el else unquote(slug).replace("-", " ")
    word = re.sub(r"\s+", " ", word).strip()

    if not definition:
        return None

    return RawTerm(
        language="it",
        term=word,
        definition=definition,
        example=example,
        source="slengo",
        source_url=url,
    )


def fetch_slengo_batch(limit: int = 20, offset: int = 0) -> list[RawTerm]:
    terms = get_slengo_term_list()
    batch = terms[offset : offset + limit]
    out: list[RawTerm] = []
    for term in batch:
        try:
            raw = fetch_slengo_term(term)
        except Exception:
            raw = None
        if raw is not None:
            out.append(raw)
        time.sleep(0.3)
    return out


def upsert_term(db, raw: RawTerm) -> Term:
    normalized = normalize(raw.term)
    existing = (
        db.query(Term)
        .filter(Term.language == raw.language, Term.normalized == normalized)
        .first()
    )
    generations = (
        db.query(Generation).filter(Generation.key.in_(raw.using_generations)).all()
    )
    if existing:
        existing.definition = raw.definition or existing.definition
        existing.example = raw.example or existing.example
        existing.source = raw.source
        existing.source_url = raw.source_url or existing.source_url
        if generations:
            existing.generations = generations
        return existing
    term = Term(
        language=raw.language,
        term=raw.term,
        normalized=normalized,
        definition=raw.definition,
        example=raw.example,
        source=raw.source,
        source_url=raw.source_url,
        generations=generations,
    )
    db.add(term)
    return term


def run_scraping(db, slengo_limit: int = 20) -> int:
    added = 0

    try:
        raw_terms = _fetch_urban_dictionary()
    except Exception:
        raw_terms = []
    for raw in raw_terms:
        if raw.term:
            upsert_term(db, raw)
            added += 1

    try:
        slengo_terms = get_slengo_term_list()
    except Exception:
        slengo_terms = []

    if slengo_terms:
        existing_count = db.query(Term).filter(Term.source == "slengo").count()
        offset = existing_count % len(slengo_terms)
        try:
            raw_terms = fetch_slengo_batch(limit=slengo_limit, offset=offset)
        except Exception:
            raw_terms = []
        for raw in raw_terms:
            if raw.term:
                upsert_term(db, raw)
                added += 1

    db.commit()
    return added
