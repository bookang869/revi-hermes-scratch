package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

// TestHandleValidateOrder_InvalidMaxOrderAmountFallsBackToDefault ensures that
// when MAX_ORDER_AMOUNT is set to an unparsable value, the handler falls back
// to the documented default (100000) instead of silently disabling ordering
// (which happens if max collapses to 0, rejecting every order).
func TestHandleValidateOrder_InvalidMaxOrderAmountFallsBackToDefault(t *testing.T) {
	os.Setenv("MAX_ORDER_AMOUNT", "not-a-number")
	defer os.Unsetenv("MAX_ORDER_AMOUNT")

	req := httptest.NewRequest(http.MethodGet, "/validate?amount=500", nil)
	rec := httptest.NewRecorder()

	handleValidateOrder(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected order within default max to be accepted (status 200), got %d with body %q", rec.Code, rec.Body.String())
	}
	if rec.Body.String() != "accepted" {
		t.Fatalf("expected body 'accepted', got %q", rec.Body.String())
	}
}

// TestHandleValidateOrder_ValidMaxOrderAmountIsRespected checks that a valid
// override of MAX_ORDER_AMOUNT is still honored.
func TestHandleValidateOrder_ValidMaxOrderAmountIsRespected(t *testing.T) {
	os.Setenv("MAX_ORDER_AMOUNT", "10")
	defer os.Unsetenv("MAX_ORDER_AMOUNT")

	req := httptest.NewRequest(http.MethodGet, "/validate?amount=500", nil)
	rec := httptest.NewRecorder()

	handleValidateOrder(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected order over configured max to be rejected (status 400), got %d with body %q", rec.Code, rec.Body.String())
	}
}
