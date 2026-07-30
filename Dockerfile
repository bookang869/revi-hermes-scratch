FROM ubuntu:24.04

# golang-go via apt (not the official go.dev tarball) -- stays on apt like
# everything else here rather than adding a new external fetch source, and
# a slightly older Go version is fine for a test fixture.
# ponytail: only Go is installed, matching the fixture-app used to prove out
# Phase 3.5's repair loop. cargo/jest/pytest toolchains aren't installed --
# add them if/when Phase 6 wires in a real polyglot app that needs them.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libffi-dev \
    curl \
    ca-certificates \
    git \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-browser --skip-setup

ENV PATH="/root/.local/bin:${PATH}"
