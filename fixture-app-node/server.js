const http = require("http");
const { summarize } = require("./order");
const { divideShare } = require("./divide");
const { bulkDiscount } = require("./discount");
const { validateOrder } = require("./config");
const { checkInventory } = require("./inventory");
const { averageOrderValue } = require("./stats");
const { formatOrder } = require("./format");
const { catalogItem } = require("./items");

/**
 * @param {string} reqUrl
 * @returns {{path: string, params: Map<string, string>}}
 */
function parseUrl(reqUrl) {
  const qIndex = reqUrl.indexOf("?");
  const path = qIndex === -1 ? reqUrl : reqUrl.slice(0, qIndex);
  const params = new Map();
  if (qIndex !== -1) {
    const query = reqUrl.slice(qIndex + 1);
    for (const pair of query.split("&")) {
      if (!pair) continue;
      const [key, value] = pair.split("=");
      params.set(decodeURIComponent(key), decodeURIComponent(value || ""));
    }
  }
  return { path, params };
}

/**
 * @param {Map<string, string>} params
 * @param {string} name
 * @returns {number}
 */
function intParam(params, name) {
  const raw = params.get(name);
  if (raw === undefined) return 0;
  const n = parseInt(raw, 10);
  return Number.isNaN(n) ? 0 : n;
}

/**
 * @param {any} res
 * @param {number} status
 * @param {string} body
 * @param {string} [contentType]
 */
function respond(res, status, body, contentType) {
  res.writeHead(status, { "Content-Type": contentType || "text/plain" });
  res.end(body);
}

// Every route is wrapped in a single top-level try/catch (mirrors the Go
// fixture's per-request recover() and the Rust fixture's catch_unwind --
// see docs/observability-part-b.md): an uncaught synchronous exception in
// a request listener would otherwise crash the whole Node process, unlike
// Go/Rust/Python where the runtime/stdlib isolates a per-request panic
// automatically. This keeps "process keeps handling requests normally
// afterward" meaningful across all four languages instead of Node being
// the one where any unfixed bug takes the whole server down.
/**
 * @param {any} req
 * @param {any} res
 */
function handle(req, res) {
  try {
    const { path, params } = parseUrl(req.url);

    if (path === "/healthz") {
      respond(res, 200, "ok");
    } else if (path === "/summarize") {
      respond(res, 200, summarize({ amount: 42 }));
    } else if (path === "/divide-share") {
      const total = intParam(params, "total");
      const parts = intParam(params, "parts");
      const result = divideShare(total, parts);
      if (result === null) {
        respond(res, 400, "parts must be positive");
      } else {
        respond(res, 200, String(result));
      }
    } else if (path === "/discount") {
      const unitPrice = intParam(params, "unit_price");
      const qty = intParam(params, "qty");
      respond(res, 200, String(bulkDiscount(unitPrice, qty)));
    } else if (path === "/validate-order") {
      const amount = intParam(params, "amount");
      respond(res, 200, validateOrder(amount) ? "accepted" : "rejected");
    } else if (path === "/inventory") {
      const sku = params.get("sku") || "";
      checkInventory(sku)
        .then(({ status, body }) => respond(res, status, body))
        .catch(() => respond(res, 500, "internal error"));
    } else if (path === "/average") {
      respond(res, 200, String(averageOrderValue([10, 20, 30])));
    } else if (path === "/format-order") {
      const amount = intParam(params, "amount");
      const { status, body } = formatOrder(amount);
      respond(res, status, body, "application/json");
    } else if (path === "/items") {
      const index = intParam(params, "index");
      const item = catalogItem(index);
      if (item === undefined) {
        respond(res, 400, "index out of range");
      } else {
        respond(res, 200, item);
      }
    } else {
      respond(res, 404, "not found");
    }
  } catch (err) {
    respond(res, 500, "internal error");
  }
}

const server = http.createServer(handle);
server.listen(8080);
