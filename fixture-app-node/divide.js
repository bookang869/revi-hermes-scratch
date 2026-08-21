// divideShare is deliberately buggy: it divides by parts without
// checking for zero, so GET /divide-share?parts=0 lets the underlying
// BigInt division's native "RangeError: Division by zero" propagate
// uncaught -- this is the seeded bug used to test the repair loop
// end-to-end (mirrors the Go/Rust/Python fixture apps' divide-by-zero
// faults).
/**
 * @param {number} total
 * @param {number} parts
 * @returns {number | null}
 */
function divideShare(total, parts) {
  return Number(BigInt(total) / BigInt(parts));
}

module.exports = { divideShare };
