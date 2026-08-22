const CATALOG_ITEMS = ["widget", "gadget", "gizmo"];

// catalogItem previously called toUpperCase() on the raw indexed lookup
// without checking whether the index was in range, so an out-of-range
// index threw "Cannot read properties of undefined (reading
// 'toUpperCase')". It now guards against out-of-range (and non-integer)
// indices and returns undefined instead of crashing.
/**
 * @param {number} index
 * @returns {string | undefined}
 */
function catalogItem(index) {
  const item = CATALOG_ITEMS[index];
  return item === undefined ? undefined : item.toUpperCase();
}

module.exports = { catalogItem };
