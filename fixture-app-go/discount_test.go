package main

import (
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
)

// TestHandleBulkDiscountExactlyTen verifies that an order of exactly 10 units
// receives the 10% bulk discount, as documented in handleBulkDiscount.
func TestHandleBulkDiscountExactlyTen(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/discount?unit_price=100&qty=10", nil)
	rec := httptest.NewRecorder()

	handleBulkDiscount(rec, req)

	resp := rec.Body.String()
	got, err := strconv.Atoi(resp)
	if err != nil {
		t.Fatalf("unexpected response body %q: %v", resp, err)
	}

	want := 900 // 10 * 100 = 1000, minus 10% = 900
	if got != want {
		t.Errorf("handleBulkDiscount(unit_price=100, qty=10) = %d, want %d", got, want)
	}
}

// TestHandleBulkDiscountBelowTen verifies that orders below the threshold
// are not discounted.
func TestHandleBulkDiscountBelowTen(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/discount?unit_price=100&qty=9", nil)
	rec := httptest.NewRecorder()

	handleBulkDiscount(rec, req)

	resp := rec.Body.String()
	got, err := strconv.Atoi(resp)
	if err != nil {
		t.Fatalf("unexpected response body %q: %v", resp, err)
	}

	want := 900 // 9 * 100 = 900, no discount applied
	if got != want {
		t.Errorf("handleBulkDiscount(unit_price=100, qty=9) = %d, want %d", got, want)
	}
}
