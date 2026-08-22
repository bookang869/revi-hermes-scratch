/**
 * @param {number} amount
 * @returns {{status: number, body: string}}
 */
function formatOrder(amount) {
  if (amount < 0) {
    return { status: 400, body: "amount must not be negative" };
  }
  return { status: 200, body: JSON.stringify({ amount, currency: "USD" }) };
}

module.exports = { formatOrder };
