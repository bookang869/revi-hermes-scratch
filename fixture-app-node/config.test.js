const { validateOrder } = require("./config");

describe("validateOrder / maxOrderAmount fallback", () => {
  const ORIGINAL_ENV = process.env.MAX_ORDER_AMOUNT;

  afterEach(() => {
    if (ORIGINAL_ENV === undefined) {
      delete process.env.MAX_ORDER_AMOUNT;
    } else {
      process.env.MAX_ORDER_AMOUNT = ORIGINAL_ENV;
    }
  });

  test("falls back to documented default (100000) when MAX_ORDER_AMOUNT is invalid/non-numeric", () => {
    process.env.MAX_ORDER_AMOUNT = "not-a-number";

    // An order within the documented default should be allowed, not
    // silently rejected because maxOrderAmount() resolved to NaN.
    expect(validateOrder(50000)).toBe(true);
    expect(validateOrder(100000)).toBe(true);
    expect(validateOrder(100001)).toBe(false);
  });

  test("falls back to documented default (100000) when MAX_ORDER_AMOUNT is unset", () => {
    delete process.env.MAX_ORDER_AMOUNT;

    expect(validateOrder(100000)).toBe(true);
    expect(validateOrder(100001)).toBe(false);
  });

  test("uses a valid MAX_ORDER_AMOUNT override when provided", () => {
    process.env.MAX_ORDER_AMOUNT = "500";

    expect(validateOrder(500)).toBe(true);
    expect(validateOrder(501)).toBe(false);
  });
});
