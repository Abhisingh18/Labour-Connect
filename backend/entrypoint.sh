#!/usr/bin/env bash
set -e

echo "Waiting for database..."
# Uses the app's engine, so it respects DATABASE_URL (cloud) or POSTGRES_* (compose).
until python -c "from app.db.session import engine; engine.connect().close()" 2>/dev/null; do
  echo "  db not ready, retrying in 2s..."
  sleep 2
done
echo "Database is up."

echo "Running migrations..."
alembic upgrade head

echo "Seeding initial data..."
python -m app.db.seed

echo "Starting API on port ${PORT:-8000}..."
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
