const CATALOG_ITEMS = ["widget", "gadget", "gizmo"];

/**
 * catalogItem returns the uppercased catalog item name at the requested
 * index, or undefined if the index is out of range -- checked before
 * calling toUpperCase() so an out-of-range index doesn't crash with
 * "Cannot read properties of undefined (reading 'toUpperCase')".
 * @param {number} index
 * @returns {string | undefined}
 */
function catalogItem(index) {
  const item = CATALOG_ITEMS[index];
  return item === undefined ? undefined : item.toUpperCase();
}

module.exports = { catalogItem };
