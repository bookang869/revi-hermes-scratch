package main

import "testing"

func TestSummarize_NilCustomer(t *testing.T) {
	got := Summarize(&Order{Amount: 42})
	want := "unknown customer owes 42"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}

func TestSummarize_WithCustomer(t *testing.T) {
	got := Summarize(&Order{Customer: &Customer{Name: "Alice"}, Amount: 10})
	want := "Alice owes 10"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}
