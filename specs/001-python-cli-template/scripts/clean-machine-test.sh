#!/bin/sh
# T042/AC2 verification (spec SC-003): on a machine with only uv, git, just,
# and prek, a fresh clone passes setup + hooks + the full gate with zero
# manual fixes. (Fresh clone + fresh venv is the documented approximation of
# a clean machine; run inside a container for full isolation.)
set -eu
. "$(dirname "$0")/lib.sh"

git clone --quiet "$ROOT" "$WORK/clean"
cd "$WORK/clean"
test ! -d .venv || fail "fresh clone unexpectedly contains a venv"

just install >"$WORK/clean-install.log" 2>&1 || { tail -5 "$WORK/clean-install.log"; fail "just install failed"; }
just install-hooks >>"$WORK/clean-install.log" 2>&1 || fail "just install-hooks failed"
just check >"$WORK/clean-check.log" 2>&1 || { tail -20 "$WORK/clean-check.log"; fail "just check failed on fresh clone"; }
prek run --all-files >"$WORK/clean-hooks.log" 2>&1 || { tail -10 "$WORK/clean-hooks.log"; fail "hook suite failed on fresh clone"; }

echo "PASS: clean-machine setup (install, hooks, full gate green from a fresh clone)"
