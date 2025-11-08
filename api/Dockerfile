FROM python:3.13-slim AS base

# Install uv once for all stages.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_LINK_MODE=hardlink \
    UV_PROJECT_ENV=.venv \
    UV_CACHE_DIR=/root/.cache/uv \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /python

FROM base AS build

# Install build dependencies only while building wheels.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl gcc g++ libpq-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# First layer: resolve and cache Python dependencies.
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Copy application source and install into the virtual environment.
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev && \
    rm -rf "${UV_CACHE_DIR}"

FROM base AS runtime

COPY --from=build /python /python
ENV PATH="/python/.venv/bin:$PATH"

CMD ["fastapi", "run", "app/main.py", "--port", "3001", "--host", "0.0.0.0"]
