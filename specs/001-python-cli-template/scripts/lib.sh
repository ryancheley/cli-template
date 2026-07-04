#!/bin/sh
# Shared helpers for template validation scripts. Sourced, not executed.
# Each scenario gets a fresh clone of the repo's committed HEAD with a local
# bare repository standing in for origin — no network, no real pushes.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

# make_repo <name>: clone committed HEAD to $WORK/<name>, with bare origin
# $WORK/<name>-origin.git tracking a main branch at the same commit.
make_repo() {
    bare="$WORK/$1-origin.git"
    clone="$WORK/$1"
    git init --bare --quiet "$bare"
    git clone --quiet "$ROOT" "$clone"
    (
        cd "$clone"
        git switch --quiet -c main 2>/dev/null || git switch --quiet main
        git remote set-url origin "$bare"
        git push --quiet origin main
    )
}

# seed_changelog <clone> with|without : commit a changelog that does or does
# not contain the ## [0.1.0] section the release pre-flight requires.
seed_changelog() {
    (
        cd "$1"
        if [ "$2" = "with" ]; then
            printf '# Changelog\n\n## [Unreleased]\n\n## [0.1.0]\n\n- Test release.\n' > CHANGELOG.md
        else
            printf '# Changelog\n\n## [Unreleased]\n' > CHANGELOG.md
        fi
        git add CHANGELOG.md
        git commit --quiet -m "docs: seed changelog for release test"
        git push --quiet origin main
    )
}
