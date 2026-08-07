package main

import "testing"

func TestSummarizeNilCustomer(t *testing.T) {
	o := &Order{Amount: 42}

	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("Summarize panicked on nil Customer: %v", r)
		}
	}()

	got := Summarize(o)
	want := "unknown customer owes 42"
	if got != want {
		t.Errorf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}

func TestSummarizeWithCustomer(t *testing.T) {
	o := &Order{Customer: &Customer{Name: "Alice"}, Amount: 10}

	got := Summarize(o)
	want := "Alice owes 10"
	if got != want {
		t.Errorf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}
