const http = require("http");
const { EventEmitter } = require("events");

jest.mock("http");

const { checkInventory } = require("./inventory");

/**
 * Builds a fake http.get that immediately invokes the response callback
 * with a fake IncomingMessage-like EventEmitter carrying the given
 * statusCode, then emits the given chunks and an "end" event.
 */
function mockHttpGet(statusCode, chunks) {
  http.get.mockImplementation((_url, callback) => {
    const resp = new EventEmitter();
    resp.statusCode = statusCode;
    callback(resp);
    process.nextTick(() => {
      for (const chunk of chunks) {
        resp.emit("data", chunk);
      }
      resp.emit("end");
    });
    // Return a fake request object supporting .on("error", ...)
    return new EventEmitter();
  });
}

describe("checkInventory", () => {
  afterEach(() => {
    jest.resetAllMocks();
  });

  test("forwards a non-200 downstream response as-is, not as a 200", async () => {
    mockHttpGet(503, ["inventory service down"]);

    const result = await checkInventory("sku-123");

    expect(result.status).toBe(503);
    expect(result.status).not.toBe(200);
    expect(result.body).toBe("inventory service down");
  });

  test("forwards a 404 downstream response as-is", async () => {
    mockHttpGet(404, ["not found"]);

    const result = await checkInventory("missing-sku");

    expect(result.status).toBe(404);
    expect(result.body).toBe("not found");
  });

  test("still forwards a genuine 200 downstream response", async () => {
    mockHttpGet(200, ["in stock"]);

    const result = await checkInventory("sku-ok");

    expect(result.status).toBe(200);
    expect(result.body).toBe("in stock");
  });
});
