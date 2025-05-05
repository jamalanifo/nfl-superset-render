FROM apache/superset:latest

USER root

# Install additional dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install required Python packages
RUN pip install psycopg2-binary sqlalchemy-utils redis

# Create directory for configuration
RUN mkdir -p /app/pythonpath

# Copy configuration files
COPY ./docker/pythonpath/superset_config.py /app/pythonpath/superset_config.py
COPY ./docker/docker-init-render.sh /app/docker-init-render.sh

# Make the entrypoint script executable
RUN chmod +x /app/docker-init-render.sh

# Health check
HEALTHCHECK CMD curl -f http://localhost:8088/health || exit 1

# Expose the port
EXPOSE 8088

# Start with the script
CMD ["/app/docker-init-render.sh"]