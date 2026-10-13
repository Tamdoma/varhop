import {test, expect} from "bun:test";
import {join} from "node:path";
import {lstatSync, existsSync} from "node:fs";

// Plugin root manifest required by omarchy-plugin-validate: schemaVersion 1,
// kinds ["overlay"], keepLoaded, and a relative entry point that exists.
const ROOT = join(import.meta.dir, "..");

test("manifest.json declares the ivan.varhop overlay plugin", () => {
  const path = join(ROOT, "manifest.json");
  expect(existsSync(path)).toBe(true);
  const m = JSON.parse(require("node:fs").readFileSync(path, "utf8"));
  expect(m.schemaVersion).toBe(1);
  expect(m.id).toBe("ivan.varhop");
  expect(typeof m.name).toBe("string");
  expect(typeof m.version).toBe("string");
  expect(m.kinds).toEqual(["overlay"]);
  expect(m.keepLoaded).toBe(true);
  const ep = m.entryPoints?.overlay;
  expect(typeof ep).toBe("string");
  expect(ep.startsWith("/")).toBe(false);
  expect(ep.includes("..")).toBe(false);
  const epPath = join(ROOT, ep);
  expect(existsSync(epPath)).toBe(true);
  expect(lstatSync(epPath).isSymbolicLink()).toBe(false);
});
