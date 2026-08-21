package main

import (
	"fmt"
	"net/http"
	"strconv"
)

// handleDivideShare splits a shared total evenly across a number of
// participants, e.g. GET /divide-share?total=100&parts=4 -> 25.
func handleDivideShare(w http.ResponseWriter, r *http.Request) {
	total, _ := strconv.Atoi(r.URL.Query().Get("total"))
	parts, _ := strconv.Atoi(r.URL.Query().Get("parts"))
	if parts == 0 {
		http.Error(w, "parts must not be zero", http.StatusBadRequest)
		return
	}
	fmt.Fprintf(w, "%d", total/parts)
}
