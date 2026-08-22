// maxOrderAmount falls back to the documented 100000 default whenever
// MAX_ORDER_AMOUNT is unset OR set to an invalid (non-numeric) value.
// Previously an invalid value parsed to NaN via parseInt() unchecked,
// and every subsequent `amount <= NaN` comparison in validateOrder was
// always false, silently rejecting every order instead of falling back
// to the default (mirrors the Go/Rust/Python fixture apps' config
// faults).
/**
 * @returns {number}
 */
function maxOrderAmount() {
  const raw = process.env.MAX_ORDER_AMOUNT;
  if (raw) {
    const parsed = parseInt(raw, 10);
    if (!Number.isNaN(parsed)) {
      return parsed;
    }
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

module.exports = { validateOrder, maxOrderAmount };
