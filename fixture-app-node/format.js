/**
 * @param {number} amount
 * @returns {{status: number, body: string}}
 */
function formatOrder(amount) {
  if (typeof amount !== "number" || Number.isNaN(amount) || amount < 0) {
    return { status: 400, body: JSON.stringify({ error: "amount must be non-negative" }) };
  }
  return { status: 200, body: JSON.stringify({ amount, currency: "USD" }) };
}

module.exports = { formatOrder };
