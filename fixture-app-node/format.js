// formatOrder is deliberately buggy: it accepts and echoes back negative
// amounts instead of rejecting them with 400 -- this is the seeded bug
// used to test the repair loop end-to-end (mirrors the Go/Rust/Python
// fixture apps' bad-validation faults).
/**
 * @param {number} amount
 * @returns {{status: number, body: string}}
 */
function formatOrder(amount) {
  return { status: 200, body: JSON.stringify({ amount, currency: "USD" }) };
}

module.exports = { formatOrder };
