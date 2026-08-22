use crate::http_util;
use std::collections::HashMap;

/// Splits a shared total evenly across a number of participants, e.g.
/// divide_share(100, 4) -> Some(25). Returns None when `parts` is zero,
/// since there is no meaningful share to compute (and integer division by
/// zero would panic).
pub fn divide_share(total: i64, parts: i64) -> Option<i64> {
    if parts == 0 {
        None
    } else {
        Some(total / parts)
    }
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let total = http_util::query_i64(query, "total");
    let parts = http_util::query_i64(query, "parts");
    match divide_share(total, parts) {
        Some(share) => (200, share.to_string()),
        None => (400, "parts must not be zero".to_string()),
    }
}
