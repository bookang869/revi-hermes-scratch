package main

import "testing"

// TestAverageOrderValue fails before the fix (stats.go fails to compile due
// to the undefined identifier 'order') and passes after the fix, verifying
// AverageOrderValue computes the correct mean and handles the empty case.
func TestAverageOrderValue(t *testing.T) {
	if got := AverageOrderValue([]int{10, 20, 30}); got != 20 {
		t.Errorf("AverageOrderValue([10,20,30]) = %d, want 20", got)
	}

	if got := AverageOrderValue([]int{}); got != 0 {
		t.Errorf("AverageOrderValue([]) = %d, want 0", got)
	}

	if got := AverageOrderValue([]int{5}); got != 5 {
		t.Errorf("AverageOrderValue([5]) = %d, want 5", got)
	}
}
