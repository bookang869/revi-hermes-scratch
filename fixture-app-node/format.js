/**
 * formatOrder returns a JSON view of an order's amount, rejecting
 * negative amounts with (400, ...) rather than echoing back a
 * nonsensical order.
 * @param {number} amount
 * @returns {{status: number, body: string}}
 */
function formatOrder(amount) {
  if (amount < 0) {
    return {
      status: 400,
      body: JSON.stringify({ error: "amount must be non-negative" }),
    };
  }
  return { status: 200, body: JSON.stringify({ amount, currency: "USD" }) };
}

module.exports = { formatOrder };
