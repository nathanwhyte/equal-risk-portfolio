import os
from typing import override
from uuid import UUID

from sqlalchemy import DateTime, Double, String, create_engine, func, select, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Mapped, Session, declarative_base, mapped_column
from sqlalchemy.types import TIMESTAMP

Base = declarative_base()  # pyright: ignore[reportAny]


class ClosePrice(Base):  # pyright: ignore[reportAny]
    __tablename__: str = "close_prices"

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=func.gen_random_uuid()
    )
    ticker: Mapped[str] = mapped_column(String(16), nullable=False)
    date: Mapped[str] = mapped_column(DateTime, nullable=False)
    close: Mapped[float] = mapped_column(Double, nullable=False)
    created_at: Mapped[str] = mapped_column(
        TIMESTAMP, nullable=False, default=text("now()")
    )
    updated_at: Mapped[str] = mapped_column(
        TIMESTAMP, nullable=False, default=text("now()")
    )

    @override
    def __repr__(self):
        return f"Close(id={self.id!r}, ticker={self.ticker!r}, date={self.date!r}, close={self.close!r})"


def init_db_engine() -> Engine:
    pg_user = os.getenv("EQUAL_RISK_PORTFOLIO_DATABASE_USERNAME")
    pg_pass = os.getenv("EQUAL_RISK_PORTFOLIO_DATABASE_PASSWORD")
    pg_host = os.getenv("EQUAL_RISK_PORTFOLIO_DATABASE_HOST")
    pg_db = os.getenv("EQUAL_RISK_PORTFOLIO_DATABASE")

    print("\n\n")
    print(f"Connecting to database: postgresql+psycopg2://{pg_user}:{pg_pass}@{pg_host}/{pg_db}")
    print("\n\n")

    db_url = f"postgresql+psycopg2://{pg_user}:{pg_pass}@{pg_host}/{pg_db}"

    return create_engine(db_url)


def check_tickers(engine: Engine, tickers: list[str]):
    with Session(engine) as session:
        stmt = (
            select(ClosePrice.ticker).where(ClosePrice.ticker.in_(tickers)).distinct()
        )
        existing = [r[0] for r in session.execute(stmt)]
        return list(set(tickers) - set(existing))
