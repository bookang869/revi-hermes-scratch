package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHandleBulkDiscountExactlyTenUnits ensures that an order of exactly 10
// units receives the 10% bulk discount, matching the documented behavior in
// handleBulkDiscount's comment: "applies a 10% discount to orders of 10 or
// more units".
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

// TestHandleBulkDiscountAboveTenUnits keeps coverage of the existing
// above-threshold behavior to guard against regressions.
func TestHandleBulkDiscountAboveTenUnits(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/discount?unit_price=100&qty=20", nil)
	rec := httptest.NewRecorder()

	handleBulkDiscount(rec, req)

	got := rec.Body.String()
	want := "1800"
	if got != want {
		t.Errorf("handleBulkDiscount(qty=20) = %q, want %q", got, want)
	}
}

// TestHandleBulkDiscountBelowTenUnits ensures no discount is applied below
// the threshold.
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
