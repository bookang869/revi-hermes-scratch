package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHandleDivideShareZeroParts ensures a zero "parts" query parameter does
// not cause a divide-by-zero panic and instead returns a 400 error.
func TestHandleDivideShareZeroParts(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/divide-share?total=100&parts=0", nil)
	rec := httptest.NewRecorder()

	handleDivideShare(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
}

// TestHandleDivideShareNormal ensures normal division still works correctly.
func TestHandleDivideShareNormal(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/divide-share?total=100&parts=4", nil)
	rec := httptest.NewRecorder()

	handleDivideShare(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, rec.Code)
	}
	if body := rec.Body.String(); body != "25" {
		t.Fatalf("expected body %q, got %q", "25", body)
	}
}
