use crate::http_util;
use std::collections::HashMap;

pub const CATALOG_ITEMS: [&str; 3] = ["widget", "gadget", "gizmo"];

/// Returns the catalog item at `index`, or None if out of range.
pub fn catalog_item(index: i64) -> Option<&'static str> {
    if index < 0 {
        return None;
    }
    CATALOG_ITEMS.get(index as usize).copied()
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let index = http_util::query_i64(query, "index");
    match catalog_item(index) {
        None => (400, "index out of range".to_string()),
        Some(item) => (200, item.to_string()),
    }
}
