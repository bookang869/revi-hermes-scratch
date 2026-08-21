use crate::http_util;
use std::collections::HashMap;

/// Splits a shared total evenly across a number of participants, e.g.
/// divide_share(100, 4) -> Some(25). Rejects a zero (or negative) parts
/// count instead of letting the division happen.
pub fn divide_share(total: i64, parts: i64) -> Option<i64> {
    if parts <= 0 {
        return None;
    }
    Some(total / parts)
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let total = http_util::query_i64(query, "total");
    let parts = http_util::query_i64(query, "parts");
    match divide_share(total, parts) {
        None => (400, "parts must be positive".to_string()),
        Some(v) => (200, v.to_string()),
    }
}
