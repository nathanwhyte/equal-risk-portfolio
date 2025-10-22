import logging

import app.math as math
import app.fetch as fetch

from fastapi import FastAPI
from pydantic import BaseModel

import app.db as db

logger = logging.getLogger("uvicorn")
app = FastAPI()

db_engine = db.init_db_engine()


class EqualRiskRequest(BaseModel):
    tickers: list[str]


@app.get("/")
async def root() -> str:
    return "Hello, world!"


@app.post("/calculate")
async def calculate_equal_risk(request: EqualRiskRequest):
    logger.info(f"Received request {request.tickers}")

    tickers_not_in_db = db.check_tickers(db_engine, request.tickers)

    if len(tickers_not_in_db) > 0:
        logger.info(f"Fetching data for {tickers_not_in_db}")
        fetch.fetch_ticker_data(db_engine, tickers_not_in_db)

    logger.info(f"Calculating equal risk for {request.tickers}")

    weights = math.calculate(
        db_engine,
        request.tickers,
    )

    logger.info(f"Returning equal risk weights {weights}")

    return {"weights": weights}
