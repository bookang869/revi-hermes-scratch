#!/usr/bin/env bash
# Resolves SERVICE_NAME (from the alert's client_payload.service_name, or a
# rehearsal's service_name input) to how to boot that service for the
# synthetic smoke test (TRD FR-03, PLAN 6.5), plus which directory holds its
# fixture app (FIXTURE_APP_DIR -- only consumed by fake-agent.sh, the
# rehearsal test double for Hermes; the real agent explores the repo itself,
# so hermes-triage.yml never needs this field). Fixed table, not a codebase
# inspection -- unlike test-framework detection (manifest_for()), "how do I
# start this app" isn't reliably inferable from a manifest file, so each
# fixture app gets an explicit entry here as its language pass lands.
# Replaces hermes-triage.yml's old hardcoded single
# REVI_BOOT_COMMAND/REVI_HEALTH_URL pair and hermes-rehearsal.yml's old
# hardcoded single FIXTURE_APP_DIR.
#
# Usage: SERVICE_NAME=<name> resolve-boot-command.sh
# Prints, one per line: REVI_BOOT_COMMAND= / REVI_HEALTH_URL= / FIXTURE_APP_DIR=
set -euo pipefail

: "${SERVICE_NAME:?SERVICE_NAME is required}"

case "$SERVICE_NAME" in
  rehearsal-fixture-app)
    echo "REVI_BOOT_COMMAND=cd fixture-app-go && go run ."
    echo "REVI_HEALTH_URL=http://localhost:8080/healthz"
    echo "FIXTURE_APP_DIR=fixture-app-go"
    ;;
  rehearsal-fixture-app-rust)
    echo "REVI_BOOT_COMMAND=cd fixture-app-rust && cargo run"
    echo "REVI_HEALTH_URL=http://localhost:8080/healthz"
    echo "FIXTURE_APP_DIR=fixture-app-rust"
    ;;
  rehearsal-fixture-app-node)
    echo "REVI_BOOT_COMMAND=cd fixture-app-node && node server.js"
    echo "REVI_HEALTH_URL=http://localhost:8080/healthz"
    echo "FIXTURE_APP_DIR=fixture-app-node"
    ;;
  rehearsal-fixture-app-python)
    echo "REVI_BOOT_COMMAND=cd fixture-app-python && python3 server.py"
    echo "REVI_HEALTH_URL=http://localhost:8080/healthz"
    echo "FIXTURE_APP_DIR=fixture-app-python"
    ;;
  *)
    echo "resolve-boot-command: no boot command mapped for service '$SERVICE_NAME'" >&2
    exit 1
    ;;
esac
