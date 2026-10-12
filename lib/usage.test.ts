import {test, expect} from "bun:test";
import {recordCopy, resetUsage, parseUsage, HALF_LIFE_MS} from "./usage.mjs";

const T0 = 1_700_000_000_000;

test("HALF_LIFE_MS is 14 days in milliseconds", () => {
  expect(HALF_LIFE_MS).toBe(14 * 24 * 60 * 60 * 1000);
});

test("resetUsage returns an empty v1 state", () => {
  expect(resetUsage()).toEqual({version: 1, entries: {}});
});

test("recordCopy on an empty state starts the entry at score 1", () => {
  const s = recordCopy(resetUsage(), "prompts/c/a.md", T0);
  expect(s).toEqual({version: 1, entries: {"prompts/c/a.md": {score: 1, last: T0}}});
});

test("a repeat copy one half-life later decays the stored score by half", () => {
  const s1 = recordCopy(resetUsage(), "id/a", T0);
  const s2 = recordCopy(s1, "id/a", T0 + HALF_LIFE_MS);
  expect(s2.entries["id/a"].score).toBeCloseTo(1.5, 10);
  expect(s2.entries["id/a"].last).toBe(T0 + HALF_LIFE_MS);
});

test("recordCopy does not decay untouched entries and does not mutate its input", () => {
  const s1 = recordCopy(resetUsage(), "id/a", T0);
  const before = JSON.stringify(s1);
  const s2 = recordCopy(s1, "id/b", T0 + 2 * HALF_LIFE_MS);
  expect(s2.entries["id/a"].score).toBe(1);
  expect(s2.entries["id/a"].last).toBe(T0);
  expect(JSON.stringify(s1)).toBe(before);
});

test("parseUsage accepts a serialized state", () => {
  const s = {version: 1, entries: {"id/a": {score: 2.5, last: T0}}};
  expect(parseUsage(JSON.stringify(s))).toEqual({state: s});
});

test("parseUsage rejects malformed JSON and wrong shapes with an error", () => {
  for (const bad of [
    "not json {",
    "{}",
    JSON.stringify({version: 2, entries: {}}),
    JSON.stringify({version: 1, entries: {"id/a": {score: "x", last: 1}}}),
    JSON.stringify({version: 1, entries: {"id/a": {score: 1}}}),
    JSON.stringify({version: 1, entries: [1, 2]}),
    JSON.stringify("hello"),
  ]) {
    const r = parseUsage(bad);
    expect(r).toHaveProperty("error");
    expect((r as {error: string}).error.length).toBeGreaterThan(0);
  }
});
