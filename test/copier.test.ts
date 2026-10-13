import {test, expect} from "bun:test";
import {join} from "node:path";
import {waylandEnv, withClipboardRestored} from "./clipboard";

// Copier.qml runs standalone under `quickshell -p` (proofs-overlay.md row 21):
// `false`, a missing binary and a timed-out `sleep` must each report failure.
// The clipboard is saved and restored around the run.
test("copier reports failure for exit!=0, failed start and timeout", {timeout: 60_000}, () => withClipboardRestored(() => {
    const res = Bun.spawnSync({
      cmd: ["quickshell", "-p", join(import.meta.dir, "..", "qml", "tst_copier.qml")],
      env: {
        ...process.env,
        ...waylandEnv(),
        QT_QPA_PLATFORM: "wayland",
      },
      stdout: "pipe",
      stderr: "pipe",
      timeout: 60_000,
    });
    const out = res.stdout.toString() + res.stderr.toString();
    if (res.exitCode !== 0 || out.includes("copier-probe:"))
      console.error(out);
    expect(res.exitCode).toBe(0);
    expect(out.includes("copier-probe:")).toBe(false);
}));

test("one retained copier completes consecutive stdin copies", {timeout: 60_000}, () => {
  const result = Bun.spawnSync({
    cmd: ["quickshell", "-p", join(import.meta.dir, "..", "qml", "tst_copier_repeated.qml")],
    env: {...waylandEnv(), QT_QPA_PLATFORM: "wayland"},
    stdout: "pipe", stderr: "pipe", timeout: 10_000,
  });
  if (result.exitCode !== 0) console.error(result.stdout.toString() + result.stderr.toString());
  expect(result.exitCode).toBe(0);
});
