/**
 * maxOrderAmount rejects orders over a configurable maximum, read from
 * MAX_ORDER_AMOUNT (defaults to 100000 if unset or unparsable -- an
 * invalid config value must fall back to the default, not silently
 * disable ordering entirely via a NaN comparison that's always false).
 * @returns {number}
 */
function maxOrderAmount() {
  const raw = process.env.MAX_ORDER_AMOUNT;
  if (raw) {
    const n = parseInt(raw, 10);
    if (!Number.isNaN(n)) {
      return n;
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

module.exports = { validateOrder };
