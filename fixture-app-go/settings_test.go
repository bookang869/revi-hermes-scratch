package main

import (
	"net/http/httptest"
	"os"
	"testing"
)

// TestHandleValidateOrder_InvalidMaxOrderAmountFallsBackToDefault ensures that
// when MAX_ORDER_AMOUNT is set to an unparsable value, the handler falls back
// to the documented default (100000) instead of silently disabling ordering
// (which happens if the invalid value is treated as 0).
func TestHandleValidateOrder_InvalidMaxOrderAmountFallsBackToDefault(t *testing.T) {
	oldVal, wasSet := os.LookupEnv("MAX_ORDER_AMOUNT")
	if err := os.Setenv("MAX_ORDER_AMOUNT", "not-a-number"); err != nil {
		t.Fatalf("failed to set MAX_ORDER_AMOUNT: %v", err)
	}
	defer func() {
		if wasSet {
			os.Setenv("MAX_ORDER_AMOUNT", oldVal)
		} else {
			os.Unsetenv("MAX_ORDER_AMOUNT")
		}
	}()

	req := httptest.NewRequest("GET", "/validate-order?amount=500", nil)
	rec := httptest.NewRecorder()

	handleValidateOrder(rec, req)

	if rec.Code != 200 {
		t.Fatalf("expected order within default max to be accepted (status 200), got status %d with body %q", rec.Code, rec.Body.String())
	}
	if got := rec.Body.String(); got != "accepted" {
		t.Fatalf("expected body %q, got %q", "accepted", got)
	}
}

// TestHandleValidateOrder_ValidMaxOrderAmountIsRespected is a sanity check
// that a valid MAX_ORDER_AMOUNT still correctly rejects amounts over it.
func TestHandleValidateOrder_ValidMaxOrderAmountIsRespected(t *testing.T) {
	oldVal, wasSet := os.LookupEnv("MAX_ORDER_AMOUNT")
	if err := os.Setenv("MAX_ORDER_AMOUNT", "1000"); err != nil {
		t.Fatalf("failed to set MAX_ORDER_AMOUNT: %v", err)
	}
	defer func() {
		if wasSet {
			os.Setenv("MAX_ORDER_AMOUNT", oldVal)
		} else {
			os.Unsetenv("MAX_ORDER_AMOUNT")
		}
	}()

	req := httptest.NewRequest("GET", "/validate-order?amount=5000", nil)
	rec := httptest.NewRecorder()

	handleValidateOrder(rec, req)

	if rec.Code != 400 {
		t.Fatalf("expected amount over configured max to be rejected (status 400), got status %d with body %q", rec.Code, rec.Body.String())
	}
}
