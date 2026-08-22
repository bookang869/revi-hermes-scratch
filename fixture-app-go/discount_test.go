package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHandleBulkDiscountExactlyTenUnits verifies that an order of exactly
// 10 units receives the 10% bulk discount, as documented in handleBulkDiscount.
func TestHandleBulkDiscountExactlyTenUnits(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/discount?unit_price=100&qty=10", nil)
	rec := httptest.NewRecorder()

	handleBulkDiscount(rec, req)

	got := rec.Body.String()
	want := "900"
	if got != want {
		t.Errorf("handleBulkDiscount(qty=10) = %q, want %q", got, want)
	}
}

func TestHandleBulkDiscountBelowTenUnits(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/discount?unit_price=100&qty=9", nil)
	rec := httptest.NewRecorder()

	handleBulkDiscount(rec, req)

	got := rec.Body.String()
	want := "900"
	if got != want {
		t.Errorf("handleBulkDiscount(qty=9) = %q, want %q", got, want)
	}
}
