const { summarize } = require("./order");

describe("summarize", () => {
  it("returns a summary when the customer is present", () => {
    const order = { customer: { name: "Ada" }, amount: 42 };
    expect(summarize(order)).toBe("Ada owes 42");
  });

  it("does not throw when the customer is missing", () => {
    const order = { amount: 15 };
    expect(() => summarize(order)).not.toThrow();
    expect(summarize(order)).toBe("Unknown customer owes 15");
  });
});
