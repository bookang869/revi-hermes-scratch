use revi_fixture_app_rust::divide::divide_share;

#[test]
fn divide_share_returns_zero_when_parts_is_zero() {
    assert_eq!(divide_share(100, 0), 0);
}

#[test]
fn divide_share_splits_evenly() {
    assert_eq!(divide_share(100, 4), 25);
}
