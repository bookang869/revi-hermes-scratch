FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libffi-dev \
    curl \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-browser --skip-setup

ENV PATH="/root/.local/bin:${PATH}"
