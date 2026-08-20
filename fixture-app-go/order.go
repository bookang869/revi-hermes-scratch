package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

// Summarize previously dereferenced o.Customer without checking for nil, so
// an Order with no Customer attached panicked with "invalid memory address
// or nil pointer dereference". Fixed to fall back to "Unknown customer"
// when o.Customer is nil.
func Summarize(o *Order) string {
	name := "Unknown customer"
	if o.Customer != nil {
		name = o.Customer.Name
	}
	return fmt.Sprintf("%s owes %d", name, o.Amount)
}
