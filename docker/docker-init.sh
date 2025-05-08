#!/bin/bash
set -e

echo "Initializing Superset..."

# Check for required environment variables
echo "Checking environment variables..."
if [ -z "$DATABASE_USER" ] || [ -z "$DATABASE_PASSWORD" ] || [ -z "$DATABASE_HOST" ]; then
    echo "Error: Missing required database environment variables!"
    echo "Make sure DATABASE_USER, DATABASE_PASSWORD, and DATABASE_HOST are set."
    exit 1
fi

# Set default port if not specified
if [ -z "$DATABASE_PORT" ]; then
    echo "DATABASE_PORT not set, defaulting to 6543..."
    export DATABASE_PORT=6543
fi

# Check Redis configuration
if [ -z "$REDIS_HOST" ] || [ -z "$REDIS_PORT" ]; then
    echo "Warning: Redis configuration not complete. Some features may not work."
else
    # Wait for Redis to be available
    echo "Waiting for Redis..."
    timeout=60
    while ! nc -z ${REDIS_HOST} ${REDIS_PORT} >/dev/null 2>&1; do
      timeout=$((timeout - 1))
      if [ $timeout -eq 0 ]; then
        echo "Warning: Redis connection timed out. Continuing without Redis..."
        break
      fi
      echo "Redis not available yet - waiting..."
      sleep 1
    done
fi

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

# Start Gunicorn server with production settings
echo "Starting Superset server..."
gunicorn \
    --bind 0.0.0.0:8088 \
    --workers=4 \
    --timeout 120 \
    --worker-class=gthread \
    --threads=10 \
    "superset.app:create_app()"