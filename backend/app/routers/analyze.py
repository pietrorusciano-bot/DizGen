from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import DiscoveredTerm, Term, User
from ..schemas import AnalyzeRequest, AnalyzeResponse, TermMatch
from ..services.matcher import find_matches

router = APIRouter(prefix="/api/analyze", tags=["analyze"])


@router.post("", response_model=AnalyzeResponse)
def analyze_text(
    payload: AnalyzeRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    terms = db.query(Term).filter(Term.language == payload.language).all()
    candidates = [(t.normalized, t) for t in terms]
    matched = find_matches(payload.text, candidates)

    user_generation_key = user.generation.key if user.generation else None

    results: list[TermMatch] = []
    for term, _start, _end in matched:
        using = [g.key for g in term.generations]
        familiar = user_generation_key in using
        if not familiar:
            existing = (
                db.query(DiscoveredTerm)
                .filter(
                    DiscoveredTerm.user_id == user.id,
                    DiscoveredTerm.term_id == term.id,
                )
                .first()
            )
            if existing is None:
                db.add(DiscoveredTerm(user_id=user.id, term_id=term.id))
        results.append(
            TermMatch(
                id=term.id,
                term=term.term,
                definition=term.definition,
                example=term.example,
                source=term.source,
                source_url=term.source_url,
                using_generations=using,
                familiar=familiar,
            )
        )
    db.commit()
    return AnalyzeResponse(language=payload.language, matches=results)
