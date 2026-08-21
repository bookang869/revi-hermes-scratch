package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
)

// TestHandleInventoryCheck_NonOKDownstream verifies that when the downstream
// inventory service responds with a non-200 status, handleInventoryCheck
// surfaces a 503 to the caller instead of forwarding the downstream body as
// if it were a successful 200 lookup.
func TestHandleInventoryCheck_NonOKDownstream(t *testing.T) {
	downstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"error":"downstream exploded"}`))
	}))
	defer downstream.Close()

	origURL := os.Getenv("INVENTORY_URL")
	os.Setenv("INVENTORY_URL", downstream.URL)
	defer os.Setenv("INVENTORY_URL", origURL)

	req := httptest.NewRequest(http.MethodGet, "/inventory?sku=abc123", nil)
	rec := httptest.NewRecorder()

	handleInventoryCheck(rec, req)

	res := rec.Result()
	if res.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("expected status %d when downstream fails, got %d (body: %s)",
			http.StatusServiceUnavailable, res.StatusCode, rec.Body.String())
	}

	if strings.Contains(rec.Body.String(), "downstream exploded") {
		t.Fatalf("downstream error body must not be forwarded as-is, got: %s", rec.Body.String())
	}
}

// TestHandleInventoryCheck_OKDownstream verifies the happy path still works:
// a 200 from downstream is relayed as a 200 with the body intact.
func TestHandleInventoryCheck_OKDownstream(t *testing.T) {
	downstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"sku":"abc123","in_stock":true}`))
	}))
	defer downstream.Close()

	origURL := os.Getenv("INVENTORY_URL")
	os.Setenv("INVENTORY_URL", downstream.URL)
	defer os.Setenv("INVENTORY_URL", origURL)

	req := httptest.NewRequest(http.MethodGet, "/inventory?sku=abc123", nil)
	rec := httptest.NewRecorder()

	handleInventoryCheck(rec, req)

	res := rec.Result()
	if res.StatusCode != http.StatusOK {
		t.Fatalf("expected status %d for successful downstream lookup, got %d", http.StatusOK, res.StatusCode)
	}
	if !strings.Contains(rec.Body.String(), "in_stock") {
		t.Fatalf("expected body to contain downstream payload, got: %s", rec.Body.String())
	}
}
