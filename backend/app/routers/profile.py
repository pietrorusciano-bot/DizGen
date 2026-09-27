from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import DiscoveredTerm, User
from ..schemas import ProfileUpdateRequest, UserOut

router = APIRouter(prefix="/api/profile", tags=["profile"])


@router.get("", response_model=UserOut)
def get_profile(
    user: User = Depends(get_current_user),
):
    return user


@router.patch("", response_model=UserOut)
def update_profile(
    payload: ProfileUpdateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if payload.gender is not None:
        user.gender = payload.gender
    db.commit()
    db.refresh(user)
    return user


@router.delete("", status_code=204)
def delete_profile(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db.query(DiscoveredTerm).filter(DiscoveredTerm.user_id == user.id).delete()
    db.delete(user)
    db.commit()
    return Response(status_code=204)
