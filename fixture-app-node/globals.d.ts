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

// Jest surface. Originally just test()/expect().toBe() -- too narrow: real
// Hermes runs (2026-08-21 Node Stage 1) wrote describe()/it()/lifecycle
// hooks and matchers beyond toBe() (e.g. .not.toBeUndefined(), .toEqual())
// in 5 of 8 faults, and tsc rejected all of them with "Cannot find name"
// even though the tests were otherwise correct -- a fixture typing gap
// misreported as an EXHAUSTION, not a real Hermes failure. Considered
// vendoring the real @types/jest package instead of expanding this by
// hand; rejected after testing it for real: it pulls in a ~10MB transitive
// closure (expect, pretty-format, jest-diff, @babel/*, @jest/*, @types/node)
// and produced outright syntax errors against this repo's TypeScript
// version, since the Dockerfile's `npm install -g typescript` is unpinned
// and could drift out of sync with whatever @types/node version got
// vendored -- a worse, harder-to-diagnose failure mode (breaks the gate for
// every fault, not just one) than this file occasionally missing an
// identifier (a clean, one-line-fixable TS2593/TS2339 naming exactly what's
// missing). Extend this list if a future fault's Hermes-authored test hits
// another gap -- that failure mode is expected and cheap to fix, not a sign
// this approach is wrong.
declare function describe(name: string, fn: () => void): void;
declare function it(name: string, fn: () => void): void;
declare function test(name: string, fn: () => void): void;
declare function beforeEach(fn: () => void): void;
declare function afterEach(fn: () => void): void;
declare function beforeAll(fn: () => void): void;
declare function afterAll(fn: () => void): void;
interface JestMatchers {
  toBe(expected: any): void;
  toEqual(expected: any): void;
  toBeNull(): void;
  toBeUndefined(): void;
  toBeDefined(): void;
  toBeTruthy(): void;
  toBeFalsy(): void;
  toContain(expected: any): void;
  toThrow(expected?: any): void;
  toHaveLength(expected: number): void;
  not: JestMatchers;
}
declare function expect(actual: any): JestMatchers;
