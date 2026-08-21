package main

import (
	"fmt"
	"net/http"
)

func main() {
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "ok")
	})
	http.HandleFunc("/summarize", func(w http.ResponseWriter, r *http.Request) {
		o := &Order{Amount: 42}
		fmt.Fprint(w, Summarize(o))
	})
	http.HandleFunc("/divide-share", handleDivideShare)
	http.HandleFunc("/discount", handleBulkDiscount)
	http.HandleFunc("/validate-order", handleValidateOrder)
	http.HandleFunc("/inventory", handleInventoryCheck)
	http.HandleFunc("/format-order", handleFormatOrder)
	http.HandleFunc("/items", handleCatalogItem)
	http.HandleFunc("/average", handleAverageOrderValue)
	http.ListenAndServe(":8080", nil)
}
