package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

// Summarize returns a human-readable summary of the order. It safely
// handles an Order with no Customer attached (or a nil Order) instead of
// panicking with a nil pointer dereference.
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
