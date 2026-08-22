const { validateOrder, maxOrderAmount } = require('./config');

describe('maxOrderAmount', () => {
  const ORIGINAL_ENV = process.env.MAX_ORDER_AMOUNT;

  afterEach(() => {
    if (ORIGINAL_ENV === undefined) {
      delete process.env.MAX_ORDER_AMOUNT;
    } else {
      process.env.MAX_ORDER_AMOUNT = ORIGINAL_ENV;
    }
  });

  test('falls back to the documented default of 100000 when unset', () => {
    delete process.env.MAX_ORDER_AMOUNT;
    expect(maxOrderAmount()).toBe(100000);
  });

  test('falls back to the documented default of 100000 when invalid (non-numeric)', () => {
    process.env.MAX_ORDER_AMOUNT = 'not-a-number';
    expect(maxOrderAmount()).toBe(100000);
  });

  test('uses a valid numeric override when provided', () => {
    process.env.MAX_ORDER_AMOUNT = '500';
    expect(maxOrderAmount()).toBe(500);
  });

  test('validateOrder does not silently reject every order when MAX_ORDER_AMOUNT is invalid', () => {
    process.env.MAX_ORDER_AMOUNT = 'garbage';
    expect(validateOrder(50000)).toBe(true);
    expect(validateOrder(100000)).toBe(true);
    expect(validateOrder(100001)).toBe(false);
  });
});
