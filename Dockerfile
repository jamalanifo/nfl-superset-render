FROM apache/superset:latest

USER root

# Install additional dependencies
RUN pip install psycopg2-binary sqlalchemy-utils redis

# Copy configuration files
COPY ./docker/pythonpath/superset_config.py /app/pythonpath/superset_config.py

# Copy initialization script
COPY ./docker/docker-init-render.sh /app/docker-init-render.sh
RUN chmod +x /app/docker-init-render.sh

# Health check - use the correct Superset health endpoint
HEALTHCHECK CMD curl -f http://localhost:8088/health || exit 1

# Expose the port
EXPOSE 8088

# Start with the script
CMD ["/app/docker-init-render.sh"]

# Switch to superset user at the end
USER superset