use crate::http_util;
use std::collections::HashMap;

pub const CATALOG_ITEMS: [&str; 3] = ["widget", "gadget", "gizmo"];

/// Returns the catalog item at `index`.
pub fn catalog_item(index: i64) -> &'static str {
    CATALOG_ITEMS[index as usize]
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let index = http_util::query_i64(query, "index");
    (200, catalog_item(index).to_string())
}
