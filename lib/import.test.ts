import {test, expect} from "bun:test";
import {importLibrary} from "./import.mjs";

const one = (path: string, text: string) => {
  const r = importLibrary([{path, text}]);
  expect(r.prompts).toHaveLength(1);
  return {r, p: r.prompts[0]};
};

test("thematic break fixture: --- + prose + --- = header, prose errors, body follows", () => {
  const {r, p} = one("prompts/c/t.md", "---\nprose line one\n---\nBody.\n");
  expect(p.body).toBe("Body.\n");
  expect(p.title).toBe("t");
  expect(r.errors.map((e) => e.line)).toContain(2);
});

test("empty-header escape: a body starting with --- survives verbatim", () => {
  const body = "---\nexample:\n  - yaml\n";
  const {r, p} = one("prompts/c/y.md", "---\n---\n" + body);
  expect(p.body).toBe(body);
  expect(r.errors).toEqual([]);
});

test("unclosed --- is all body plus an unclosed error", () => {
  const {r, p} = one("prompts/c/u.md", "---\ntitle: t\nbody never closes");
  expect(p.body).toBe("---\ntitle: t\nbody never closes");
  expect(r.errors).toHaveLength(1);
  expect(r.errors[0].line).toBe(1);
  expect(r.errors[0].message).toMatch(/unclosed/i);
});

test("title with ': ' must be quoted; unquoted ': ' errors and title defaults", () => {
  const q = one("prompts/c/q.md", '---\ntitle: "Fix: the thing #2"\n---\nB');
  expect(q.p.title).toBe("Fix: the thing #2");
  expect(q.r.errors).toEqual([]);

  const u = one("prompts/c/u2.md", "---\ntitle: Fix: the thing\n---\nB");
  expect(u.p.title).toBe("u2");
  expect(u.r.errors.map((e) => e.line)).toContain(2);
});

test("comment stripping requires a space before #", () => {
  const {r, p} = one("prompts/c/h.md", "---\ntitle: A # trailing\ndescription: 'keep # this'\n---\nB");
  expect(p.title).toBe("A");
  expect(p.description).toBe("keep # this");
  expect(r.errors).toEqual([]);
});

test("description: | is an unsupported known key; title still parses", () => {
  const {r, p} = one(
    "prompts/c/d.md",
    "---\ndescription: |\n  folded text here\ntitle: t\n---\nB",
  );
  expect(p.title).toBe("t");
  expect(p.description).toBeNull();
  expect(r.errors.map((e) => e.line)).toContain(2);
  expect(r.errors.map((e) => e.line)).toContain(3);
});

test("BOM then leading blank lines means no header; BOM is stripped, body verbatim", () => {
  const {r, p} = one("prompts/c/bom.md", "\uFEFF\n\r\n---\r\ntitle: X\r\n---\r\nbody");
  expect(p.body).toBe("\n\r\n---\r\ntitle: X\r\n---\r\nbody");
  expect(p.title).toBe("bom");
  expect(r.errors).toEqual([]);
});

test("BOM without a header leaves body unchanged after stripping", () => {
  const {r, p} = one("prompts/c/nb.md", "\uFEFFbody text\nmore");
  expect(p.body).toBe("body text\nmore");
  expect(p.title).toBe("nb");
  expect(r.errors).toEqual([]);
});

test("BOM before a CRLF header parses, body keeps CRLF and no final newline", () => {
  const {r, p} = one("prompts/c/cr.md", "\uFEFF---\r\ntitle: X\r\n---\r\nbody\r\nend");
  expect(p.title).toBe("X");
  expect(p.body).toBe("body\r\nend");
  expect(r.errors).toEqual([]);
});

test("duplicate title: first wins, second gets an error", () => {
  const {r, p} = one("prompts/c/dup.md", "---\ntitle: one\ntitle: two\n---\nB");
  expect(p.title).toBe("one");
  expect(r.errors).toHaveLength(1);
  expect(r.errors[0].line).toBe(3);
  expect(r.errors[0].message).toMatch(/duplicate/i);
});

test("mixed-type flow tags coerce to strings and drop duplicates", () => {
  const {r, p} = one("prompts/c/mix.md", '---\ntags: [a, 2, "b c", a]\n---\nB');
  expect(p.tags).toEqual(["a", "2", "b c"]);
  expect(r.errors).toEqual([]);
});

test("indentless and indented block tags, plus a single scalar tag", () => {
  const {r, p} = one("prompts/c/blk.md", "---\ntags:\n- a\n  - b\n---\nB");
  expect(p.tags).toEqual(["a", "b"]);
  expect(r.errors).toEqual([]);

  const s = one("prompts/c/s.md", "---\ntags: one\n---\nB");
  expect(s.p.tags).toEqual(["one"]);
});

test("paths: category and optional subcategory, deeper errors, rest ignored", () => {
  const r = importLibrary([
    {path: "prompts/code/review.md", text: "b1"},
    {path: "prompts/code/lint/eslint.md", text: "b2"},
    {path: "prompts/code/lint/x/deep.md", text: "b3"},
    {path: "prompts/loose.md", text: "b4"},
    {path: "docs/readme.md", text: "b5"},
    {path: "README.md", text: "b6"},
    {path: "prompts/code/notes.txt", text: "b7"},
    {path: "prompts/code/UP.MD", text: "b8"},
  ]);
  expect(r.prompts.map((p) => p.id)).toEqual([
    "prompts/code/review.md",
    "prompts/code/lint/eslint.md",
  ]);
  expect(r.prompts[0].category).toBe("code");
  expect(r.prompts[0].subcategory).toBeNull();
  expect(r.prompts[0].fileName).toBe("review.md");
  expect(r.prompts[1].subcategory).toBe("lint");
  expect(r.errors).toHaveLength(2);
  expect(r.errors.map((e) => e.path).sort()).toEqual([
    "prompts/code/lint/x/deep.md",
    "prompts/loose.md",
  ]);
  expect(r.errors.every((e) => e.line === null)).toBe(true);
});

test("a prompt carries names and precomputed folded search fields", () => {
  const {p} = one(
    "prompts/code/lint/x.md",
    '---\ntitle: Ćevap Tč\ntags: [Rěd]\n---\nsay {{A}} then {{B}}',
  );
  expect(p.names).toEqual(["A", "B"]);
  expect(p.search.title).toBe("cevap tc");
  expect(p.search.fileName).toBe("x");
  expect(p.search.tags).toEqual(["red"]);
  expect(p.search.category).toBe("code");
  expect(p.search.subcategory).toBe("lint");
  expect(p.search.body).toBe("say {{a}} then {{b}}");
});

test("unknown metadata continuation lines are ignored without hiding known-key errors", () => {
  const {r, p} = one(
    "prompts/c/example.md",
    "---\nfuture:\n  hint: keep\n  - example\nother:\n- ignored\ntitle: Known\ndescription: |\n---\nBody",
  );
  expect(p.title).toBe("Known");
  expect(p.body).toBe("Body");
  expect(r.errors.map((e) => e.line)).toEqual([8]);
});

test("comments after empty metadata values stay absent and block tags still parse", () => {
  const {r, p} = one(
    "prompts/c/example.md",
    "---\ntitle: # comment\ndescription: # comment\ntags: # labels\n- useful\n---\nBody",
  );
  expect(p.title).toBe("example");
  expect(p.description).toBeNull();
  expect(p.tags).toEqual(["useful"]);
  expect(r.errors).toEqual([]);
});
