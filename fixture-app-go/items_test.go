package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHandleCatalogItem_OutOfRangeReturnsBadRequest(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/items?index=100", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for out-of-range index, got %d", http.StatusBadRequest, rec.Code)
	}
}

func TestHandleCatalogItem_NegativeIndexReturnsBadRequest(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/items?index=-1", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for negative index, got %d", http.StatusBadRequest, rec.Code)
	}
}

func TestHandleCatalogItem_ValidIndexReturnsItem(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/items?index=0", nil)
	rec := httptest.NewRecorder()

	handleCatalogItem(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d for valid index, got %d", http.StatusOK, rec.Code)
	}
	if body := rec.Body.String(); body != catalogItems[0] {
		t.Fatalf("expected body %q, got %q", catalogItems[0], body)
	}
}
