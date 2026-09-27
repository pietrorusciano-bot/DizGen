import time

from app.database import SessionLocal
from app.models import Term

TOTAL = 10775


def main() -> None:
    while True:
        db = SessionLocal()
        try:
            s = db.query(Term).filter(Term.source == "slengo").count()
        finally:
            db.close()
        pct = s / TOTAL * 100
        with open("progress_log.txt", "a", encoding="utf-8") as f:
            f.write(
                f"{time.strftime('%d/%m %H:%M:%S')} - {pct:.1f}% "
                f"({s}/{TOTAL} termini Slengo)\n"
            )
        time.sleep(900)


if __name__ == "__main__":
    main()
