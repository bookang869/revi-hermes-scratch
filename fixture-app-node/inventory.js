const http = require("http");

// checkInventory is deliberately buggy: it forwards the downstream
// inventory service's response as if it were always a successful 200
// lookup, regardless of the actual status code it got back -- this is
// the seeded bug used to test the repair loop end-to-end (mirrors the
// Go/Rust/Python fixture apps' dependency faults).
/**
 * @param {string} sku
 * @returns {Promise<{status: number, body: string}>}
 */
function checkInventory(sku) {
  const base = process.env.INVENTORY_URL || "";
  const url = `${base}/stock?sku=${encodeURIComponent(sku)}`;
  return new Promise((resolve) => {
    try {
      const req = http.get(url, (resp) => {
        let body = "";
        resp.on("data", (/** @type {any} */ chunk) => {
          body += chunk;
        });
        resp.on("end", () => {
          resolve({ status: 200, body });
        });
      });
      req.on("error", () => {
        resolve({ status: 503, body: "inventory service unavailable" });
      });
    } catch (err) {
      resolve({ status: 503, body: "inventory service unavailable" });
    }
  });
}

module.exports = { checkInventory };
