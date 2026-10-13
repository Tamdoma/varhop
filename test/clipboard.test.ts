import {test, expect} from "bun:test";
import {join} from "node:path";
import {waylandEnv, withClipboardRestored} from "./clipboard";

test("nonempty clipboard and primary restoration completes and preserves bytes", {timeout: 15_000}, () => withClipboardRestored(() => {
  const probe: string = `
    import {waylandEnv, withClipboardRestored} from ${JSON.stringify(join(import.meta.dir, "clipboard.ts"))};
    const env = waylandEnv();
    const put = (args, text) => {
      const result = Bun.spawnSync({cmd: ["wl-copy", ...args, "--type", "text/plain;charset=utf-8"],
        env, stdin: Buffer.from(text), stdout: "ignore", stderr: "ignore"});
      if (result.exitCode !== 0) throw new Error("Clipboard fixture write failed: " + result.exitCode);
    };
    const read = (args) => {
      const result = Bun.spawnSync({cmd: ["wl-paste", ...args, "--no-newline"], env});
      if (result.exitCode !== 0) throw new Error("Clipboard fixture read failed: " + result.exitCode);
      return result.stdout;
    };
    const clipboard = "varhop clipboard č\\r\\n";
    const primary = "varhop primary ž\\n";
    put([], clipboard);
    put(["--primary"], primary);
    withClipboardRestored(() => { put([], "replacement"); put(["--primary"], "replacement"); });
    if (!read([]).equals(Buffer.from(clipboard)) || !read(["--primary"]).equals(Buffer.from(primary)))
      throw new Error("Nonempty selections were not restored byte-exact");
  `;
  const result: Bun.SyncSubprocess<"pipe", "pipe"> = Bun.spawnSync({
    cmd: ["bun", "--eval", probe], env: waylandEnv(),
    stdout: "pipe", stderr: "pipe", timeout: 3000,
  });
  if (result.exitCode !== 0)
    console.error({exitCode: result.exitCode, timeout: result.exitedDueToTimeout, stderr: result.stderr.toString()});
  expect(result.exitCode).toBe(0);
}));
