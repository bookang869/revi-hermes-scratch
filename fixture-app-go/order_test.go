package main

import "testing"

// Regression test for the seeded nil-pointer-dereference bug: Summarize
// used to panic when o.Customer was nil. This must not panic, and should
// fall back to "Unknown customer".
func TestSummarizeNilCustomer(t *testing.T) {
	o := &Order{Amount: 42}

	got := Summarize(o)

	want := "Unknown customer owes 42"
	if got != want {
		t.Fatalf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}

// Baseline happy-path test: Summarize still works normally when a Customer
// is attached.
func TestSummarizeWithCustomer(t *testing.T) {
	o := &Order{Customer: &Customer{Name: "Alice"}, Amount: 10}

	got := Summarize(o)

	want := "Alice owes 10"
	if got != want {
		t.Fatalf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}
