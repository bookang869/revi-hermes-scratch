// averageOrderValue is deliberately broken: an unclosed paren makes this
// a genuine SyntaxError, so requiring this module (and thus booting the
// whole app -- server.js requires it at load time) fails -- this is the
// seeded bug used to test the repair loop end-to-end (mirrors the
// Go/Rust/Python fixture apps' compile-error faults).
/**
 * @param {number[]} orders
 * @returns {number}
 */
function averageOrderValue(orders) {
  if (orders.length === 0) {
    return 0;
  }
  const sum = orders.reduce((a, b) => a + b, 0);
  return sum / orders.length;
}

module.exports = { averageOrderValue };
