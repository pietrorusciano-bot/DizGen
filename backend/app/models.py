from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Table
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base

term_generations = Table(
    "term_generations",
    Base.metadata,
    Column("term_id", ForeignKey("terms.id"), primary_key=True),
    Column("generation_id", ForeignKey("generations.id"), primary_key=True),
)


class Generation(Base):
    __tablename__ = "generations"

    id: Mapped[int] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(64))
    start_year: Mapped[int] = mapped_column(Integer)
    end_year: Mapped[int] = mapped_column(Integer)

    terms: Mapped[list["Term"]] = relationship(
        secondary=term_generations, back_populates="generations"
    )


class Term(Base):
    __tablename__ = "terms"

    id: Mapped[int] = mapped_column(primary_key=True)
    language: Mapped[str] = mapped_column(String(8), default="it", index=True)
    term: Mapped[str] = mapped_column(String(128), index=True)
    normalized: Mapped[str] = mapped_column(String(128), index=True)
    definition: Mapped[str] = mapped_column(String(1024))
    example: Mapped[str] = mapped_column(String(512), default="")
    source: Mapped[str] = mapped_column(String(256), default="manual")
    source_url: Mapped[str] = mapped_column(String(512), default="")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    generations: Mapped[list[Generation]] = relationship(
        secondary=term_generations, back_populates="terms"
    )


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(128))
    birth_year: Mapped[int] = mapped_column(Integer)
    gender: Mapped[str | None] = mapped_column(String(16), nullable=True)
    generation_id: Mapped[int | None] = mapped_column(
        ForeignKey("generations.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    generation: Mapped[Generation | None] = relationship()


class DiscoveredTerm(Base):
    __tablename__ = "discovered_terms"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    term_id: Mapped[int] = mapped_column(ForeignKey("terms.id"), index=True)
    discovered_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    term: Mapped[Term] = relationship()
