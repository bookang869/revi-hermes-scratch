package main

import "testing"

// TestSummarizeNilCustomer verifies that Summarize does not panic when the
// Order has no Customer attached. Before the fix, this test crashed the
// process with "invalid memory address or nil pointer dereference".
func TestSummarizeNilCustomer(t *testing.T) {
	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("Summarize panicked on nil Customer: %v", r)
		}
	}()

	o := &Order{Amount: 42}
	got := Summarize(o)
	want := "unknown customer owes 42"
	if got != want {
		t.Errorf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}

// TestSummarizeWithCustomer ensures the normal (non-nil) path still works.
func TestSummarizeWithCustomer(t *testing.T) {
	o := &Order{Customer: &Customer{Name: "Alice"}, Amount: 10}
	got := Summarize(o)
	want := "Alice owes 10"
	if got != want {
		t.Errorf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}
