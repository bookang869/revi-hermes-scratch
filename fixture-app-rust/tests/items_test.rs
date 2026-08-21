use revi_fixture_app_rust::items::catalog_item;

// Fails before the fix (catalog_item panics with an index-out-of-bounds
// panic for an out-of-range index instead of returning None), passes after
// the fix.
#[test]
fn catalog_item_out_of_range_returns_none_instead_of_panicking() {
    assert_eq!(catalog_item(3), None);
    assert_eq!(catalog_item(100), None);
    assert_eq!(catalog_item(-1), None);
}

#[test]
fn catalog_item_in_range_returns_expected_items() {
    assert_eq!(catalog_item(0), Some("widget"));
    assert_eq!(catalog_item(1), Some("gadget"));
    assert_eq!(catalog_item(2), Some("gizmo"));
}
