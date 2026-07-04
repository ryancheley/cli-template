#!/bin/sh
# T022 verification: full `just release` mutation path against a local bare
# origin — bump committed, pushed, verified, tagged, tag pushed.
set -eu
. "$(dirname "$0")/lib.sh"

make_repo happy
seed_changelog "$WORK/happy" with
cd "$WORK/happy"
orig_version=$(grep -m1 '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')
uv sync --quiet

just release 0.1.0 </dev/null >"$WORK/happy.log" 2>&1 || {
    cat "$WORK/happy.log"
    fail "release exited non-zero (started from $orig_version)"
}

[ -n "$(git ls-remote --tags origin refs/tags/v0.1.0)" ] || fail "tag v0.1.0 not on origin"
grep -q 'version = "0.1.0"' pyproject.toml || fail "pyproject version not bumped"
[ "$(git rev-parse HEAD)" = "$(git -C "$WORK/happy-origin.git" rev-parse main)" ] || fail "bump commit not on origin/main"
[ -z "$(git status --porcelain)" ] || fail "working tree dirty after release"

echo "PASS: release happy path (bump $orig_version -> 0.1.0, commit + tag on origin)"
