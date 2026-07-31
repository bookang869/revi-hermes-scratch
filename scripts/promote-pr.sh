#!/usr/bin/env bash
# PR_REVIEW promotion (PLAN 3.6). Called only after hermes-wrapper.sh's gate
# passes: commits the working tree, force-pushes hermes/hotfix-[alert-id]
# with GITHUB_TOKEN_HERMES, opens a same-repo PR to main (or, if one is
# already open for that branch, force-pushes and adds a timestamped comment
# instead of a duplicate PR), then escalates PR_READY -- reusing escalate.sh
# as-is, since its payload already has a PR_URL field.
set -euo pipefail

: "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"
: "${GITHUB_TOKEN_HERMES:?GITHUB_TOKEN_HERMES is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${ALERT_ID:?ALERT_ID is required}"
: "${SERVICE_NAME:?SERVICE_NAME is required}"
: "${ERROR_SUMMARY:?ERROR_SUMMARY is required}"
: "${SUMMARY:?SUMMARY is required}"
: "${CONFIDENCE_NOTE:?CONFIDENCE_NOTE is required}"
: "${ATTEMPTS_MADE:?ATTEMPTS_MADE is required}"
: "${REVI_ESCALATION_WEBHOOK_URL:?REVI_ESCALATION_WEBHOOK_URL is required}"
: "${REVI_ESCALATION_WEBHOOK_SECRET:?REVI_ESCALATION_WEBHOOK_SECRET is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ponytail: override hook for tests only (points at a local fake API server
# instead of github.com); never set in the real workflow.
API="${GITHUB_API_BASE_URL:-https://api.github.com}/repos/$GITHUB_REPOSITORY"
OWNER="${GITHUB_REPOSITORY%%/*}"
export BRANCH="hermes/hotfix-$ALERT_ID"
AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN_HERMES"
export TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cd "$GITHUB_WORKSPACE"

git config user.name "revi-hermes[bot]"
git config user.email "revi-hermes[bot]@users.noreply.github.com"
git checkout -b "$BRANCH"
git add -A
git commit -q -m "Hermes hotfix: $SUMMARY"

# Header-based auth (same trick actions/checkout uses) instead of embedding
# the token in the remote URL -- keeps it out of push error output/logs.
git -c http."https://github.com/".extraheader="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN_HERMES" | base64 -w0)" \
  push --force origin "HEAD:refs/heads/$BRANCH"

EXISTING_PR_URL="$(curl --fail --silent --show-error -H "$AUTH_HEADER" \
  "$API/pulls?head=$OWNER:$BRANCH&state=open" | \
  python3 -c 'import json, sys; d = json.load(sys.stdin); print(d[0]["html_url"] if d else "")')"

if [[ -n "$EXISTING_PR_URL" ]]; then
  PR_URL="$EXISTING_PR_URL"
  PR_NUMBER="${PR_URL##*/}"
  COMMENT_PAYLOAD="$(python3 -c '
import json, os, sys
ts = os.environ["TIMESTAMP"]
summary = os.environ["SUMMARY"]
json.dump({"body": f"Hermes re-dispatched at {ts}: {summary}"}, sys.stdout)
')"
  curl --fail --silent --show-error -X POST -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "$COMMENT_PAYLOAD" \
    "$API/issues/$PR_NUMBER/comments" > /dev/null
else
  PR_PAYLOAD="$(python3 -c '
import json, os, sys
service_name = os.environ["SERVICE_NAME"]
alert_id = os.environ["ALERT_ID"]
error_summary = os.environ["ERROR_SUMMARY"]
summary = os.environ["SUMMARY"]
confidence_note = os.environ["CONFIDENCE_NOTE"]
body = (
    "Automated fix from Re:vi/Hermes.\n\n"
    f"**Error:** {error_summary}\n"
    f"**Summary:** {summary}\n"
    f"**Confidence:** {confidence_note}\n"
)
json.dump({
    "title": f"Hermes hotfix: {service_name} ({alert_id})",
    "head": os.environ["BRANCH"],
    "base": "main",
    "body": body,
}, sys.stdout)
')"
  PR_URL="$(curl --fail --silent --show-error -X POST -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "$PR_PAYLOAD" \
    "$API/pulls" | python3 -c 'import json, sys; print(json.load(sys.stdin)["html_url"])')"
fi

SERVICE_NAME="$SERVICE_NAME" \
SEVERITY="page" \
REASON="PR_READY" \
REVI_MODE="PR_REVIEW" \
ERROR_SUMMARY="$ERROR_SUMMARY" \
CONFIDENCE_NOTE="$CONFIDENCE_NOTE" \
ATTEMPTS_MADE="$ATTEMPTS_MADE" \
ALERT_ID="$ALERT_ID" \
PR_URL="$PR_URL" \
bash "$SCRIPT_DIR/escalate.sh"

echo "pr_url=$PR_URL" >> "${GITHUB_OUTPUT:-/dev/null}"
