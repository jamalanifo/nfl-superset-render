#!/bin/bash
set -e

echo "Initializing Superset..."

# Environment check
echo "Environment: ${SUPERSET_ENV}"
echo "Redis host: ${REDIS_HOST}"
echo "Redis port: ${REDIS_PORT}"

# Check if Redis is needed for this deployment
if [ -n "${REDIS_HOST}" ] && [ -n "${REDIS_PORT}" ]; then
    # Try to connect to Redis but with a fallback
    echo "Checking Redis availability..."
    if nc -z ${REDIS_HOST} ${REDIS_PORT} >/dev/null 2>&1; then
        echo "Redis is available."
        REDIS_AVAILABLE=true
    else
        echo "WARNING: Redis is not available. Proceeding with limited functionality."
        REDIS_AVAILABLE=false
        # Modify configurations to work without Redis
        export CACHE_CONFIG='{"CACHE_TYPE": "NullCache"}'
        export DATA_CACHE_CONFIG='{"CACHE_TYPE": "NullCache"}'
        export FILTER_STATE_CACHE_CONFIG='{"CACHE_TYPE": "NullCache"}'
        export EXPLORE_FORM_DATA_CACHE_CONFIG='{"CACHE_TYPE": "NullCache"}'
    fi
else
    echo "Redis configuration not provided. Using NullCache."
    REDIS_AVAILABLE=false
    # Set cache to NullCache when Redis isn't configured
    export CACHE_CONFIG='{"CACHE_TYPE": "NullCache"}'
    export DATA_CACHE_CONFIG='{"CACHE_TYPE": "NullCache"}'
    export FILTER_STATE_CACHE_CONFIG='{"CACHE_TYPE": "NullCache"}'
    export EXPLORE_FORM_DATA_CACHE_CONFIG='{"CACHE_TYPE": "NullCache"}'
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