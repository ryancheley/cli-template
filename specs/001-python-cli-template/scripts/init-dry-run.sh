#!/bin/sh
# T031/T041 verification (BLOCKING, spec SC-001/SC-002): full init dry run in a
# temp clone — zero placeholder residue, dev artifacts gone, init disarmed,
# renamed CLI works, full gate green.
set -eu
. "$(dirname "$0")/lib.sh"

git clone --quiet "$ROOT" "$WORK/init"
cd "$WORK/init"

start=$(date +%s)
just init name=demo-tool author="Test Author" email=test@example.com github=testowner description="A demo tool" \
    >"$WORK/init.log" 2>&1 || { cat "$WORK/init.log"; fail "init exited non-zero"; }

# Residue: every old token variant, case-insensitive, across the whole tree.
RESIDUE='cli[-_]template|ryan cheley|rcheley@gmail\.com|ryancheley'
if grep -rqiE "$RESIDUE" --exclude-dir=.git --exclude-dir=.venv --exclude=uv.lock .; then
    grep -riE "$RESIDUE" --exclude-dir=.git --exclude-dir=.venv --exclude=uv.lock . | head -20
    fail "placeholder residue found"
fi

test ! -f scripts/init.py || fail "scripts/init.py still present"
just --summary 2>/dev/null | tr ' ' '\n' | grep -qx init && fail "init recipe still in justfile" || true
test ! -d .specify || fail ".specify/ not removed (amendment A1)"
test ! -d specs || fail "specs/ not removed (amendment A1)"
grep -qE 'SPECKIT|template-only' CLAUDE.md 2>/dev/null && fail "template-only/speckit blocks still in CLAUDE.md" || true

uv run demo-tool --version >/dev/null || fail "renamed CLI --version failed"
uv run demo-tool hello | grep -q "Hello, World!" || fail "renamed CLI hello failed"
just check >"$WORK/check.log" 2>&1 || { tail -20 "$WORK/check.log"; fail "just check failed post-init"; }

elapsed=$(( $(date +%s) - start ))
echo "PASS: init dry run (residue-free, disarmed, dev artifacts gone, gates green; ${elapsed}s)"
