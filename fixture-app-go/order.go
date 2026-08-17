package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

// Summarize used to dereference o.Customer without checking for nil, so an
// Order with no Customer attached panicked with "invalid memory address or
// nil pointer dereference" -- this was the seeded bug used to test the
// Phase 3.5 repair loop end-to-end (trace_id abc, service payment-processor,
// error_summary "boom"). Fixed by falling back to a generic label when no
// Customer is attached.
func Summarize(o *Order) string {
	if o.Customer == nil {
		return fmt.Sprintf("unknown customer owes %d", o.Amount)
	}
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount)
}
