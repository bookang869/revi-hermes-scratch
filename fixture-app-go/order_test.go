package main

import "testing"

func TestSummarize_NilCustomer(t *testing.T) {
	got := Summarize(&Order{Amount: 42})
	want := "unknown customer owes 42"
	if got != want {
		t.Errorf("Summarize() = %q, want %q", got, want)
	}
}
