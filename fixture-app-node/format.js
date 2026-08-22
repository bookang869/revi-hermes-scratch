// formatOrder rejects negative amounts with a 400 response instead of
// echoing them back -- this mirrors the Go/Rust/Python fixture apps'
// validation fixes.
/**
 * @param {number} amount
 * @returns {{status: number, body: string}}
 */
function formatOrder(amount) {
  if (amount < 0) {
    return { status: 400, body: JSON.stringify({ error: "amount must not be negative" }) };
  }
  return { status: 200, body: JSON.stringify({ amount, currency: "USD" }) };
}

module.exports = { formatOrder };
