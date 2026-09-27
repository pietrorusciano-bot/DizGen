from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Term
from ..schemas import TermOut

router = APIRouter(prefix="/api/terms", tags=["terms"])


@router.get("", response_model=list[TermOut])
def list_terms(
    language: str = Query("it"),
    q: str | None = Query(None),
    db: Session = Depends(get_db),
):
    query = db.query(Term).filter(Term.language == language)
    if q:
        query = query.filter(Term.normalized.like(f"%{q.lower()}%"))
    return query.order_by(Term.term).all()
