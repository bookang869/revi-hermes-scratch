#!/usr/bin/env bash
# Test double for $REVI_AGENT_COMMAND -- mimics `hermes -z "<prompt>"`'s
# interface (takes the prompt as its final arg, prints the JSON contract to
# stdout) without spending real API calls. FAKE_AGENT_MODE controls what it
# actually does to the checked-out fixture app, so the wrapper's real gating
# (git diff check, go build, go test) gets exercised against real file
# changes, not just canned JSON.
#
# FAKE_AGENT_SEQUENCE (optional, comma-separated) simulates different
# behavior per repair-loop attempt, e.g. "fail_no_test,fail_always,succeed"
# for a "fails twice then succeeds" scenario -- tracked via a counter file
# since the wrapper invokes this fresh each attempt with no attempt number.
set -euo pipefail

APP_DIR="${FIXTURE_APP_DIR:?FIXTURE_APP_DIR is required}"

if [[ -n "${FAKE_AGENT_SEQUENCE:-}" ]]; then
  COUNTER_FILE="${FAKE_AGENT_COUNTER_FILE:?FAKE_AGENT_COUNTER_FILE is required when FAKE_AGENT_SEQUENCE is set}"
  N=0
  [[ -f "$COUNTER_FILE" ]] && N="$(cat "$COUNTER_FILE")"
  echo "$((N + 1))" > "$COUNTER_FILE"
  IFS=',' read -ra MODES <<< "$FAKE_AGENT_SEQUENCE"
  MODE="${MODES[$N]}"
else
  MODE="${FAKE_AGENT_MODE:?FAKE_AGENT_MODE is required}"
fi

case "$MODE" in
  succeed)
    # Real fix + a real sibling test that actually exercises it.
    cat > "$APP_DIR/order.go" <<'GO'
package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

func Summarize(o *Order) string {
	if o.Customer == nil {
		return fmt.Sprintf("unknown customer owes %d", o.Amount)
	}
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount)
}
GO
    cat > "$APP_DIR/order_test.go" <<'GO'
package main

import "testing"

func TestSummarize_NilCustomer(t *testing.T) {
	got := Summarize(&Order{Amount: 42})
	want := "unknown customer owes 42"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}
GO
    echo '{"confidence_note": "High confidence: added nil check on Order.Customer", "summary": "Fixed nil pointer dereference in Summarize", "test_framework": "go"}'
    ;;

  fail_no_test)
    # Fixes the bug but never writes a test file -- must be rejected
    # regardless of go test passing, per PLAN's "AI fails to write the
    # L1/L2 test -> reject patch" rule.
    cat > "$APP_DIR/order.go" <<'GO'
package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

func Summarize(o *Order) string {
	if o.Customer == nil {
		return fmt.Sprintf("unknown customer owes %d", o.Amount)
	}
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount)
}
GO
    echo '{"confidence_note": "Fixed it", "summary": "Added nil check", "test_framework": "go"}'
    ;;

  fail_broken_compile)
    # Test file written, but the "fix" does not even compile.
    cat > "$APP_DIR/order.go" <<'GO'
package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

func Summarize(o *Order) string {
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount extraTokenBreaksCompile)
}
GO
    cat > "$APP_DIR/order_test.go" <<'GO'
package main

import "testing"

func TestSummarize_NilCustomer(t *testing.T) {
	_ = Summarize(&Order{Amount: 42})
}
GO
    echo '{"confidence_note": "Fixed it", "summary": "Added nil check", "test_framework": "go"}'
    ;;

  fail_always)
    # Compiles, test file exists, but the fix is wrong -- test fails.
    cat > "$APP_DIR/order_test.go" <<'GO'
package main

import "testing"

func TestSummarize_NilCustomer(t *testing.T) {
	got := Summarize(&Order{Amount: 42})
	want := "this will never match because the bug is not actually fixed"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}
GO
    echo '{"confidence_note": "Fixed it", "summary": "Added nil check", "test_framework": "go"}'
    ;;

  fail_test_wrong_dir)
    # Real fix, but the "test file" lands outside the manifest directory --
    # must be rejected even though some file in the repo matches the
    # suffix, per the gate's directory-scoping requirement.
    cat > "$APP_DIR/order.go" <<'GO'
package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

func Summarize(o *Order) string {
	if o.Customer == nil {
		return fmt.Sprintf("unknown customer owes %d", o.Amount)
	}
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount)
}
GO
    cat > "$GITHUB_WORKSPACE/rogue_test.go" <<'GO'
package rogue

import "testing"

func TestNothing(t *testing.T) {}
GO
    echo '{"confidence_note": "High confidence: added nil check on Order.Customer", "summary": "Fixed nil pointer dereference in Summarize", "test_framework": "go"}'
    ;;

  succeed_via_rename)
    # Test file arrives via a staged git rename (R  old -> new) rather than
    # a fresh untracked file -- exercises that the gate reads the renamed-to
    # path, not the renamed-from one.
    cat > "$APP_DIR/order.go" <<'GO'
package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

func Summarize(o *Order) string {
	if o.Customer == nil {
		return fmt.Sprintf("unknown customer owes %d", o.Amount)
	}
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount)
}
GO
    cat > "$APP_DIR/scratch.go" <<'GO'
package main

import "testing"

func TestSummarize_NilCustomer(t *testing.T) {
	got := Summarize(&Order{Amount: 42})
	want := "unknown customer owes 42"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}
GO
    git -C "$GITHUB_WORKSPACE" add "$APP_DIR/scratch.go"
    git -C "$GITHUB_WORKSPACE" -c user.email=t@t -c user.name=t commit -qm placeholder
    git -C "$GITHUB_WORKSPACE" mv "$APP_DIR/scratch.go" "$APP_DIR/order_test.go"
    echo '{"confidence_note": "High confidence: added nil check on Order.Customer", "summary": "Fixed nil pointer dereference in Summarize", "test_framework": "go"}'
    ;;

  fail_lint_violation)
    # Real fix, real passing test -- but an unrelated function in the same
    # file has a bad Printf verb (%d against a string arg). Compiles and
    # tests pass; only `go vet` catches it. Isolates the new lint gate from
    # the build/test gates the other scenarios already cover.
    cat > "$APP_DIR/order.go" <<'GO'
package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

func Summarize(o *Order) string {
	if o.Customer == nil {
		return fmt.Sprintf("unknown customer owes %d", o.Amount)
	}
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount)
}

func debugLog(o *Order) {
	fmt.Printf("processing order for %d\n", o.Customer.Name)
}
GO
    cat > "$APP_DIR/order_test.go" <<'GO'
package main

import "testing"

func TestSummarize_NilCustomer(t *testing.T) {
	got := Summarize(&Order{Amount: 42})
	want := "unknown customer owes 42"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}
GO
    echo '{"confidence_note": "High confidence: added nil check on Order.Customer", "summary": "Fixed nil pointer dereference in Summarize", "test_framework": "go"}'
    ;;

  malformed_json)
    echo 'Sure, I fixed the bug! Here is what I did: added a nil check.'
    ;;

  *)
    echo "fake-agent: unknown FAKE_AGENT_MODE '$MODE'" >&2
    exit 1
    ;;
esac
