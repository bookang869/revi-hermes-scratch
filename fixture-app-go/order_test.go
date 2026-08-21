package main

import "testing"

// TestSummarizeNilCustomer verifies that Summarize does not panic when the
// Order has no Customer attached. Before the fix, this panicked with
// "invalid memory address or nil pointer dereference" because Summarize
// dereferenced o.Customer.Name without a nil check.
func TestSummarizeNilCustomer(t *testing.T) {
	o := &Order{Amount: 42}

	got := Summarize(o)

	want := "unknown customer owes 42"
	if got != want {
		t.Fatalf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}

// TestSummarizeWithCustomer ensures the normal (non-nil Customer) path still
// works correctly.
func TestSummarizeWithCustomer(t *testing.T) {
	o := &Order{Customer: &Customer{Name: "Alice"}, Amount: 10}

	got := Summarize(o)

	want := "Alice owes 10"
	if got != want {
		t.Fatalf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}

// TestSummarizeNilOrder ensures a nil *Order also does not panic.
func TestSummarizeNilOrder(t *testing.T) {
	got := Summarize(nil)

	want := "no order"
	if got != want {
		t.Fatalf("Summarize(nil) = %q, want %q", got, want)
	}
}
