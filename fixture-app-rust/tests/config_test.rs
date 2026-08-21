// Regression test for: an invalid MAX_ORDER_AMOUNT value used to silently
// disable ordering (falling back to 0) instead of falling back to the
// documented default of 100000.
//
// std::env::set_var/remove_var mutate global process state, and cargo runs
// tests in the same process across multiple threads by default. To avoid
// racing with any other test that touches MAX_ORDER_AMOUNT, everything here
// runs inside a single #[test] function so the env var is never observed by
// two tests concurrently.

use revi_fixture_app_rust::config::max_order_amount;
use std::env;

const VAR: &str = "MAX_ORDER_AMOUNT";
const DEFAULT: i64 = 100_000;

#[test]
fn max_order_amount_env_var_handling() {
    // Unset: should fall back to the documented default.
    env::remove_var(VAR);
    assert_eq!(max_order_amount(), DEFAULT);

    // Valid override: should use the parsed value.
    env::set_var(VAR, "5000");
    assert_eq!(max_order_amount(), 5000);

    // Invalid (unparsable) value: must fall back to the documented default,
    // NOT to 0 -- 0 silently disables ordering since every positive amount
    // would then exceed the cap.
    env::set_var(VAR, "not-a-number");
    assert_eq!(max_order_amount(), DEFAULT);

    // Empty string is also invalid and must fall back the same way.
    env::set_var(VAR, "");
    assert_eq!(max_order_amount(), DEFAULT);

    env::remove_var(VAR);
}
