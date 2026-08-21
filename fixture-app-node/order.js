/**
 * @typedef {{name: string}} Customer
 * @typedef {{customer?: Customer, amount: number}} Order
 */

/**
 * @param {Order} order
 * @returns {string}
 */
function summarize(order) {
  const name = order.customer ? order.customer.name : "Unknown customer";
  return `${name} owes ${order.amount}`;
}

module.exports = { summarize };
