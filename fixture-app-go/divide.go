package main

import (
	"fmt"
	"net/http"
	"strconv"
)

// handleDivideShare splits a shared total evenly across a number of
// participants, e.g. GET /divide-share?total=100&parts=4 -> 25. Rejects a
// zero (or negative) parts count with 400 instead of letting the division
// happen.
func handleDivideShare(w http.ResponseWriter, r *http.Request) {
	total, _ := strconv.Atoi(r.URL.Query().Get("total"))
	parts, _ := strconv.Atoi(r.URL.Query().Get("parts"))
	if parts <= 0 {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprint(w, "parts must be positive")
		return
	}
	fmt.Fprintf(w, "%d", total/parts)
}
