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

# This container has no USER directive (runs as root), but GitHub Actions
# container jobs bind-mount $GITHUB_WORKSPACE from the host runner, owned
# by a different, non-root UID -- git's ownership check refuses to operate
# on a directory it doesn't recognize as "ours" (root touching someone
# else's files), failing every git command in the workspace with "fatal:
# detected dubious ownership" until this exception is granted. --system
# (not --global, which only covers root's own home dir / a specific repo)
# so it's baked into the image itself and every consumer -- hermes-triage.yml,
# hermes-rehearsal.yml, any future workflow -- gets it for free, instead of
# each workflow needing its own copy of the same fix (hermes-triage.yml went
# without one for a long time despite hermes-rehearsal.yml already having
# hit and fixed this exact error, found 2026-08-21 tracing Part B's Python
# batch silently losing attempt 1 of Hermes's 3-attempt budget on every run).
# Wildcard is deliberate, confirmed with the user: this image only ever runs
# one ephemeral, single-purpose CI job at a time, nothing else sensitive
# shares it, so trusting any directory inside it carries no real added risk.
RUN git config --system --add safe.directory '*'
