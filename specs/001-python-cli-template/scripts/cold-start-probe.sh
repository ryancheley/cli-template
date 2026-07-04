#!/bin/sh
# T048/AC8 verification (spec SC-008): drive a FRESH headless Claude Code
# session in a temp copy of the template and confirm it scaffolds a new tool
# using only in-repo documentation.
#
# SEMI-MANUAL by plan decision: spends real tokens and takes minutes. Run it
# deliberately; afterwards review the transcript for clarifying questions
# attributable to missing documentation (there must be none).
set -eu
. "$(dirname "$0")/lib.sh"

command -v claude >/dev/null 2>&1 || fail "claude CLI not installed"

git clone --quiet "$ROOT" "$WORK/probe"
cd "$WORK/probe"
transcript=$(mktemp /tmp/cold-start-probe-XXXXXX.log)

claude -p "Scaffold this template into a new CLI tool named probe-tool by Probe Author, \
email probe@example.com, GitHub owner probeowner, description 'probe tool'. \
Follow CLAUDE.md exactly. Verify per its post-init instructions. Do not push anything." \
    --dangerously-skip-permissions >"$transcript" 2>&1 || { tail -20 "$transcript"; fail "session exited non-zero"; }

test ! -f scripts/init.py || fail "session did not run init (script still present)"
grep -rqiE 'cli[-_]template' --exclude-dir=.git --exclude-dir=.venv --exclude=uv.lock . && fail "placeholder residue after session" || true
uv run probe-tool --version >/dev/null || fail "scaffolded CLI does not run"

echo "PASS: cold-start probe scaffolded probe-tool from in-repo docs alone"
echo "Transcript for manual review (clarifying questions = FAIL): $transcript"
