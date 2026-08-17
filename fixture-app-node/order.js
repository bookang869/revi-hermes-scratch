/**
 * @typedef {{name: string}} Customer
 * @typedef {{customer?: Customer, amount: number}} Order
 */

// summarize is deliberately buggy: it accesses order.customer.name without
// checking whether customer is present, so an Order with no Customer
// attached throws -- this is the seeded bug used to test the repair loop
// end-to-end (mirrors the Go/Rust fixture apps' order.go/order.rs).
/**
 * @param {Order} order
 * @returns {string}
 */
function summarize(order) {
  return `${order.customer.name} owes ${order.amount}`;
}

module.exports = { summarize };
