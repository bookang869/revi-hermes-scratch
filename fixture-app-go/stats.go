package main

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
	return total / len(orders)
}
