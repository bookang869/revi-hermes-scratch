use revi_fixture_app_rust::items::catalog_item;

#[test]
fn catalog_item_returns_item_for_valid_index() {
    assert_eq!(catalog_item(0), Some("widget"));
    assert_eq!(catalog_item(1), Some("gadget"));
    assert_eq!(catalog_item(2), Some("gizmo"));
}

#[test]
fn catalog_item_returns_none_for_out_of_bounds_index() {
    // Before the fix this indexed the array directly and panicked
    // ("index out of bounds") for any index >= CATALOG_ITEMS.len().
    assert_eq!(catalog_item(3), None);
    assert_eq!(catalog_item(1000), None);
}

#[test]
fn catalog_item_returns_none_for_negative_index() {
    assert_eq!(catalog_item(-1), None);
}
