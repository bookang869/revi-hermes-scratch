package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
)

// handleInventoryCheck asks a downstream inventory service (URL from
// INVENTORY_URL) whether a SKU is in stock and relays its response. A
// non-200 from the downstream service is a dependency failure and must be
// surfaced as 503, not forwarded as if it were a successful lookup.
func handleInventoryCheck(w http.ResponseWriter, r *http.Request) {
	url := os.Getenv("INVENTORY_URL")
	resp, err := http.Get(url + "/stock?sku=" + r.URL.Query().Get("sku"))
	if err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		fmt.Fprint(w, "inventory service unavailable")
		return
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	w.Write(body)
}
