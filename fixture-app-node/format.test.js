const { formatOrder } = require("./format");

describe("formatOrder", () => {
  test("rejects negative amounts with 400", () => {
    const { status, body } = formatOrder(-5);
    expect(status).toBe(400);
    const parsed = JSON.parse(body);
    expect(parsed.amount).toBeUndefined();
    expect(parsed.error).toBeDefined();
  });

  test("accepts zero amount with 200", () => {
    const { status, body } = formatOrder(0);
    expect(status).toBe(200);
    expect(JSON.parse(body)).toEqual({ amount: 0, currency: "USD" });
  });

  test("accepts positive amount with 200 and echoes it back", () => {
    const { status, body } = formatOrder(42);
    expect(status).toBe(200);
    expect(JSON.parse(body)).toEqual({ amount: 42, currency: "USD" });
  });
});
