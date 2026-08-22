use revi_fixture_app_rust::items::catalog_item;

// Before the fix, catalog_item(index) indexed CATALOG_ITEMS directly with
// an unchecked usize cast, so any out-of-range index (e.g. one supplied by
// a client via ?index=99) panicked with "index out of bounds" instead of
// returning a handled error. This test fails on the old signature/behavior
// and passes once catalog_item bounds-checks and returns None.
#[test]
fn out_of_bounds_index_does_not_panic() {
    assert_eq!(catalog_item(99), None);
    assert_eq!(catalog_item(-1), None);
    assert_eq!(catalog_item(3), None); // CATALOG_ITEMS has exactly 3 items (0..=2)
}

#[test]
fn in_bounds_index_returns_item() {
    assert_eq!(catalog_item(0), Some("widget"));
    assert_eq!(catalog_item(1), Some("gadget"));
    assert_eq!(catalog_item(2), Some("gizmo"));
}
