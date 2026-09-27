from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from .database import get_db
from .models import Generation, User
from .security import decode_access_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def get_current_user(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
) -> User:
    subject = decode_access_token(token)
    if subject is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token non valido o scaduto",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = db.query(User).filter(User.username == subject).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Utente non trovato"
        )
    return user


def generation_for_birth_year(db: Session, birth_year: int) -> Generation:
    generation = (
        db.query(Generation)
        .filter(Generation.start_year <= birth_year, Generation.end_year >= birth_year)
        .first()
    )
    if generation is None:
        generation = db.query(Generation).order_by(Generation.end_year.desc()).first()
    return generation
