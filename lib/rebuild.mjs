export const rebuild = (segments, values) => {
  const unset = [];
  const seen = new Set();
  let text = "";
  for (const seg of segments) {
    if (seg.kind === "text") {
      text += seg.text;
    } else if (Object.hasOwn(values, seg.name)) {
      text += values[seg.name];
    } else {
      text += seg.raw;
      if (!seen.has(seg.name)) {
        seen.add(seg.name);
        unset.push(seg.name);
      }
    }
  }
  return {text, unset};
};
