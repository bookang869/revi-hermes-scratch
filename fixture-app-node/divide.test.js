const { divideShare } = require("./divide");

describe("divideShare", () => {
  test("returns null instead of throwing when parts is zero", () => {
    expect(() => divideShare(100, 0)).not.toThrow();
    expect(divideShare(100, 0)).toBeNull();
  });

  test("returns null when parts is negative", () => {
    expect(divideShare(100, -5)).toBeNull();
  });

  test("divides evenly when parts is positive", () => {
    expect(divideShare(100, 4)).toBe(25);
  });
});
