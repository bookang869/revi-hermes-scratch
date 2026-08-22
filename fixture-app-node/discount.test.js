const { bulkDiscount } = require("./discount");

test("applies 10% bulk discount to orders of exactly 10 units", () => {
  // unitPrice=100, qty=10 -> total=1000, discounted = floor(1000*0.9) = 900
  expect(bulkDiscount(100, 10)).toBe(900);
});

test("applies 10% bulk discount to orders above 10 units", () => {
  expect(bulkDiscount(100, 11)).toBe(990);
});

test("does not apply discount to orders below 10 units", () => {
  expect(bulkDiscount(100, 9)).toBe(900);
});
