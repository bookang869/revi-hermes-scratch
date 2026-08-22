package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

// TestHandleInventoryCheckForwardsDownstreamFailure ensures that a non-200
// response from the downstream inventory service is surfaced as a 503,
// not forwarded to the client as if it were a successful 200 lookup.
func TestHandleInventoryCheckForwardsDownstreamFailure(t *testing.T) {
	downstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("boom"))
	}))
	defer downstream.Close()

	oldURL := os.Getenv("INVENTORY_URL")
	os.Setenv("INVENTORY_URL", downstream.URL)
	defer os.Setenv("INVENTORY_URL", oldURL)

	req := httptest.NewRequest(http.MethodGet, "/inventory?sku=abc", nil)
	rec := httptest.NewRecorder()

	handleInventoryCheck(rec, req)

	res := rec.Result()
	if res.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("expected status %d when downstream fails, got %d", http.StatusServiceUnavailable, res.StatusCode)
	}
}

// TestHandleInventoryCheckForwardsDownstreamSuccess ensures a healthy 200
// response from the downstream service is still relayed as-is.
func TestHandleInventoryCheckForwardsDownstreamSuccess(t *testing.T) {
	downstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"sku":"abc","in_stock":true}`))
	}))
	defer downstream.Close()

	oldURL := os.Getenv("INVENTORY_URL")
	os.Setenv("INVENTORY_URL", downstream.URL)
	defer os.Setenv("INVENTORY_URL", oldURL)

	req := httptest.NewRequest(http.MethodGet, "/inventory?sku=abc", nil)
	rec := httptest.NewRecorder()

	handleInventoryCheck(rec, req)

	res := rec.Result()
	if res.StatusCode != http.StatusOK {
		t.Fatalf("expected status %d on downstream success, got %d", http.StatusOK, res.StatusCode)
	}
}
