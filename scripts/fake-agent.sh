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

  rust_succeed)
    # Real fix + a real test (in the same file -- cargo has no sibling-file
    # suffix convention, per hermes-wrapper.sh's test_file_suffix comment).
    cat > "$APP_DIR/src/order.rs" <<'RUST'
pub struct Customer {
    pub name: String,
}

pub struct Order {
    pub customer: Option<Customer>,
    pub amount: i64,
}

pub fn summarize(o: &Order) -> String {
    match &o.customer {
        Some(c) => format!("{} owes {}", c.name, o.amount),
        None => format!("unknown customer owes {}", o.amount),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn summarize_nil_customer() {
        let o = Order {
            customer: None,
            amount: 42,
        };
        assert_eq!(summarize(&o), "unknown customer owes 42");
    }
}
RUST
    echo '{"confidence_note": "High confidence: matched on Option<Customer>", "summary": "Fixed unwrap-on-None panic in summarize", "test_framework": "cargo"}'
    ;;

  rust_fail_broken_compile)
    # The "fix" does not even compile.
    cat > "$APP_DIR/src/order.rs" <<'RUST'
pub struct Customer {
    pub name: String,
}

pub struct Order {
    pub customer: Option<Customer>,
    pub amount: i64,
}

pub fn summarize(o: &Order) -> String {
    format!("{} owes {}", o.customer.as_ref().unwrap().name, o.amount extraTokenBreaksCompile)
}
RUST
    echo '{"confidence_note": "Fixed it", "summary": "Matched on Option", "test_framework": "cargo"}'
    ;;

  rust_fail_lint_violation)
    # Real fix, real passing test -- but an unrelated function has a
    # clippy-flagged len()==0 comparison (clippy::len_zero, on by default,
    # not just pedantic). Compiles and tests pass; only `cargo clippy`
    # catches it -- isolates the lint gate from the build/test gates the
    # other scenarios already cover.
    cat > "$APP_DIR/src/order.rs" <<'RUST'
pub struct Customer {
    pub name: String,
}

pub struct Order {
    pub customer: Option<Customer>,
    pub amount: i64,
}

pub fn summarize(o: &Order) -> String {
    match &o.customer {
        Some(c) => format!("{} owes {}", c.name, o.amount),
        None => format!("unknown customer owes {}", o.amount),
    }
}

pub fn has_customer_name(o: &Order) -> bool {
    match &o.customer {
        Some(c) => c.name.len() == 0,
        None => true,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn summarize_nil_customer() {
        let o = Order {
            customer: None,
            amount: 42,
        };
        assert_eq!(summarize(&o), "unknown customer owes 42");
    }

    #[test]
    fn has_customer_name_nil_customer() {
        let o = Order {
            customer: None,
            amount: 42,
        };
        assert!(has_customer_name(&o));
    }
}
RUST
    echo '{"confidence_note": "High confidence: matched on Option<Customer>", "summary": "Fixed unwrap-on-None panic in summarize", "test_framework": "cargo"}'
    ;;

  node_succeed)
    # Real fix + a real sibling test that actually exercises it.
    cat > "$APP_DIR/order.js" <<'JS'
/**
 * @typedef {{name: string}} Customer
 * @typedef {{customer?: Customer, amount: number}} Order
 */

/**
 * @param {Order} order
 * @returns {string}
 */
function summarize(order) {
  if (!order.customer) {
    return `unknown customer owes ${order.amount}`;
  }
  return `${order.customer.name} owes ${order.amount}`;
}

module.exports = { summarize };
JS
    cat > "$APP_DIR/order.test.js" <<'JS'
const { summarize } = require("./order");

test("summarize with no customer", () => {
  expect(summarize({ amount: 42 })).toBe("unknown customer owes 42");
});
JS
    echo '{"confidence_note": "High confidence: guarded on order.customer before dereferencing", "summary": "Fixed undefined property access in summarize", "test_framework": "jest"}'
    ;;

  node_fail_broken_compile)
    # Test file written, but the "fix" does not even parse.
    cat > "$APP_DIR/order.js" <<'JS'
/**
 * @param {{customer?: {name: string}, amount: number}} order
 * @returns {string}
 */
function summarize(order) {
  return `${order.customer.name} owes ${order.amount extraTokenBreaksCompile}`;
}

module.exports = { summarize };
JS
    cat > "$APP_DIR/order.test.js" <<'JS'
const { summarize } = require("./order");

test("summarize with no customer", () => {
  expect(summarize({ amount: 42 })).toBe("unknown customer owes 42");
});
JS
    echo '{"confidence_note": "Fixed it", "summary": "Guarded on order.customer", "test_framework": "jest"}'
    ;;

  node_fail_lint_violation)
    # Real fix, real passing test -- but an unrelated function uses `==`
    # instead of `===`. Compiles (tsc) and tests pass; only eslint's
    # eqeqeq rule catches it -- isolates the lint gate from the build/test
    # gates the other scenarios already cover.
    cat > "$APP_DIR/order.js" <<'JS'
/**
 * @typedef {{name: string}} Customer
 * @typedef {{customer?: Customer, amount: number}} Order
 */

/**
 * @param {Order} order
 * @returns {string}
 */
function summarize(order) {
  if (!order.customer) {
    return `unknown customer owes ${order.amount}`;
  }
  return `${order.customer.name} owes ${order.amount}`;
}

/**
 * @param {Order} order
 * @returns {boolean}
 */
function isRoundAmount(order) {
  return order.amount == 0;
}

module.exports = { summarize, isRoundAmount };
JS
    cat > "$APP_DIR/order.test.js" <<'JS'
const { summarize } = require("./order");

test("summarize with no customer", () => {
  expect(summarize({ amount: 42 })).toBe("unknown customer owes 42");
});
JS
    echo '{"confidence_note": "High confidence: guarded on order.customer before dereferencing", "summary": "Fixed undefined property access in summarize", "test_framework": "jest"}'
    ;;

  malformed_json)
    echo 'Sure, I fixed the bug! Here is what I did: added a nil check.'
    ;;

  *)
    echo "fake-agent: unknown FAKE_AGENT_MODE '$MODE'" >&2
    exit 1
    ;;
esac
