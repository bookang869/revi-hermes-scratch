FROM ubuntu:24.04

# golang-go/cargo/rust-clippy/nodejs/npm/python3-pip via apt (not go.dev
# tarball / rustup / nodesource / pyenv) -- stays on apt like everything else
# here rather than adding a new external fetch source, and a slightly older
# toolchain version is fine for a test fixture.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    python3-pip \
    libffi-dev \
    curl \
    ca-certificates \
    git \
    golang-go \
    cargo \
    rust-clippy \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Global install (not per-fixture-app devDependencies/requirements.txt) so
# `git clean -fd` between repair-loop attempts (hermes-wrapper.sh) never
# wipes the toolchain -- npx/pytest/ruff resolve these off PATH without
# touching the network. --break-system-packages: Ubuntu 24.04's pip refuses
# an unscoped system-wide install (PEP 668) otherwise; there's no venv here
# to scope it to instead, same tradeoff npm's global install already makes.
RUN npm install -g typescript eslint jest
RUN pip3 install --break-system-packages pytest ruff

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-browser --skip-setup

ENV PATH="/root/.local/bin:${PATH}"
