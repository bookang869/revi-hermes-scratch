const { summarize } = require("./order");

describe("summarize", () => {
  test("does not throw and returns a fallback when order has no customer", () => {
    const order = { amount: 42 };
    expect(() => summarize(order)).not.toThrow();
    expect(summarize(order)).toBe("Unknown owes 42");
  });

  test("uses the customer name when a customer is present", () => {
    const order = { customer: { name: "Ada" }, amount: 10 };
    expect(summarize(order)).toBe("Ada owes 10");
  });
});
