pub struct Customer {
    pub name: String,
}

pub struct Order {
    pub customer: Option<Customer>,
    pub amount: i64,
}

pub fn summarize(o: &Order) -> String {
    match &o.customer {
        Some(c) => format!("{} owes {}", c.name, o.amount),
        None => format!("unknown customer owes {}", o.amount),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn summarize_nil_customer() {
        let o = Order {
            customer: None,
            amount: 42,
        };
        assert_eq!(summarize(&o), "unknown customer owes 42");
    }
}
