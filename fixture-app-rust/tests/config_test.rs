use revi_fixture_app_rust::config;
use std::env;
use std::sync::Mutex;

// MAX_ORDER_AMOUNT is process-global env state; serialize tests that touch it
// so they don't race each other.
static ENV_LOCK: Mutex<()> = Mutex::new(());

#[test]
fn invalid_max_order_amount_falls_back_to_documented_default() {
    let _guard = ENV_LOCK.lock().unwrap();
    env::set_var("MAX_ORDER_AMOUNT", "not-a-number");

    let amount = config::max_order_amount();

    env::remove_var("MAX_ORDER_AMOUNT");

    // Before the fix, an invalid value parsed to 0, which silently disables
    // ordering (every amount > 0 gets rejected). The documented default is
    // 100000.
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
    env::set_var("MAX_ORDER_AMOUNT", "42");

    let amount = config::max_order_amount();

    env::remove_var("MAX_ORDER_AMOUNT");

    assert_eq!(amount, 42);
}
