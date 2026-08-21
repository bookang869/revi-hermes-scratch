const { bulkDiscount } = require("./discount");

test("applies 10% bulk discount to orders of exactly 10 units", () => {
  expect(bulkDiscount(100, 10)).toBe(900);
});

test("applies 10% bulk discount to orders of more than 10 units", () => {
  expect(bulkDiscount(100, 11)).toBe(990);
});

test("does not apply bulk discount to orders below 10 units", () => {
  expect(bulkDiscount(100, 9)).toBe(900);
});
