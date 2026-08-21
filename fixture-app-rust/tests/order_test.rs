use revi_fixture_app_rust::order::{summarize, Customer, Order};

#[test]
fn summarize_handles_missing_customer_without_panicking() {
    let o = Order {
        customer: None,
        amount: 42,
    };

    // Before the fix, this call panicked with:
    // "called `Option::unwrap()` on a `None` value"
    let result = summarize(&o);

    assert_eq!(result, "Unknown customer owes 42");
}

#[test]
fn summarize_with_customer_present() {
    let o = Order {
        customer: Some(Customer {
            name: "Alice".to_string(),
        }),
        amount: 100,
    };

    let result = summarize(&o);

    assert_eq!(result, "Alice owes 100");
}
