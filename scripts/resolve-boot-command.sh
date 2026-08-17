#!/usr/bin/env bash
# Resolves SERVICE_NAME (from the alert's client_payload.service_name, or a
# rehearsal's service_name input) to how to boot that service for the
# synthetic smoke test (TRD FR-03, PLAN 6.5). This is a fixed table, not a
# codebase inspection -- unlike test-framework detection (manifest_for()),
# "how do I start this app" isn't reliably inferable from a manifest file,
# so each fixture app gets an explicit entry here as its language pass
# lands. Replaces hermes-triage.yml's old hardcoded single
# REVI_BOOT_COMMAND/REVI_HEALTH_URL pair.
#
# Usage: SERVICE_NAME=<name> resolve-boot-command.sh
# Prints, one per line: REVI_BOOT_COMMAND= / REVI_HEALTH_URL=
set -euo pipefail

: "${SERVICE_NAME:?SERVICE_NAME is required}"

case "$SERVICE_NAME" in
  rehearsal-fixture-app)
    echo "REVI_BOOT_COMMAND=cd fixture-app && go run ."
    echo "REVI_HEALTH_URL=http://localhost:8080/healthz"
    ;;
  rehearsal-fixture-app-rust)
    echo "REVI_BOOT_COMMAND=cd fixture-app-rust && cargo run"
    echo "REVI_HEALTH_URL=http://localhost:8080/healthz"
    ;;
  *)
    echo "resolve-boot-command: no boot command mapped for service '$SERVICE_NAME'" >&2
    exit 1
    ;;
esac
