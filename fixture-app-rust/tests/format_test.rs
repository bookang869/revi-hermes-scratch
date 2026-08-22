use revi_fixture_app_rust::format::format_order;

#[test]
fn rejects_negative_amount() {
    assert_eq!(format_order(-1), None);
}

#[test]
fn accepts_non_negative_amount() {
    assert_eq!(
        format_order(100),
        Some("{\"amount\":100,\"currency\":\"USD\"}".to_string())
    );
}

#[test]
fn accepts_zero_amount() {
    assert_eq!(
        format_order(0),
        Some("{\"amount\":0,\"currency\":\"USD\"}".to_string())
    );
}
