import io
import math
import re
import struct
import wave

import httpx

from ..config import settings

GROQ_TRANSCRIBE_URL = "https://api.groq.com/openai/v1/audio/transcriptions"
PCM_RMS_THRESHOLD = 120.0

_HALLUCINATIONS = {
    "grazie",
    "grazie mille",
    "grazie per aver guardato",
    "grazie per la visione",
    "grazie per aver ascoltato",
    "grazie per l'ascolto",
    "ciao",
    "ciao ciao",
    "arrivederci",
    "thank you",
    "thank you for watching",
    "sottotitoli di",
    "sottotitoli creati da",
    "sottotitoli da",
}


def clean_transcript(text: str) -> str:
    sentences = re.split(r"(?<=[.!?])\s+", text.strip())
    kept = []
    for sentence in sentences:
        normalized = sentence.strip().strip(".,;:!? ").lower()
        if normalized in _HALLUCINATIONS:
            continue
        kept.append(sentence.strip())
    return " ".join(kept).strip()


def pcm16_to_wav(pcm: bytes, sample_rate: int, channels: int) -> bytes:
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        w.writeframes(pcm)
    return buffer.getvalue()


def pcm16_rms(pcm: bytes) -> float:
    sample_count = len(pcm) // 2
    if sample_count == 0:
        return 0.0
    samples = struct.unpack(f"<{sample_count}h", pcm[: sample_count * 2])
    return math.sqrt(sum(sample * sample for sample in samples) / sample_count)


def transcribe_pcm16(pcm: bytes, sample_rate: int = 16000, channels: int = 1) -> str:
    if not settings.GROQ_API_KEY:
        raise RuntimeError("GROQ_API_KEY non configurata")

    if pcm16_rms(pcm) < PCM_RMS_THRESHOLD:
        return ""

    wav_bytes = pcm16_to_wav(pcm, sample_rate, channels)

    response = httpx.post(
        GROQ_TRANSCRIBE_URL,
        headers={"Authorization": f"Bearer {settings.GROQ_API_KEY}"},
        files={"file": ("audio.wav", wav_bytes, "audio/wav")},
        data={
            "model": settings.GROQ_MODEL,
            "language": "it",
            "prompt": "Conversazione naturale in italiano. Trascrivi fedelmente le parole pronunciate.",
            "response_format": "json",
        },
        timeout=60,
    )
    response.raise_for_status()
    data = response.json()
    return clean_transcript((data.get("text") or "").strip())
