use revi_fixture_app_rust::stats::average_order_value;

#[test]
fn average_order_value_computes_mean() {
    assert_eq!(average_order_value(&[10, 20, 30]), 20);
}

#[test]
fn average_order_value_empty_is_zero() {
    assert_eq!(average_order_value(&[]), 0);
}
