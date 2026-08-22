package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHandleFormatOrderRejectsNegativeAmount ensures /format-order rejects
// negative amounts with 400 instead of echoing them back.
func TestHandleFormatOrderRejectsNegativeAmount(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/format-order?amount=-5", nil)
	rec := httptest.NewRecorder()

	handleFormatOrder(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for negative amount, got %d (body: %q)", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

// TestHandleFormatOrderAcceptsPositiveAmount ensures valid amounts are still
// accepted and echoed back correctly as JSON.
func TestHandleFormatOrderAcceptsPositiveAmount(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/format-order?amount=42", nil)
	rec := httptest.NewRecorder()

	handleFormatOrder(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d for positive amount, got %d (body: %q)", http.StatusOK, rec.Code, rec.Body.String())
	}

	var view orderView
	if err := json.Unmarshal(rec.Body.Bytes(), &view); err != nil {
		t.Fatalf("failed to decode JSON response: %v (body: %q)", err, rec.Body.String())
	}
	if view.Amount != 42 {
		t.Fatalf("expected amount 42, got %d", view.Amount)
	}
	if view.Currency != "USD" {
		t.Fatalf("expected currency USD, got %q", view.Currency)
	}
}

// TestHandleFormatOrderRejectsZeroBoundary ensures zero (a boundary value)
// is still accepted since it is not negative.
func TestHandleFormatOrderRejectsZeroBoundary(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/format-order?amount=0", nil)
	rec := httptest.NewRecorder()

	handleFormatOrder(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d for zero amount, got %d (body: %q)", http.StatusOK, rec.Code, rec.Body.String())
	}
}
