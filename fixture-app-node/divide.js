/**
 * divideShare splits a shared total evenly across a number of
 * participants, e.g. divideShare(100, 4) -> 25. Rejects a zero (or
 * negative) parts count explicitly instead of letting the underlying
 * BigInt division's native "RangeError: Division by zero" propagate
 * uncaught.
 * @param {number} total
 * @param {number} parts
 * @returns {number | null} null signals an invalid parts count
 */
function divideShare(total, parts) {
  if (parts <= 0) {
    return null;
  }
  return Number(BigInt(total) / BigInt(parts));
}

module.exports = { divideShare };
