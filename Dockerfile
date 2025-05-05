FROM apache/superset:latest

USER root

# Install additional dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends netcat-openbsd curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install required Python packages
RUN pip install psycopg2-binary sqlalchemy-utils redis

# Copy configuration files
COPY ./docker/pythonpath/superset_config.py /app/pythonpath/superset_config.py
COPY ./docker/docker-init-render.sh /app/docker-init-render.sh

# Make the entrypoint script executable
RUN chmod +x /app/docker-init-render.sh

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8088/health || exit 1

# Expose the port
EXPOSE 8088

# Set environment variables
ENV PYTHONPATH=/app/pythonpath
ENV FLASK_APP=superset.app:create_app()
ENV FLASK_ENV=production

# Start with the script
CMD ["/app/docker-init-render.sh"]