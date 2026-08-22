package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

// TestHandleValidateOrder_InvalidMaxOrderAmountFallsBackToDefault ensures that
// when MAX_ORDER_AMOUNT is set to an invalid (non-numeric) value, the handler
// falls back to the documented default (100000) instead of silently disabling
// ordering (which would happen if the invalid value parsed to 0 and rejected
// every order).
func TestHandleValidateOrder_InvalidMaxOrderAmountFallsBackToDefault(t *testing.T) {
	old, hadOld := os.LookupEnv("MAX_ORDER_AMOUNT")
	os.Setenv("MAX_ORDER_AMOUNT", "not-a-number")
	defer func() {
		if hadOld {
			os.Setenv("MAX_ORDER_AMOUNT", old)
		} else {
			os.Unsetenv("MAX_ORDER_AMOUNT")
		}
	}()

	req := httptest.NewRequest(http.MethodGet, "/validate-order?amount=500", nil)
	rec := httptest.NewRecorder()

	handleValidateOrder(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200 (order accepted under default max), got %d with body %q", rec.Code, rec.Body.String())
	}
	if rec.Body.String() != "accepted" {
		t.Fatalf("expected body %q, got %q", "accepted", rec.Body.String())
	}
}

// TestHandleValidateOrder_ValidMaxOrderAmountEnforced verifies a validly
// configured MAX_ORDER_AMOUNT is still respected.
func TestHandleValidateOrder_ValidMaxOrderAmountEnforced(t *testing.T) {
	old, hadOld := os.LookupEnv("MAX_ORDER_AMOUNT")
	os.Setenv("MAX_ORDER_AMOUNT", "1000")
	defer func() {
		if hadOld {
			os.Setenv("MAX_ORDER_AMOUNT", old)
		} else {
			os.Unsetenv("MAX_ORDER_AMOUNT")
		}
	}()

	req := httptest.NewRequest(http.MethodGet, "/validate-order?amount=5000", nil)
	rec := httptest.NewRecorder()

	handleValidateOrder(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400 (order rejected over configured max), got %d with body %q", rec.Code, rec.Body.String())
	}
}
