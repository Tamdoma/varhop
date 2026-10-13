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
  for (let s = 0; s <= field.length - term.length; s += 1) {
    if (field[s] !== term[0]) continue;
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
  }
  return best;
};

// Best field for one term: {field, score, weight} or null.
const termBest = (search, term) => {
  let best = null;
  const tryField = (field, value, weight) => {
    if (value === null) return;
    const q = subseq(term, value);
    if (q === 0) return;
    const score = q * weight;
    if (
      best === null ||
      score > best.score ||
      (score === best.score && weight > best.weight) ||
      (score === best.score &&
        weight === best.weight &&
        FIELD_ORDER[field] < FIELD_ORDER[best.field])
    )
      best = {field, score, weight};
  };
  // A title that folds to the file stem is the derived default, not a real
  // title: the same string already scores at fileName weight.
  tryField("title", search.title === search.fileName ? null : search.title, 6);
  tryField("fileName", search.fileName, 5);
  for (const tag of search.tags) tryField("tags", tag, 4);
  tryField("category", search.category, 3);
  tryField("subcategory", search.subcategory, 3);
  tryField("description", search.description, 2);
  return best;
};

// {score, field} when every term matches some structured field, else null.
const structuredMatch = (prompt, terms) => {
  let score = 0;
  let top = null;
  for (const term of terms) {
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

const emptyRank = (prompts, usage) => {
  const byId = new Map(prompts.map((p) => [p.id, p]));
  const recent = Object.keys(usage.entries)
    .filter((id) => byId.has(id))
    .sort((a, b) => usage.entries[b].last - usage.entries[a].last)
    .slice(0, 10);
  const recentSet = new Set(recent);
  const rest = prompts
    .filter((p) => !recentSet.has(p.id))
    .sort(
      (a, b) =>
        cmpStr(a.search.category, b.search.category) ||
        cmpStr(a.search.title, b.search.title) ||
        cmpStr(a.search.subcategory ?? "", b.search.subcategory ?? ""),
    );
  const row = (p) => ({id: p.id, score: 0, matchedField: null, snippet: null});
  return [...recent.map((id) => row(byId.get(id))), ...rest.map(row)];
};

/**
 * @returns {{id: string, score: number, matchedField: string|null, snippet: string|null}[]}
 */
export const rank = (prompts, query, usage, now) => {
  const terms = fold(query)
    .split(/\s+/)
    .filter((t) => t !== "");
  if (terms.length === 0) return emptyRank(prompts, usage);

  const structured = [];
  const bodyPool = [];
  prompts.forEach((p, i) => {
    const m = structuredMatch(p, terms);
    if (m === null) bodyPool.push({p, i});
    else structured.push({p, i, m, f: frecency(usage, p.id, now)});
  });

  structured.sort(
    (a, b) =>
      b.m.score - a.m.score ||
      b.f - a.f ||
      FIELD_ORDER[a.m.field] - FIELD_ORDER[b.m.field] ||
      a.i - b.i,
  );

  const body = [];
  if (structured.length < DISPLAY_CHUNK && terms.every((t) => t.length >= 3)) {
    for (const c of bodyPool) {
      if (terms.every((t) => c.p.search.body.includes(t)))
        body.push({...c, f: frecency(usage, c.p.id, now)});
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
