import argparse
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

from app.database import SessionLocal
from app.models import Term
from app.services.scraper import fetch_slengo_term, get_slengo_term_list, upsert_term


def main() -> int:
    parser = argparse.ArgumentParser(description="Importa termini da Slengo.")
    parser.add_argument("--limit", type=int, default=0, help="Max termini da importare (0 = tutti)")
    parser.add_argument("--offset", type=int, default=0, help="Offset di partenza")
    parser.add_argument("--workers", type=int, default=12, help="Richieste concorrenti")
    args = parser.parse_args()

    db = SessionLocal()
    try:
        slugs = get_slengo_term_list()
        print(f"Slengo: {len(slugs)} termini trovati nella pagina browse")

        end = len(slugs) if args.limit <= 0 else min(args.offset + args.limit, len(slugs))
        batch = slugs[args.offset:end]
        print(f"Da importare: {len(batch)} termini (offset={args.offset})")

        imported = 0
        failed = 0
        start = time.time()

        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futures = {ex.submit(fetch_slengo_term, s): s for s in batch}
            for i, fut in enumerate(as_completed(futures), 1):
                raw = fut.result()
                if raw is None:
                    failed += 1
                else:
                    upsert_term(db, raw)
                    imported += 1
                if i % 500 == 0:
                    db.commit()
                    print(f"  ... {i}/{len(batch)} importati={imported} falliti={failed}")

        db.commit()
        total = db.query(Term).filter(Term.language == "it").count()
        print(f"Fatto in {time.time() - start:.1f}s: {imported} importati, {failed} falliti")
        print(f"Totale termini italiani nel DB: {total}")
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())
