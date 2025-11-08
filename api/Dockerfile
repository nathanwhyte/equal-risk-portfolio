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
    apt-get install --no-install-recommends -y build-essential gcc g++ libpq-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Prime dependency cache. Skip installing the local project to keep this layer stable.
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

# Copy application source.
COPY . .

FROM base AS runtime

COPY --from=build /python /python
ENV PATH="/python/.venv/bin:$PATH"

CMD ["fastapi", "run", "app/main.py", "--port", "3001", "--host", "0.0.0.0"]
