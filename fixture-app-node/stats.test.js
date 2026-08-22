const { averageOrderValue } = require("./stats");

describe("averageOrderValue", () => {
  it("returns 0 for an empty list of orders", () => {
    expect(averageOrderValue([])).toBe(0);
  });

  it("computes the average of a list of order amounts", () => {
    expect(averageOrderValue([10, 20, 30])).toBe(20);
  });

  it("handles a single order", () => {
    expect(averageOrderValue([42])).toBe(42);
  });
});
