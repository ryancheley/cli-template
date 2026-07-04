#!/bin/sh
# T026/T044 verification (BLOCKING, spec SC-005): each unmet release
# precondition aborts with its own actionable message and zero mutations.
# Scenarios: non-main branch, dirty tree, missing changelog entry, failing
# check, tag already exists.
set -eu
. "$(dirname "$0")/lib.sh"

# assert_no_release <clone>: no v0.1.0 tag anywhere, version untouched.
assert_no_release() {
    (
        cd "$1"
        git rev-parse -q --verify refs/tags/v0.1.0 >/dev/null && fail "$2: local tag was created" || true
        [ -z "$(git ls-remote --tags origin refs/tags/v0.1.0)" ] || fail "$2: remote tag was created"
        grep -q 'version = "0.1.0"' pyproject.toml && fail "$2: version was bumped" || true
    )
}

# --- S1: not on main ---------------------------------------------------------
make_repo s1
cd "$WORK/s1"
git switch --quiet -c feature
out=$(just release 0.1.0 2>&1) && fail "S1: release should abort off-main" || true
echo "$out" | grep -qi 'not on main' || fail "S1: message missing branch cause: $out"
[ -z "$(git status --porcelain)" ] || fail "S1: working tree mutated"
assert_no_release "$WORK/s1" S1
echo "PASS S1: non-main branch aborts, no mutations"

# --- S2: dirty working tree --------------------------------------------------
make_repo s2
cd "$WORK/s2"
echo "uncommitted" >> README.md
out=$(just release 0.1.0 2>&1) && fail "S2: release should abort on dirty tree" || true
echo "$out" | grep -qi 'dirty' || fail "S2: message missing dirty-tree cause: $out"
assert_no_release "$WORK/s2" S2
echo "PASS S2: dirty tree aborts, no mutations"

# --- S3: missing changelog section -------------------------------------------
make_repo s3
seed_changelog "$WORK/s3" without
cd "$WORK/s3"
out=$(just release 0.1.0 2>&1) && fail "S3: release should abort without changelog entry" || true
echo "$out" | grep -Fq "has no '## [0.1.0]'" || fail "S3: message missing changelog cause: $out"
[ -z "$(git status --porcelain)" ] || fail "S3: working tree mutated"
assert_no_release "$WORK/s3" S3
echo "PASS S3: missing changelog entry aborts, no mutations"

# --- S4: failing check --------------------------------------------------------
make_repo s4
seed_changelog "$WORK/s4" with
cd "$WORK/s4"
printf 'import os\n' > bad.py
git add bad.py && git commit --quiet -m "✅ test: introduce lint failure" && git push --quiet origin main
uv sync --quiet
out=$(just release 0.1.0 2>&1) && fail "S4: release should abort on failing check" || true
echo "$out" | grep -Fq "'just check' failed" || fail "S4: message missing check cause: $out"
assert_no_release "$WORK/s4" S4
echo "PASS S4: failing check aborts, no mutations"

# --- S5: tag already exists ----------------------------------------------------
make_repo s5
seed_changelog "$WORK/s5" with
cd "$WORK/s5"
git tag v0.1.0
out=$(just release 0.1.0 2>&1) && fail "S5: release should abort when tag exists" || true
echo "$out" | grep -qi 'already exists' || fail "S5: message missing tag cause: $out"
[ -z "$(git status --porcelain)" ] || fail "S5: working tree mutated"
grep -q 'version = "0.1.0"' pyproject.toml && fail "S5: version was bumped" || true
echo "PASS S5: existing tag aborts, no mutations"

echo "PASS: all 5 negative release scenarios"
