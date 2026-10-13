import {readdirSync} from "node:fs";

type Selection = {kind: "absent"} | {kind: "data", mime: string, bytes: Buffer};

export const waylandEnv = (): NodeJS.ProcessEnv => {
  const runtime: string = process.env.XDG_RUNTIME_DIR ?? `/run/user/${process.getuid()}`;
  const socket: string | undefined = process.env.WAYLAND_DISPLAY
    ?? readdirSync(runtime).find((name: string): boolean => /^wayland-\d+$/.test(name));
  if (socket === undefined) throw new Error(`No Wayland socket in ${runtime}`);
  return {...process.env, XDG_RUNTIME_DIR: runtime, WAYLAND_DISPLAY: socket};
};

const readSelection = (args: string[], env: NodeJS.ProcessEnv): Selection => {
  const types: ReturnType<typeof Bun.spawnSync> = Bun.spawnSync({
    cmd: ["wl-paste", ...args, "--list-types"], env,
  });
  if (types.exitCode === 1 && types.stderr.toString() === "Nothing is copied\n")
    return {kind: "absent"};
  if (types.exitCode !== 0)
    throw new Error(`wl-paste ${args.join(" ")} --list-types exited ${types.exitCode}: ${types.stderr}`);
  const names: string[] = types.stdout.toString().trimEnd().split("\n");
  const mime: string = names.includes("text/plain;charset=utf-8") ? "text/plain;charset=utf-8" : names[0];
  const result: ReturnType<typeof Bun.spawnSync> = Bun.spawnSync({
    cmd: ["wl-paste", ...args, "--no-newline", "--type", mime], env,
  });
  if (result.exitCode !== 0)
    throw new Error(`wl-paste ${args.join(" ")} --type ${mime} exited ${result.exitCode}: ${result.stderr}`);
  return {kind: "data", mime, bytes: result.stdout};
};

const restoreSelection = (args: string[], saved: Selection, env: NodeJS.ProcessEnv): void => {
  const result: ReturnType<typeof Bun.spawnSync> = Bun.spawnSync({
    cmd: ["wl-copy", ...args, ...(saved.kind === "absent" ? ["--clear"] : ["--type", saved.mime])],
    env, stdin: saved.kind === "data" ? saved.bytes : "ignore", stdout: "ignore", stderr: "pipe",
  });
  if (result.exitCode !== 0)
    throw new Error(`wl-copy ${args.join(" ")} restoration exited ${result.exitCode}: ${result.stderr}`);
  const actual: Selection = readSelection(args, env);
  const equal: boolean = saved.kind === "absent" ? actual.kind === "absent"
    : actual.kind === "data" && saved.mime === actual.mime && saved.bytes.equals(actual.bytes);
  if (!equal) throw new Error(`Clipboard restoration byte comparison failed for ${args.join(" ") || "clipboard"}`);
};

export const withClipboardRestored = (run: () => void): void => {
  const env: NodeJS.ProcessEnv = waylandEnv();
  const clipboard: Selection = readSelection([], env);
  const primary: Selection = readSelection(["--primary"], env);
  try {
    run();
  } finally {
    try {
      restoreSelection([], clipboard, env);
    } finally {
      restoreSelection(["--primary"], primary, env);
    }
  }
};
