// divideShare splits a shared total evenly across a number of
// participants, e.g. divideShare(100, 4) -> 25. Rejects a zero (or
// negative) parts count by returning null instead of letting the
// underlying BigInt division's native "RangeError: Division by zero"
// propagate uncaught (mirrors the Go/Rust/Python fixture apps'
// divide-by-zero guards).
/**
 * @param {number} total
 * @param {number} parts
 * @returns {number | null}
 */
function divideShare(total, parts) {
  if (parts <= 0) {
    return null;
  }
  return Number(BigInt(total) / BigInt(parts));
}

module.exports = { divideShare };
