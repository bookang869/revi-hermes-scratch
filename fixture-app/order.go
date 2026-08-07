package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

// Summarize returns a human-readable summary of the order. It guards
// against a nil Customer (and a nil Order) so callers don't crash with a
// nil pointer dereference when an order has no customer attached.
func Summarize(o *Order) string {
	if o == nil {
		return "no order"
	}
	name := "unknown customer"
	if o.Customer != nil {
		name = o.Customer.Name
	}
	return fmt.Sprintf("%s owes %d", name, o.Amount)
}
