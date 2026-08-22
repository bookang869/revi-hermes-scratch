const { catalogItem } = require("./items");

describe("catalogItem", () => {
  test("returns the upper-cased item for a valid index", () => {
    expect(catalogItem(0)).toBe("WIDGET");
    expect(catalogItem(1)).toBe("GADGET");
    expect(catalogItem(2)).toBe("GIZMO");
  });

  test("does not throw and returns undefined for an out-of-range index", () => {
    expect(() => catalogItem(99)).not.toThrow();
    expect(catalogItem(99)).toBeUndefined();
  });

  test("does not throw and returns undefined for a negative index", () => {
    expect(() => catalogItem(-1)).not.toThrow();
    expect(catalogItem(-1)).toBeUndefined();
  });
});
