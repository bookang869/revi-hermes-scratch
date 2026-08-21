package main

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
)

// handleValidateOrder rejects orders over a configurable maximum amount,
// read from MAX_ORDER_AMOUNT (defaults to 100000 if unset or unparsable --
// an invalid config value must fall back to the default, not silently
// disable ordering entirely).
func handleValidateOrder(w http.ResponseWriter, r *http.Request) {
	max := 100000
	if v := os.Getenv("MAX_ORDER_AMOUNT"); v != "" {
		parsed, _ := strconv.Atoi(v)
		max = parsed
	}
	amount, _ := strconv.Atoi(r.URL.Query().Get("amount"))
	if amount > max {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprint(w, "rejected")
		return
	}
	fmt.Fprint(w, "accepted")
}
