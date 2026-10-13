import {test, expect} from "bun:test";
import {join} from "node:path";

// Copier.qml runs standalone under `quickshell -p` (proofs-overlay.md row 21):
// `false`, a missing binary and a timed-out `sleep` must each report failure.
// The clipboard is saved and restored around the run.
const paste = (args) =>
  Bun.spawnSync({cmd: ["wl-paste", ...args], stdout: "pipe", stderr: "pipe"});

test("copier reports failure for exit!=0, failed start and timeout", () => {
  const saved = paste(["-n"]).stdout;
  try {
    const res = Bun.spawnSync({
      cmd: ["quickshell", "-p", join(import.meta.dir, "..", "qml", "tst_copier.qml")],
      env: {...process.env, QT_QPA_PLATFORM: "wayland"},
      stdout: "pipe",
      stderr: "pipe",
      timeout: 60_000,
    });
    const out = res.stdout.toString() + res.stderr.toString();
    if (res.exitCode !== 0 || out.includes("copier-probe:"))
      console.error(out);
    expect(res.exitCode).toBe(0);
    expect(out.includes("copier-probe:")).toBe(false);
  } finally {
    if (saved.length > 0)
      Bun.spawnSync({cmd: ["wl-copy", "--type", "text/plain;charset=utf-8"], stdin: saved});
  }
});
