/**
 * @typedef {{score: number, last: number}} UsageEntry
 * @typedef {{version: 1, entries: Record<string, UsageEntry>}} UsageState
 */

export const HALF_LIFE_MS = 14 * 24 * 60 * 60 * 1000;

/** @returns {UsageState} */
export const resetUsage = () => ({version: 1, entries: {}});

/**
 * Returns a new state with id's score decayed then bumped; input is not mutated.
 * @param {UsageState} usage
 * @param {string} id
 * @param {number} now epoch milliseconds
 * @returns {UsageState}
 */
export const recordCopy = (usage, id, now) => {
  const prev = usage.entries[id];
  const score =
    prev === undefined ? 1 : prev.score * 2 ** (-(now - prev.last) / HALF_LIFE_MS) + 1;
  return {version: 1, entries: {...usage.entries, [id]: {score, last: now}}};
};

const isRecord = (v) => typeof v === "object" && v !== null && !Array.isArray(v);

/**
 * @param {string} text serialized UsageState
 * @returns {{state: UsageState} | {error: string}}
 */
export const parseUsage = (text) => {
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    return {error: "not valid JSON"};
  }
  if (!isRecord(parsed)) return {error: "state is not an object"};
  if (parsed.version !== 1) return {error: "version is not 1"};
  if (!isRecord(parsed.entries)) return {error: "entries is not an object"};
  for (const [id, e] of Object.entries(parsed.entries)) {
    if (!isRecord(e) || typeof e.score !== "number" || typeof e.last !== "number")
      return {error: "entry " + id + " lacks numeric score/last"};
  }
  return {state: parsed};
};
