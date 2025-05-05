#!/bin/bash
set -e

echo "Initializing Superset..."

# Check if REDIS_HOST and REDIS_PORT are available
if [ -n "$REDIS_HOST" ] && [ -n "$REDIS_PORT" ]; then
    echo "Checking Redis connection at ${REDIS_HOST}:${REDIS_PORT}..."
    # Wait for Redis with a more robust approach
    timeout=30
    while ! nc -z ${REDIS_HOST} ${REDIS_PORT} >/dev/null 2>&1; do
        timeout=$((timeout - 1))
        if [ $timeout -eq 0 ]; then
            echo "Warning: Redis connection timed out, but continuing with setup..."
            break
        fi
        echo "Redis not available yet - waiting..."
        sleep 1
    done
else
    echo "Redis configuration not found. Continuing without Redis..."
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
echo "Starting Superset server on port 8088..."
gunicorn \
    --bind 0.0.0.0:8088 \
    --workers=4 \
    --timeout 120 \
    --worker-class=gthread \
    --threads=10 \
    "superset.app:create_app()"