#!/usr/bin/env bash
# Hermes wrapper + repair loop (TRD FR-02/FR-04, PLAN 3.5). Agent-agnostic:
# invokes $REVI_AGENT_COMMAND, never trusts its exit code, independently
# gates each attempt (compile + lint + test-file-was-actually-written + test
# run), retries up to 3 times, escalates via escalate.sh on exhaustion.
set -uo pipefail  # not -e: failures are inspected, not fatal mid-loop

: "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"
: "${TRACE_ID:?TRACE_ID is required}"
: "${ERROR_SUMMARY:?ERROR_SUMMARY is required}"
: "${ALERT_ID:?ALERT_ID is required}"
: "${REVI_MODE:?REVI_MODE is required}"
: "${SERVICE_NAME:?SERVICE_NAME is required}"
LOG_CONTEXT="${LOG_CONTEXT:-}"
REVI_AGENT_COMMAND="${REVI_AGENT_COMMAND:-hermes --provider anthropic --model claude-sonnet-5 -z}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAX_ATTEMPTS=3
FORCED_TEST_FRAMEWORK="${REVI_FALLBACK_TEST:-}"

cd "$GITHUB_WORKSPACE"

build_prompt() {
  local framework_instruction
  if [[ -n "$FORCED_TEST_FRAMEWORK" ]]; then
    framework_instruction="The test framework for this repository is fixed: $FORCED_TEST_FRAMEWORK. Use it -- do not try to detect a different one."
  else
    framework_instruction='Determine which test framework applies to the file you are fixing by finding its nearest manifest walking up from that file (go.mod -> go, Cargo.toml -> cargo, package.json -> jest, requirements.txt -> pytest). If none applies anywhere up to the repo root, report test_framework as "none" and do not write a test file.'
  fi
  cat <<PROMPT
You are diagnosing and fixing a production crash in this repository.

trace_id: $TRACE_ID
service_name: $SERVICE_NAME
error_summary: $ERROR_SUMMARY
log_context:
$LOG_CONTEXT

Find the file responsible for this crash and fix it. Unless test_framework is "none", also write a sibling test file (same directory as the fixed file, matching the ecosystem's naming convention) that fails before your fix and passes after it -- do not skip this. $framework_instruction

When done, respond with ONLY a single literal JSON object, no surrounding prose, matching exactly this schema:
{"confidence_note": "string", "summary": "string", "test_framework": "string"}
PROMPT
}

# Prompt asks for ONLY a JSON object, but be defensive: take the last
# balanced-looking {...} block in case the agent adds prose anyway.
extract_json() {
  python3 -c '
import re, sys
text = sys.stdin.read()
matches = re.findall(r"\{[^{}]*\}", text, re.DOTALL)
print(matches[-1] if matches else "")
'
}

# Prints confidence_note / summary / test_framework, one per line, and exits
# non-zero if the JSON is malformed or test_framework is missing/empty.
parse_response() {
  python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    framework = d.get("test_framework", "")
    if not framework:
        sys.exit(1)
    print(d.get("confidence_note", ""))
    print(d.get("summary", ""))
    print(framework)
except Exception:
    sys.exit(1)
'
}

manifest_for() {
  case "$1" in
    go)     echo "go.mod" ;;
    cargo)  echo "Cargo.toml" ;;
    jest)   echo "package.json" ;;
    pytest) echo "requirements.txt" ;;
  esac
}

# Ties the gate to what Hermes actually changed rather than a repo-wide
# guess: walks up from the directory of the first file git shows as changed
# to find the nearest manifest. Self-verifying -- doesn't require Hermes to
# report a path, since the wrapper already inspects git status for the
# test-file check below. awk '{print $NF}' (not $2) also gets renamed files
# right -- `R  old -> new` puts the new path last.
# ponytail: takes the first changed file only; a single attempt spanning two
# components (unlikely -- the prompt asks for a co-located sibling test
# file) would gate on just one. Fine for a single-service repo/fixture.
find_manifest_dir() {
  local manifest="$1" changed_file dir
  changed_file="$(git -C "$GITHUB_WORKSPACE" status --porcelain | awk '{print $NF}' | head -1)"
  [[ -z "$changed_file" ]] && return 1

  dir="$(cd "$GITHUB_WORKSPACE/$(dirname "$changed_file")" && pwd)"
  while :; do
    [[ -f "$dir/$manifest" ]] && { echo "$dir"; return 0; }
    [[ "$dir" == "$GITHUB_WORKSPACE" ]] && return 1
    dir="$(dirname "$dir")"
  done
}

# Gates one attempt. Returns 0 (pass) or 1 (fail); prints the reason to stderr.
run_gate() {
  local framework="$1" test_command="$2" test_file_suffix="$3"

  if [[ "$framework" == "none" ]]; then
    return 0  # L3: no automated gate; PR_REVIEW human review is the safety net
  fi

  local manifest manifest_dir
  manifest="$(manifest_for "$framework")"
  manifest_dir="$(find_manifest_dir "$manifest")"
  if [[ -z "$manifest_dir" ]]; then
    echo "gate: no $manifest found for framework $framework" >&2
    return 1
  fi

  # A green test run proves nothing if no test file actually changed --
  # enforce PLAN's "AI fails to write the L1/L2 test -> reject patch" rule
  # directly, rather than trusting the test command's exit code alone.
  # Cargo/pytest have no suffix convention in the TRD, so this check is
  # skipped for those two (ponytail: revisit if a convention gets adopted).
  if [[ -n "$test_file_suffix" ]]; then
    local manifest_rel changed_files
    manifest_rel="${manifest_dir#"$GITHUB_WORKSPACE"}"
    manifest_rel="${manifest_rel#/}"
    changed_files="$(git -C "$GITHUB_WORKSPACE" status --porcelain | awk '{print $NF}')"
    [[ -n "$manifest_rel" ]] && changed_files="$(grep -- "^${manifest_rel}/" <<< "$changed_files")"
    if ! grep -q -- "${test_file_suffix}\$" <<< "$changed_files"; then
      echo "gate: no changed file under $manifest_dir matching *$test_file_suffix -- test not written" >&2
      return 1
    fi
  fi

  case "$framework" in
    go)    (cd "$manifest_dir" && go build ./...) || { echo "gate: go build failed" >&2; return 1; } ;;
    cargo) (cd "$manifest_dir" && cargo build) || { echo "gate: cargo build failed" >&2; return 1; } ;;
    jest)  (cd "$manifest_dir" && tsc --noEmit) || { echo "gate: tsc build failed" >&2; return 1; } ;;
  esac

  # Lint pass (PLAN 6.2, folded into 6.5's per-language passes). pytest still
  # has no lint toolchain installed (Dockerfile ponytail: add flake8/ruff
  # when Python's 6.5 pass lands), so that framework skips this check rather
  # than gating on a tool that doesn't exist.
  case "$framework" in
    go)    (cd "$manifest_dir" && go vet ./...) || { echo "gate: go vet failed" >&2; return 1; } ;;
    cargo) (cd "$manifest_dir" && cargo clippy --all-targets -- -D warnings) || { echo "gate: cargo clippy failed" >&2; return 1; } ;;
    jest)  (cd "$manifest_dir" && eslint .) || { echo "gate: eslint failed" >&2; return 1; } ;;
  esac

  if ! (cd "$manifest_dir" && eval "$test_command"); then
    echo "gate: test command failed: $test_command" >&2
    return 1
  fi

  return 0
}

ATTEMPT=0
OUTCOME="FAILED"
CONFIDENCE_NOTE=""
SUMMARY=""
GATE_FRAMEWORK=""
GATE_TEST_COMMAND=""
GATE_MANIFEST_DIR=""

while [[ "$ATTEMPT" -lt "$MAX_ATTEMPTS" ]]; do
  ATTEMPT=$((ATTEMPT + 1))
  echo "=== Hermes repair attempt $ATTEMPT/$MAX_ATTEMPTS ==="

  # Clean tree before every attempt so each one starts from the original
  # bug, not a previous failed attempt's partial edit.
  git -C "$GITHUB_WORKSPACE" checkout -- . 2>/dev/null
  git -C "$GITHUB_WORKSPACE" clean -fd 2>/dev/null

  PROMPT="$(build_prompt)"
  RAW_OUTPUT="$($REVI_AGENT_COMMAND "$PROMPT" 2>&1)"
  echo "agent exit code: $? (logged only, never gates success)"

  JSON="$(printf '%s' "$RAW_OUTPUT" | extract_json)"
  if [[ -z "$JSON" ]]; then
    echo "attempt $ATTEMPT: no JSON found in agent output -- failed attempt"
    echo "agent output (first 1000 chars): $(printf '%s' "$RAW_OUTPUT" | head -c 1000)"
    continue
  fi

  PARSED="$(printf '%s' "$JSON" | parse_response)"
  if [[ $? -ne 0 || -z "$PARSED" ]]; then
    echo "attempt $ATTEMPT: malformed or incomplete JSON -- failed attempt"
    echo "agent output (first 1000 chars): $(printf '%s' "$RAW_OUTPUT" | head -c 1000)"
    continue
  fi

  CONFIDENCE_NOTE="$(sed -n '1p' <<< "$PARSED")"
  SUMMARY="$(sed -n '2p' <<< "$PARSED")"
  REPORTED_FRAMEWORK="$(sed -n '3p' <<< "$PARSED")"
  EFFECTIVE_FRAMEWORK="${FORCED_TEST_FRAMEWORK:-$REPORTED_FRAMEWORK}"

  # Reuse detect-test-framework.sh's L1 code path as a plain
  # framework-name -> command/suffix lookup (its "none" case exists
  # specifically for this call site).
  FRAMEWORK_INFO="$(REVI_FALLBACK_TEST="$EFFECTIVE_FRAMEWORK" REPO_ROOT="$GITHUB_WORKSPACE" CRASHED_FILE="." "$SCRIPT_DIR/detect-test-framework.sh" 2>&1)"
  if [[ $? -ne 0 ]]; then
    echo "attempt $ATTEMPT: unrecognized test_framework '$EFFECTIVE_FRAMEWORK' -- failed attempt"
    continue
  fi
  TEST_COMMAND="$(grep '^TEST_COMMAND=' <<< "$FRAMEWORK_INFO" | cut -d= -f2-)"
  TEST_FILE_SUFFIX="$(grep '^TEST_FILE_SUFFIX=' <<< "$FRAMEWORK_INFO" | cut -d= -f2-)"

  if run_gate "$EFFECTIVE_FRAMEWORK" "$TEST_COMMAND" "$TEST_FILE_SUFFIX"; then
    OUTCOME="PASSED"
    GATE_FRAMEWORK="$EFFECTIVE_FRAMEWORK"
    GATE_TEST_COMMAND="$TEST_COMMAND"
    # Same directory run_gate already resolved -- recomputed here (cheap,
    # side-effect-free directory walk) since run_gate's copy is local to
    # its own scope. AUTONOMOUS mode's test-grid step (PLAN 4.2) reuses
    # this via GITHUB_OUTPUT instead of re-detecting from scratch.
    if [[ "$EFFECTIVE_FRAMEWORK" == "none" ]]; then
      GATE_MANIFEST_DIR="$GITHUB_WORKSPACE"
    else
      GATE_MANIFEST_DIR="$(find_manifest_dir "$(manifest_for "$EFFECTIVE_FRAMEWORK")")"
    fi
    break
  fi
  echo "attempt $ATTEMPT: gate failed"
done

{
  echo "outcome=$OUTCOME"
  echo "attempts_made=$ATTEMPT"
  echo "confidence_note=$CONFIDENCE_NOTE"
  echo "summary=$SUMMARY"
  echo "test_framework=$GATE_FRAMEWORK"
  echo "test_command=$GATE_TEST_COMMAND"
  echo "manifest_dir=$GATE_MANIFEST_DIR"
} >> "${GITHUB_OUTPUT:-/dev/null}"

if [[ "$OUTCOME" == "PASSED" ]]; then
  echo "Hermes repair succeeded on attempt $ATTEMPT/$MAX_ATTEMPTS"
  exit 0
fi

echo "Hermes exhausted $MAX_ATTEMPTS attempts without a valid patch"
SEVERITY="page"
[[ "$REVI_MODE" == "AUTONOMOUS" ]] && SEVERITY="critical"

SERVICE_NAME="$SERVICE_NAME" \
SEVERITY="$SEVERITY" \
REASON="EXHAUSTION" \
REVI_MODE="$REVI_MODE" \
ERROR_SUMMARY="$ERROR_SUMMARY" \
CONFIDENCE_NOTE="[UNRESOLVED - 3 ATTEMPTS FAILED]" \
ATTEMPTS_MADE="$ATTEMPT" \
ALERT_ID="$ALERT_ID" \
bash "$SCRIPT_DIR/escalate.sh"

exit 1
