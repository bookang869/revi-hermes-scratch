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
// against a nil Customer (or a nil Order itself) instead of dereferencing
// it directly, which previously caused a
// "invalid memory address or nil pointer dereference" panic.
func Summarize(o *Order) string {
	if o == nil {
		return "unknown customer owes 0"
	}
	name := "unknown customer"
	if o.Customer != nil {
		name = o.Customer.Name
	}
	return fmt.Sprintf("%s owes %d", name, o.Amount)
}
