// bulkDiscount applies a 10% bulk discount to orders of 10 units or more.
/**
 * @param {number} unitPrice
 * @param {number} qty
 * @returns {number}
 */
function bulkDiscount(unitPrice, qty) {
  let total = unitPrice * qty;
  if (qty >= 10) {
    total = Math.floor((total * 90) / 100);
  }
  return total;
}

module.exports = { bulkDiscount };
