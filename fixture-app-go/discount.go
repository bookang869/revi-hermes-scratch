package main

import (
	"fmt"
	"net/http"
	"strconv"
)

// handleBulkDiscount applies a 10% discount to orders of 10 or more units.
// GET /discount?unit_price=100&qty=10 -> 900 (10x100, 10% off).
func handleBulkDiscount(w http.ResponseWriter, r *http.Request) {
	unitPrice, _ := strconv.Atoi(r.URL.Query().Get("unit_price"))
	qty, _ := strconv.Atoi(r.URL.Query().Get("qty"))
	total := unitPrice * qty
	if qty > 10 {
		total = total * 90 / 100
	}
	fmt.Fprintf(w, "%d", total)
}
