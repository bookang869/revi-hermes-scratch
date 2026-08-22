const http = require("http");
const { checkInventory } = require("./inventory");

/**
 * Starts a throwaway HTTP server that always responds with the given
 * status/body, to stand in for the downstream inventory service.
 * @param {number} status
 * @param {string} body
 * @returns {Promise<{url: string, close: () => Promise<void>}>}
 */
function startFakeDownstream(status, body) {
  return new Promise((resolve) => {
    const server = http.createServer((_req, res) => {
      res.writeHead(status, { "Content-Type": "text/plain" });
      res.end(body);
    });
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      const port = typeof address === "object" && address ? address.port : 0;
      resolve({
        url: `http://127.0.0.1:${port}`,
        close: () => new Promise((res) => server.close(() => res())),
      });
    });
  });
}

describe("checkInventory", () => {
  let originalInventoryUrl;

  beforeEach(() => {
    originalInventoryUrl = process.env.INVENTORY_URL;
  });

  afterEach(() => {
    if (originalInventoryUrl === undefined) {
      delete process.env.INVENTORY_URL;
    } else {
      process.env.INVENTORY_URL = originalInventoryUrl;
    }
  });

  test("forwards a downstream non-200 status instead of reporting 200", async () => {
    const downstream = await startFakeDownstream(503, "out of stock service down");
    process.env.INVENTORY_URL = downstream.url;

    try {
      const result = await checkInventory("sku-123");
      expect(result.status).toBe(503);
      expect(result.body).toBe("out of stock service down");
    } finally {
      await downstream.close();
    }
  });

  test("still forwards a genuine 200 as 200", async () => {
    const downstream = await startFakeDownstream(200, "in stock");
    process.env.INVENTORY_URL = downstream.url;

    try {
      const result = await checkInventory("sku-456");
      expect(result.status).toBe(200);
      expect(result.body).toBe("in stock");
    } finally {
      await downstream.close();
    }
  });
});
