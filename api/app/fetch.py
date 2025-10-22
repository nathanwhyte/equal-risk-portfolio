from datetime import date, datetime, timedelta, timezone
from uuid import uuid4

from polygon import (
    RESTClient,  # pyright: ignore[reportAttributeAccessIssue, reportUnknownVariableType]
)
from sqlalchemy import text
from sqlalchemy.engine import Engine

polygon_client = RESTClient("pfVuWDAv5Y4Vs1JkIWlEMtGyfFhRdrw9")

today = date.today()
yesterday = today - timedelta(days=1)
prior_year = today.year - 1


def fetch_close_prices(ticker: str):
    aggs = []
    for a in polygon_client.list_aggs(
        ticker,
        1,
        "day",
        f"{prior_year}-01-01",
        yesterday.strftime("%Y-%m-%d"),
        adjusted="true",
        sort="asc",
    ):
        aggs.append(
            {
                "id": str(uuid4()),
                "ticker": ticker,
                # normalize polygon timestamps to UTC
                "date": str(
                    datetime.fromtimestamp(a.timestamp / 1000, tz=timezone.utc)
                ),
                "close": float(a.close),
            }
        )

    return aggs


def fetch_ticker_data(engine: Engine, tickers: list[str]):
    data = []
    for t in tickers:
        data.extend(fetch_close_prices(t))

    with engine.begin() as conn:
        _ = conn.execute(
            text(
                "INSERT INTO close_prices (id, ticker, date, close) VALUES (:id, :ticker, :date, :close)"
            ),
            data,
        )
