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

Find the file responsible for this crash and fix it. Unless test_framework is "none", also write a sibling test file (same directory as the fixed file) that fails before your fix and passes after it -- do not skip this. Name it using exactly this suffix convention, not any other valid convention for the language: Go -> <name>_test.go, Rust -> tests/<name>_test.rs, Jest -> <name>.test.js, pytest -> <name>_test.py (e.g. fixing order.py means writing order_test.py, not test_order.py). $framework_instruction

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

# Prefers walking up from FIXTURE_APP_DIR (the service's own app directory,
# already resolved from SERVICE_NAME by resolve-boot-command.sh and trusted
# elsewhere in the pipeline for booting/smoke-testing it) when set -- this is
# a known-correct anchor, unlike guessing from git status order below.
# Falls back to walking up from the first file git shows as changed when
# FIXTURE_APP_DIR is unset or its walk doesn't find the manifest. That
# fallback is self-verifying (doesn't require Hermes to report a path, since
# the wrapper already inspects git status for the test-file check below) but
# fragile on its own: git status order isn't tied to which file the fix
# actually lives in, so a single attempt spanning two directories (e.g. a
# stray file touched outside the fixture app) can walk from the wrong one --
# caught live 2026-08-19 during a real rehearsal run, where attempt 1 failed
# "no requirements.txt found" despite fixture-app-python/requirements.txt
# existing. awk '{print $NF}' (not $2) gets renamed files right -- `R  old ->
# new` puts the new path last.
find_manifest_dir() {
  local manifest="$1" changed_file dir anchor

  if [[ -n "${FIXTURE_APP_DIR:-}" ]]; then
    # Accepts either form: production passes a GITHUB_WORKSPACE-relative
    # path (matching resolve-boot-command.sh's other outputs); the local
    # test harness (test_hermes_wrapper.sh) passes an absolute path since
    # fake-agent.sh writes fixture files directly from it.
    anchor="$FIXTURE_APP_DIR"
    [[ "$anchor" != /* ]] && anchor="$GITHUB_WORKSPACE/$anchor"
    if [[ -d "$anchor" ]]; then
      dir="$(cd "$anchor" && pwd)"
      while :; do
        [[ -f "$dir/$manifest" ]] && { echo "$dir"; return 0; }
        [[ "$dir" == "$GITHUB_WORKSPACE" ]] && break
        dir="$(dirname "$dir")"
      done
    fi
  fi

  changed_file="$(git -C "$GITHUB_WORKSPACE" status --porcelain --untracked-files=all | awk '{print $NF}' | head -1)"
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
  local framework="$1" test_command="$2" test_file_suffix="$3" test_file_prefix="$4"

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
  # directly, rather than trusting the test command's exit code alone. All
  # four frameworks now have a non-empty suffix (PLAN 6.5 follow-up,
  # 2026-08-17) -- Cargo's targets its tests/ integration-test directory,
  # since in-crate #[cfg(test)] mods aren't a separate file to check for.
  # --untracked-files=all is required here: plain `git status --porcelain`
  # collapses a brand-new untracked directory (tests/, which doesn't exist
  # in the seeded fixture) into a single `?? fixture-app-rust/tests/` line
  # instead of listing the file inside it, so the suffix grep below would
  # never match a real tests/order_test.rs -- caught by scenario J
  # regressing to FAILED once Cargo's suffix went from empty to non-empty.
  if [[ -n "$test_file_suffix" ]]; then
    local manifest_rel changed_files match_anchor
    manifest_rel="${manifest_dir#"$GITHUB_WORKSPACE"}"
    manifest_rel="${manifest_rel#/}"
    changed_files="$(git -C "$GITHUB_WORKSPACE" status --porcelain --untracked-files=all | awk '{print $NF}')"
    [[ -n "$manifest_rel" ]] && changed_files="$(grep -- "^${manifest_rel}/" <<< "$changed_files")"
    # test_file_prefix (Cargo only, "tests/") additionally requires the
    # match sit in that subdirectory relative to manifest_dir -- a bare
    # suffix match alone would also accept e.g. src/order_test.rs, which
    # `cargo test` wouldn't even discover (PLAN 6.9 audit, 2026-08-20).
    if [[ -n "$manifest_rel" ]]; then
      match_anchor="^${manifest_rel}/${test_file_prefix}"
    else
      match_anchor="^${test_file_prefix}"
    fi
    if ! grep -q -- "${match_anchor}.*${test_file_suffix}\$" <<< "$changed_files"; then
      echo "gate: no changed file under $manifest_dir/${test_file_prefix} matching *$test_file_suffix -- test not written" >&2
      return 1
    fi
  fi

  case "$framework" in
    go)     (cd "$manifest_dir" && go build ./...) || { echo "gate: go build failed" >&2; return 1; } ;;
    cargo)  (cd "$manifest_dir" && cargo build) || { echo "gate: cargo build failed" >&2; return 1; } ;;
    jest)   (cd "$manifest_dir" && tsc --noEmit) || { echo "gate: tsc build failed" >&2; return 1; } ;;
    pytest) (cd "$manifest_dir" && python3 -m py_compile ./*.py) || { echo "gate: py_compile failed" >&2; return 1; } ;;
  esac

  # Lint pass (PLAN 6.2, folded into 6.5's per-language passes).
  case "$framework" in
    go)     (cd "$manifest_dir" && go vet ./...) || { echo "gate: go vet failed" >&2; return 1; } ;;
    cargo)  (cd "$manifest_dir" && cargo clippy --all-targets -- -D warnings) || { echo "gate: cargo clippy failed" >&2; return 1; } ;;
    jest)   (cd "$manifest_dir" && eslint .) || { echo "gate: eslint failed" >&2; return 1; } ;;
    pytest) (cd "$manifest_dir" && ruff check .) || { echo "gate: ruff check failed" >&2; return 1; } ;;
  esac

  # Fails-before/passes-after check (test-quality gap, 2026-08-17, grilled
  # with the user): a green test run proves nothing about whether the test
  # actually exercises the bug -- a vacuous test (one that never calls the
  # buggy path) would pass regardless of the fix and sail through every
  # check above, which is the one way a non-fix could reach `main`
  # unattended in AUTONOMOUS mode. Verify the new test specifically catches
  # the bug: stash away everything Hermes changed EXCEPT the new test
  # file(s) (restoring the original buggy source), confirm the test fails
  # against that, then restore the fix and fall through to the existing
  # "test must pass" check below. Only meaningful when the fix actually
  # touched a non-test file -- if Hermes only wrote a test and changed
  # nothing else, there's nothing to isolate, and the plain run below
  # already rejects an unfixed bug on its own.
  if [[ -n "$test_file_suffix" ]]; then
    local fix_files=() line
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      [[ "$line" == *"$test_file_suffix" ]] && continue
      fix_files+=("$line")
    done <<< "$changed_files"

    if [[ "${#fix_files[@]}" -gt 0 ]]; then
      if ! git -C "$GITHUB_WORKSPACE" stash push --quiet --include-untracked -- "${fix_files[@]}"; then
        echo "gate: failed to isolate the fix for the fails-before check -- rejecting this attempt" >&2
        return 1
      fi

      echo "gate: running test WITHOUT the fix (must fail) -- verifying the new test isn't vacuous"
      local before_rc=0
      (cd "$manifest_dir" && eval "$test_command") || before_rc=$?

      if ! git -C "$GITHUB_WORKSPACE" stash pop --quiet; then
        echo "gate: failed to restore the fix after the fails-before check -- workspace may be in a bad state, rejecting this attempt" >&2
        return 1
      fi

      if [[ "$before_rc" -eq 0 ]]; then
        echo "gate: sibling test passes even without the fix -- vacuous test, rejected" >&2
        return 1
      fi
    fi
  fi

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
  TEST_FILE_PREFIX="$(grep '^TEST_FILE_PREFIX=' <<< "$FRAMEWORK_INFO" | cut -d= -f2-)"

  if run_gate "$EFFECTIVE_FRAMEWORK" "$TEST_COMMAND" "$TEST_FILE_SUFFIX" "$TEST_FILE_PREFIX"; then
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

# Observability write path (revi/docs/observability-part-a.md): validated
# reflects whether THIS gate -- compile/lint/test-quality, the one TRD calls
# "Re:vi's own gate" -- passed, independent of what a later AUTONOMOUS-only
# check (smoke/regression) does with it. merged is never true from here; only
# autonomous-promote.sh's own successful-merge branch sets it. model is
# parsed straight out of REVI_AGENT_COMMAND (the --model flag value) rather
# than hardcoded, so a future override still reports correctly.
VALIDATED="false"
MERGED="false"
ESCALATION_REASON=""
FAILURE_STAGE=""
FAILURE_CLASSIFICATION=""
MODEL=""
read -ra _AGENT_CMD_PARTS <<< "$REVI_AGENT_COMMAND"
for _i in "${!_AGENT_CMD_PARTS[@]}"; do
  if [[ "${_AGENT_CMD_PARTS[$_i]}" == "--model" ]]; then
    MODEL="${_AGENT_CMD_PARTS[$((_i + 1))]}"
    break
  fi
done

if [[ "$OUTCOME" == "PASSED" ]]; then
  VALIDATED="true"
else
  ESCALATION_REASON="EXHAUSTION"
  FAILURE_STAGE="patch_generation"
  FAILURE_CLASSIFICATION="remediation_failure"
fi

{
  echo "outcome=$OUTCOME"
  echo "attempts_made=$ATTEMPT"
  echo "confidence_note=$CONFIDENCE_NOTE"
  echo "summary=$SUMMARY"
  echo "test_framework=$GATE_FRAMEWORK"
  echo "test_command=$GATE_TEST_COMMAND"
  echo "manifest_dir=$GATE_MANIFEST_DIR"
  echo "validated=$VALIDATED"
  echo "merged=$MERGED"
  echo "escalation_reason=$ESCALATION_REASON"
  echo "failure_stage=$FAILURE_STAGE"
  echo "failure_classification=$FAILURE_CLASSIFICATION"
  echo "model=$MODEL"
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
