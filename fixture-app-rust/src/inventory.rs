use crate::http_util;
use std::collections::HashMap;
use std::env;

/// Asks a downstream inventory service (base URL from INVENTORY_URL)
/// whether a SKU is in stock and relays its response.
pub fn inventory_check(sku: &str) -> (u16, String) {
    let base_url = env::var("INVENTORY_URL").unwrap_or_default();
    match http_util::http_get(&base_url, &format!("/stock?sku={sku}")) {
        Err(_) => (503, "inventory service unavailable".to_string()),
        Ok((status, body)) => (status, body),
    }
}

pub fn handle(query: &HashMap<String, String>) -> (u16, String) {
    let sku = http_util::query_str(query, "sku");
    inventory_check(sku)
}
