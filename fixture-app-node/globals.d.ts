// Minimal ambient declarations so `tsc --noEmit` can type-check this
// fixture's CommonJS + Jest globals without needing @types/node or
// @types/jest as network-fetched devDependencies (Dockerfile installs the
// jest/eslint/typescript *tools* globally, but not their .d.ts packages --
// this keeps the gate self-contained the same way go/cargo need no
// external dependency to build the fixture apps).
declare function require(id: string): any;
declare const module: { exports: any };
// Same TS2591-style gap as require()/module above, hit for the first time
// authoring the Part B fault corpus (config.js/inventory.js's process.env
// reads) -- no @types/node means no ambient `process` global either.
declare const process: any;

// TypeScript special-cases require() calls whose argument string literal
// matches a known Node core module name (e.g. "http") and emits a
// @types/node hint (TS2591) regardless of the generic `require` signature
// above -- an explicit ambient module short-circuits that resolution path.
declare module "http";

declare function test(name: string, fn: () => void): void;
declare function expect(actual: any): {
  toBe(expected: any): void;
};
