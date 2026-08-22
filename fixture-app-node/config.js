// maxOrderAmount reads MAX_ORDER_AMOUNT from the environment. If it is
// unset, empty, or not a valid finite number, it falls back to the
// documented 100000 default instead of silently producing NaN (which
// would make every `amount <= NaN` comparison in validateOrder false,
// silently rejecting every order).
/**
 * @returns {number}
 */
const DEFAULT_MAX_ORDER_AMOUNT = 100000;

function maxOrderAmount() {
  const raw = process.env.MAX_ORDER_AMOUNT;
  if (raw !== undefined && raw !== null && raw.trim() !== '') {
    const parsed = Number(raw);
    if (Number.isFinite(parsed)) {
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

module.exports = { validateOrder, maxOrderAmount, DEFAULT_MAX_ORDER_AMOUNT };
