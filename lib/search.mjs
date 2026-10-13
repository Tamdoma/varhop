import {fold} from "./fold.mjs";
import {HALF_LIFE_MS} from "./usage.mjs";

export {fold} from "./fold.mjs";
export const DISPLAY_CHUNK = 50;

// Sort precedence for equal scores; field weights live in termBest.
const FIELD_ORDER = {
  title: 0,
  fileName: 1,
  tags: 2,
  category: 3,
  subcategory: 4,
  description: 5,
};

/**
 * Subsequence quality in (0,1]: a consecutive run scores 1, every unmatched
 * gap lowers it. Returns 0 when term is not a subsequence of field.
 */
const subseq = (term, field) => {
  let best = 0;
  // indexOf walks field positions natively; a JS char loop per position is
  // measurably slower in QV4, which is what runs this in the overlay.
  let s = field.indexOf(term[0]);
  while (s !== -1 && s <= field.length - term.length) {
    let i = s;
    let pairs = 0;
    let gaps = 0;
    let ok = true;
    for (let t = 1; t < term.length; t += 1) {
      const j = field.indexOf(term[t], i + 1);
      if (j === -1) {
        ok = false;
        break;
      }
      gaps += j - i - 1;
      if (j === i + 1) pairs += 1;
      i = j;
    }
    if (ok) {
      const q = (term.length + pairs) / (2 * term.length - 1 + gaps);
      if (q > best) best = q;
    }
    s = field.indexOf(term[0], s + 1);
  }
  return best;
};

// A field that lacks a term character cannot contain the term as a
// subsequence, so a per-field character mask skips the subseq scan for most
// non-matching fields. Masks are folded-char bitsets computed once per
// prompt (prompt objects are shared per import).
const fieldMask = (value) => {
  if (value === null) return -1;
  let m = 0;
  for (let i = 0; i < value.length; i += 1)
    m |= 1 << (value.charCodeAt(i) % 32);
  return m;
};

const termMasks = new Map();

const termMask = (term) => {
  let m = termMasks.get(term);
  if (m === undefined) {
    m = fieldMask(term);
    termMasks.set(term, m);
  }
  return m;
};

// WeakMap.get costs ~5 µs per call in QV4 (26 ms at 5000 prompts), so the
// union mask rides on the prompt's search object once computed.
const masksOf = (prompt) => {
  const s = prompt.search;
  if (s.__mask === undefined) {
    s.__mask = fieldMask(s.title) | fieldMask(s.fileName) |
        fieldMask(s.category) | fieldMask(s.subcategory) |
        fieldMask(s.description);
    for (const t of s.tags) s.__mask |= fieldMask(t);
  }
  return s.__mask;
};

// Best field for one term: {field, score, weight} or null. Kept free of
// per-field object churn because it runs on the keystroke path.
const termBest = (search, term) => {
  let bestField = null;
  let bestScore = 0;
  let bestWeight = 0;
  const tryField = (field, value, weight) => {
    if (value === null) return;
    const q = subseq(term, value);
    if (q === 0) return;
    const score = q * weight;
    if (
      bestField === null ||
      score > bestScore ||
      (score === bestScore && weight > bestWeight) ||
      (score === bestScore &&
        weight === bestWeight &&
        FIELD_ORDER[field] < FIELD_ORDER[bestField])
    ) {
      bestField = field;
      bestScore = score;
      bestWeight = weight;
    }
  };
  tryField("title", search.title, 6);
  tryField("fileName", search.fileName, 5);
  for (let i = 0; i < search.tags.length; i += 1)
    tryField("tags", search.tags[i], 4);
  tryField("category", search.category, 3);
  tryField("subcategory", search.subcategory, 3);
  tryField("description", search.description, 2);
  return bestField === null
    ? null
    : {field: bestField, score: bestScore, weight: bestWeight};
};

// {score, field} when every term matches some structured field, else null.
const structuredMatch = (prompt, terms) => {
  let score = 0;
  let top = null;
  // Every term character must occur in at least one field, so the union
  // mask rejects a prompt before its fields are scanned.
  const masks = masksOf(prompt);
  for (const term of terms) {
    const tm = termMask(term);
    if ((masks & tm) !== tm)
      return null;
    const t = termBest(prompt.search, term);
    if (t === null) return null;
    score += t.score;
    if (
      top === null ||
      t.score > top.score ||
      (t.score === top.score && t.weight > top.weight) ||
      (t.score === top.score &&
        t.weight === top.weight &&
        FIELD_ORDER[t.field] < FIELD_ORDER[top.field])
    )
      top = t;
  }
  return {score, field: top.field};
};

const frecency = (usage, id, now) => {
  const e = usage.entries[id];
  return e === undefined
    ? 0
    : e.score * 2 ** (-(now - e.last) / HALF_LIFE_MS);
};

const snippet = (prompt, term) => {
  const idx = prompt.search.body.split("\n").findIndex((l) => l.includes(term));
  return prompt.body.split("\n")[idx].trim();
};

const cmpStr = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

// The category/subcategory/title order changes only when the prompt array
// changes, so it is cached per array identity; a keystroke at a large
// library otherwise re-sorts thousands of prompts inside the 50 ms frame
// budget. One library is live at a time, so each cache holds only the last
// array and a replaced import drops it. No WeakMap: QV4 (Qt 6.12) crashes in
// WeakMap.get once a key has been collected.
let sortedFor = null;
let sortedIdx = null;

const cachedOrder = (prompts) => {
  if (sortedFor === prompts && sortedIdx.length === prompts.length) return sortedIdx;
  const idx = prompts.map((_, i) => i);
  idx.sort(
    (a, b) =>
      cmpStr(prompts[a].search.category, prompts[b].search.category) ||
      cmpStr(prompts[a].search.subcategory ?? "", prompts[b].search.subcategory ?? "") ||
      cmpStr(prompts[a].search.title, prompts[b].search.title),
  );
  sortedFor = prompts;
  sortedIdx = idx;
  return idx;
};

// The empty-query row list changes only with the prompt array or the usage
// snapshot; both arrive as immutable objects, so identity keys the cache.
let emptyFor = null;
let emptyUsage = null;
let emptyRows = null;

const emptyRank = (prompts, usage) => {
  if (emptyFor === prompts && emptyUsage === usage) return emptyRows;

  const byId = new Map(prompts.map((p) => [p.id, p]));
  const recent = Object.keys(usage.entries)
    .filter((id) => byId.has(id))
    .sort((a, b) => usage.entries[b].last - usage.entries[a].last)
    .slice(0, 10);
  const recentSet = new Set(recent);
  const order = cachedOrder(prompts);
  const rest = [];
  for (const i of order) {
    const p = prompts[i];
    if (!recentSet.has(p.id)) rest.push(p);
  }
  const row = (p) => ({id: p.id, score: 0, matchedField: null, snippet: null});
  const rows = [...recent.map((id) => row(byId.get(id))), ...rest.map(row)];
  emptyFor = prompts;
  emptyUsage = usage;
  emptyRows = rows;
  return rows;
};

/**
 * @returns {{id: string, score: number, matchedField: string|null, snippet: string|null}[]}
 */
// Typing extends or shortens a query one keystroke at a time. Stronger
// terms can only shrink the structured match set, and body candidates can
// only come from prompts outside it, so every query's candidate split is
// kept in a small LRU per prompt array: a keystroke re-matches only the
// surviving candidates of the best cached prefix instead of the whole
// library. Backspacing hits the earlier query's cached split exactly. A
// fresh import starts cold.
let narrowFor = null;
let narrowStates = null;
const TERM_SEP = "\u0000";
const NARROW_CAP = 64;

// True when every old term is a string-prefix of the new term at the same
// position (prefix strings are trivially substrings of their extensions,
// hence stronger subsequence terms) and no old term was dropped.
const extendsLast = (oldTerms, newTerms) =>
  oldTerms.length <= newTerms.length &&
  oldTerms.every((t, i) => newTerms[i].startsWith(t));

export const rank = (prompts, query, usage, now) => {
  const terms = fold(query)
    .split(/\s+/)
    .filter((t) => t !== "");
  if (terms.length === 0) return emptyRank(prompts, usage);

  if (narrowFor !== prompts) {
    narrowFor = prompts;
    narrowStates = new Map();
  }
  const states = narrowStates;

  const key = terms.join(TERM_SEP);
  let base = states.get(key);
  // An exact hit already carries this query's match results; only the
  // time-dependent frecency needs recomputing.
  const exact = base !== undefined;
  if (base === undefined) {
    // Longest cached state whose terms still narrow this query.
    for (const s of states.values()) {
      if (
        extendsLast(s.terms, terms) &&
        (base === undefined || s.terms.length > base.terms.length)
      )
        base = s;
    }
    if (base === undefined)
      base = {terms: [], structured: prompts.map((_, i) => ({i})), pool: []};
  }

  const structured = [];
  const bodyPool = base.pool.slice();
  const structuredCands = [];
  // Pool candidates failed a prefix term and can never structured-match a
  // stronger query again, so they pass through without rescanning.
  for (const c of base.structured) {
    const ci = c.i;
    const m = exact ? c.m : structuredMatch(prompts[ci], terms);
    if (m === null) bodyPool.push(ci);
    else {
      structuredCands.push({i: ci, m});
      structured.push({p: prompts[ci], i: ci, m, f: frecency(usage, prompts[ci].id, now)});
    }
  }

  if (!exact) {
    if (states.size > NARROW_CAP) {
      const oldest = states.keys().next();
      states.delete(oldest.value);
    }
    states.set(key, {terms, structured: structuredCands, pool: bodyPool});
  }

  structured.sort(
    (a, b) =>
      b.m.score - a.m.score ||
      b.f - a.f ||
      FIELD_ORDER[a.m.field] - FIELD_ORDER[b.m.field] ||
      a.i - b.i,
  );

  const body = [];
  if (structured.length < DISPLAY_CHUNK && terms.every((t) => t.length >= 3)) {
    // A term's characters absent from the body can never substring-match,
    // so the import-time body mask skips scanning most candidates.
    const tms = terms.map(termMask);
    for (const ci of bodyPool) {
      const p = prompts[ci];
      if (tms.every((tm) => (p.search.bodyMask & tm) === tm) &&
          terms.every((t) => p.search.body.includes(t)))
        body.push({p, i: ci, f: frecency(usage, p.id, now)});
    }
    body.sort((a, b) => b.f - a.f || a.i - b.i);
  }


  return [
    ...structured.map((s) => ({
      id: s.p.id,
      score: s.m.score,
      matchedField: s.m.field,
      snippet: null,
    })),
    ...body.map((b) => ({
      id: b.p.id,
      score: 0,
      matchedField: "body",
      snippet: snippet(b.p, terms[0]),
    })),
  ];
};
