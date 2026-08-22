package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHandleDivideShareZeroParts ensures that requesting a divide-share
// with parts=0 does not panic with a divide-by-zero runtime error and
// instead responds with a client error.
func TestHandleDivideShareZeroParts(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/divide-share?total=100&parts=0", nil)
	rec := httptest.NewRecorder()

	handleDivideShare(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d (body: %q)", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

// TestHandleDivideShareNormal verifies the happy path still computes the
// correct integer division result.
func TestHandleDivideShareNormal(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/divide-share?total=100&parts=4", nil)
	rec := httptest.NewRecorder()

	handleDivideShare(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, rec.Code)
	}
	if got, want := rec.Body.String(), "25"; got != want {
		t.Fatalf("expected body %q, got %q", want, got)
	}
}
