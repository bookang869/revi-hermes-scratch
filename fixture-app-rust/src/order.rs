use std::collections::HashMap;

pub struct Customer {
    pub name: String,
}

pub struct Order {
    pub customer: Option<Customer>,
    pub amount: i64,
}

/// Summarizes an order.
pub fn summarize(o: &Order) -> String {
    format!("{} owes {}", o.customer.as_ref().unwrap().name, o.amount)
}

pub fn handle(_query: &HashMap<String, String>) -> (u16, String) {
    let o = Order {
        customer: None,
        amount: 42,
    };
    (200, summarize(&o))
}
