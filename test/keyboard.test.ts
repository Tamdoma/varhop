import {test, expect} from "bun:test";
import {readFileSync} from "node:fs";
import {parseSequence, withKeyboard, type KeyEvent} from "./keyboard";

const listed = (name: string): boolean =>
  readFileSync("/proc/bus/input/devices", "utf8").includes(`N: Name="${name}"`);

test("chords press left to right and release right to left", () => {
  const events: KeyEvent[] = parseSequence("ctrl+shift+left a");
  expect(events).toEqual([
    {code: 29, value: 1}, {code: 42, value: 1}, {code: 105, value: 1},
    {code: 105, value: 0}, {code: 42, value: 0}, {code: 29, value: 0},
    {code: 30, value: 1}, {code: 30, value: 0},
  ]);
});

test("an unknown key name is refused by name", () => {
  expect(() => parseSequence("ctrl+nope")).toThrow("nope");
});

test("the virtual keyboard exists only while run executes, also when run throws", {timeout: 10_000}, () => {
  const name: string = "varhop-keyboard-test-kbd";
  const seen: boolean = withKeyboard(name, (): boolean => listed(name));
  expect(seen).toBe(true);
  expect(listed(name)).toBe(false);
  expect(() => withKeyboard(name, (): never => { throw new Error("run failed"); })).toThrow("run failed");
  expect(listed(name)).toBe(false);
});

test("a usage error exits 2 with its message and no result line", () => {
  const result: ReturnType<typeof Bun.spawnSync> = Bun.spawnSync({cmd: [process.execPath, `${import.meta.dir}/keyboard.ts`, "--device", "kbd"]});
  expect(result.exitCode).toBe(2);
  expect(result.stdout.toString()).toBe("");
  expect(result.stderr.toString()).toContain("--device must start with varhop-");
});
