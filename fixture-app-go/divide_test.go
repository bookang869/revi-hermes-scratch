package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHandleDivideShareZeroParts ensures a request with parts=0 does not
// panic with a divide-by-zero runtime error and instead returns a proper
// HTTP error response.
func TestHandleDivideShareZeroParts(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/divide-share?total=100&parts=0", nil)
	rec := httptest.NewRecorder()

	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("handleDivideShare panicked: %v", r)
		}
	}()

	handleDivideShare(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for parts=0, got %d", http.StatusBadRequest, rec.Code)
	}
}

// TestHandleDivideShareValid ensures normal division still works correctly.
func TestHandleDivideShareValid(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/divide-share?total=100&parts=4", nil)
	rec := httptest.NewRecorder()

	handleDivideShare(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, rec.Code)
	}

	got := rec.Body.String()
	want := "25"
	if got != want {
		t.Fatalf("expected body %q, got %q", want, got)
	}
}
