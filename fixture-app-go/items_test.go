package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHandleCatalogItem_OutOfRangeIndex(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/items?index=99", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for out-of-range index, got %d", http.StatusBadRequest, rec.Code)
	}
}

func TestHandleCatalogItem_NegativeIndex(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/items?index=-1", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for negative index, got %d", http.StatusBadRequest, rec.Code)
	}
}

func TestHandleCatalogItem_ValidIndex(t *testing.T) {
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
