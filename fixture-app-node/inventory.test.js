const http = require("http");
const { checkInventory } = require("./inventory");

/**
 * Spins up a tiny local HTTP server that always responds with the given
 * status/body, points INVENTORY_URL at it, runs `fn`, then tears down.
 * @param {number} status
 * @param {string} body
 * @param {(base: string) => Promise<void>} fn
 */
function withDownstream(status, body, fn) {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      res.writeHead(status, { "Content-Type": "text/plain" });
      res.end(body);
    });
    server.listen(0, "127.0.0.1", async () => {
      const address = server.address();
      const base = `http://127.0.0.1:${address.port}`;
      const prevUrl = process.env.INVENTORY_URL;
      process.env.INVENTORY_URL = base;
      try {
        await fn(base);
        resolve(undefined);
      } catch (err) {
        reject(err);
      } finally {
        if (prevUrl === undefined) {
          delete process.env.INVENTORY_URL;
        } else {
          process.env.INVENTORY_URL = prevUrl;
        }
        server.close();
      }
    });
  });
}

test("checkInventory forwards a downstream 200 as 200", async () => {
  await withDownstream(200, "in stock", async () => {
    const result = await checkInventory("sku-1");
    expect(result.status).toBe(200);
    expect(result.body).toBe("in stock");
  });
});

test("checkInventory forwards a downstream non-200 status instead of masking it as 200", async () => {
  await withDownstream(404, "sku not found", async () => {
    const result = await checkInventory("missing-sku");
    expect(result.status).toBe(404);
    expect(result.body).toBe("sku not found");
  });
});

test("checkInventory forwards a downstream 500 as 500", async () => {
  await withDownstream(500, "downstream error", async () => {
    const result = await checkInventory("sku-2");
    expect(result.status).toBe(500);
    expect(result.body).toBe("downstream error");
  });
});
