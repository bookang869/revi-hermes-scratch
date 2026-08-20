#!/usr/bin/env bash
# AUTONOMOUS promotion: existing test grid + merge to main via the GitHub
# REST API (TRD FR-05, PLAN 4.2/4.3). Called only after hermes-wrapper.sh's
# gate AND smoke-test.sh have both passed. Reuses the framework/manifest_dir
# the wrapper already detected (TEST_COMMAND/MANIFEST_DIR env, sourced from
# steps.wrapper.outputs in the workflow) rather than re-detecting -- this is
# a single-service repo per TRD Sec 2.
#
# On a full pass: commits + force-pushes hermes/hotfix-[alert-id] with
# GITHUB_TOKEN_HERMES, runs the project's full test suite from
# MANIFEST_DIR, and if that also passes, creates the merge commit into main
# via the GitHub REST API's "merge a branch" endpoint using
# GITHUB_TOKEN_PROD. Corrected 2026-08-03 (TRD Sec 5): this endpoint does
# NOT produce an auto-"Verified"/signed commit -- that was an earlier
# unconfirmed assumption, empirically falsified. No GPG key is used either
# way; the merge is a plain, unsigned commit like any other API-created one.
#
# On a test-grid failure: abandon the workspace (never attempt the merge),
# force-delete the just-pushed hotfix branch, escalate REGRESSION/critical --
# main stays untouched either way.
set -uo pipefail  # not -e: failure paths are inspected, not fatal mid-script

: "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"
: "${GITHUB_TOKEN_HERMES:?GITHUB_TOKEN_HERMES is required}"
: "${GITHUB_TOKEN_PROD:?GITHUB_TOKEN_PROD is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${ALERT_ID:?ALERT_ID is required}"
: "${SERVICE_NAME:?SERVICE_NAME is required}"
: "${ERROR_SUMMARY:?ERROR_SUMMARY is required}"
: "${SUMMARY:?SUMMARY is required}"
: "${CONFIDENCE_NOTE:?CONFIDENCE_NOTE is required}"
: "${ATTEMPTS_MADE:?ATTEMPTS_MADE is required}"
: "${TEST_COMMAND:?TEST_COMMAND is required}"
: "${MANIFEST_DIR:?MANIFEST_DIR is required}"
: "${REVI_ESCALATION_WEBHOOK_URL:?REVI_ESCALATION_WEBHOOK_URL is required}"
: "${REVI_ESCALATION_WEBHOOK_SECRET:?REVI_ESCALATION_WEBHOOK_SECRET is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ponytail: override hook for tests only (points at a local fake API server
# instead of github.com); never set in the real workflow.
API="${GITHUB_API_BASE_URL:-https://api.github.com}/repos/$GITHUB_REPOSITORY"
BRANCH="hermes/hotfix-$ALERT_ID"
export BRANCH
HERMES_AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN_HERMES"
PROD_AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN_PROD"

cd "$GITHUB_WORKSPACE"

escalate() {
  SERVICE_NAME="$SERVICE_NAME" \
  SEVERITY="critical" \
  REASON="$1" \
  REVI_MODE="AUTONOMOUS" \
  ERROR_SUMMARY="$ERROR_SUMMARY" \
  CONFIDENCE_NOTE="$2" \
  ATTEMPTS_MADE="$ATTEMPTS_MADE" \
  ALERT_ID="$ALERT_ID" \
  bash "$SCRIPT_DIR/escalate.sh"
}

git config user.name "revi-hermes[bot]"
git config user.email "revi-hermes[bot]@users.noreply.github.com"
git checkout -b "$BRANCH"
git add -A
git commit -q -m "Hermes autonomous fix: $SUMMARY"

# Header-based auth (same trick as promote-pr.sh) instead of embedding the
# token in the remote URL -- keeps it out of push error output/logs.
git -c http."https://github.com/".extraheader="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN_HERMES" | base64 -w0)" \
  push --force origin "HEAD:refs/heads/$BRANCH"

echo "=== Running full test grid: $TEST_COMMAND (in $MANIFEST_DIR) ==="
if ! (cd "$MANIFEST_DIR" && eval "$TEST_COMMAND"); then
  echo "autonomous-promote: existing test grid failed -- abandoning, main untouched" >&2

  # Branch Pruning (TRD FR-05): force-delete the branch just pushed so no
  # dangling evidence of the rejected attempt is left on the remote.
  curl --silent --show-error -X DELETE -H "$HERMES_AUTH_HEADER" \
    "$API/git/refs/heads/$BRANCH" > /dev/null

  escalate "REGRESSION" "$CONFIDENCE_NOTE"
  {
    echo "outcome=FAILED"
    echo "escalation_reason=REGRESSION"
    echo "failure_stage=regression_test"
    echo "failure_classification=remediation_failure"
  } >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 1
fi

echo "=== Test grid passed -- merging $BRANCH into main via GitHub REST API ==="
MERGE_PAYLOAD="$(python3 -c '
import json, os, sys
alert_id = os.environ["ALERT_ID"]
summary = os.environ["SUMMARY"]
branch = os.environ["BRANCH"]
json.dump({
    "base": "main",
    "head": branch,
    "commit_message": f"Hermes autonomous fix: {summary} (alert {alert_id})",
}, sys.stdout)
')"

RESPONSE="$(curl --silent --show-error -w '\n%{http_code}' \
  -X POST -H "$PROD_AUTH_HEADER" -H "Content-Type: application/json" \
  -d "$MERGE_PAYLOAD" "$API/merges")"
HTTP_CODE="$(tail -n1 <<< "$RESPONSE")"
BODY="$(sed '$d' <<< "$RESPONSE")"

if [[ "$HTTP_CODE" != 2* ]]; then
  echo "autonomous-promote: merge API returned $HTTP_CODE: $BODY" >&2
  # MERGE_REJECTED (added 2026-08-20, PLAN 6.9 audit): every gate already
  # passed here (build/lint/test-quality plus the full test grid) -- the
  # API merge call itself was rejected (e.g. a still-pending required
  # status check, an unexpected conflict). Previously reused REGRESSION,
  # which is misleading: a real REGRESSION means the fix is bad and its
  # branch gets force-deleted; here the branch is deliberately left in
  # place so a human can inspect/manually merge it after investigating why
  # the API call itself failed. A paged human needs to tell these apart
  # from the reason alone, not by reading into the confidence note.
  escalate "MERGE_REJECTED" "$CONFIDENCE_NOTE (merge API rejected: HTTP $HTTP_CODE)"
  {
    echo "outcome=FAILED"
    echo "escalation_reason=MERGE_REJECTED"
    echo "failure_stage=merge"
    # infrastructure_failure, not remediation_failure: every code-quality
    # gate already passed here (build/lint/test-quality plus the full test
    # grid) -- the API call itself was rejected (pending status check,
    # conflict, transient GitHub issue), which is a supporting-infra
    # problem, not evidence Hermes's fix was wrong (revi/docs/
    # observability-part-a.md metric #12).
    echo "failure_classification=infrastructure_failure"
  } >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 1
fi

MERGE_SHA="$(python3 -c '
import json, sys
try:
    print(json.loads(sys.stdin.read() or "{}").get("sha", ""))
except Exception:
    print("")
' <<< "$BODY")"

echo "autonomous-promote: merged $BRANCH into main (sha: ${MERGE_SHA:-n/a})"
{
  echo "outcome=MERGED"
  echo "merge_sha=$MERGE_SHA"
  echo "merged=true"
} >> "${GITHUB_OUTPUT:-/dev/null}"
