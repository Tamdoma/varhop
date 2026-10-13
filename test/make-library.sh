#!/usr/bin/env bash
# make-library.sh <prompt-count> <repo-id> <account-id> <login> <out-path>
# Writes a synthetic library.json bundle in varhop-fetch's shape: every other
# prompt gets a ~20 KB body. Fixture input for the search/latency live checks.
set -u
N=${1:?prompt count}
RID=${2:?repo id}
AID=${3:?account id}
LOGIN=${4:?login}
OUT=${5:?out path}
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

BODY=$(printf 'word %.0s' $(seq 1 3000))
{
  echo -n '{"version":1,"generation":1,"repo":"Tamdoma/varhop-prompts","repoId":'"$RID"',"accountId":'"$AID"',"login":"'"$LOGIN"'","commit":"synthetic","fetchedAt":0,"status":"ok","slot":"a","files":['
  for i in $(seq 1 "$N"); do
    if [ "$i" -gt 1 ]; then echo -n ","; fi
    if [ $((i % 2)) -eq 0 ]; then text="---\ntitle: Prompt $i\ndescription: synthetic row $i\n---\n$BODY"; else text="---\ntitle: Prompt $i\ndescription: synthetic row $i\n---\nbody $i {{A}}"; fi
    jq -nc --arg p "prompts/cat$((i % 10))/p$i.md" --arg t "$text" '{path:$p,text:$t}'
  done
  echo -n '],"errors":[]}'
} > "$TMP"
mv -f "$TMP" "$OUT"
