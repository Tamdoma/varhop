import {test, expect} from "bun:test";
import {join} from "node:path";

test("every exported module loads in the QML engine and a smoke call exits 0", () => {
  const res = Bun.spawnSync({
    cmd: ["/usr/lib/qt6/bin/qml", join(import.meta.dir, "qml-smoke.qml")],
    env: {
      ...process.env,
      QT_QPA_PLATFORM: "offscreen",
      QT_FORCE_STDERR_LOGGING: "1",
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  if (res.exitCode !== 0)
    console.error(res.stderr.toString());
  expect(res.exitCode).toBe(0);
}, 30_000);
