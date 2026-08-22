const CATALOG_ITEMS = ["widget", "gadget", "gizmo"];

// catalogItem previously called toUpperCase() on the raw indexed lookup
// without checking whether the index was in range, so an out-of-range
// index threw "Cannot read properties of undefined (reading
// 'toUpperCase')". It now guards against out-of-range indexes and
// returns undefined instead, matching the callers' expectations (mirrors
// the Go/Rust/Python fixture apps' out-of-range faults).
/**
 * @param {number} index
 * @returns {string | undefined}
 */
function catalogItem(index) {
  const item = CATALOG_ITEMS[index];
  return item === undefined ? undefined : item.toUpperCase();
}

module.exports = { catalogItem };
