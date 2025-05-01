FROM apache/superset:latest

USER root

# Install additional dependencies for PostgreSQL
RUN pip install psycopg2-binary sqlalchemy-utils redis

# Copy configuration files
COPY ./docker/pythonpath/superset_config.py /app/pythonpath/superset_config.py

# Make health check script available
HEALTHCHECK CMD curl -f http://localhost:8088/health || exit 1

USER superset

# Copy initialization script and make it executable
COPY ./docker/docker-init-render.sh /app/docker-init-render.sh
RUN chmod +x /app/docker-init-render.sh

# Expose the default Superset port
EXPOSE 8088

# Start Superset using the initialization script
CMD ["/app/docker-init-render.sh"]