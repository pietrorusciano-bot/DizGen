import json

from app.database import SessionLocal
from app.models import Term


def main() -> int:
    db = SessionLocal()
    try:
        terms = db.query(Term).all()
        data = [
            {
                "language": t.language,
                "term": t.term,
                "definition": t.definition,
                "example": t.example,
                "source": t.source,
                "source_url": t.source_url,
                "generations": [g.key for g in t.generations],
            }
            for t in terms
        ]
    finally:
        db.close()

    with open("app/terms_dump.json", "w", encoding="utf-8") as f:
        json.dump({"terms": data}, f, ensure_ascii=False)
    print(f"Esportati {len(data)} termini in app/terms_dump.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
