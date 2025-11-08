from datetime import date, timedelta

import numpy as np
import pandas as pd
from scipy.optimize import minimize
from sqlalchemy import select
from sqlalchemy.engine import Engine

from app.db import ClosePrice


def risk_contributions(weights: np.ndarray, cov_matrix: pd.Series):
    # `weights.T` is shorthand for transposing the weights array
    total_portfolio_variance = np.dot(weights.T, np.dot(cov_matrix.values, weights))

    # `@` is shorthand for matrix multiplication
    marginal_contrib = cov_matrix.values @ weights

    risk_contrib = weights * marginal_contrib

    return risk_contrib, total_portfolio_variance


def risk_budget_objective(weights: np.ndarray, cov_matrix: pd.Series):
    risk_contrib, total_portfolio_variance = risk_contributions(weights, cov_matrix)
    risk_contrib_percent = risk_contrib / total_portfolio_variance

    n_assets = len(weights)

    target_percent = np.array([1.0 / n_assets] * n_assets)
    return np.sum((risk_contrib_percent - target_percent) ** 2)


def cap_and_redistribute(
    raw_weights: pd.Series, past_returns: pd.Series, cap: float, top_n: int
) -> pd.Series:
    # 1) Apply cap
    capped = raw_weights.copy()
    capped = capped.clip(upper=cap)
    surplus = 1.0 - capped.sum()

    if surplus <= 0 or top_n == 0:
        # All surplus used or no redistribution requested
        return capped / capped.sum()

    # 2) Identify top N tickers by past_returns
    #    Drop tickers missing returns
    valid_returns = past_returns.reindex(capped.index).dropna()
    n = min(top_n, len(valid_returns))
    top_tickers = valid_returns.nlargest(n).index

    # 3) Add equal share of surplus to each
    add_each = surplus / n
    capped.loc[top_tickers] += add_each

    # 4) Normalize final to exactly sum to 1
    return capped / capped.sum()


def equal_risk(
    prior_year_data: pd.DataFrame,
    current_year_data: pd.DataFrame,
    cap: float | None = None,
    top_n: int | None = None,
) -> pd.Series:
    prior_year_data = prior_year_data.dropna(axis=1, how="all")
    current_year_data = current_year_data.dropna(axis=1, how="all")

    daily_returns_prior = prior_year_data.pct_change(fill_method=None)

    cov_matrix_prior = daily_returns_prior.cov()
    cov_matrix_prior += np.eye(len(cov_matrix_prior)) * 1e-6

    n_assets = len(cov_matrix_prior.columns)
    init_weights = np.ones(n_assets) / n_assets
    init_weights /= np.sum(init_weights)

    constraints = [{"type": "eq", "fun": lambda weights: np.sum(weights) - 1}]
    weight_bounds = [(0.0, 1.0) for _ in range(n_assets)]

    result = minimize(
        fun=risk_budget_objective,
        x0=init_weights,
        args=(cov_matrix_prior,),
        method="SLSQP",
        bounds=weight_bounds,
        constraints=constraints,
        options={"disp": False, "maxiter": 1000},
    )

    weights_series = pd.Series(result.x, index=prior_year_data.columns)

    if cap is not None and top_n is not None:
        # Calculate past returns over prior year
        past_returns = prior_year_data.iloc[-1] / prior_year_data.iloc[0] - 1.0
        weights_series = cap_and_redistribute(weights_series, past_returns, cap, top_n)


    return weights_series.map("{:.2%}".format)


def fetch_close_prices(engine: Engine, tickers: list[str]):
    today = date.today()
    yesterday = today - timedelta(days=1)

    current_year = today.year
    prior_year = today.year - 1

    time_span_start = f"{prior_year}-01-01 00:00:00"
    time_span_end = f"{yesterday.strftime('%Y-%m-%d')} 00:00:00"

    stmt = (
        select(ClosePrice.ticker, ClosePrice.date, ClosePrice.close)
        .where(
            ClosePrice.ticker.in_(tickers),
            ClosePrice.date >= time_span_start,
            ClosePrice.date <= time_span_end,
        )
        .order_by(ClosePrice.ticker, ClosePrice.date)
    )

    df = pd.read_sql(stmt, engine)

    df.set_index(["date"], inplace=True)

    data = df.pivot_table(values="close", index=df.index, columns="ticker")

    current_year_data = data.loc[
        f"{current_year}-01-01" : f"{yesterday.strftime('%Y-%m-%d')}"
    ]
    prior_year_data = data.loc[f"{prior_year}-01-01" : f"{prior_year}-12-31"]

    return prior_year_data, current_year_data


def calculate(
    engine: Engine,
    tickers: list[str],
    cap: float | None = None,
    top_n: int | None = None,
):
    prior_year_data, current_year_data = fetch_close_prices(engine, tickers)

    weights_series = equal_risk(prior_year_data, current_year_data, cap, top_n)

    weights = [
        {"ticker": ticker, "weight": weight}
        for ticker, weight in weights_series.items()
    ]

    return weights
