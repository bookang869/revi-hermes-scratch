use revi_fixture_app_rust::config;

// Single test function: MAX_ORDER_AMOUNT is read from process-wide env, and
// Cargo runs #[test] fns in this binary on separate threads by default, so
// keeping every env mutation + assertion in one test avoids cross-test
// races over the shared env var.
#[test]
fn invalid_max_order_amount_falls_back_to_documented_default() {
    // Invalid (non-numeric) value must NOT silently disable ordering by
    // falling back to 0 -- it must fall back to the documented default.
    std::env::set_var("MAX_ORDER_AMOUNT", "not-a-number");
    assert_eq!(config::max_order_amount(), 100_000);
    std::env::remove_var("MAX_ORDER_AMOUNT");

    // Unset stays on the documented default.
    assert_eq!(config::max_order_amount(), 100_000);

    // A valid override is still honored.
    std::env::set_var("MAX_ORDER_AMOUNT", "42");
    assert_eq!(config::max_order_amount(), 42);
    std::env::remove_var("MAX_ORDER_AMOUNT");
}
