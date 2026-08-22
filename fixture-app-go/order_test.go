package main

import "testing"

// TestSummarizeNilCustomer verifies that Summarize does not panic when the
// Order has no Customer attached. Before the fix, this caused:
// "panic: runtime error: invalid memory address or nil pointer dereference".
func TestSummarizeNilCustomer(t *testing.T) {
	o := &Order{Amount: 42}

	got := Summarize(o)

	want := "unknown customer owes 42"
	if got != want {
		t.Fatalf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}

// TestSummarizeNilOrder verifies that Summarize does not panic when passed
// a nil *Order.
func TestSummarizeNilOrder(t *testing.T) {
	got := Summarize(nil)

	want := "no order"
	if got != want {
		t.Fatalf("Summarize(nil) = %q, want %q", got, want)
	}
}

// TestSummarizeWithCustomer verifies existing behavior still works when a
// Customer is present.
func TestSummarizeWithCustomer(t *testing.T) {
	o := &Order{Customer: &Customer{Name: "Alice"}, Amount: 10}

	got := Summarize(o)

	want := "Alice owes 10"
	if got != want {
		t.Fatalf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}
