import {test, expect} from "bun:test";
import {importLibrary} from "./import.mjs";
import {fold, rank, DISPLAY_CHUNK} from "./search.mjs";
import {resetUsage, recordCopy} from "./usage.mjs";

type Fields = {
  path?: string;
  title?: string;
  description?: string | null;
  tags?: string[];
  body?: string;
};

const NO_USAGE = resetUsage();
const NOW = 1_700_000_000_000;

const prompt = (f: Fields) => {
  const path = f.path ?? "prompts/c/p.md";
  const stem = path.slice(path.lastIndexOf("/") + 1, -3);
  const lines = ["---"];
  if (f.title !== undefined && f.title !== stem) lines.push(`title: ${JSON.stringify(f.title)}`);
  if (f.description !== undefined && f.description !== null)
    lines.push(`description: ${JSON.stringify(f.description)}`);
  if (f.tags !== undefined) lines.push(`tags: [${f.tags.map((t) => JSON.stringify(t)).join(", ")}]`);
  lines.push("---", f.body ?? "");
  const r = importLibrary([{path, text: lines.join("\n")}]);
  if (r.prompts.length !== 1) throw new Error(`fixture ${path} did not import: ${JSON.stringify(r.errors)}`);
  return r.prompts[0];
};

const order = (prompts: ReturnType<typeof prompt>[], query: string, usage = NO_USAGE) =>
  rank(prompts, query, usage, NOW).map((r) => r.id);

test("fold lowercases and strips diacritics, đ folds to d", () => {
  expect(fold("Đorđe")).toBe("dorde");
  expect(fold("č Ž Š Ć Đ")).toBe("c z s c d");
  expect(fold("ÁbC")).toBe("abc");
});

test("a folded query matches diacritics in the library", () => {
  const a = prompt({path: "prompts/c/a.md", title: "Đorđe notes"});
  const b = prompt({path: "prompts/c/b.md", title: "plain"});
  expect(order([a, b], "dorde")).toEqual([a.id]);
});

test("terms are ANDed: every term must match some field", () => {
  const a = prompt({path: "prompts/c/a.md", title: "alpha beta"});
  const b = prompt({path: "prompts/c/b.md", title: "alpha only"});
  expect(order([a, b], "alpha beta")).toEqual([a.id]);
});

test("field weights run title > file name > tags > category/subcategory > description", () => {
  const term = "zqx";
  const title = prompt({path: "prompts/misc/pt.md", title: `has ${term}`});
  const file = prompt({path: `prompts/misc/${term}.md`});
  const tag = prompt({path: "prompts/misc/pg.md", tags: [term]});
  const cat = prompt({path: `prompts/${term}/pc.md`});
  const sub = prompt({path: `prompts/other/${term}/pd.md`});
  const desc = prompt({path: "prompts/misc/pe.md", description: `has ${term}`});
  const all = [desc, sub, cat, tag, file, title];
  const o = order(all, term);
  expect(o).toHaveLength(6);
  expect(o).toEqual([title.id, file.id, tag.id, cat.id, sub.id, desc.id]);
  expect(scoreOf(all, term, cat.id)).toBe(scoreOf(all, term, sub.id));
});

const scoreOf = (prompts: ReturnType<typeof prompt>[], query: string, id: string) =>
  rank(prompts, query, NO_USAGE, NOW).find((r) => r.id === id)?.score;

test("fzf-V1 shape: tight subsequence beats scattered, no typo tolerance", () => {
  const tight = prompt({path: "prompts/c/rev.md", title: "Code Review"});
  const scattered = prompt({path: "prompts/c/s.md", title: "cut dinner rolls"});
  const o = order([scattered, tight], "cdr");
  expect(o).toEqual([tight.id, scattered.id]);
  expect(order([tight], "cdoe")).toEqual([]);
});

test("queries and fields match case-insensitively", () => {
  const a = prompt({path: "prompts/c/a.md", title: "Code Review"});
  expect(order([a], "CODE")).toEqual([a.id]);
});

test("body tier: terms of 3+ chars match folded body when structured hits are few", () => {
  const bodyHit = prompt({path: "prompts/c/b.md", title: "unrelated", body: "the quixotic path\nsecond line"});
  const structured = prompt({path: "prompts/c/s.md", title: "quixotic guide"});
  const rows = rank([bodyHit, structured], "quixotic", NO_USAGE, NOW);
  expect(rows.map((r) => r.id)).toEqual([structured.id, bodyHit.id]);
  const bodyRow = rows[1];
  expect(bodyRow.matchedField).toBe("body");
  expect(bodyRow.snippet).toBe("the quixotic path");
});

test("terms shorter than 3 characters never reach the body", () => {
  const bodyHit = prompt({path: "prompts/c/b.md", title: "unrelated", body: "up and away"});
  expect(order([bodyHit], "up")).toEqual([]);
});

test("body tier is skipped once structured matches fill the display chunk", () => {
  const term = "needleword";
  const structured = Array.from({length: DISPLAY_CHUNK}, (_, i) =>
    prompt({path: `prompts/c/s${i}.md`, title: `${term} ${i}`}),
  );
  const bodyHit = prompt({path: "prompts/c/b.md", title: "other", body: `has ${term} inside`});
  expect(DISPLAY_CHUNK).toBe(50);
  const rows = rank([...structured, bodyHit], term, NO_USAGE, NOW);
  expect(rows).toHaveLength(DISPLAY_CHUNK);
  expect(rows.some((r) => r.id === bodyHit.id)).toBe(false);
});

test("frecency reorders only within equal relevance", () => {
  const stale = prompt({path: "prompts/c/dup.md", title: "repeat me"});
  const used = prompt({path: "prompts/z/dup.md", title: "repeat me"});
  let usage = recordCopy(NO_USAGE, used.id, NOW - 1000);
  expect(order([stale, used], "repeat me", usage)).toEqual([used.id, stale.id]);

  const titleHit = prompt({path: "prompts/c/t.md", title: "needle term"});
  const descHit = prompt({path: "prompts/c/d.md", description: "needle term"});
  usage = recordCopy(NO_USAGE, descHit.id, NOW - 1000);
  expect(order([titleHit, descHit], "needle term", usage)).toEqual([titleHit.id, descHit.id]);
});

test("empty query: up to 10 recent copies by recency, then library by category", () => {
  const lib = [
    prompt({path: "prompts/b/x.md", title: "bx"}),
    prompt({path: "prompts/a/y.md", title: "ay"}),
    prompt({path: "prompts/a/sub/z.md", title: "az"}),
    prompt({path: "prompts/a/sub/a.md", title: "aa"}),
    prompt({path: "prompts/c/w.md", title: "cw"}),
  ];
  const byCategory = [
    "prompts/a/sub/a.md",
    "prompts/a/y.md",
    "prompts/a/sub/z.md",
    "prompts/b/x.md",
    "prompts/c/w.md",
  ];
  expect(order(lib, "")).toEqual(byCategory);

  let usage = NO_USAGE;
  usage = recordCopy(usage, "prompts/c/w.md", NOW - 5000);
  usage = recordCopy(usage, "prompts/a/y.md", NOW - 1000);
  expect(order(lib, "", usage)).toEqual([
    "prompts/a/y.md",
    "prompts/c/w.md",
    "prompts/a/sub/a.md",
    "prompts/a/sub/z.md",
    "prompts/b/x.md",
  ]);
});

test("empty query caps the recent section at 10", () => {
  const lib = Array.from({length: 12}, (_, i) =>
    prompt({path: `prompts/c/p${String(i).padStart(2, "0")}.md`, title: `p${i}`}),
  );
  let usage = NO_USAGE;
  lib.forEach((p, i) => {
    usage = recordCopy(usage, p.id, NOW - (12 - i) * 1000);
  });
  const rows = rank(lib, "", usage, NOW).map((r) => r.id);
  const recent = lib.slice(-10).map((p) => p.id).reverse();
  expect(rows.slice(0, 10)).toEqual(recent);
  expect(rows.slice(10)).toEqual(["prompts/c/p00.md", "prompts/c/p01.md"]);
});
