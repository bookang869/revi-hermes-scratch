package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

// Summarize is deliberately buggy: it dereferences o.Customer without
// checking for nil, so an Order with no Customer attached panics with
// "invalid memory address or nil pointer dereference" -- this is the seeded
// bug used to test the Phase 3.5 repair loop end-to-end.
func Summarize(o *Order) string {
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount)
}
