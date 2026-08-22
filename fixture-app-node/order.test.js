const { summarize } = require("./order");

describe("summarize", () => {
  it("does not throw when order has no customer", () => {
    const order = { amount: 42 };
    expect(() => summarize(order)).not.toThrow();
    expect(summarize(order)).toBe("Unknown customer owes 42");
  });

  it("includes the customer name when customer is present", () => {
    const order = { customer: { name: "Alice" }, amount: 10 };
    expect(summarize(order)).toBe("Alice owes 10");
  });
});
