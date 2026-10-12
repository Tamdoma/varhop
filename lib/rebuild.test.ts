import {test, expect} from "bun:test";
import {splitSegments} from "./tokens.mjs";
import {rebuild} from "./rebuild.mjs";

const build = (body: string, values: Record<string, string>) =>
  rebuild(splitSegments(body), values);

test("with no values the body is reproduced exactly and every name is unset", () => {
  const r = build("line1\nline2 {{A}} tail\n", {});
  expect(r.text).toBe("line1\nline2 {{A}} tail\n");
  expect(r.unset).toEqual(["A"]);
});

test("a CRLF body with no final newline round-trips", () => {
  const r = build("a\r\n{{X}}\r\nend", {});
  expect(r.text).toBe("a\r\n{{X}}\r\nend");
  expect(r.unset).toEqual(["X"]);
});

test("escapes come out as literal {{NAME}} and are not unset names", () => {
  const r = build("e \\{{E}} t {{T}}", {});
  expect(r.text).toBe("e {{E}} t {{T}}");
  expect(r.unset).toEqual(["T"]);
});

test("every occurrence of a name gets its value", () => {
  const r = build("{{A}} and {{B}} and {{A}}", {A: "1", B: "two"});
  expect(r.text).toBe("1 and two and 1");
  expect(r.unset).toEqual([]);
});

test("a value containing {{OTHER}} is inserted literally", () => {
  const r = build("{{A}}!", {A: "{{OTHER}}"});
  expect(r.text).toBe("{{OTHER}}!");
  expect(r.unset).toEqual([]);
});

test("an empty string is a set value, not unset", () => {
  const r = build("x{{A}}y", {A: ""});
  expect(r.text).toBe("xy");
  expect(r.unset).toEqual([]);
});

test("unset names are reported in first-appearance order", () => {
  const r = build("{{B}} {{A}} {{B}}", {A: "v"});
  expect(r.text).toBe("{{B}} v {{B}}");
  expect(r.unset).toEqual(["B"]);
});
