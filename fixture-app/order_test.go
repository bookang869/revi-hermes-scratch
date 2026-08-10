package main

import "testing"

func TestSummarize_NilCustomer(t *testing.T) {
	o := &Order{Amount: 42}
	got := Summarize(o)
	want := "unknown customer owes 42"
	if got != want {
		t.Fatalf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}

func TestSummarize_WithCustomer(t *testing.T) {
	o := &Order{Customer: &Customer{Name: "Alice"}, Amount: 10}
	got := Summarize(o)
	want := "Alice owes 10"
	if got != want {
		t.Fatalf("Summarize(%+v) = %q, want %q", o, got, want)
	}
}

func TestSummarize_NilOrder(t *testing.T) {
	got := Summarize(nil)
	want := "no order"
	if got != want {
		t.Fatalf("Summarize(nil) = %q, want %q", got, want)
	}
}
