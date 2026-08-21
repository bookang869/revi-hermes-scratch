package main

import "testing"

func TestAverageOrderValue(t *testing.T) {
	got := AverageOrderValue([]int{10, 20, 30})
	want := 20
	if got != want {
		t.Fatalf("AverageOrderValue([10,20,30]) = %d, want %d", got, want)
	}
}

func TestAverageOrderValueEmpty(t *testing.T) {
	got := AverageOrderValue([]int{})
	want := 0
	if got != want {
		t.Fatalf("AverageOrderValue([]) = %d, want %d", got, want)
	}
}
