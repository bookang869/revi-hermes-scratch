const { averageOrderValue } = require('./stats');

test('averageOrderValue computes the mean of order totals', () => {
  expect(averageOrderValue([10, 20, 30])).toBe(20);
});

test('averageOrderValue returns 0 for an empty list', () => {
  expect(averageOrderValue([])).toBe(0);
});
