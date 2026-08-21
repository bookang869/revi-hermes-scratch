package main

import (
	"fmt"
	"net/http"
)

// handleAverageOrderValue exposes AverageOrderValue over HTTP against a
// fixed sample so it's independently checkable, not just something Hermes
// could satisfy by deleting the broken function.
func handleAverageOrderValue(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "%d", AverageOrderValue([]int{10, 20, 30}))
}

// AverageOrderValue returns the mean of a set of order amounts, or 0 for an
// empty slice (avoids a divide-by-zero rather than panicking on no data).
func AverageOrderValue(orders []int) int {
	if len(orders) == 0 {
		return 0
	}
	total := 0
	for _, o := range orders {
		total += o
	}
	return total / len(order)
}
