package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

// TestHandleValidateOrder_InvalidMaxOrderAmountFallsBackToDefault ensures that
// an invalid (non-numeric) MAX_ORDER_AMOUNT value falls back to the documented
// default of 100000 instead of silently disabling ordering (i.e. treating the
// max as 0 and rejecting every order).
func TestHandleValidateOrder_InvalidMaxOrderAmountFallsBackToDefault(t *testing.T) {
	orig, wasSet := os.LookupEnv("MAX_ORDER_AMOUNT")
	if wasSet {
		defer os.Setenv("MAX_ORDER_AMOUNT", orig)
	} else {
		defer os.Unsetenv("MAX_ORDER_AMOUNT")
	}

	if err := os.Setenv("MAX_ORDER_AMOUNT", "not-a-number"); err != nil {
		t.Fatalf("failed to set env var: %v", err)
	}

	req := httptest.NewRequest(http.MethodGet, "/validate-order?amount=500", nil)
	rec := httptest.NewRecorder()

	handleValidateOrder(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200 (accepted using default max), got %d with body %q", rec.Code, rec.Body.String())
	}
	if got := rec.Body.String(); got != "accepted" {
		t.Fatalf("expected body %q, got %q", "accepted", got)
	}
}

// TestHandleValidateOrder_ValidMaxOrderAmountIsRespected is a sanity check
// that a valid MAX_ORDER_AMOUNT still correctly rejects amounts over it.
func TestHandleValidateOrder_ValidMaxOrderAmountIsRespected(t *testing.T) {
	orig, wasSet := os.LookupEnv("MAX_ORDER_AMOUNT")
	if wasSet {
		defer os.Setenv("MAX_ORDER_AMOUNT", orig)
	} else {
		defer os.Unsetenv("MAX_ORDER_AMOUNT")
	}

	if err := os.Setenv("MAX_ORDER_AMOUNT", "100"); err != nil {
		t.Fatalf("failed to set env var: %v", err)
	}

	req := httptest.NewRequest(http.MethodGet, "/validate-order?amount=500", nil)
	rec := httptest.NewRecorder()

	handleValidateOrder(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400 (rejected, over valid max), got %d with body %q", rec.Code, rec.Body.String())
	}
}
