use revi_fixture_app_rust::order::{summarize, Order};

#[test]
fn summarize_handles_missing_customer_without_panicking() {
    let o = Order {
        customer: None,
        amount: 42,
    };
    let result = summarize(&o);
    assert!(result.contains("42"));
}

#[test]
fn summarize_includes_customer_name_when_present() {
    let o = Order {
        customer: Some(revi_fixture_app_rust::order::Customer {
            name: "Alice".to_string(),
        }),
        amount: 10,
    };
    let result = summarize(&o);
    assert!(result.contains("Alice"));
    assert!(result.contains("10"));
}
