pub struct Customer {
    pub name: String,
}

pub struct Order {
    pub customer: Option<Customer>,
    pub amount: i64,
}

// summarize is deliberately buggy: it unwraps o.customer without checking
// for None, so an Order with no Customer attached panics -- this is the
// seeded bug used to test the repair loop end-to-end (mirrors the Go
// fixture app's fixture-app/order.go).
pub fn summarize(o: &Order) -> String {
    format!("{} owes {}", o.customer.as_ref().unwrap().name, o.amount)
}
