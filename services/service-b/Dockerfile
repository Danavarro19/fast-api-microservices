
FROM python:3.12-slim

# Python configuration
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH"

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copy dependency definitions
COPY pyproject.toml uv.lock ./

# Install dependencies from the lockfile
RUN uv sync --locked --no-dev --no-install-project

# Copy application source
COPY app/ ./app/

# Run as a non-root user
RUN useradd --system --uid 10001 appuser \
    && chown -R appuser:appuser /app

USER appuser

# Start FastAPI with Uvicorn
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]

