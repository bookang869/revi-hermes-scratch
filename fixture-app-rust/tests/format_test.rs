use revi_fixture_app_rust::format::format_order;

#[test]
fn rejects_negative_amount() {
    assert_eq!(format_order(-5), None);
}

#[test]
fn accepts_zero_amount() {
    assert_eq!(
        format_order(0),
        Some("{\"amount\":0,\"currency\":\"USD\"}".to_string())
    );
}

#[test]
fn accepts_positive_amount() {
    assert_eq!(
        format_order(1500),
        Some("{\"amount\":1500,\"currency\":\"USD\"}".to_string())
    );
}
