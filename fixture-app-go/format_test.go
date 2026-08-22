package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHandleFormatOrder_RejectsNegativeAmount(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/format-order?amount=-5", nil)
	rec := httptest.NewRecorder()

	handleFormatOrder(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d for negative amount, got %d (body: %s)", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

func TestHandleFormatOrder_AcceptsNonNegativeAmount(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/format-order?amount=42", nil)
	rec := httptest.NewRecorder()

	handleFormatOrder(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d for non-negative amount, got %d (body: %s)", http.StatusOK, rec.Code, rec.Body.String())
	}
}
