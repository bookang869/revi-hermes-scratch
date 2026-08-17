package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

// Summarize handles an Order with no Customer attached by falling back to
// a generic label instead of dereferencing a nil pointer. Previously this
// dereferenced o.Customer unconditionally, panicking with "invalid memory
// address or nil pointer dereference" whenever Customer was nil (the crash
// behind boom-1786940369048685000 in payment-processor).
func Summarize(o *Order) string {
	if o.Customer == nil {
		return fmt.Sprintf("unknown customer owes %d", o.Amount)
	}
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount)
}
