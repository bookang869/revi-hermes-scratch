use revi_fixture_app_rust::format::format_order;

#[test]
fn rejects_negative_amount() {
    assert_eq!(format_order(-1), None);
    assert_eq!(format_order(-100), None);
}

#[test]
fn accepts_zero_and_positive_amount() {
    assert_eq!(
        format_order(0),
        Some("{\"amount\":0,\"currency\":\"USD\"}".to_string())
    );
    assert_eq!(
        format_order(500),
        Some("{\"amount\":500,\"currency\":\"USD\"}".to_string())
    );
}
