package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

// TestHandleInventoryCheck_NonOKDownstreamIsSurfacedAs503 verifies that when
// the downstream inventory service responds with a non-200 status, the
// handler surfaces a 503 dependency failure instead of forwarding the
// downstream response body/status as if it were a successful lookup.
func TestHandleInventoryCheck_NonOKDownstreamIsSurfacedAs503(t *testing.T) {
	downstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"in_stock": true}`))
	}))
	defer downstream.Close()

	oldURL := os.Getenv("INVENTORY_URL")
	os.Setenv("INVENTORY_URL", downstream.URL)
	defer os.Setenv("INVENTORY_URL", oldURL)

	req := httptest.NewRequest(http.MethodGet, "/inventory?sku=ABC123", nil)
	rr := httptest.NewRecorder()

	handleInventoryCheck(rr, req)

	if rr.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected status %d for a non-200 downstream response, got %d (body=%q)",
			http.StatusServiceUnavailable, rr.Code, rr.Body.String())
	}
}

// TestHandleInventoryCheck_OKDownstreamIsForwarded verifies the happy path
// still works: a 200 from downstream is relayed as a 200 with its body.
func TestHandleInventoryCheck_OKDownstreamIsForwarded(t *testing.T) {
	downstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"in_stock": true}`))
	}))
	defer downstream.Close()

	oldURL := os.Getenv("INVENTORY_URL")
	os.Setenv("INVENTORY_URL", downstream.URL)
	defer os.Setenv("INVENTORY_URL", oldURL)

	req := httptest.NewRequest(http.MethodGet, "/inventory?sku=ABC123", nil)
	rr := httptest.NewRecorder()

	handleInventoryCheck(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, rr.Code)
	}
	if rr.Body.String() != `{"in_stock": true}` {
		t.Fatalf("expected body to be forwarded unchanged, got %q", rr.Body.String())
	}
}
