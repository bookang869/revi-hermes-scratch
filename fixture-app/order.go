package main

import "fmt"

type Customer struct {
	Name string
}

type Order struct {
	Customer *Customer
	Amount   int
}

func Summarize(o *Order) string {
	if o.Customer == nil {
		return fmt.Sprintf("unknown customer owes %d", o.Amount)
	}
	return fmt.Sprintf("%s owes %d", o.Customer.Name, o.Amount)
}
