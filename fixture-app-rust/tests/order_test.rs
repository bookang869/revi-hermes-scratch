use revi_fixture_app_rust::order::{summarize, Customer, Order};

#[test]
fn summarize_does_not_panic_when_customer_is_none() {
    let o = Order {
        customer: None,
        amount: 42,
    };
    // Before the fix, this called Option::unwrap() on a None value and
    // panicked. After the fix it should fall back to a placeholder name.
    let result = summarize(&o);
    assert_eq!(result, "Unknown customer owes 42");
}

#[test]
fn summarize_uses_customer_name_when_present() {
    let o = Order {
        customer: Some(Customer {
            name: "Alice".to_string(),
        }),
        amount: 100,
    };
    let result = summarize(&o);
    assert_eq!(result, "Alice owes 100");
}
