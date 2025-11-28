# Use Python 3.9 Alpine as base image for smaller size
FROM python:3.9-alpine

# Set working directory
WORKDIR /app

# Copy requirements first for better Docker layer caching
COPY requirements.txt .

# Install build dependencies, curl for health checks, and Python dependencies
RUN apk add --no-cache --virtual .build-deps gcc musl-dev && \
    apk add --no-cache curl && \
    pip install --no-cache-dir -r requirements.txt && \
    apk del .build-deps

# Copy application code
COPY main.py .

# Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Change ownership of the app directory
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Set environment variables with defaults
ENV REDIS_HOST=redis-queue
ENV REDIS_PORT=6379
ENV REDIS_CHANNEL=log_channel

# Run the Python application
CMD ["python", "main.py"]