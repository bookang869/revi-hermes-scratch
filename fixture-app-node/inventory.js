const http = require("http");

// checkInventory forwards the downstream inventory service's response
// status verbatim, instead of always reporting 200 -- this mirrors the
// Go/Rust/Python fixture apps' dependency faults, now fixed.
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
          resolve({ status: resp.statusCode || 502, body });
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
