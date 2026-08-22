const { validateOrder, maxOrderAmount, DEFAULT_MAX_ORDER_AMOUNT } = require('./config');

describe('config MAX_ORDER_AMOUNT handling', () => {
  const originalEnv = process.env.MAX_ORDER_AMOUNT;

  afterEach(() => {
    if (originalEnv === undefined) {
      delete process.env.MAX_ORDER_AMOUNT;
    } else {
      process.env.MAX_ORDER_AMOUNT = originalEnv;
    }
  });

  test('falls back to documented default when MAX_ORDER_AMOUNT is invalid (non-numeric)', () => {
    process.env.MAX_ORDER_AMOUNT = 'not-a-number';
    expect(maxOrderAmount()).toBe(DEFAULT_MAX_ORDER_AMOUNT);
    // Before the fix, parseInt('not-a-number', 10) -> NaN, and every
    // `amount <= NaN` comparison is false, silently rejecting all orders.
    expect(validateOrder(1)).toBe(true);
    expect(validateOrder(DEFAULT_MAX_ORDER_AMOUNT)).toBe(true);
  });

  test('falls back to documented default when MAX_ORDER_AMOUNT is unset', () => {
    delete process.env.MAX_ORDER_AMOUNT;
    expect(maxOrderAmount()).toBe(DEFAULT_MAX_ORDER_AMOUNT);
    expect(validateOrder(DEFAULT_MAX_ORDER_AMOUNT)).toBe(true);
  });

  test('falls back to documented default when MAX_ORDER_AMOUNT is empty string', () => {
    process.env.MAX_ORDER_AMOUNT = '';
    expect(maxOrderAmount()).toBe(DEFAULT_MAX_ORDER_AMOUNT);
  });

  test('uses a valid numeric MAX_ORDER_AMOUNT when provided', () => {
    process.env.MAX_ORDER_AMOUNT = '500';
    expect(maxOrderAmount()).toBe(500);
    expect(validateOrder(500)).toBe(true);
    expect(validateOrder(501)).toBe(false);
  });
});
