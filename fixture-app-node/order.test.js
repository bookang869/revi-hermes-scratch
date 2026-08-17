const { summarize } = require("./order");

test("summarize with no customer", () => {
  expect(summarize({ amount: 42 })).toBe("unknown customer owes 42");
});
