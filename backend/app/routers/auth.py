from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import generation_for_birth_year
from ..models import User
from ..schemas import RegisterRequest, Token, UserOut
from ..security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.username == payload.username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username già in uso")
    generation = generation_for_birth_year(db, payload.birth_year)
    user = User(
        username=payload.username,
        password_hash=hash_password(payload.password),
        birth_year=payload.birth_year,
        gender=payload.gender,
        generation_id=generation.id if generation else None,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(user.username)
    return Token(access_token=token, user=UserOut.model_validate(user))


@router.post("/login", response_model=Token)
def login(
    form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.username == form.username).first()
    if user is None or not verify_password(form.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenziali non valide"
        )
    token = create_access_token(user.username)
    return Token(access_token=token, user=UserOut.model_validate(user))
