package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHandleBulkDiscountAppliesAtExactlyTenUnits ensures the 10% bulk
// discount is applied for orders of exactly 10 units, not just orders
// strictly greater than 10.
func TestHandleBulkDiscountAppliesAtExactlyTenUnits(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/discount?unit_price=100&qty=10", nil)
	w := httptest.NewRecorder()

	handleBulkDiscount(w, req)

	got := w.Body.String()
	want := "900"
	if got != want {
		t.Errorf("handleBulkDiscount(unit_price=100, qty=10) = %q, want %q", got, want)
	}
}

func TestHandleBulkDiscountNoDiscountUnderTen(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/discount?unit_price=50&qty=9", nil)
	w := httptest.NewRecorder()

	handleBulkDiscount(w, req)

	got := w.Body.String()
	want := "450"
	if got != want {
		t.Errorf("handleBulkDiscount(unit_price=50, qty=9) = %q, want %q", got, want)
	}
}
