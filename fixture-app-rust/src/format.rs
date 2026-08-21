use crate::http_util;
use std::collections::HashMap;

/// Renders an order's amount as a JSON view, rejecting a negative amount
/// rather than echoing back a nonsensical order.
pub fn format_order(amount: i64) -> Option<String> {
    if amount < 0 {
        return None;
    }
    Some(format!("{{\"amount\":{amount},\"currency\":\"USD\"}}"))
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let amount = http_util::query_i64(query, "amount");
    match format_order(amount) {
        None => (400, "{\"error\":\"amount must be non-negative\"}".to_string()),
        Some(body) => (200, body),
    }
}
