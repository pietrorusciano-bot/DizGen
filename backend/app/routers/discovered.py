from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import DiscoveredTerm, Term, User
from ..schemas import TermOut

router = APIRouter(prefix="/api/discovered", tags=["discovered"])


@router.get("", response_model=list[TermOut])
def list_discovered(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(Term)
        .join(DiscoveredTerm, DiscoveredTerm.term_id == Term.id)
        .filter(DiscoveredTerm.user_id == user.id)
        .order_by(DiscoveredTerm.discovered_at.desc())
        .all()
    )
    return rows


@router.post("/{term_id}", response_model=TermOut)
def mark_discovered(
    term_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    term = db.query(Term).filter(Term.id == term_id).first()
    if term is None:
        raise HTTPException(status_code=404, detail="Termine non trovato")
    existing = (
        db.query(DiscoveredTerm)
        .filter(
            DiscoveredTerm.user_id == user.id,
            DiscoveredTerm.term_id == term_id,
        )
        .first()
    )
    if existing is None:
        db.add(DiscoveredTerm(user_id=user.id, term_id=term_id))
        db.commit()
    return term
