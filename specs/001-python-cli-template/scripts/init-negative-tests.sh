#!/bin/sh
# T032 verification (quickstart V3): init validates before mutating and
# refuses to run twice.
set -eu
. "$(dirname "$0")/lib.sh"

# N1: invalid name — exit 2, zero files modified.
git clone --quiet "$ROOT" "$WORK/n1"
cd "$WORK/n1"
uv run --no-project python scripts/init.py \
    --name "9bad name" --author "A" --email a@b.co --github x --description d \
    >"$WORK/n1.log" 2>&1 && fail "N1: invalid name should exit non-zero" || rc=$?
[ "${rc:-0}" -eq 2 ] || fail "N1: expected exit 2, got ${rc:-0}"
grep -q -- '--name' "$WORK/n1.log" || fail "N1: message does not name the offending argument"
grep -qi 'foo-tool\|kebab' "$WORK/n1.log" || fail "N1: message does not show a valid example"
[ -z "$(git status --porcelain)" ] || fail "N1: files were modified before validation passed"
echo "PASS N1: invalid name -> exit 2, actionable message, zero mutations"

# N2: second run refuses — exit 3, "already initialized".
git clone --quiet "$ROOT" "$WORK/n2"
cd "$WORK/n2"
just init name=ok-tool author="A" email=a@b.co github=x description=d \
    >"$WORK/n2-first.log" 2>&1 || { cat "$WORK/n2-first.log"; fail "N2: first init should succeed"; }
git checkout --quiet HEAD -- scripts/init.py   # simulate someone restoring the script
uv run --no-project python scripts/init.py \
    --name other --author "A" --email a@b.co --github x --description d \
    >"$WORK/n2.log" 2>&1 && fail "N2: second init should refuse" || rc=$?
[ "${rc:-0}" -eq 3 ] || fail "N2: expected exit 3, got ${rc:-0}"
grep -qi 'already initialized' "$WORK/n2.log" || fail "N2: message does not say already initialized"
echo "PASS N2: second init -> exit 3, already-initialized refusal"

echo "PASS: all init negative scenarios"
