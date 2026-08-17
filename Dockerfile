FROM ubuntu:24.04

# golang-go/cargo/rust-clippy via apt (not go.dev tarball / rustup) -- stays
# on apt like everything else here rather than adding a new external fetch
# source, and a slightly older toolchain version is fine for a test fixture.
# ponytail: jest/pytest toolchains still aren't installed -- add them when
# PLAN 6.5's Node/TS and Python passes land.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libffi-dev \
    curl \
    ca-certificates \
    git \
    golang-go \
    cargo \
    rust-clippy \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-browser --skip-setup

ENV PATH="/root/.local/bin:${PATH}"
