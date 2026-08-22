use revi_fixture_app_rust::order::{summarize, Order};

#[test]
fn summarize_handles_missing_customer_without_panicking() {
    let o = Order {
        customer: None,
        amount: 42,
    };

    let result = summarize(&o);

    assert_eq!(result, "unknown customer owes 42");
}

#[test]
fn summarize_uses_customer_name_when_present() {
    use revi_fixture_app_rust::order::Customer;

    let o = Order {
        customer: Some(Customer {
            name: "Alice".to_string(),
        }),
        amount: 10,
    };

    let result = summarize(&o);

    assert_eq!(result, "Alice owes 10");
}
