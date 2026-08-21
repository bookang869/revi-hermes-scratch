package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHandleCatalogItemOutOfRange verifies that requesting an out-of-range
// index returns a 400 Bad Request instead of panicking the process with an
// index out of range error.
func TestHandleCatalogItemOutOfRange(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/items?index=99", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for out-of-range index, got %d", http.StatusBadRequest, rec.Code)
	}
}

// TestHandleCatalogItemNegativeIndex verifies negative indices are also
// rejected instead of causing a runtime panic.
func TestHandleCatalogItemNegativeIndex(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/items?index=-1", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for negative index, got %d", http.StatusBadRequest, rec.Code)
	}
}

// TestHandleCatalogItemValidIndex verifies a valid index still returns the
// expected catalog item.
func TestHandleCatalogItemValidIndex(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/items?index=0", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d for valid index, got %d", http.StatusOK, rec.Code)
	}
	if rec.Body.String() != catalogItems[0] {
		t.Fatalf("expected body %q, got %q", catalogItems[0], rec.Body.String())
	}
}
