#!/usr/bin/env bash
# Fixture-tree test harness for detect-test-framework.sh (PLAN 3.4 "done
# when"). Builds throwaway repo trees under a tmp dir, runs the detector
# against each, asserts the output. No test framework -- this is the
# framework-detection logic itself, so bootstrapping one would be circular.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT="$SCRIPT_DIR/detect-test-framework.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0

assert_contains() {
  local output="$1" expected="$2" case_name="$3"
  if grep -qxF "$expected" <<< "$output"; then
    echo "PASS: $case_name ($expected)"
  else
    echo "FAIL: $case_name -- expected '$expected', got:"
    echo "$output" | sed 's/^/    /'
    FAILURES=$((FAILURES + 1))
  fi
}

run_case() {
  local case_name="$1" repo_root="$2" crashed_file="$3" fallback="${4:-}"
  shift 4 || true
  local output
  if [[ -n "$fallback" ]]; then
    output="$(REPO_ROOT="$repo_root" CRASHED_FILE="$crashed_file" REVI_FALLBACK_TEST="$fallback" "$DETECT")"
  else
    output="$(REPO_ROOT="$repo_root" CRASHED_FILE="$crashed_file" "$DETECT")"
  fi
  echo "--- $case_name ---"
  echo "$output"
  for expected in "$@"; do
    assert_contains "$output" "$expected" "$case_name"
  done
}

### L2: single-ecosystem repos, one per manifest type
mkdir -p "$TMP/l2-go/internal/handlers"
touch "$TMP/l2-go/go.mod"
touch "$TMP/l2-go/internal/handlers/user.go"
run_case "L2 go" "$TMP/l2-go" "internal/handlers/user.go" "" \
  "LAYER=L2" "TEST_FRAMEWORK=go" "TEST_COMMAND=go test ./..."

mkdir -p "$TMP/l2-cargo/src"
touch "$TMP/l2-cargo/Cargo.toml"
touch "$TMP/l2-cargo/src/main.rs"
run_case "L2 cargo" "$TMP/l2-cargo" "src/main.rs" "" \
  "LAYER=L2" "TEST_FRAMEWORK=cargo" "TEST_COMMAND=cargo test" "TEST_FILE_SUFFIX=_test.rs"

mkdir -p "$TMP/l2-jest/src/components"
touch "$TMP/l2-jest/package.json"
touch "$TMP/l2-jest/src/components/Button.js"
run_case "L2 jest" "$TMP/l2-jest" "src/components/Button.js" "" \
  "LAYER=L2" "TEST_FRAMEWORK=jest" "TEST_COMMAND=npx jest"

mkdir -p "$TMP/l2-pytest/app"
touch "$TMP/l2-pytest/requirements.txt"
touch "$TMP/l2-pytest/app/models.py"
run_case "L2 pytest" "$TMP/l2-pytest" "app/models.py" "" \
  "LAYER=L2" "TEST_FRAMEWORK=pytest" "TEST_COMMAND=pytest" "TEST_FILE_SUFFIX=_test.py"

### L2 monorepo: nearest-to-crashed-file must win over a decoy root manifest
mkdir -p "$TMP/monorepo/backend/internal/handlers"
mkdir -p "$TMP/monorepo/frontend/src"
touch "$TMP/monorepo/package.json"                       # decoy: repo-root JS manifest
touch "$TMP/monorepo/backend/go.mod"                      # nearest to the crashed file below
touch "$TMP/monorepo/backend/internal/handlers/user.go"   # crashed file
touch "$TMP/monorepo/frontend/package.json"
touch "$TMP/monorepo/frontend/src/App.js"
run_case "L2 monorepo (nearest wins over root decoy)" "$TMP/monorepo" \
  "backend/internal/handlers/user.go" "" \
  "LAYER=L2" "TEST_FRAMEWORK=go" "TEST_COMMAND=go test ./..."

### L1: override wins even when the file sits in a go tree
run_case "L1 override beats L2" "$TMP/l2-go" "internal/handlers/user.go" "jest" \
  "LAYER=L1" "TEST_FRAMEWORK=jest" "TEST_COMMAND=npx jest"

### L1: "none" override (used by the 3.5 wrapper to feed back Hermes's own
### self-reported "no framework applies" verdict through the same code path)
run_case "L1 none override" "$TMP/l2-go" "internal/handlers/user.go" "none" \
  "LAYER=L1" "TEST_FRAMEWORK=none" "TEST_COMMAND=exit 0"

### L1: unrecognized override fails loudly instead of silently falling to L2
if REPO_ROOT="$TMP/l2-go" CRASHED_FILE="internal/handlers/user.go" \
   REVI_FALLBACK_TEST="cobol-unit" "$DETECT" > /tmp/detect_bad_override.out 2>&1; then
  echo "FAIL: unrecognized REVI_FALLBACK_TEST should have exited non-zero"
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: unrecognized REVI_FALLBACK_TEST exits non-zero"
fi

### L3: no manifest anywhere up to REPO_ROOT
mkdir -p "$TMP/l3-none/random/nested"
touch "$TMP/l3-none/random/nested/file.txt"
run_case "L3 fallback" "$TMP/l3-none" "random/nested/file.txt" "" \
  "LAYER=L3" "TEST_FRAMEWORK=none" "TEST_COMMAND=exit 0"

echo ""
if [[ "$FAILURES" -eq 0 ]]; then
  echo "ALL PASS"
  exit 0
else
  echo "$FAILURES FAILURE(S)"
  exit 1
fi
