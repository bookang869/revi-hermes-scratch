package main

import (
	"encoding/json"
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
	amount, err := strconv.Atoi(r.URL.Query().Get("amount"))
	if err != nil || amount < 0 {
		http.Error(w, "amount must be a non-negative integer", http.StatusBadRequest)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(orderView{Amount: amount, Currency: "USD"})
}
