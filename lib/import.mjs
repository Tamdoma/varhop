import {splitSegments, uniqueNames} from "./tokens.mjs";
import {fold} from "./fold.mjs";

const KNOWN_KEYS = new Set(["title", "description", "tags"]);
const KEY_LINE = /^([A-Za-z0-9_-]+):(?:[ \t]+(.*))?$/;
const IS_ITEM = /^\s*-(?:\s|$)/;
const INDENTED = /^[ \t]/;
const UNSUPPORTED_SCALAR = /^[|>{&*!\[]/;

const DQ_ESCAPES = {
  n: "\n",
  r: "\r",
  t: "\t",
  b: "\b",
  f: "\f",
  '"': '"',
  "/": "/",
  "\\": "\\",
};

const splitLines = (text) => {
  const lines = [];
  let i = 0;
  while (i < text.length) {
    const nl = text.indexOf("\n", i);
    const end = nl === -1 ? text.length : nl + 1;
    lines.push({content: text.slice(i, nl === -1 ? end : nl), end});
    i = end;
  }
  return lines;
};

const bare = (line) => (line.endsWith("\r") ? line.slice(0, -1) : line);

const withoutComment = (s) => {
  const i = s.indexOf(" #");
  return i === -1 ? s : s.slice(0, i);
};

const cleanRest = (rest) => rest === "" || rest.startsWith("#");

const singleQuoted = (t) => {
  let out = "";
  let i = 1;
  for (;;) {
    const q = t.indexOf("'", i);
    if (q === -1) return {error: "unterminated single-quoted scalar"};
    if (t[q + 1] === "'") {
      out += t.slice(i, q) + "'";
      i = q + 2;
      continue;
    }
    out += t.slice(i, q);
    if (!cleanRest(t.slice(q + 1).trim()))
      return {error: "unexpected content after quoted scalar"};
    return {value: out};
  }
};

const doubleQuoted = (t) => {
  let out = "";
  let i = 1;
  for (;;) {
    if (i >= t.length) return {error: "unterminated double-quoted scalar"};
    const c = t[i];
    if (c === '"') {
      if (!cleanRest(t.slice(i + 1).trim()))
        return {error: "unexpected content after quoted scalar"};
      return {value: out};
    }
    if (c === "\\") {
      const e = t[i + 1];
      if (e === undefined) return {error: "unterminated double-quoted scalar"};
      if (e === "u") {
        const hex = t.slice(i + 2, i + 6);
        if (!/^[0-9A-Fa-f]{4}$/.test(hex))
          return {error: "invalid unicode escape in double-quoted scalar"};
        out += String.fromCharCode(parseInt(hex, 16));
        i += 6;
        continue;
      }
      const mapped = DQ_ESCAPES[e];
      if (mapped === undefined)
        return {error: "unsupported escape in double-quoted scalar"};
      out += mapped;
      i += 2;
      continue;
    }
    out += c;
    i += 1;
  }
};

const plainScalar = (t) => {
  const v = withoutComment(t).trim();
  if (v === "" || v === "~" || v === "null") return {absent: true};
  if (v.includes(": ")) return {error: "unsupported ': ' in unquoted scalar"};
  return {value: v};
};

const scalarValue = (t) => {
  if (t.startsWith("'")) return singleQuoted(t);
  if (t.startsWith('"')) return doubleQuoted(t);
  if (UNSUPPORTED_SCALAR.test(t)) return {error: "unsupported scalar form"};
  return plainScalar(t);
};

const quotedEnd = (s, i) => {
  const q = s[i];
  i += 1;
  while (i < s.length) {
    if (q === '"' && s[i] === "\\") i += 2;
    else if (q === "'" && s[i] === "'" && s[i + 1] === "'") i += 2;
    else if (s[i] === q) return i;
    else i += 1;
  }
  return -1;
};

const flowList = (t) => {
  const items = [];
  let i = 1;
  let start = 1;
  for (;;) {
    if (i >= t.length) return {error: "unterminated flow list"};
    const c = t[i];
    if (c === "'" || c === '"') {
      const end = quotedEnd(t, i);
      if (end === -1) return {error: "unterminated quoted item in flow list"};
      i = end + 1;
      continue;
    }
    if (c === ",") {
      items.push(t.slice(start, i));
      start = i + 1;
      i += 1;
      continue;
    }
    if (c === "]") {
      items.push(t.slice(start, i));
      if (!cleanRest(t.slice(i + 1).trim()))
        return {error: "unexpected content after flow list"};
      return {items};
    }
    i += 1;
  }
};

const itemTag = (raw, path, line, errors) => {
  const t = raw.trim();
  if (t === "") return [];
  const r = scalarValue(t);
  if (r.error) {
    errors.push({path, line, message: r.error});
    return [];
  }
  return r.absent ? [] : [r.value];
};

const tagValue = (t) => (t.startsWith("[") ? flowList(t) : scalarValue(t));

const nestedBelow = (lines, end, idx, itemsOk) => {
  const next = idx + 1;
  if (next >= end) return false;
  const l = bare(lines[next].content);
  if (itemsOk) return INDENTED.test(l) && !IS_ITEM.test(l);
  return INDENTED.test(l) || IS_ITEM.test(l);
};

const parseHeader = (path, lines, end, errors) => {
  const seen = new Set();
  const out = {title: undefined, description: undefined, tags: undefined};
  let tagsOpen = false;

  for (let idx = 1; idx < end; idx += 1) {
    const line = bare(lines[idx].content);
    const no = idx + 1;
    const keyMatch = KEY_LINE.exec(line);

    if (keyMatch) {
      tagsOpen = false;
      const key = keyMatch[1];
      const raw = (keyMatch[2] === undefined ? "" : keyMatch[2]).trim();
      if (!KNOWN_KEYS.has(key)) {
        while (idx + 1 < end) {
          const next = bare(lines[idx + 1].content);
          if (!INDENTED.test(next) && !IS_ITEM.test(next) && next.trim() !== "") break;
          idx += 1;
        }
        continue;
      }
      if (seen.has(key)) {
        errors.push({path, line: no, message: "duplicate key \"" + key + "\""});
        continue;
      }
      seen.add(key);
      if (key === "tags") {
        const r = tagValue(raw);
        if (r.error) {
          errors.push({path, line: no, message: r.error});
        } else {
          out.tags = r.items
            ? r.items.reduce((acc, item) => acc.concat(itemTag(item, path, no, errors)), [])
            : r.absent
              ? []
              : [r.value];
          tagsOpen = true;
          if (r.absent && nestedBelow(lines, end, idx, true))
            errors.push({path, line: no, message: "unsupported nested value for \"tags\""});
        }
      } else {
        const r = scalarValue(raw);
        if (r.error) {
          errors.push({path, line: no, message: r.error});
        } else if (r.absent) {
          if (nestedBelow(lines, end, idx, false))
            errors.push({path, line: no, message: "unsupported nested value for \"" + key + "\""});
        } else {
          out[key] = r.value;
        }
      }
      continue;
    }

    if (IS_ITEM.test(line) && tagsOpen) {
      const r = scalarValue(line.slice(line.indexOf("-") + 1).trim());
      if (r.error) errors.push({path, line: no, message: r.error});
      else if (!r.absent) out.tags.push(r.value);
      continue;
    }

    tagsOpen = false;
    errors.push({path, line: no, message: "unrecognized header line"});
  }

  if (out.tags !== undefined) out.tags = [...new Set(out.tags)];
  return out;
};

const importOne = (path, text) => {
  const errors = [];
  const parts = path.split("/");
  const fileName = parts[parts.length - 1];
  const stem = fileName.slice(0, -3);
  const category = parts[1];
  const subcategory = parts.length === 4 ? parts[2] : null;

  const source = text.startsWith("\uFEFF") ? text.slice(1) : text;
  const lines = splitLines(source);
  let body = source;
  let title;
  let description;
  let tags = [];

  if (lines.length > 0 && bare(lines[0].content) === "---") {
    const close = lines.findIndex((l, i) => i > 0 && bare(l.content) === "---");
    if (close === -1) {
      errors.push({path, line: 1, message: "unclosed front-matter header"});
    } else {
      const parsed = parseHeader(path, lines, close, errors);
      title = parsed.title;
      description = parsed.description;
      tags = parsed.tags === undefined ? [] : parsed.tags;
      body = source.slice(lines[close].end);
    }
  }

  const finalTitle = title === undefined ? stem : title;
  const finalDescription = description === undefined ? null : description;

  return {
    prompt: {
      id: path,
      category,
      subcategory,
      fileName,
      title: finalTitle,
      description: finalDescription,
      tags,
      body,
      segments: splitSegments(body),
      names: uniqueNames(body),
      search: {
        title: fold(finalTitle),
        fileName: fold(stem),
        tags: tags.map((t) => fold(t)),
        category: fold(category),
        subcategory: subcategory === null ? null : fold(subcategory),
        description: finalDescription === null ? null : fold(finalDescription),
        body: fold(body),
      },
    },
    errors,
  };
};

export const importLibrary = (files) => {
  const prompts = [];
  const errors = [];
  for (const f of files) {
    const {path, text} = f;
    if (!path.startsWith("prompts/") || !path.endsWith(".md")) continue;
    const depth = path.split("/").length;
    if (depth < 3 || depth > 4) {
      errors.push({
        path,
        line: null,
        message:
          "path must be prompts/<category>/<name>.md or prompts/<category>/<subcategory>/<name>.md",
      });
      continue;
    }
    const r = importOne(path, text);
    prompts.push(r.prompt);
    for (const e of r.errors) errors.push(e);
  }
  return {prompts, errors};
};
