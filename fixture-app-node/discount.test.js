const { bulkDiscount } = require("./discount");

describe("bulkDiscount", () => {
  test("applies 10% discount to orders of exactly 10 units", () => {
    // unitPrice=100, qty=10 -> total=1000, discounted=900
    expect(bulkDiscount(100, 10)).toBe(900);
  });

  test("applies 10% discount to orders of more than 10 units", () => {
    // unitPrice=100, qty=12 -> total=1200, discounted=1080
    expect(bulkDiscount(100, 12)).toBe(1080);
  });

  test("does not discount orders under 10 units", () => {
    // unitPrice=100, qty=9 -> total=900, no discount applied
    expect(bulkDiscount(100, 9)).toBe(900);
  });
});
