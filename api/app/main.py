import logging
from typing import Optional

from fastapi import FastAPI
from pydantic import BaseModel

import app.db as db
import app.fetch as fetch
import app.math as math

logger = logging.getLogger("uvicorn")
app = FastAPI()

db_engine = db.init_db_engine()


class EqualRiskRequest(BaseModel):
    tickers: list[str]
    cap: Optional[float]
    top_n: Optional[int]


@app.get("/")
async def root() -> str:
    return "Hello, world!"


@app.post("/calculate")
async def calculate_equal_risk(request: EqualRiskRequest):
    logger.info(f"Received request {request}")

    tickers_not_in_db = db.check_tickers(db_engine, request.tickers)

    if len(tickers_not_in_db) > 0:
        logger.info(f"Fetching data for {tickers_not_in_db}")
        fetch.fetch_ticker_data(db_engine, tickers_not_in_db)

    logger.info(f"Calculating equal risk for {request.tickers}")

    weights = math.calculate(
        db_engine,
        request.tickers,
        cap=request.cap,
        top_n=request.top_n,
    )

    logger.info(f"Returning equal risk weights {weights}")

    return {"weights": weights}
