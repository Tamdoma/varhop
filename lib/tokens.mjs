const NAME = /[A-Z0-9_]/;

const matchToken = (body, start) => {
  let end = start + 2;
  while (end < body.length && NAME.test(body[end])) end++;
  if (end > start + 2 && body[end] === "}" && body[end + 1] === "}")
    return {name: body.slice(start + 2, end), raw: body.slice(start, end + 2)};
  return null;
};

export const splitSegments = (body) => {
  const segs = [];
  let start = 0;
  let i = 0;
  while (i < body.length) {
    const at = body[i] === "\\" && body.startsWith("{{", i + 1) ? i + 1 : i;
    const token = body.startsWith("{{", at) ? matchToken(body, at) : null;
    if (token && at === i) {
      const text = body.slice(start, i);
      if (text) segs.push({kind: "text", text});
      segs.push({kind: "token", name: token.name, raw: token.raw});
      i += token.raw.length;
      start = i;
    } else if (token) {
      const text = body.slice(start, i);
      if (text) segs.push({kind: "text", text});
      i = at + token.raw.length;
      start = at;
    } else {
      i++;
    }
  }
  if (start < body.length) segs.push({kind: "text", text: body.slice(start)});
  return segs;
};

export const uniqueNames = (body) => {
  const seen = new Set();
  for (const seg of splitSegments(body)) {
    if (seg.kind === "token") seen.add(seg.name);
  }
  return [...seen];
};
