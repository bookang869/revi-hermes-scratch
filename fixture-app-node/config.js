// maxOrderAmount is deliberately buggy: it returns parseInt()'s result
// unchecked, so an invalid MAX_ORDER_AMOUNT (e.g. non-numeric) parses to
// NaN -- and every subsequent `amount <= NaN` comparison in
// validateOrder is always false, silently rejecting every order instead
// of falling back to the documented 100000 default. This is the seeded
// bug used to test the repair loop end-to-end (mirrors the Go/Rust/
// Python fixture apps' config faults).
/**
 * @returns {number}
 */
function maxOrderAmount() {
  const raw = process.env.MAX_ORDER_AMOUNT;
  if (raw) {
    return parseInt(raw, 10);
  }
  return 100000;
}

/**
 * @param {number} amount
 * @returns {boolean}
 */
function validateOrder(amount) {
  return amount <= maxOrderAmount();
}

module.exports = { validateOrder };
