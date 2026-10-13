import {test, expect} from "bun:test";
import {join} from "node:path";
import {readdirSync} from "node:fs";

// akrogon run-check scrubs the session env. Rebuild the two values the
// Wayland client needs; the socket name varies (wayland-1 here), so scan it.
const waylandEnv = () => {
  const runtime = process.env.XDG_RUNTIME_DIR ?? `/run/user/${process.getuid()}`;
  const sock = process.env.WAYLAND_DISPLAY
    ?? readdirSync(runtime).find((n) => /^wayland-\d+$/.test(n))
    ?? "wayland-0";
  return {XDG_RUNTIME_DIR: runtime, WAYLAND_DISPLAY: sock};
};

// Component checks: the interactive views import no Quickshell module, so
// qmltestrunner on the real Wayland platform loads them, pastes from the real
// clipboard and synthesizes clicks (proofs-overlay.md row 16).
test("view component checks pass under qmltestrunner on wayland", {timeout: 60_000}, () => {
  const res = Bun.spawnSync({
    cmd: [
      "/usr/lib/qt6/bin/qmltestrunner",
      "-input",
      join(import.meta.dir, "..", "qml", "tst_views.qml"),
    ],
    env: {
      ...process.env,
      ...waylandEnv(),
      QT_QPA_PLATFORM: "wayland",
      QT_IM_MODULE: process.env.QT_IM_MODULE ?? "fcitx",
      QT_FORCE_STDERR_LOGGING: "1",
    },
    stdout: "pipe",
    stderr: "pipe",
    timeout: 120_000,
  });
  const out = res.stdout.toString() + res.stderr.toString();
  if (res.exitCode !== 0 || !out.includes("Totals:") || !/Totals:.*0 failed/.test(out))
    console.error(out);
  expect(res.exitCode).toBe(0);
  expect(/Totals:.*0 failed/.test(out)).toBe(true);
});
