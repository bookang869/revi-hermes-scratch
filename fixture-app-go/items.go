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
	idx, _ := strconv.Atoi(r.URL.Query().Get("index"))
	if idx < 0 || idx >= len(catalogItems) {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprint(w, "index out of range")
		return
	}
	fmt.Fprint(w, catalogItems[idx])
}
