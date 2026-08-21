/**
 * averageOrderValue returns the mean of a set of order amounts, or 0 for
 * an empty list (avoids a divide-by-zero rather than returning NaN).
 * Exposed over HTTP against a fixed sample so it's independently
 * checkable, not just something Hermes could satisfy by deleting the
 * broken function.
 * @param {number[]} orders
 * @returns {number}
 */
function averageOrderValue(orders) {
  if (orders.length === 0) {
    return 0;
  }
  const sum = orders.reduce((a, b) => a + b, 0);
  return sum / orders.length;
}

module.exports = { averageOrderValue };
