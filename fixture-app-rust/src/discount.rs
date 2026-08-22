use crate::http_util;
use std::collections::HashMap;

/// Applies a 10% discount to orders of 10 units or more. bulk_discount(100,
/// 10) -> 900 (10x100, 10% off).
pub fn bulk_discount(unit_price: i64, qty: i64) -> i64 {
    let total = unit_price * qty;
    if qty >= 10 {
        total * 90 / 100
    } else {
        total
    }
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let unit_price = http_util::query_i64(query, "unit_price");
    let qty = http_util::query_i64(query, "qty");
    (200, bulk_discount(unit_price, qty).to_string())
}
