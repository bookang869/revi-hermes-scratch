use revi_fixture_app_rust::divide::divide_share;

#[test]
fn divides_evenly_when_parts_is_nonzero() {
    assert_eq!(divide_share(100, 4), Some(25));
}

#[test]
fn returns_none_instead_of_panicking_when_parts_is_zero() {
    // Before the fix, divide_share(100, 0) panicked with
    // "attempt to divide by zero". It must now return None.
    assert_eq!(divide_share(100, 0), None);
}
