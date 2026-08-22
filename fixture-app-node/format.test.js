const { formatOrder } = require("./format");

describe("formatOrder", () => {
  test("rejects negative amounts with 400", () => {
    const { status, body } = formatOrder(-5);
    expect(status).toBe(400);
    const parsed = JSON.parse(body);
    expect(parsed.amount).toBeUndefined();
  });

  test("accepts non-negative amounts with 200 and echoes them back", () => {
    const { status, body } = formatOrder(42);
    expect(status).toBe(200);
    const parsed = JSON.parse(body);
    expect(parsed.amount).toBe(42);
    expect(parsed.currency).toBe("USD");
  });

  test("accepts zero amount with 200", () => {
    const { status, body } = formatOrder(0);
    expect(status).toBe(200);
    const parsed = JSON.parse(body);
    expect(parsed.amount).toBe(0);
  });
});
