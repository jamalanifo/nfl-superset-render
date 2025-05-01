#!/bin/bash
set -e

echo "Initializing Superset..."

# Setup Superset if the database needs initialization
superset db upgrade

# Create admin user if not exists
superset fab create-admin \
    --username admin \
    --email admin@example.com \
    --password ${ADMIN_PASSWORD:-admin} \
    --firstname Superset \
    --lastname Admin

# Initialize permissions and roles
superset init

# Start Gunicorn server with production settings
echo "Starting Superset server..."
gunicorn \
    --bind 0.0.0.0:8088 \
    --workers=2 \
    --timeout 120 \
    --limit-request-line 0 \
    --limit-request-field_size 0 \
    "superset.app:create_app()"