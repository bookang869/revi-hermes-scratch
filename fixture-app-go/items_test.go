package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHandleCatalogItem_OutOfRangeReturnsBadRequest(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/catalog-item?index=99", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for out-of-range index, got %d", http.StatusBadRequest, rec.Code)
	}
}

func TestHandleCatalogItem_NegativeIndexReturnsBadRequest(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/catalog-item?index=-1", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for negative index, got %d", http.StatusBadRequest, rec.Code)
	}
}

func TestHandleCatalogItem_ValidIndexReturnsItem(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/catalog-item?index=0", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d for valid index, got %d", http.StatusOK, rec.Code)
	}
	if got, want := rec.Body.String(), catalogItems[0]; got != want {
		t.Fatalf("expected body %q, got %q", want, got)
	}
}
