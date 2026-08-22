const { formatOrder } = require("./format");

describe("formatOrder", () => {
  test("rejects negative amounts with 400", () => {
    const { status, body } = formatOrder(-5);
    expect(status).toBe(400);
    expect(body).not.toContain("-5");
  });

  test("accepts non-negative amounts with 200 and echoes them back", () => {
    const { status, body } = formatOrder(42);
    expect(status).toBe(200);
    expect(JSON.parse(body)).toEqual({ amount: 42, currency: "USD" });
  });
});
