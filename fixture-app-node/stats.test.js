const { averageOrderValue } = require('./stats');

test('averageOrderValue returns 0 for empty orders', () => {
  expect(averageOrderValue([])).toBe(0);
});

test('averageOrderValue computes the average of order totals', () => {
  expect(averageOrderValue([10, 20, 30])).toBe(20);
});
