pub struct Customer {
    pub name: String,
}

pub struct Order {
    pub customer: Option<Customer>,
    pub amount: i64,
}

// summarize previously unwrapped o.customer without checking for None, so
// an Order with no Customer attached would panic. It now falls back to a
// placeholder name when no customer is attached.
pub fn summarize(o: &Order) -> String {
    let name = o
        .customer
        .as_ref()
        .map(|c| c.name.as_str())
        .unwrap_or("unknown customer");
    format!("{} owes {}", name, o.amount)
}
