FROM ubuntu:24.04

# golang-go/cargo/rust-clippy/nodejs/npm via apt (not go.dev tarball / rustup
# / nodesource) -- stays on apt like everything else here rather than adding
# a new external fetch source, and a slightly older toolchain version is
# fine for a test fixture.
# ponytail: pytest's toolchain still isn't installed -- add it when PLAN
# 6.5's Python pass lands.
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
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Global install (not per-fixture-app devDependencies) so `git clean -fd`
# between repair-loop attempts (hermes-wrapper.sh) never wipes the
# toolchain -- npx resolves these off PATH without touching the network.
RUN npm install -g typescript eslint jest

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-browser --skip-setup

ENV PATH="/root/.local/bin:${PATH}"
