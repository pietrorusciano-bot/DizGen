from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from .database import Base, SessionLocal, engine
from .routers import analyze, auth, discovered, generations, profile, terms, transcribe
from .scheduler import start_scheduler, stop_scheduler
from .seed_data import seed, seed_from_dump


def _migrate() -> None:
    with engine.begin() as conn:
        columns = [row[1] for row in conn.execute(text("PRAGMA table_info(users)"))]
        if "gender" not in columns:
            conn.execute(text("ALTER TABLE users ADD COLUMN gender VARCHAR(16)"))


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    _migrate()
    db = SessionLocal()
    try:
        seed(db)
        seed_from_dump(db)
    finally:
        db.close()
    start_scheduler()
    yield
    stop_scheduler()


app = FastAPI(title="GeneraTalk API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(generations.router)
app.include_router(terms.router)
app.include_router(analyze.router)
app.include_router(transcribe.router)
app.include_router(discovered.router)
app.include_router(profile.router)


@app.get("/api/health")
def health():
    return {"status": "ok"}
