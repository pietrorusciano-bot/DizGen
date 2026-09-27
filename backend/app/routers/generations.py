from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Generation
from ..schemas import GenerationOut

router = APIRouter(prefix="/api/generations", tags=["generations"])


@router.get("", response_model=list[GenerationOut])
def list_generations(db: Session = Depends(get_db)):
    return db.query(Generation).order_by(Generation.start_year).all()
