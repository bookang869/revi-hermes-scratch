use revi_fixture_app_rust::divide::divide_share;

#[test]
fn divide_share_splits_evenly() {
    assert_eq!(divide_share(100, 4), Some(25));
}

#[test]
fn divide_share_zero_parts_does_not_panic() {
    // Before the fix, this called `total / parts` directly, which panics
    // with "attempt to divide by zero" when parts == 0. It must now return
    // None instead of panicking.
    assert_eq!(divide_share(100, 0), None);
}
