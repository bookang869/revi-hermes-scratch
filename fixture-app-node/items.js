const CATALOG_ITEMS = ["widget", "gadget", "gizmo"];

// catalogItem is deliberately buggy: it calls toUpperCase() on the raw
// indexed lookup without checking whether the index was in range, so an
// out-of-range index throws "Cannot read properties of undefined
// (reading 'toUpperCase')" -- this is the seeded bug used to test the
// repair loop end-to-end (mirrors the Go/Rust/Python fixture apps'
// out-of-range faults).
/**
 * @param {number} index
 * @returns {string | undefined}
 */
function catalogItem(index) {
  return CATALOG_ITEMS[index].toUpperCase();
}

module.exports = { catalogItem };
