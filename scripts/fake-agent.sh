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

  fail_vacuous_test)
    # Real fix, real passing test -- but the test only exercises the
    # already-working "Customer present" path, never the nil-Customer case
    # that was actually broken. Passes every gate that predates the
    # fails-before/passes-after check (build, vet, "test passes") since the
    # test would pass identically against the original buggy Summarize too
    # -- this is what the fails-before check exists to catch.
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

func TestSummarize_WithCustomer(t *testing.T) {
	got := Summarize(&Order{Customer: &Customer{Name: "Bob"}, Amount: 42})
	want := "Bob owes 42"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}
GO
    echo '{"confidence_note": "High confidence: added nil check on Order.Customer", "summary": "Fixed nil pointer dereference in Summarize", "test_framework": "go"}'
    ;;

  rust_succeed)
    # Real fix + a real sibling test under tests/ (Cargo's integration-test
    # dir -- the only Cargo convention that's a genuinely separate file the
    # way order_test.go/order.test.js/order_test.py are, per PLAN 6.5's
    # follow-up; requires src/lib.rs to expose `pub mod order` since
    # integration tests link against the crate from outside).
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
RUST
    mkdir -p "$APP_DIR/tests"
    cat > "$APP_DIR/tests/order_test.rs" <<'RUST'
use revi_fixture_app_rust::order::{summarize, Order};

#[test]
fn summarize_nil_customer() {
    let o = Order {
        customer: None,
        amount: 42,
    };
    assert_eq!(summarize(&o), "unknown customer owes 42");
}
RUST
    echo '{"confidence_note": "High confidence: matched on Option<Customer>", "summary": "Fixed unwrap-on-None panic in summarize", "test_framework": "cargo"}'
    ;;

  rust_fail_broken_compile)
    # Test file written, but the "fix" does not even compile.
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
    mkdir -p "$APP_DIR/tests"
    cat > "$APP_DIR/tests/order_test.rs" <<'RUST'
use revi_fixture_app_rust::order::{summarize, Order};

#[test]
fn summarize_nil_customer() {
    let o = Order {
        customer: None,
        amount: 42,
    };
    let _ = summarize(&o);
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
RUST
    mkdir -p "$APP_DIR/tests"
    cat > "$APP_DIR/tests/order_test.rs" <<'RUST'
use revi_fixture_app_rust::order::{summarize, Order};

#[test]
fn summarize_nil_customer() {
    let o = Order {
        customer: None,
        amount: 42,
    };
    assert_eq!(summarize(&o), "unknown customer owes 42");
}
RUST
    echo '{"confidence_note": "High confidence: matched on Option<Customer>", "summary": "Fixed unwrap-on-None panic in summarize", "test_framework": "cargo"}'
    ;;

  rust_fail_no_test)
    # Fixes the bug but never writes a tests/*_test.rs file -- must be
    # rejected regardless of cargo test/clippy passing, per PLAN's "AI
    # fails to write the L1/L2 test -> reject patch" rule.
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
RUST
    echo '{"confidence_note": "Fixed it", "summary": "Matched on Option", "test_framework": "cargo"}'
    ;;

  rust_fail_test_wrong_subdir)
    # Real fix + a real *_test.rs file -- but placed in src/, not tests/.
    # cargo test wouldn't even discover it there (it's not declared as a
    # module), and it's not the genuinely-separate-file convention TRD
    # names for Cargo. Proves the TEST_FILE_PREFIX check (PLAN 6.9 audit,
    # 2026-08-20) rejects a suffix-only match outside tests/, the same way
    # scenario G already proves for a test file outside manifest_dir
    # entirely.
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
RUST
    cat > "$APP_DIR/src/order_test.rs" <<'RUST'
// Never declared as a module -- cargo wouldn't compile or run this.
#[test]
fn summarize_nil_customer() {
    assert!(true);
}
RUST
    echo '{"confidence_note": "High confidence: matched on Option<Customer>", "summary": "Fixed unwrap-on-None panic in summarize", "test_framework": "cargo"}'
    ;;

  rust_fail_vacuous_test)
    # Real fix, real passing test -- but the test only exercises the
    # already-working "Some(Customer)" path, never the None case that was
    # actually broken. Passes every gate that predates the fails-before/
    # passes-after check, since it would pass identically against the
    # original unwrap-on-None summarize too.
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
RUST
    mkdir -p "$APP_DIR/tests"
    cat > "$APP_DIR/tests/order_test.rs" <<'RUST'
use revi_fixture_app_rust::order::{summarize, Customer, Order};

#[test]
fn summarize_with_customer() {
    let o = Order {
        customer: Some(Customer {
            name: "Bob".to_string(),
        }),
        amount: 42,
    };
    assert_eq!(summarize(&o), "Bob owes 42");
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

  node_fail_vacuous_test)
    # Real fix, real passing test -- but the test only exercises the
    # already-working "customer present" path, never the missing-customer
    # case that was actually broken. Passes every gate that predates the
    # fails-before/passes-after check, since it would pass identically
    # against the original unguarded summarize too.
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

test("summarize with customer", () => {
  expect(summarize({ customer: { name: "Bob" }, amount: 42 })).toBe("Bob owes 42");
});
JS
    echo '{"confidence_note": "High confidence: guarded on order.customer before dereferencing", "summary": "Fixed undefined property access in summarize", "test_framework": "jest"}'
    ;;

  python_succeed)
    # Real fix + a real sibling test (order_test.py -- pytest's *_test.py
    # discovery convention, matching order_test.go/order.test.js's suffix
    # shape rather than the test_*.py prefix, per PLAN 6.5's follow-up).
    cat > "$APP_DIR/order.py" <<'PY'
class Customer:
    def __init__(self, name):
        self.name = name


class Order:
    def __init__(self, customer=None, amount=0):
        self.customer = customer
        self.amount = amount


def summarize(order):
    if order.customer is None:
        return f"unknown customer owes {order.amount}"
    return f"{order.customer.name} owes {order.amount}"
PY
    cat > "$APP_DIR/order_test.py" <<'PY'
from order import Order, summarize


def test_summarize_nil_customer():
    got = summarize(Order(amount=42))
    assert got == "unknown customer owes 42"
PY
    echo '{"confidence_note": "High confidence: guarded on order.customer before dereferencing", "summary": "Fixed AttributeError on None customer in summarize", "test_framework": "pytest"}'
    ;;

  python_succeed_stray_file_first)
    # Same as python_succeed, but also touches a workspace-root file whose
    # name sorts alphabetically before the fixture dir -- reproduces the live
    # rehearsal failure (2026-08-19) where find_manifest_dir's old
    # first-changed-file heuristic walked from that stray file's directory
    # (the workspace root) instead of the fixture app, and never found
    # requirements.txt because the walk only goes up, not down into
    # subdirectories. Proves the FIXTURE_APP_DIR anchor fix resolves it.
    echo "unrelated scratch note" > "$GITHUB_WORKSPACE/AAA_scratch_notes.txt"
    cat > "$APP_DIR/order.py" <<'PY'
class Customer:
    def __init__(self, name):
        self.name = name


class Order:
    def __init__(self, customer=None, amount=0):
        self.customer = customer
        self.amount = amount


def summarize(order):
    if order.customer is None:
        return f"unknown customer owes {order.amount}"
    return f"{order.customer.name} owes {order.amount}"
PY
    cat > "$APP_DIR/order_test.py" <<'PY'
from order import Order, summarize


def test_summarize_nil_customer():
    got = summarize(Order(amount=42))
    assert got == "unknown customer owes 42"
PY
    echo '{"confidence_note": "High confidence: guarded on order.customer before dereferencing", "summary": "Fixed AttributeError on None customer in summarize", "test_framework": "pytest"}'
    ;;

  python_fail_broken_compile)
    # Test file written, but the "fix" does not even parse.
    cat > "$APP_DIR/order.py" <<'PY'
class Customer:
    def __init__(self, name):
        self.name = name


class Order:
    def __init__(self, customer=None, amount=0):
        self.customer = customer
        self.amount = amount


def summarize(order):
    return f"{order.customer.name} owes {order.amount extraTokenBreaksSyntax}"
PY
    cat > "$APP_DIR/order_test.py" <<'PY'
from order import Order, summarize


def test_summarize_nil_customer():
    summarize(Order(amount=42))
PY
    echo '{"confidence_note": "Fixed it", "summary": "Guarded on order.customer", "test_framework": "pytest"}'
    ;;

  python_fail_lint_violation)
    # Real fix, real passing test -- but an unrelated function compares to
    # None with `==` instead of `is` (ruff/flake8 E711, on by default).
    # Compiles (py_compile) and tests pass; only `ruff check` catches it --
    # isolates the lint gate from the build/test gates the other scenarios
    # already cover.
    cat > "$APP_DIR/order.py" <<'PY'
class Customer:
    def __init__(self, name):
        self.name = name


class Order:
    def __init__(self, customer=None, amount=0):
        self.customer = customer
        self.amount = amount


def summarize(order):
    if order.customer is None:
        return f"unknown customer owes {order.amount}"
    return f"{order.customer.name} owes {order.amount}"


def has_customer(order):
    return order.customer == None
PY
    cat > "$APP_DIR/order_test.py" <<'PY'
from order import Order, summarize


def test_summarize_nil_customer():
    got = summarize(Order(amount=42))
    assert got == "unknown customer owes 42"
PY
    echo '{"confidence_note": "High confidence: guarded on order.customer before dereferencing", "summary": "Fixed AttributeError on None customer in summarize", "test_framework": "pytest"}'
    ;;

  python_fail_vacuous_test)
    # Real fix, real passing test -- but the test only exercises the
    # already-working "customer present" path, never the None case that
    # was actually broken. Passes every gate that predates the
    # fails-before/passes-after check, since it would pass identically
    # against the original unguarded summarize too.
    cat > "$APP_DIR/order.py" <<'PY'
class Customer:
    def __init__(self, name):
        self.name = name


class Order:
    def __init__(self, customer=None, amount=0):
        self.customer = customer
        self.amount = amount


def summarize(order):
    if order.customer is None:
        return f"unknown customer owes {order.amount}"
    return f"{order.customer.name} owes {order.amount}"
PY
    cat > "$APP_DIR/order_test.py" <<'PY'
from order import Customer, Order, summarize


def test_summarize_with_customer():
    got = summarize(Order(customer=Customer("Bob"), amount=42))
    assert got == "Bob owes 42"
PY
    echo '{"confidence_note": "High confidence: guarded on order.customer before dereferencing", "summary": "Fixed AttributeError on None customer in summarize", "test_framework": "pytest"}'
    ;;

  python_fail_no_test)
    # Fixes the bug but never writes an order_test.py file -- must be
    # rejected regardless of py_compile/ruff/pytest passing, per PLAN's "AI
    # fails to write the L1/L2 test -> reject patch" rule.
    cat > "$APP_DIR/order.py" <<'PY'
class Customer:
    def __init__(self, name):
        self.name = name


class Order:
    def __init__(self, customer=None, amount=0):
        self.customer = customer
        self.amount = amount


def summarize(order):
    if order.customer is None:
        return f"unknown customer owes {order.amount}"
    return f"{order.customer.name} owes {order.amount}"
PY
    echo '{"confidence_note": "Fixed it", "summary": "Guarded on order.customer", "test_framework": "pytest"}'
    ;;

  malformed_json)
    echo 'Sure, I fixed the bug! Here is what I did: added a nil check.'
    ;;

  *)
    echo "fake-agent: unknown FAKE_AGENT_MODE '$MODE'" >&2
    exit 1
    ;;
esac
