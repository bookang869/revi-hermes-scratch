use crate::http_util;
use std::collections::HashMap;

/// Splits a shared total evenly across a number of participants, e.g.
/// divide_share(100, 4) -> 25.
pub fn divide_share(total: i64, parts: i64) -> i64 {
    total / parts
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let total = http_util::query_i64(query, "total");
    let parts = http_util::query_i64(query, "parts");
    (200, divide_share(total, parts).to_string())
}
