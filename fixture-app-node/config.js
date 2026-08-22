// maxOrderAmount reads MAX_ORDER_AMOUNT from the environment. If the value
// is missing OR invalid (non-numeric, parses to NaN), it falls back to the
// documented default of 100000 instead of silently propagating NaN, which
// previously made every `amount <= NaN` comparison in validateOrder false
// and disabled ordering entirely.
const DEFAULT_MAX_ORDER_AMOUNT = 100000;

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
  return DEFAULT_MAX_ORDER_AMOUNT;
}

/**
 * @param {number} amount
 * @returns {boolean}
 */
function validateOrder(amount) {
  return amount <= maxOrderAmount();
}

module.exports = { validateOrder };
