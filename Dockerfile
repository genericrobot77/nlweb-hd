# Stage 1: Build stage
FROM python:3.13-slim AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc g++ python3-dev build-essential cmake make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements file
COPY code/python/requirements.txt /app/requirements.txt

# Install Python packages into builder
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt


# Stage 2: Runtime stage (this is what runs)
FROM python:3.13-slim

# Install runtime deps (+ git so VS Code is happy)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgomp1 libgcc-s1 git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create a non-root user
RUN groupadd -r nlweb && \
    useradd -r -g nlweb -d /app -s /bin/bash nlweb

# Copy application code
COPY code/ /app/
COPY static/ /app/static/
COPY config/ /app/config/

# Copy installed packages from builder stage
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Create data directories and set permissions as root
RUN mkdir -p /app/data /app/data/json_with_embeddings /app/logs && \
    cp -r /app/static /static && \
    chown -R nlweb:nlweb /app && \
    chmod -R 755 /app/data /app/logs

USER nlweb

EXPOSE 8000

ENV NLWEB_OUTPUT_DIR=/app
ENV PYTHONPATH=/app
ENV PORT=8000
ENV NLWEB_CONFIG_DIR=/app/config

CMD ["python", "python/app-file.py"]

# If starting from scratch, use a Node.js base image
FROM node:18

# Or if you already have a different base image (e.g., Ubuntu, Alpine)
FROM ubuntu:22.04

# Install Node.js and npm
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*