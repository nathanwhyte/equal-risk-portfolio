FROM python:3.12

# Install uv.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copy the application into the container.
COPY . /python

# Install the application dependencies.
WORKDIR /python
RUN uv sync --frozen --no-cache

# Run the application.
CMD ["/python/.venv/bin/fastapi", "run", "app/main.py", "--port", "3001", "--host", "0.0.0.0"]
