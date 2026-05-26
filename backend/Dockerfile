# syntax=docker/dockerfile:1
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

COPY telemetry /app/telemetry
COPY backend/fast_app /app/backend/fast_app

ENV CSV_DIR="/app/telemetry/ParsedCSVs"

EXPOSE 8000

CMD ["python", "-m", "uvicorn", "backend.fast_app.main:app", "--host", "0.0.0.0", "--port", "8000"]
