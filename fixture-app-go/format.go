package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
)

type orderView struct {
	Amount   int    `json:"amount"`
	Currency string `json:"currency"`
}

// handleFormatOrder returns a JSON view of an order's amount, rejecting
// negative amounts with 400 rather than echoing back a nonsensical order.
func handleFormatOrder(w http.ResponseWriter, r *http.Request) {
	amount, _ := strconv.Atoi(r.URL.Query().Get("amount"))
	if amount < 0 {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprint(w, "amount must not be negative")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(orderView{Amount: amount, Currency: "USD"})
}
