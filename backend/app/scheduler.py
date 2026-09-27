import logging

from apscheduler.schedulers.background import BackgroundScheduler

from .config import settings
from .database import SessionLocal
from .services.scraper import run_scraping

logger = logging.getLogger("dizgen.scheduler")
scheduler = BackgroundScheduler()


def _job():
    db = SessionLocal()
    try:
        added = run_scraping(db)
        logger.info("Scraping completato: %d termini aggiunti/aggiornati", added)
    except Exception as exc:
        logger.exception("Errore durante lo scraping: %s", exc)
    finally:
        db.close()


def start_scheduler():
    if not settings.SCRAPE_ENABLED:
        return
    scheduler.add_job(
        _job,
        "interval",
        minutes=settings.SCRAPE_INTERVAL_MINUTES,
        id="scrape",
        replace_existing=True,
    )
    scheduler.start()


def stop_scheduler():
    if scheduler.running:
        scheduler.shutdown(wait=False)
