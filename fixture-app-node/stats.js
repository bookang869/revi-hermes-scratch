/**
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
