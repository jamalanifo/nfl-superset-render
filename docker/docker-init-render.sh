#!/bin/bash
set -e

echo "Initializing Superset..."

# Wait for Redis to be available (simple check)
echo "Waiting for Redis..."
timeout=60
while ! nc -z ${REDIS_HOST} ${REDIS_PORT} >/dev/null 2>&1; do
  timeout=$((timeout - 1))
  if [ $timeout -eq 0 ]; then
    echo "Error: Redis connection timed out"
    exit 1
  fi
  sleep 1
done

# Setup Superset database
echo "Initializing database..."
superset db upgrade

# Create admin user if not exists
echo "Creating admin user..."
superset fab create-admin \
    --username admin \
    --email admin@example.com \
    --password "${ADMIN_PASSWORD:-admin}" \
    --firstname Superset \
    --lastname Admin || echo "Admin user may already exist"

# Initialize permissions and roles
echo "Initializing roles and permissions..."
superset init

# Start Celery worker in background
echo "Starting Celery worker..."
celery --app=superset.tasks.celery_app:app worker \
    --loglevel=INFO \
    --concurrency=2 \
    --detach

# Start Celery beat in background
echo "Starting Celery beat..."
celery --app=superset.tasks.celery_app:app beat \
    --loglevel=INFO \
    --pidfile /tmp/celerybeat.pid \
    --schedule /tmp/celerybeat-schedule \
    --detach

# Start Gunicorn server with production settings
echo "Starting Superset server..."
gunicorn \
    --bind 0.0.0.0:8088 \
    --workers=4 \
    --timeout 120 \
    --worker-class=gthread \
    --threads=10 \
    --limit-request-line 0 \
    --limit-request-field_size 0 \
    "superset.app:create_app()"