use revi_fixture_app_rust::items::catalog_item;

// Before the fix, catalog_item(index) returned &'static str and indexed
// CATALOG_ITEMS directly, panicking with "index out of bounds" for any
// index >= CATALOG_ITEMS.len() (or negative). This test exercises exactly
// that crash path (trace_id trace-t2-1787359906903960000): it fails to
// compile/panics before the fix, and passes once catalog_item returns
// Option<&'static str> and uses a bounds-checked get().
#[test]
fn out_of_range_index_returns_none_instead_of_panicking() {
    assert_eq!(catalog_item(3), None);
    assert_eq!(catalog_item(100), None);
}

#[test]
fn negative_index_returns_none_instead_of_panicking() {
    assert_eq!(catalog_item(-1), None);
}

#[test]
fn in_range_indices_return_expected_items() {
    assert_eq!(catalog_item(0), Some("widget"));
    assert_eq!(catalog_item(1), Some("gadget"));
    assert_eq!(catalog_item(2), Some("gizmo"));
}
