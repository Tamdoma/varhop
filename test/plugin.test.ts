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

// The card surface follows the Omarchy Emojis recipe with live tokens and no
// colour snapshot or alpha code of its own.
test("Varhop.qml builds the card on the Omarchy menu surface", () => {
  const src = require("node:fs").readFileSync(join(ROOT, "Varhop.qml"), "utf8");
  for (const needle of [
    "BorderSurface", "Commons.Color.menu.background", "Commons.Color.menu.scrim",
    'Border.surfaceSpec("menu", "border"', "Style.cornerRadius",
    "Style.space(560)", "Style.space(480)", "Style.gapsOut",
    "theme: Commons.Color", "tokens: Style",
  ]) expect(src.replace(/"menu",\s*"border"/g, '"menu", "border"')).toContain(needle);
  expect(src).not.toMatch(/property var colors/);
  expect(src).not.toMatch(/\balpha\b|\bopacity\b|Qt\.rgba/);
});
