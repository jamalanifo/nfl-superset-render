FROM apache/superset:latest

USER root

# Install additional dependencies
RUN pip install psycopg2-binary sqlalchemy-utils redis

# Copy configuration files
COPY ./docker/pythonpath/superset_config.py /app/pythonpath/superset_config.py

# Create a health check route
RUN mkdir -p /app/superset/views && \
    echo 'from flask import Blueprint, jsonify\n\
health_bp = Blueprint("health", __name__)\n\
\n\
@health_bp.route("/health")\n\
def health():\n\
    return jsonify({"status": "ok"})\n\
' > /app/superset/views/health.py

# Add health blueprint to configuration 
RUN echo 'from superset.views.health import health_bp\n\
BLUEPRINTS = [health_bp]\n\
' >> /app/pythonpath/superset_config.py

# Create initialization script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Initializing Superset..."\n\
\n\
# Setup Superset database\n\
echo "Initializing database..."\n\
superset db upgrade\n\
\n\
# Create admin user if not exists\n\
echo "Creating admin user..."\n\
superset fab create-admin \\\n\
    --username admin \\\n\
    --email admin@example.com \\\n\
    --password "${ADMIN_PASSWORD:-admin}" \\\n\
    --firstname Superset \\\n\
    --lastname Admin || echo "Admin user may already exist"\n\
\n\
# Initialize permissions and roles\n\
echo "Initializing roles and permissions..."\n\
superset init\n\
\n\
# Start Celery worker in background (if needed)\n\
if [[ -n "$REDIS_HOST" ]]; then\n\
    echo "Starting Celery worker..."\n\
    celery --app=superset.tasks.celery_app:app worker \\\n\
        --loglevel=INFO \\\n\
        --concurrency=2 \\\n\
        --detach\n\
    \n\
    echo "Starting Celery beat..."\n\
    celery --app=superset.tasks.celery_app:app beat \\\n\
        --loglevel=INFO \\\n\
        --pidfile /tmp/celerybeat.pid \\\n\
        --schedule /tmp/celerybeat-schedule \\\n\
        --detach\n\
fi\n\
\n\
# Start Gunicorn server with production settings\n\
echo "Starting Superset server..."\n\
gunicorn \\\n\
    --bind 0.0.0.0:8088 \\\n\
    --workers=4 \\\n\
    --timeout 120 \\\n\
    --worker-class=gthread \\\n\
    --threads=10 \\\n\
    "superset.app:create_app()"\n\
' > /app/docker-entrypoint.sh

RUN chmod +x /app/docker-entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD curl -f http://localhost:8088/health || exit 1

# Expose the port
EXPOSE 8088

# Start with the script
CMD ["/app/docker-entrypoint.sh"]

# Switch to superset user at the end
USER superset