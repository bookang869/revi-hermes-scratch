/**
 * @typedef {{name: string}} Customer
 * @typedef {{customer?: Customer, amount: number}} Order
 */

// summarize is deliberately buggy: it accesses order.customer.name
// without checking whether customer is present, so an Order with no
// Customer attached throws -- this is the seeded bug used to test the
// repair loop end-to-end (mirrors the Go/Rust/Python fixture apps'
// order.go/order.rs/order.py).
/**
 * @param {Order} order
 * @returns {string}
 */
function summarize(order) {
  const name = order.customer ? order.customer.name : "Unknown";
  return `${name} owes ${order.amount}`;
}

module.exports = { summarize };
