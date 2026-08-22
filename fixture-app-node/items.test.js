const { catalogItem } = require("./items");

describe("catalogItem", () => {
  it("returns the uppercased item for a valid index", () => {
    expect(catalogItem(0)).toBe("WIDGET");
    expect(catalogItem(1)).toBe("GADGET");
    expect(catalogItem(2)).toBe("GIZMO");
  });

  it("returns undefined for an out-of-range index instead of throwing", () => {
    expect(() => catalogItem(99)).not.toThrow();
    expect(catalogItem(99)).toBeUndefined();
  });

  it("returns undefined for a negative index instead of throwing", () => {
    expect(() => catalogItem(-1)).not.toThrow();
    expect(catalogItem(-1)).toBeUndefined();
  });
});
