use std::collections::HashMap;

pub struct Customer {
    pub name: String,
}

pub struct Order {
    pub customer: Option<Customer>,
    pub amount: i64,
}

/// Summarizes an order, falling back to "Unknown customer" when no
/// Customer is attached instead of dereferencing a None.
pub fn summarize(o: &Order) -> String {
    let name = o
        .customer
        .as_ref()
        .map(|c| c.name.as_str())
        .unwrap_or("Unknown customer");
    format!("{} owes {}", name, o.amount)
}

pub fn handle(_query: &HashMap<String, String>) -> (u16, String) {
    let o = Order {
        customer: None,
        amount: 42,
    };
    (200, summarize(&o))
}
