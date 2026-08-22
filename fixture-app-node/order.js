/**
 * @typedef {{name: string}} Customer
 * @typedef {{customer?: Customer, amount: number}} Order
 */

// summarize previously accessed order.customer.name without checking
// whether customer is present, so an Order with no Customer attached
// would throw. It now falls back to a generic label when customer is
// missing (mirrors the Go/Rust/Python fixture apps' order.go/order.rs/order.py).
/**
 * @param {Order} order
 * @returns {string}
 */
function summarize(order) {
  const name = order.customer ? order.customer.name : "Unknown customer";
  return `${name} owes ${order.amount}`;
}

module.exports = { summarize };
