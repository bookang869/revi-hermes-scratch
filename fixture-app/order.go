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
// against a nil Customer so an Order with no Customer attached no longer
// panics with "invalid memory address or nil pointer dereference".
func Summarize(o *Order) string {
	name := "unknown customer"
	if o.Customer != nil {
		name = o.Customer.Name
	}
	return fmt.Sprintf("%s owes %d", name, o.Amount)
}
