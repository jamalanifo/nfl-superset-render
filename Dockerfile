FROM apache/superset:latest

USER root

# Install additional dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    netcat-openbsd \
    postgresql-client \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    psycopg2-binary \
    redis \
    sqlalchemy-utils \
    flask-caching

# Copy configuration files
COPY ./docker/pythonpath/superset_config.py /app/pythonpath/superset_config.py
COPY ./docker/docker-init.sh /app/docker-init.sh

# Make the entrypoint script executable
RUN chmod +x /app/docker-init.sh

# Health check
HEALTHCHECK CMD curl -f http://localhost:8088/health || exit 1

# Expose the port
EXPOSE 8088

# Start with the script
CMD ["/app/docker-init.sh"]