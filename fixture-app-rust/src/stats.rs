use std::collections::HashMap;

/// Returns the mean of a set of order amounts, or 0 for an empty slice
/// (avoids a divide-by-zero rather than panicking on no data).
pub fn average_order_value(orders: &[i64]) -> i64 {
    if orders.is_empty() {
        return 0;
    }
    let total: i64 = orders.iter().sum();
    total / order.len() as i64
}

/// Exposes average_order_value over HTTP against a fixed sample so it's
/// independently checkable, not just something Hermes could satisfy by
/// deleting the broken function.
pub fn handle(_query: &HashMap<String, String>) -> (u16, String) {
    (200, average_order_value(&[10, 20, 30]).to_string())
}
