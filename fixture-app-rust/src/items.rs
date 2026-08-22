use crate::http_util;
use std::collections::HashMap;

pub const CATALOG_ITEMS: [&str; 3] = ["widget", "gadget", "gizmo"];

/// Returns the catalog item at `index`, or `None` when `index` is out of
/// bounds (negative or >= CATALOG_ITEMS.len()). Callers must not index
/// CATALOG_ITEMS directly with an unchecked, user-supplied value.
pub fn catalog_item(index: i64) -> Option<&'static str> {
    if index < 0 {
        return None;
    }
    let index = index as usize;
    if index >= CATALOG_ITEMS.len() {
        return None;
    }
    Some(CATALOG_ITEMS[index])
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let index = http_util::query_i64(query, "index");
    match catalog_item(index) {
        None => (400, "index out of range".to_string()),
        Some(item) => (200, item.to_string()),
    }
}
