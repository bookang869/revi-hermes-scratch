const http = require("http");

/**
 * checkInventory asks a downstream inventory service (URL from
 * INVENTORY_URL) whether a SKU is in stock and relays its response. A
 * non-200 from the downstream service is a dependency failure and must be
 * surfaced as (503, ...), not forwarded as if it were a successful
 * lookup.
 * @param {string} sku
 * @returns {Promise<{status: number, body: string}>}
 */
function checkInventory(sku) {
  const base = process.env.INVENTORY_URL || "";
  const url = `${base}/stock?sku=${encodeURIComponent(sku)}`;
  return new Promise((resolve) => {
    // http.get() itself throws synchronously for a malformed URL (e.g.
    // INVENTORY_URL unset), before the request object -- and thus its
    // 'error' event -- even exists. That throw happens inside this
    // executor, so without this try/catch it would reject the promise
    // instead of resolving it, and an unhandled rejection crashes the
    // whole Node process by default (found while hand-verifying this
    // fixture, 2026-08-21).
    try {
      const req = http.get(url, (resp) => {
        let body = "";
        resp.on("data", (/** @type {any} */ chunk) => {
          body += chunk;
        });
        resp.on("end", () => {
          if (resp.statusCode !== 200) {
            resolve({ status: 503, body: "inventory service unavailable" });
          } else {
            resolve({ status: 200, body });
          }
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
