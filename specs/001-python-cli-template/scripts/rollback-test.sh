#!/bin/sh
# T023/T046 verification: rollback-release declines safely and, on
# confirmation, deletes the tag (remote + local) and reverts the bump commit.
set -eu
. "$(dirname "$0")/lib.sh"

make_repo rb
seed_changelog "$WORK/rb" with
cd "$WORK/rb"
orig_version=$(grep -m1 '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')
uv sync --quiet
just release 0.1.0 </dev/null >"$WORK/rb-release.log" 2>&1 || {
    cat "$WORK/rb-release.log"
    fail "setup release failed"
}

# Declining must change nothing.
printf 'n\n' | just rollback-release 0.1.0 >"$WORK/rb-decline.log" 2>&1 && fail "decline should exit non-zero" || true
[ -n "$(git ls-remote --tags origin refs/tags/v0.1.0)" ] || fail "decline deleted the remote tag"
git rev-parse -q --verify refs/tags/v0.1.0 >/dev/null || fail "decline deleted the local tag"
grep -q 'version = "0.1.0"' pyproject.toml || fail "decline changed the version"

# Confirming must fully roll back.
printf 'yes\n' | just rollback-release 0.1.0 >"$WORK/rb-accept.log" 2>&1 || {
    cat "$WORK/rb-accept.log"
    fail "rollback exited non-zero"
}
[ -z "$(git ls-remote --tags origin refs/tags/v0.1.0)" ] || fail "remote tag still present"
git rev-parse -q --verify refs/tags/v0.1.0 >/dev/null && fail "local tag still present" || true
grep -q "version = \"$orig_version\"" pyproject.toml || fail "version bump not reverted to $orig_version"

echo "PASS: rollback (decline is a no-op; confirm removes tag remote+local and reverts bump)"
