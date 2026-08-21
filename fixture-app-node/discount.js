// bulkDiscount is deliberately buggy: it only applies the 10% bulk
// discount to orders of MORE than 10 units, not orders of exactly 10 --
// this is the seeded off-by-one used to test the repair loop end-to-end
// (mirrors the Go/Rust/Python fixture apps' discount faults).
/**
 * @param {number} unitPrice
 * @param {number} qty
 * @returns {number}
 */
function bulkDiscount(unitPrice, qty) {
  let total = unitPrice * qty;
  if (qty > 10) {
    total = Math.floor((total * 90) / 100);
  }
  return total;
}

module.exports = { bulkDiscount };
