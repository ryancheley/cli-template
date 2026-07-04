# cli-template development interface — every dev and CI action is a recipe here.
# If you have to remember a raw command, that's a missing recipe.

# List all recipes
[group('help')]
default:
    @just --list

# Install all dependencies (including dev group)
[group('setup')]
install:
    uv sync --dev

# Install git hooks via prek
[group('setup')]
install-hooks:
    prek install

# Lint with ruff
[group('quality')]
lint:
    uv run ruff check .

# Lint and auto-fix with ruff
[group('quality')]
lint-fix:
    uv run ruff check --fix .

# Format with ruff
[group('quality')]
format:
    uv run ruff format .

# Check formatting without changing files
[group('quality')]
format-check:
    uv run ruff format --check .

# Type-check with ty
[group('quality')]
typecheck:
    uv run ty check

# Audit GitHub Actions workflows with zizmor
[group('quality')]
security:
    uv run zizmor .github/workflows/

# Auto-fix lint findings, then format
[group('quality')]
fix: lint-fix format

# Run every quality gate plus tests, fail fast
[group('quality')]
check: format-check lint typecheck security test-cov

# Run the test suite
[group('test')]
test:
    uv run pytest

# Run tests with coverage, enforcing the 80% floor
[group('test')]
test-cov:
    uv run pytest --cov --cov-fail-under=80

# Build sdist and wheel into a clean dist/
[group('build')]
build:
    rm -rf dist
    uv build

# Build, then validate the artifacts with twine
[group('build')]
build-check: build
    uv run twine check dist/*

# Remove build artifacts and tool caches
[group('build')]
clean:
    rm -rf dist .pytest_cache .ruff_cache .coverage htmlcov coverage.xml

# Run the CLI without installing it globally
[group('cli')]
run *ARGS:
    uv run cli-template {{ ARGS }}

# Upgrade the lockfile and re-sync
[group('dev')]
deps-update:
    uv lock --upgrade
    uv sync

# Audit dependencies for known vulnerabilities
[group('dev')]
deps-audit:
    uv run pip-audit

# Environment health check
[group('dev')]
doctor:
    #!/bin/sh
    set -u
    status=0
    if command -v uv >/dev/null 2>&1; then echo "uv:      $(uv --version)"; else echo "uv:      MISSING"; status=1; fi
    if command -v just >/dev/null 2>&1; then echo "just:    $(just --version)"; else echo "just:    MISSING"; status=1; fi
    if command -v prek >/dev/null 2>&1; then echo "prek:    $(prek --version)"; else echo "prek:    MISSING"; status=1; fi
    echo "python:  $(uv run python --version 2>/dev/null || echo 'venv missing — run: just install')"
    echo "branch:  $(git branch --show-current 2>/dev/null || echo 'not a git repo')"
    if [ -z "$(git status --porcelain 2>/dev/null)" ]; then echo "git:     clean"; else echo "git:     dirty"; fi
    if uv run python -c "import cli_template" 2>/dev/null; then echo "import:  cli_template OK"; else echo "import:  FAILED — run: just install"; status=1; fi
    exit $status

# Run all git hooks against every file
[group('git')]
hooks-run:
    prek run --all-files

# Assert the changelog has an Unreleased section
[group('docs')]
changelog-check:
    grep -q '^## \[Unreleased\]' CHANGELOG.md

# Validate a version string and classify the bump (major/minor/patch)
[group('release')]
release-check version:
    #!/bin/sh
    set -eu
    current=$(grep -m1 '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')
    uv run --no-project python -c '
    import re, sys
    new, cur = sys.argv[1], sys.argv[2]
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", new):
        sys.exit(f"ERROR: {new!r} is not semver X.Y.Z (e.g. 1.2.3).")
    nt = tuple(map(int, new.split(".")))
    ct = tuple(map(int, cur.split(".")))
    if nt <= ct:
        sys.exit(f"ERROR: {new} is not an increment over the current version {cur}.")
    if nt == (ct[0] + 1, 0, 0):
        print(f"{new} is a valid MAJOR bump from {cur}")
    elif nt == (ct[0], ct[1] + 1, 0):
        print(f"{new} is a valid MINOR bump from {cur}")
    elif nt == (ct[0], ct[1], ct[2] + 1):
        print(f"{new} is a valid PATCH bump from {cur}")
    else:
        sys.exit(
            f"ERROR: {new} is not a single increment from {cur} "
            f"(expected {ct[0] + 1}.0.0, {ct[0]}.{ct[1] + 1}.0, or {ct[0]}.{ct[1]}.{ct[2] + 1})."
        )
    ' "{{ version }}" "$current"

# Show current version, commits since last tag, and recent CI runs
[group('release')]
release-status:
    #!/bin/sh
    set -u
    echo "Current version: $(grep -m1 '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')"
    last=$(git describe --tags --abbrev=0 2>/dev/null || echo none)
    echo "Last tag:        $last"
    if [ "$last" != "none" ]; then
        echo "Commits since:   $(git rev-list "$last"..HEAD --count)"
    else
        echo "Commits total:   $(git rev-list HEAD --count)"
    fi
    echo "Recent CI runs:"
    gh run list --limit 5 2>/dev/null || echo "  (gh unavailable)"

# Release a version: pre-flight checks, bump, commit, push, tag (see CLAUDE.md)
[group('release')]
release version: (release-check version)
    #!/bin/sh
    set -eu
    v="{{ version }}"
    branch=$(git branch --show-current)
    if [ "$branch" != "main" ]; then
        echo "ERROR: Not on main (on '$branch'). Switch first: git switch main" >&2
        exit 1
    fi
    if [ -n "$(git status --porcelain)" ]; then
        echo "ERROR: Working tree is dirty. Commit or stash your changes first." >&2
        exit 1
    fi
    git fetch origin main --quiet
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
        echo "ERROR: Local main differs from origin/main. Pull or push first, then retry." >&2
        exit 1
    fi
    if ! gh auth status >/dev/null 2>&1; then
        echo "ERROR: GitHub CLI is not authenticated. Run: gh auth login" >&2
        exit 1
    fi
    if ! grep -q "^## \[$v\]" CHANGELOG.md; then
        echo "ERROR: CHANGELOG.md has no '## [$v]' section. Add it before releasing (same PR as the changes)." >&2
        exit 1
    fi
    if git rev-parse -q --verify "refs/tags/v$v" >/dev/null; then
        echo "ERROR: Tag v$v already exists locally. If a release failed midway, run: just rollback-release $v" >&2
        exit 1
    fi
    if [ -n "$(git ls-remote --tags origin "refs/tags/v$v")" ]; then
        echo "ERROR: Tag v$v already exists on origin. Pick a new version or roll back first." >&2
        exit 1
    fi
    if ! just check; then
        echo "ERROR: 'just check' failed. Fix the failures, then re-run the release." >&2
        exit 1
    fi
    echo "Pre-flight passed. Releasing v$v..."
    uv run --no-project python -c '
    import pathlib, re, sys
    p = pathlib.Path("pyproject.toml")
    p.write_text(re.sub(r"(?m)^version = \".*\"$", f"version = \"{sys.argv[1]}\"", p.read_text(), count=1))
    ' "$v"
    uv sync --quiet
    git add pyproject.toml uv.lock
    git commit -m "🔖 release: v$v"
    if ! git push origin main; then
        echo "ERROR: Push failed. Rolling back the local bump commit." >&2
        git reset --hard HEAD~1
        exit 1
    fi
    git fetch origin main --quiet
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
        echo "ERROR: Push verification failed — origin/main is not at the bump commit. Investigate before tagging." >&2
        exit 1
    fi
    git tag "v$v"
    if ! git push origin "v$v"; then
        git tag -d "v$v"
        echo "ERROR: Tag push failed; local tag removed. NOTE: the bump commit IS already on origin/main." >&2
        echo "Re-run when connectivity is back: git tag v$v && git push origin v$v — or roll back: just rollback-release $v" >&2
        exit 1
    fi
    echo "Released v$v: bump commit and tag pushed. The publish workflow takes it from here."
    echo "Watch it with: gh run watch"

# Undo a release: delete the tag (remote+local) and revert the bump commit
[group('release')]
rollback-release version:
    #!/bin/sh
    set -eu
    v="{{ version }}"
    echo "This will delete tag v$v (remote and local) and revert the version-bump commit."
    printf "Type 'yes' to continue: "
    read -r answer
    case "$answer" in
        y|yes) ;;
        *) echo "Aborted. Nothing changed."; exit 1 ;;
    esac
    remote_tag=$(git ls-remote --tags origin "refs/tags/v$v")
    local_tag=$(git rev-parse -q --verify "refs/tags/v$v" || true)
    if [ -z "$remote_tag" ] && [ -z "$local_tag" ]; then
        echo "ERROR: Tag v$v exists neither locally nor on origin — nothing to roll back. Was $v ever released?" >&2
        exit 1
    fi
    if [ -n "$remote_tag" ]; then
        git push origin ":refs/tags/v$v"
        echo "Deleted remote tag v$v."
    else
        echo "Remote tag v$v not found (already deleted?) — skipping."
    fi
    if [ -n "$local_tag" ]; then
        git tag -d "v$v"
        echo "Deleted local tag v$v."
    fi
    if git log -1 --pretty=%s | grep -q "release: v$v"; then
        git revert --no-edit HEAD
        git push --force-with-lease origin main
        echo "Reverted the bump commit and pushed."
    else
        echo "WARNING: HEAD is not the v$v bump commit; not reverting automatically." >&2
        echo "Find it with: git log --oneline --grep=\"release: v$v\"" >&2
    fi
    echo "Rollback of v$v complete."
