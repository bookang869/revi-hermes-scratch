use std::env;
use std::sync::Mutex;

use revi_fixture_app_rust::config;

// env::set_var is process-global; serialize tests that touch MAX_ORDER_AMOUNT.
static ENV_LOCK: Mutex<()> = Mutex::new(());

#[test]
fn invalid_max_order_amount_falls_back_to_documented_default() {
    let _guard = ENV_LOCK.lock().unwrap();

    env::set_var("MAX_ORDER_AMOUNT", "not-a-number");

    let amount = config::max_order_amount();

    env::remove_var("MAX_ORDER_AMOUNT");

    // Must fall back to the documented default (100000), not silently
    // disable ordering by falling back to 0.
    assert_eq!(amount, 100_000);
}

#[test]
fn unset_max_order_amount_uses_documented_default() {
    let _guard = ENV_LOCK.lock().unwrap();

    env::remove_var("MAX_ORDER_AMOUNT");

    assert_eq!(config::max_order_amount(), 100_000);
}

#[test]
fn valid_max_order_amount_is_respected() {
    let _guard = ENV_LOCK.lock().unwrap();

    env::set_var("MAX_ORDER_AMOUNT", "5000");

    let amount = config::max_order_amount();

    env::remove_var("MAX_ORDER_AMOUNT");

    assert_eq!(amount, 5000);
}
