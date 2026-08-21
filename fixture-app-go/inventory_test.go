package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
)

func TestHandleInventoryCheck_NonOKDownstreamIsSurfacedAs503(t *testing.T) {
	downstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"in_stock": true}`))
	}))
	defer downstream.Close()

	oldURL := os.Getenv("INVENTORY_URL")
	os.Setenv("INVENTORY_URL", downstream.URL)
	defer os.Setenv("INVENTORY_URL", oldURL)

	req := httptest.NewRequest(http.MethodGet, "/inventory?sku=abc123", nil)
	rec := httptest.NewRecorder()

	handleInventoryCheck(rec, req)

	res := rec.Result()
	if res.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("expected status %d for non-200 downstream response, got %d", http.StatusServiceUnavailable, res.StatusCode)
	}

	body := rec.Body.String()
	if strings.Contains(body, "in_stock") {
		t.Fatalf("downstream error body should not be forwarded as a successful lookup, got body: %q", body)
	}
}

func TestHandleInventoryCheck_OKDownstreamIsForwarded(t *testing.T) {
	downstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"in_stock": true}`))
	}))
	defer downstream.Close()

	oldURL := os.Getenv("INVENTORY_URL")
	os.Setenv("INVENTORY_URL", downstream.URL)
	defer os.Setenv("INVENTORY_URL", oldURL)

	req := httptest.NewRequest(http.MethodGet, "/inventory?sku=abc123", nil)
	rec := httptest.NewRecorder()

	handleInventoryCheck(rec, req)

	res := rec.Result()
	if res.StatusCode != http.StatusOK {
		t.Fatalf("expected status %d for 200 downstream response, got %d", http.StatusOK, res.StatusCode)
	}

	body := rec.Body.String()
	if !strings.Contains(body, "in_stock") {
		t.Fatalf("expected successful downstream body to be forwarded, got body: %q", body)
	}
}
