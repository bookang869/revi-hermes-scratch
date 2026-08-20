#!/usr/bin/env bash
# Three-layer test framework detection (TRD FR-02, PLAN 3.4).
# L1: REVI_FALLBACK_TEST override, trusted outright.
# L2: nearest manifest walking UP FROM THE CRASHED FILE (not repo root) --
#     this is what makes polyglot monorepos resolve to the right language.
# L3: no manifest found anywhere up to REPO_ROOT -- smoke-only fallback.
#
# Usage: REPO_ROOT=<path> CRASHED_FILE=<path relative to REPO_ROOT> \
#          [REVI_FALLBACK_TEST=<go|cargo|jest|pytest>] detect-test-framework.sh
# Prints, one per line: TEST_FRAMEWORK= / TEST_COMMAND= / TEST_FILE_SUFFIX= / LAYER=
set -euo pipefail

: "${REPO_ROOT:?REPO_ROOT is required}"
: "${CRASHED_FILE:?CRASHED_FILE is required}"

# framework|test command|sibling test file suffix|required path prefix
# (relative to manifest_dir; empty means "anywhere under manifest_dir").
# Cargo's suffix targets its tests/ integration-test directory (e.g.
# tests/order_test.rs), not an in-crate #[cfg(test)] mod -- the only Cargo
# convention that's a genuinely separate file the same way Go/Jest/pytest's
# sibling files are (PLAN 6.5 follow-up, 2026-08-17). The suffix alone
# doesn't rule out a same-named file sitting elsewhere in the crate (e.g.
# src/order_test.rs, which cargo test wouldn't even discover) -- the
# required prefix (added 2026-08-20, PLAN 6.9 audit) closes that gap; only
# Cargo needs one since it's the only convention whose separate-file
# location is a specific subdirectory rather than "wherever the fixed file
# lives".
# "none" is a valid override too (Phase 3.5): it lets the wrapper feed back
# Hermes's own self-reported "no framework applies" verdict through the same
# code path as a real L1 override, rather than needing a second lookup table.
profile() {
  case "$1" in
    go)     echo "go|go test ./...|_test.go|" ;;
    cargo)  echo "cargo|cargo test|_test.rs|tests/" ;;
    jest)   echo "jest|npx jest|.test.js|" ;;
    pytest) echo "pytest|pytest|_test.py|" ;;
    none)   echo "none|exit 0||" ;;
    *)      return 1 ;;
  esac
}

emit() {
  local layer="$1" framework cmd suffix prefix
  IFS='|' read -r framework cmd suffix prefix <<< "$2"
  echo "TEST_FRAMEWORK=$framework"
  echo "TEST_COMMAND=$cmd"
  echo "TEST_FILE_SUFFIX=$suffix"
  echo "TEST_FILE_PREFIX=$prefix"
  echo "LAYER=$layer"
}

# L1: explicit override -- an unrecognized value is almost certainly an
# operator typo, so fail loudly rather than silently falling through to L2.
if [[ -n "${REVI_FALLBACK_TEST:-}" ]]; then
  if ! p=$(profile "$REVI_FALLBACK_TEST"); then
    echo "detect-test-framework: unrecognized REVI_FALLBACK_TEST '$REVI_FALLBACK_TEST'" >&2
    exit 1
  fi
  emit "L1" "$p"
  exit 0
fi

# L2: walk up from the crashed file's directory toward REPO_ROOT (inclusive),
# stopping at the first manifest found.
dir="$(cd "$REPO_ROOT/$(dirname "$CRASHED_FILE")" && pwd)"
root="$(cd "$REPO_ROOT" && pwd)"

while true; do
  if [[ -f "$dir/go.mod" ]]; then emit "L2" "$(profile go)"; exit 0; fi
  if [[ -f "$dir/Cargo.toml" ]]; then emit "L2" "$(profile cargo)"; exit 0; fi
  if [[ -f "$dir/package.json" ]]; then emit "L2" "$(profile jest)"; exit 0; fi
  if [[ -f "$dir/requirements.txt" ]]; then emit "L2" "$(profile pytest)"; exit 0; fi
  [[ "$dir" == "$root" ]] && break
  dir="$(dirname "$dir")"
done

# L3: bare-metal fallback -- no manifest recognized anywhere up to REPO_ROOT.
echo "TEST_FRAMEWORK=none"
echo "TEST_COMMAND=exit 0"
echo "TEST_FILE_SUFFIX="
echo "TEST_FILE_PREFIX="
echo "LAYER=L3"
