package main

import (
	"strings"
	"testing"
)

func TestSummarizeWithNilCustomer(t *testing.T) {
	o := &Order{Amount: 42}
	got := Summarize(o)
	if !strings.Contains(got, "42") {
		t.Fatalf("expected summary to contain amount, got %q", got)
	}
}

func TestSummarizeWithCustomer(t *testing.T) {
	o := &Order{Customer: &Customer{Name: "Alice"}, Amount: 10}
	got := Summarize(o)
	want := "Alice owes 10"
	if got != want {
		t.Fatalf("got %q, want %q", got, want)
	}
}
