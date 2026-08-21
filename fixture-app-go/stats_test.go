package main

import "testing"

func TestAverageOrderValue(t *testing.T) {
	if got := AverageOrderValue([]int{10, 20, 30}); got != 20 {
		t.Errorf("AverageOrderValue([10,20,30]) = %d, want 20", got)
	}
	if got := AverageOrderValue([]int{}); got != 0 {
		t.Errorf("AverageOrderValue([]) = %d, want 0", got)
	}
}
