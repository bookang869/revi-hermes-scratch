use revi_fixture_app_rust::divide::divide_share;

#[test]
fn divide_share_zero_parts_returns_zero_instead_of_panicking() {
    assert_eq!(divide_share(100, 0), 0);
}

#[test]
fn divide_share_normal_case_still_divides() {
    assert_eq!(divide_share(100, 4), 25);
}
