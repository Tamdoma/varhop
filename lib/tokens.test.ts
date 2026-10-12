import {test, expect} from "bun:test";
import {splitSegments, uniqueNames} from "./tokens.mjs";

type Seg = {kind: "text"; text: string} | {kind: "token"; name: string; raw: string};

const joined = (segs: Seg[]): string =>
  segs.map((s) => (s.kind === "text" ? s.text : s.raw)).join("");

test("splits a body into text and token segments", () => {
  expect(splitSegments("hi {{NAME}} bye")).toEqual([
    {kind: "text", text: "hi "},
    {kind: "token", name: "NAME", raw: "{{NAME}}"},
    {kind: "text", text: " bye"},
  ]);
});

test("token names allow digits and underscores anywhere", () => {
  const segs = splitSegments("{{A1_2}} {{1}} {{_X}}") as Seg[];
  expect(segs.filter((s) => s.kind === "token").map((s) => (s as {name: string}).name)).toEqual([
    "A1_2",
    "1",
    "_X",
  ]);
});

test("{{{NAME}}} is literal brace, token, literal brace", () => {
  expect(splitSegments("{{{NAME}}}")).toEqual([
    {kind: "text", text: "{"},
    {kind: "token", name: "NAME", raw: "{{NAME}}"},
    {kind: "text", text: "}"},
  ]);
});

test("tokens inside code fences count", () => {
  const segs = splitSegments("```\n{{INSIDE_FENCE}}\n```") as Seg[];
  expect(segs.some((s) => s.kind === "token" && s.name === "INSIDE_FENCE")).toBe(true);
});

test("an escaped \\{{NAME}} becomes a text segment holding the literal", () => {
  const segs = splitSegments("a \\{{NAME}} b") as Seg[];
  expect(segs.every((s) => s.kind === "text")).toBe(true);
  expect(joined(segs)).toBe("a {{NAME}} b");
});

test("backslash is removed only before a valid token", () => {
  expect(joined(splitSegments("a \\{{abc}} b") as Seg[])).toBe("a \\{{abc}} b");
  expect(joined(splitSegments("a \\{{NA-ME}} b") as Seg[])).toBe("a \\{{NA-ME}} b");
  expect(joined(splitSegments("a \\x{{T}} b") as Seg[])).toBe("a \\x{{T}} b");
});

test("lowercase and malformed braces stay literal", () => {
  for (const bad of ["{{abc}}", "{{Name}}", "{{NAME", "{NAME}", "{{}}", "{{NA ME}}", "{{NA-ME}}"]) {
    const segs = splitSegments(bad) as Seg[];
    expect(segs.every((s) => s.kind === "text")).toBe(true);
    expect(joined(segs)).toBe(bad);
  }
});

test("uniqueNames lists names in first-appearance order", () => {
  expect(uniqueNames("x {{B}} y {{A}} z {{B}}")).toEqual(["B", "A"]);
  expect(uniqueNames("no tokens")).toEqual([]);
});
