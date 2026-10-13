// Virtual uinput keyboard for live overlay checks. Sends a key sequence to the
// focused surface and compares the observed text. Key names are Linux key codes,
// so on the hr layout KEY_Y types z and KEY_Z types y.
//   bun test/keyboard.ts --device varhop-<leaf>-kbd --keys "ctrl+a backspace a b" \
//     --read field|clipboard|none [--expect "<text>"]
// Exit 0 with a pass line on match, 1 with a fail line (expected, observed) on mismatch.
import {dlopen, FFIType, ptr} from "bun:ffi";
import {closeSync, openSync, writeSync} from "node:fs";
import {parseArgs} from "node:util";
import {waylandEnv, withClipboardRestored} from "./clipboard";

export type KeyEvent = {code: number, value: 0 | 1};
type Read = "field" | "clipboard" | "none";

const CODES: Record<string, number> = {
  esc: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8, 8: 9, 9: 10, 0: 11, minus: 12, backspace: 14, tab: 15,
  q: 16, w: 17, e: 18, r: 19, t: 20, y: 21, u: 22, i: 23, o: 24, p: 25, enter: 28, ctrl: 29,
  a: 30, s: 31, d: 32, f: 33, g: 34, h: 35, j: 36, k: 37, l: 38, shift: 42,
  z: 44, x: 45, c: 46, v: 47, b: 48, n: 49, m: 50, comma: 51, period: 52, slash: 53, alt: 56, space: 57,
  home: 102, up: 103, left: 105, right: 106, end: 107, down: 108, delete: 111, super: 125,
};

// linux/uinput.h and linux/input-event-codes.h
const UI_SET_EVBIT: bigint = 0x40045564n;
const UI_SET_KEYBIT: bigint = 0x40045565n;
const UI_DEV_SETUP: bigint = 0x405c5503n;
const UI_DEV_CREATE: bigint = 0x5501n;
const UI_DEV_DESTROY: bigint = 0x5502n;
const EV_SYN: number = 0;
const EV_KEY: number = 1;
const BUS_VIRTUAL: number = 6;
const KEY_GAP_MS: number = 30;

const codeOf = (name: string): number => {
  const code: number | undefined = CODES[name];
  if (code === undefined) throw new Error(`Unknown key name: ${name}`);
  return code;
};

export const parseSequence = (text: string): KeyEvent[] =>
  text.trim().split(/\s+/).filter((token: string): boolean => token !== "").flatMap((token: string): KeyEvent[] => {
    const codes: number[] = token.split("+").map(codeOf);
    return [
      ...codes.map((code: number): KeyEvent => ({code, value: 1})),
      ...codes.toReversed().map((code: number): KeyEvent => ({code, value: 0})),
    ];
  });

const libc = dlopen("libc.so.6", {ioctl: {args: [FFIType.i32, FFIType.u64, FFIType.u64], returns: FFIType.i32}});

const ioctl = (fd: number, request: bigint, arg: bigint): void => {
  const result: number = libc.symbols.ioctl(fd, request, arg);
  if (result !== 0) throw new Error(`uinput ioctl 0x${request.toString(16)} failed with ${result}`);
};

const inputEvent = (type: number, code: number, value: number): Uint8Array => {
  const bytes: Uint8Array = new Uint8Array(24);
  const view: DataView = new DataView(bytes.buffer);
  view.setUint16(16, type, true);
  view.setUint16(18, code, true);
  view.setInt32(20, value, true);
  return bytes;
};

const hyprctlJson = <T>(args: string[]): T => {
  const result: ReturnType<typeof Bun.spawnSync> = Bun.spawnSync({cmd: ["hyprctl", ...args, "-j"]});
  if (result.exitCode !== 0) throw new Error(`hyprctl ${args.join(" ")} exited ${result.exitCode}: ${result.stderr}`);
  return JSON.parse(result.stdout.toString()) as T;
};

const keyboardRegistered = (name: string): boolean =>
  hyprctlJson<{keyboards: {name: string}[]}>(["devices"]).keyboards.some((k: {name: string}): boolean => k.name === name);

const waitForKeyboard = (name: string): void => {
  const deadline: number = Date.now() + 3000;
  while (!keyboardRegistered(name)) {
    if (Date.now() > deadline) throw new Error(`Virtual keyboard ${name} not registered by Hyprland within 3 s`);
    Bun.sleepSync(50);
  }
};

export const withKeyboard = <T>(name: string, run: (send: (events: KeyEvent[]) => void) => T): T => {
  const fd: number = openSync("/dev/uinput", "w");
  try {
    ioctl(fd, UI_SET_EVBIT, BigInt(EV_KEY));
    for (const code of new Set(Object.values(CODES))) ioctl(fd, UI_SET_KEYBIT, BigInt(code));
    const setup: Uint8Array = new Uint8Array(92);
    new DataView(setup.buffer).setUint16(0, BUS_VIRTUAL, true);
    setup.set(new TextEncoder().encode(name).subarray(0, 79), 8);
    ioctl(fd, UI_DEV_SETUP, BigInt(ptr(setup)));
    ioctl(fd, UI_DEV_CREATE, 0n);
    try {
      waitForKeyboard(name);
      return run((events: KeyEvent[]): void => {
        for (const event of events) {
          writeSync(fd, inputEvent(EV_KEY, event.code, event.value));
          writeSync(fd, inputEvent(EV_SYN, 0, 0));
          Bun.sleepSync(KEY_GAP_MS);
        }
      });
    } finally {
      ioctl(fd, UI_DEV_DESTROY, 0n);
    }
  } finally {
    closeSync(fd);
  }
};

const readClipboard = (): string => {
  const result: ReturnType<typeof Bun.spawnSync> = Bun.spawnSync({cmd: ["wl-paste", "--no-newline"], env: waylandEnv()});
  if (result.exitCode === 1 && result.stderr.toString() === "Nothing is copied\n") return "";
  if (result.exitCode !== 0) throw new Error(`wl-paste exited ${result.exitCode}: ${result.stderr}`);
  return result.stdout.toString();
};

const observeClipboard = (expected: string): string => {
  const deadline: number = Date.now() + 2000;
  let observed: string = readClipboard();
  while (observed !== expected && Date.now() < deadline) {
    Bun.sleepSync(50);
    observed = readClipboard();
  }
  return observed;
};

const varhopLayerShown = (): boolean =>
  Object.values(hyprctlJson<Record<string, {levels: Record<string, {namespace: string}[]>}>>(["layers"]))
    .some((monitor): boolean => Object.values(monitor.levels).flat().some((layer): boolean => layer.namespace === "varhop"));

const main = (): void => {
  const {values} = parseArgs({options: {
    device: {type: "string"}, keys: {type: "string"}, read: {type: "string"}, expect: {type: "string"},
  }, strict: true});
  const {device, keys, read, expect} = values;
  if (device === undefined || !device.startsWith("varhop-")) throw new Error(`--device must start with varhop-, got ${device}`);
  if (keys === undefined) throw new Error("--keys is required");
  if (read !== "field" && read !== "clipboard" && read !== "none") throw new Error(`--read must be field, clipboard or none, got ${read}`);
  if (read !== "none" && expect === undefined) throw new Error(`--expect is required with --read ${read}`);
  const mode: Read = read;
  const events: KeyEvent[] = [...parseSequence(keys), ...(mode === "field" ? parseSequence("ctrl+a ctrl+c") : [])];
  if (!varhopLayerShown()) throw new Error("No varhop layer is shown; refusing to send keys");
  let observed: string | null = null;
  withClipboardRestored((): void => withKeyboard(device, (send: (events: KeyEvent[]) => void): void => {
    send(events);
    observed = mode === "none" ? null : observeClipboard(expect as string);
  }));
  if (mode === "none" || observed === expect) {
    console.log(JSON.stringify({result: "pass", observed}));
    return;
  }
  console.log(JSON.stringify({result: "fail", expected: expect, observed}));
  process.exitCode = 1;
};

if (import.meta.main) main();
