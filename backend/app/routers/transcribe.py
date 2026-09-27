from fastapi import APIRouter, Depends, HTTPException, Request

from ..deps import get_current_user
from ..models import User
from ..services.transcriber import transcribe_pcm16

router = APIRouter(prefix="/api/transcribe", tags=["transcribe"])


@router.post("")
async def transcribe_audio(
    request: Request,
    _user: User = Depends(get_current_user),
):
    sample_rate = int(request.query_params.get("sample_rate", "16000"))
    channels = int(request.query_params.get("channels", "1"))
    body = await request.body()
    if not body:
        raise HTTPException(status_code=400, detail="Audio vuoto")
    try:
        text = transcribe_pcm16(body, sample_rate=sample_rate, channels=channels)
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Errore Groq: {exc}")
    return {"text": text}
