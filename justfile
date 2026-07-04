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
