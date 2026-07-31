#!/usr/bin/env bash
# End-to-end test of promote-pr.sh (PLAN 3.6 "done when": dispatch on a
# seeded bug yields an open PR + a page, and a re-dispatch updates rather
# than duplicates). Uses a local bare repo as the git remote and a fake
# GitHub API server instead of hitting real GitHub, same pattern as
# test_hermes_wrapper.sh's fake agent / mock receiver.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMOTE="$SCRIPT_DIR/promote-pr.sh"

FAILURES=0
PORT_BASE=8790

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if grep -qF -- "$needle" <<< "$haystack"; then
    echo "PASS: $label"
  else
    echo "FAIL: $label -- expected to find '$needle' in: $haystack"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_eq() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $label ($expected)"
  else
    echo "FAIL: $label -- expected '$expected', got '$actual'"
    FAILURES=$((FAILURES + 1))
  fi
}

# Sets up a bare "origin" + a checked-out working repo, a fake GitHub API
# (seeded with EXISTING_PR_URL, empty = "no PR yet"), and a mock escalation
# receiver, then runs promote-pr.sh and echoes everything the assertions need.
run_scenario() {
  local name="$1" existing_pr_url="$2"
  echo ""
  echo "=== scenario: $name ==="

  local origin; origin="$(mktemp -d)"
  git init -q --bare "$origin"
  local repo; repo="$(mktemp -d)"
  ( cd "$repo" && git init -q -b main && git remote add origin "$origin" \
      && echo seed > seed.txt && git add -A \
      && git -c user.email=t@t -c user.name=t commit -qm seed \
      && git push -q origin main )
  echo "fix" >> "$repo/seed.txt"  # simulates the wrapper's uncommitted patch

  local api_port=$((PORT_BASE + 1)); PORT_BASE=$api_port
  local recv_port=$((PORT_BASE + 1)); PORT_BASE=$recv_port
  local api_out; api_out="$(mktemp)"
  local recv_out; recv_out="$(mktemp)"
  local gh_output; gh_output="$(mktemp)"

  python3 "$SCRIPT_DIR/fake-github-api.py" "$api_port" "$existing_pr_url" > "$api_out" 2>&1 &
  local api_pid=$!
  python3 "$SCRIPT_DIR/mock_receiver.py" "promote-test-secret" "$recv_port" > "$recv_out" 2>&1 &
  local recv_pid=$!
  sleep 0.3

  ( export GITHUB_WORKSPACE="$repo"
    export GITHUB_TOKEN_HERMES="dummy-token"
    export GITHUB_REPOSITORY="fake-owner/fake-repo"
    export GITHUB_API_BASE_URL="http://127.0.0.1:$api_port"
    export ALERT_ID="test-$name" SERVICE_NAME="fixture-svc"
    export ERROR_SUMMARY="invalid memory address or nil pointer dereference"
    export SUMMARY="fixed the nil check" CONFIDENCE_NOTE="high" ATTEMPTS_MADE="1"
    export REVI_ESCALATION_WEBHOOK_URL="http://127.0.0.1:$recv_port"
    export REVI_ESCALATION_WEBHOOK_SECRET="promote-test-secret"
    export GITHUB_OUTPUT="$gh_output"
    bash "$PROMOTE" > /dev/null 2>&1
  )
  local promote_exit=$?

  sleep 0.3
  kill "$api_pid" "$recv_pid" 2>/dev/null
  wait "$api_pid" "$recv_pid" 2>/dev/null

  PROMOTE_EXIT="$promote_exit"
  PR_URL_OUTPUT="$(grep '^pr_url=' "$gh_output" 2>/dev/null | cut -d= -f2-)"
  API_LOG="$(cat "$api_out" 2>/dev/null)"
  ESCALATION_PAYLOAD="$(grep 'RECEIVED_PAYLOAD' "$recv_out" 2>/dev/null || echo '')"
  PUSHED_BRANCH="$(git -C "$origin" branch --list "hermes/hotfix-test-$name")"

  rm -rf "$origin" "$repo" "$api_out" "$recv_out" "$gh_output"
}

### Scenario A: no PR exists yet -- creates one, escalates PR_READY
run_scenario "new-pr" ""
assert_eq "$PROMOTE_EXIT" "0" "A: promote-pr.sh exit code"
assert_contains "$PUSHED_BRANCH" "hermes/hotfix-test-new-pr" "A: hotfix branch pushed to origin"
assert_contains "$API_LOG" "CREATE_PR_PAYLOAD" "A: PR create call made"
assert_contains "$API_LOG" "\"base\": \"main\"" "A: PR targets main"
assert_eq "$PR_URL_OUTPUT" "http://127.0.0.1:9/pulls/1" "A: pr_url output"
assert_contains "$ESCALATION_PAYLOAD" "\"reason\": \"PR_READY\"" "A: escalation reason"
assert_contains "$ESCALATION_PAYLOAD" "\"severity\": \"page\"" "A: escalation severity"
assert_contains "$ESCALATION_PAYLOAD" "\"pr_url\": \"http://127.0.0.1:9/pulls/1\"" "A: escalation pr_url"

### Scenario B: PR already open -- comments instead of creating a duplicate
run_scenario "existing-pr" "http://example.com/pulls/42"
assert_eq "$PROMOTE_EXIT" "0" "B: promote-pr.sh exit code"
assert_contains "$PUSHED_BRANCH" "hermes/hotfix-test-existing-pr" "B: hotfix branch force-pushed to origin"
assert_contains "$API_LOG" "COMMENT_PAYLOAD" "B: PR comment call made"
if grep -q "CREATE_PR_PAYLOAD" <<< "$API_LOG"; then
  echo "FAIL: B: should not create a duplicate PR"
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: B: no duplicate PR created"
fi
assert_eq "$PR_URL_OUTPUT" "http://example.com/pulls/42" "B: pr_url output reuses existing PR"
assert_contains "$ESCALATION_PAYLOAD" "\"pr_url\": \"http://example.com/pulls/42\"" "B: escalation pr_url reuses existing PR"

echo ""
if [[ "$FAILURES" -eq 0 ]]; then
  echo "ALL PASS"
  exit 0
else
  echo "$FAILURES FAILURE(S)"
  exit 1
fi
