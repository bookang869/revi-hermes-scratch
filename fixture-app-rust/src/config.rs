use crate::http_util;
use std::collections::HashMap;
use std::env;

const DEFAULT_MAX_ORDER_AMOUNT: i64 = 100_000;

/// Reads the order amount cap from MAX_ORDER_AMOUNT, falling back to the
/// documented default of 100000 when the var is unset.
pub fn max_order_amount() -> i64 {
    match env::var("MAX_ORDER_AMOUNT") {
        Ok(v) => v.parse::<i64>().unwrap_or(0),
        Err(_) => DEFAULT_MAX_ORDER_AMOUNT,
    }
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let amount = http_util::query_i64(query, "amount");
    if amount > max_order_amount() {
        (400, "rejected".to_string())
    } else {
        (200, "accepted".to_string())
    }
}
