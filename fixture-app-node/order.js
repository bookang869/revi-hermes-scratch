/**
 * @typedef {{name: string}} Customer
 * @typedef {{customer?: Customer, amount: number}} Order
 */

/**
 * @param {Order} order
 * @returns {string}
 */
function summarize(order) {
  if (!order.customer) {
    return `unknown customer owes ${order.amount}`;
  }
  return `${order.customer.name} owes ${order.amount}`;
}

module.exports = { summarize };
