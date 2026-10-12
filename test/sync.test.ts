import { describe, test, expect } from "bun:test";
import { spawnSync } from "bun";
import {
  mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync,
  readdirSync, symlinkSync, rmSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const ROOT = join(import.meta.dir, "..");
const SYNC = join(ROOT, "bin/varhop-sync");
const FETCH = join(ROOT, "bin/varhop-fetch");

const ACCOUNT = "6634086";
const LOGIN = "ivanjuras";
const REPO_ID = "1416196860";

interface RunOut { code: number; out: string; err: string; json(): any }

function run(cmd: string[], env: Record<string, string> = {}): RunOut {
  const p = spawnSync({
    cmd,
    env: { ...process.env, ...env } as Record<string, string>,
    stdout: "pipe",
    stderr: "pipe",
  });
  const out = p.stdout.toString();
  const err = p.stderr.toString();
  return {
    code: p.exitCode,
    out,
    err,
    json() {
      const lines = out.trim().split("\n").filter((l) => l.trim().length > 0);
      expect(lines.length).toBe(1);
      return JSON.parse(lines[0]);
    },
  };
}

function tmp(prefix: string): string {
  return mkdtempSync(join(tmpdir(), prefix));
}

function git(dir: string, args: string[]): string {
  const p = spawnSync({ cmd: ["git", "-C", dir, ...args], stdout: "pipe", stderr: "pipe" });
  if (p.exitCode !== 0) throw new Error(`git ${args.join(" ")}: ${p.stderr.toString()}`);
  return p.stdout.toString().trim();
}

/** Create a git repo populated from a map of relpath -> content (string | Buffer). */
function makeRepo(files: Record<string, string | Buffer>, extra?: (dir: string) => void): string {
  const dir = tmp("varhop-src-");
  git(dir, ["init", "-q"]);
  git(dir, ["config", "user.email", "t@t"]);
  git(dir, ["config", "user.name", "t"]);
  writeFiles(dir, files);
  extra?.(dir);
  git(dir, ["add", "-A"]);
  git(dir, ["commit", "-qm", "c1"]);
  return dir;
}

function writeFiles(dir: string, files: Record<string, string | Buffer>): void {
  for (const [rel, content] of Object.entries(files)) {
    const abs = join(dir, rel);
    mkdirSync(join(abs, ".."), { recursive: true });
    writeFileSync(abs, content);
  }
}

function commitAll(dir: string, files: Record<string, string | Buffer>, msg = "c2"): string {
  writeFiles(dir, files);
  git(dir, ["add", "-A"]);
  git(dir, ["commit", "-qm", msg]);
  return git(dir, ["rev-parse", "HEAD"]);
}

function fetchArgs(url: string, cache: string, gen: number | string, repoId = REPO_ID): string[] {
  return [FETCH, url, cache, repoId, ACCOUNT, LOGIN, String(gen)];
}

function stagedPath(cache: string, n: number | string): string {
  return join(cache, `staged-${n}.json`);
}

function stagedFiles(cache: string): string[] {
  return existsSync(cache) ? readdirSync(cache).filter((f) => /^staged-\d+\.json$/.test(f)) : [];
}

function readLibrary(cache: string): any {
  return JSON.parse(readFileSync(join(cache, "library.json"), "utf8"));
}

/** sha256-style snapshot of every file under dir: sorted "path=sha" lines. */
function dirSnapshot(dir: string): string[] {
  if (!existsSync(dir)) return [];
  const p = spawnSync({ cmd: ["find", dir, "-type", "f"], stdout: "pipe" });
  return p.stdout.toString().trim().split("\n").filter(Boolean).sort().map((f) => {
    const h = spawnSync({ cmd: ["sha256sum", f], stdout: "pipe" });
    return `${f.slice(dir.length)}=${h.stdout.toString().split(" ")[0]}`;
  });
}

const PROMPTS = {
  "prompts/notes/daily.md": "# Daily\n\nbody {{NAME}}\n",
  "prompts/dev/code/review.md": "review me\n",
};

describe("fetch + accept lifecycle", () => {
  test("fetch stages without touching library; accept publishes; second fetch publishes new commit", () => {
    const src = makeRepo(PROMPTS);
    const cache = tmp("varhop-cache-");
    writeFileSync(join(cache, "library.json"), JSON.stringify({ marker: "keep" }));

    const libBefore = readFileSync(join(cache, "library.json"));
    const r1 = run(fetchArgs(`file://${src}`, cache, 1));
    expect(r1.code).toBe(0);
    const s1 = r1.json();
    expect(s1.status).toBe("ok");
    expect(s1.generation).toBe(1);
    expect(existsSync(stagedPath(cache, 1))).toBe(true);
    expect(readFileSync(join(cache, "library.json"))).toEqual(libBefore);

    const a1 = run([SYNC, "accept", cache, "1"]);
    expect(a1.code).toBe(0);
    expect(a1.json()).toEqual({ accepted: 1 });
    const lib1 = readLibrary(cache);
    expect(lib1.generation).toBe(1);
    expect(lib1.commit).toBe(git(src, ["rev-parse", "HEAD"]));
    expect(lib1.files.map((f: any) => f.path).sort()).toEqual(
      ["prompts/dev/code/review.md", "prompts/notes/daily.md"].sort(),
    );
    expect(lib1.files.find((f: any) => f.path === "prompts/notes/daily.md").text)
      .toBe(PROMPTS["prompts/notes/daily.md"]);
    expect(["a", "b"]).toContain(lib1.slot);

    const head2 = commitAll(src, { "prompts/notes/new.md": "new file\n" });
    const r2 = run(fetchArgs(`file://${src}`, cache, 2));
    expect(r2.code).toBe(0);
    const a2 = run([SYNC, "accept", cache, "2"]);
    expect(a2.code).toBe(0);
    const lib2 = readLibrary(cache);
    expect(lib2.generation).toBe(2);
    expect(lib2.commit).toBe(head2);
    expect(lib2.slot).not.toBe(lib1.slot);
    expect(lib2.files.map((f: any) => f.path)).toContain("prompts/notes/new.md");
  }, 60000);

  test("accept of an unstaged generation exits non-zero and changes nothing; accept sweeps other staged files", () => {
    const src = makeRepo(PROMPTS);
    const cache = tmp("varhop-cache-");

    const bad = run([SYNC, "accept", cache, "99"]);
    expect(bad.code).toBe(9);
    expect(bad.json().error).toBe("not-staged");
    expect(existsSync(join(cache, "library.json"))).toBe(false);

    run(fetchArgs(`file://${src}`, cache, 3));
    run(fetchArgs(`file://${src}`, cache, 4));
    expect(stagedFiles(cache).sort()).toEqual(["staged-3.json", "staged-4.json"]);
    const a = run([SYNC, "accept", cache, "4"]);
    expect(a.code).toBe(0);
    expect(stagedFiles(cache)).toEqual([]);
    expect(readLibrary(cache).generation).toBe(4);
  }, 60000);

  test("a failed fetch exits non-zero with error JSON and preserves library and active slot", () => {
    const src = makeRepo(PROMPTS);
    const cache = tmp("varhop-cache-");
    run(fetchArgs(`file://${src}`, cache, 1));
    run([SYNC, "accept", cache, "1"]);
    const libBefore = readFileSync(join(cache, "library.json"));
    const active = join(cache, `slot-${readLibrary(cache).slot}`);
    const slotBefore = dirSnapshot(active);

    const r = run(fetchArgs(`file://${join(tmp("varhop-gone-"), "nonexistent")}`, cache, 2));
    expect(r.code).not.toBe(0);
    expect(r.json().error).toBeString();
    expect(r.json().message).toBeString();
    expect(readFileSync(join(cache, "library.json"))).toEqual(libBefore);
    expect(dirSnapshot(active)).toEqual(slotBefore);
    expect(stagedFiles(cache)).toEqual([]);
  }, 60000);

  test("fetch of repo B left unaccepted keeps A's library and slot; later accept publishes B", () => {
    const srcA = makeRepo(PROMPTS);
    const srcB = makeRepo({ "prompts/x/y.md": "B prompt\n" });
    const cache = tmp("varhop-cache-");

    run(fetchArgs(`file://${srcA}`, cache, 1, "111"));
    run([SYNC, "accept", cache, "1"]);
    const libA = readFileSync(join(cache, "library.json"));
    const activeA = join(cache, `slot-${readLibrary(cache).slot}`);
    const slotABefore = dirSnapshot(activeA);

    run(fetchArgs(`file://${srcB}`, cache, 2, "222"));
    expect(readFileSync(join(cache, "library.json"))).toEqual(libA);
    expect(dirSnapshot(activeA)).toEqual(slotABefore);

    const a = run([SYNC, "accept", cache, "2"]);
    expect(a.code).toBe(0);
    const lib = readLibrary(cache);
    expect(lib.generation).toBe(2);
    expect(lib.repoId).toBe("222");
  }, 60000);

  test("failure between read and staged rename leaves no staged file and keeps previous bundle", () => {
    const src = makeRepo(PROMPTS);
    const cache = tmp("varhop-cache-");
    run(fetchArgs(`file://${src}`, cache, 1));
    run([SYNC, "accept", cache, "1"]);
    const libBefore = readFileSync(join(cache, "library.json"));

    // Injection: a directory occupying the fixed temp path makes the bundle write fail.
    mkdirSync(join(cache, "staged-tmp-2.json"));
    const r = run(fetchArgs(`file://${src}`, cache, 2));
    expect(r.code).not.toBe(0);
    expect(r.json().error).toBe("cache-io");
    expect(existsSync(stagedPath(cache, 2))).toBe(false);
    expect(readFileSync(join(cache, "library.json"))).toEqual(libBefore);
    rmSync(join(cache, "staged-tmp-2.json"), { recursive: true });
  }, 60000);

  test("checkout transforms from .gitattributes eol=crlf ident do not alter bundle text", () => {
    const body = "line one\n$Id$\nline three\n";
    const src = makeRepo({
      ".gitattributes": "*.md text eol=crlf ident\n",
      "prompts/c/p.md": body,
    });
    const cache = tmp("varhop-cache-");
    const r = run(fetchArgs(`file://${src}`, cache, 1));
    expect(r.code).toBe(0);
    run([SYNC, "accept", cache, "1"]);
    const lib = readLibrary(cache);
    expect(lib.files[0].path).toBe("prompts/c/p.md");
    // Byte-exact against the real blob; the checkout would be CRLF/$Id$-expanded.
    const blobBytes = spawnSync({ cmd: ["git", "-C", src, "cat-file", "-p", "HEAD:prompts/c/p.md"], stdout: "pipe" }).stdout;
    expect(lib.files[0].text).toBe(blobBytes.toString());
  }, 60000);
});

describe("repo states and file selection", () => {
  test("empty repo stages status empty-repo with exit 0", () => {
    const dir = tmp("varhop-empty-");
    git(dir, ["init", "-q"]);
    git(dir, ["config", "user.email", "t@t"]);
    git(dir, ["config", "user.name", "t"]);
    const cache = tmp("varhop-cache-");
    const r = run(fetchArgs(`file://${dir}`, cache, 1));
    expect(r.code).toBe(0);
    const j = r.json();
    expect(j.status).toBe("empty-repo");
    const staged = JSON.parse(readFileSync(stagedPath(cache, 1), "utf8"));
    expect(staged.status).toBe("empty-repo");
    expect(staged.commit).toBeNull();
    expect(staged.files).toEqual([]);
  }, 60000);

  test("repo without prompts/ stages status no-prompts with exit 0", () => {
    const src = makeRepo({ "README.md": "hi\n", "docs/x.md": "not prompts\n" });
    const cache = tmp("varhop-cache-");
    const r = run(fetchArgs(`file://${src}`, cache, 1));
    expect(r.code).toBe(0);
    const j = r.json();
    expect(j.status).toBe("no-prompts");
    expect(JSON.parse(readFileSync(stagedPath(cache, 1), "utf8")).status).toBe("no-prompts");
  }, 60000);

  test("symlinks, submodules and non-.md files are skipped; invalid UTF-8 errors while others load", () => {
    const sub = makeRepo({ "prompts/z/in.md": "sub file\n" });
    const src = tmp("varhop-src-");
    git(src, ["init", "-q"]);
    git(src, ["config", "user.email", "t@t"]);
    git(src, ["config", "user.name", "t"]);
    writeFiles(src, {
      "prompts/c/good.md": "good body\n",
      "prompts/c/notes.txt": "not markdown\n",
      "prompts/c/bad.md": Buffer.from([0x66, 0xff, 0xfe, 0x67]),
    });
    symlinkSync("good.md", join(src, "prompts/c/link.md"));
    git(src, ["-c", "protocol.file.allow=always", "submodule", "add", "-q", sub, "prompts/sub"]);
    git(src, ["add", "-A"]);
    git(src, ["commit", "-qm", "c1"]);

    const cache = tmp("varhop-cache-");
    const r = run(fetchArgs(`file://${src}`, cache, 1));
    expect(r.code).toBe(0);
    const j = r.json();
    expect(j.status).toBe("ok");
    const staged = JSON.parse(readFileSync(stagedPath(cache, 1), "utf8"));
    expect(staged.files.map((f: any) => f.path)).toEqual(["prompts/c/good.md"]);
    expect(staged.files[0].text).toBe("good body\n");
    expect(staged.errors.map((e: any) => e.path)).toEqual(["prompts/c/bad.md"]);
  }, 60000);

  test("files deeper than two levels and files directly under prompts/ become error entries", () => {
    const src = makeRepo({
      "prompts/a/b/c/deep.md": "too deep\n",
      "prompts/top.md": "no category\n",
      "prompts/c/ok.md": "fine\n",
    });
    const cache = tmp("varhop-cache-");
    const r = run(fetchArgs(`file://${src}`, cache, 1));
    expect(r.code).toBe(0);
    const staged = JSON.parse(readFileSync(stagedPath(cache, 1), "utf8"));
    expect(staged.files.map((f: any) => f.path)).toEqual(["prompts/c/ok.md"]);
    expect(staged.errors.map((e: any) => e.path).sort()).toEqual(
      ["prompts/a/b/c/deep.md", "prompts/top.md"].sort(),
    );
  }, 60000);
});

describe("argument validation", () => {
  const BAD = ["../x", "a/b/c", "-x/y", "a b/c", "a;b/c", "a/../c", "./x"];
  for (const repo of BAD) {
    test(`sync refuses malformed repo '${repo}' with usage exit 2`, () => {
      const cache = tmp("varhop-cache-");
      const r = run([SYNC, "sync", repo, cache, "--generation", "1"]);
      expect(r.code).toBe(2);
      expect(r.json().error).toBe("usage");
    });
  }

  test("sync requires --generation and paired numeric expect flags", () => {
    const cache = tmp("varhop-cache-");
    for (const args of [
      ["sync", "o/r", cache],
      ["sync", "o/r", cache, "--generation", "x"],
      ["sync", "o/r", cache, "--generation", "1", "--expect-account", "1"],
      ["sync", "o/r", cache, "--generation", "1", "--expect-account", "1", "--expect-repo", "z"],
    ]) {
      const r = run([SYNC, ...args]);
      expect(r.code).toBe(2);
      expect(r.json().error).toBe("usage");
    }
  });
});

describe("auth", () => {
  test("empty GH_CONFIG_DIR: status reports unauthenticated with fix; sync exits auth without prompting", () => {
    const emptyCfg = tmp("varhop-ghcfg-");
    const env = { GH_CONFIG_DIR: emptyCfg };
    const s = run([SYNC, "status"], env);
    expect(s.code).toBe(0);
    expect(s.json()).toEqual({ authenticated: false, fix: "gh auth login" });

    const cache = tmp("varhop-cache-");
    const r = run([SYNC, "sync", "o/r", cache, "--generation", "1"], env);
    expect(r.code).toBe(3);
    const j = r.json();
    expect(j.error).toBe("auth");
    expect(j.fix).toBe("gh auth login");
    expect(stagedFiles(cache)).toEqual([]);
    expect(existsSync(join(cache, "library.json"))).toBe(false);
  }, 30000);
});
