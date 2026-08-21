package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// TestHandleDivideShareZeroParts ensures that calling /divide-share with
// parts=0 does not panic with a divide-by-zero runtime error, and instead
// returns a well-formed HTTP error response.
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
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}

	body := rec.Body.String()
	if !strings.Contains(body, "parts must not be zero") {
		t.Fatalf("expected error message about zero parts, got %q", body)
	}
}

// TestHandleDivideShareNormal ensures normal division still works.
func TestHandleDivideShareNormal(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/divide-share?total=100&parts=4", nil)
	rec := httptest.NewRecorder()

	handleDivideShare(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, rec.Code)
	}

	body := rec.Body.String()
	if body != "25" {
		t.Fatalf("expected body %q, got %q", "25", body)
	}
}
