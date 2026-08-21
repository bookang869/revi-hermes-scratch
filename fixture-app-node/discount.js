/**
 * bulkDiscount applies a 10% discount to orders of 10 or more units.
 * bulkDiscount(100, 10) -> 900 (10x100, 10% off).
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
