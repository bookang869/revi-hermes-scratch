package main

import (
	"fmt"
	"net/http"
	"strconv"
)

var catalogItems = []string{"widget", "gadget", "gizmo"}

// handleCatalogItem returns the catalog item at the requested index, or
// 400 if the index is out of range.
func handleCatalogItem(w http.ResponseWriter, r *http.Request) {
	idx, err := strconv.Atoi(r.URL.Query().Get("index"))
	if err != nil || idx < 0 || idx >= len(catalogItems) {
		http.Error(w, "index out of range", http.StatusBadRequest)
		return
	}
	fmt.Fprint(w, catalogItems[idx])
}
