package main

import "testing"

// TestSummarize_NilCustomer reproduces the crash from trace_id abc
// (service payment-processor, error_summary "boom"): Summarize used to
// dereference o.Customer without a nil check, panicking with "invalid
// memory address or nil pointer dereference" whenever an Order had no
// Customer attached. This test fails before the fix (panic) and passes
// after it.
func TestSummarize_NilCustomer(t *testing.T) {
	got := Summarize(&Order{Amount: 42})
	want := "unknown customer owes 42"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}

// TestSummarize_WithCustomer guards the existing non-nil behavior so the
// fix doesn't regress the normal path.
func TestSummarize_WithCustomer(t *testing.T) {
	got := Summarize(&Order{Customer: &Customer{Name: "Ada"}, Amount: 10})
	want := "Ada owes 10"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}
