# Contract: justfile Recipe Catalog

**Feature**: 001-python-cli-template

Default recipe: `just --list` (via `default: just --list` alias). Shell: sh
(just's default). Every recipe carries `[group('...')]` and a one-line doc
comment. `uv run` everywhere; the strings `pip install`, `poetry`, `pipx`, and
the bare `pre-commit` command appear nowhere.

## setup

| Recipe | Behavior |
|--------|----------|
| `install` | `uv sync --dev` |
| `install-hooks` | `prek install` |
| `init name= author= email= github= description= [title=]` | Pass-through to `scripts/init.py` (see init-contract). Delimited by marker comments; removed by init itself. |

## quality

| Recipe | Behavior |
|--------|----------|
| `lint` | `uv run ruff check .` |
| `lint-fix` | `uv run ruff check --fix .` |
| `format` | `uv run ruff format .` |
| `format-check` | `uv run ruff format --check .` |
| `typecheck` | `uv run ty check` |
| `security` | `uv run zizmor .github/workflows/` |
| `fix` | lint-fix then format |
| `check` | format-check → lint → typecheck → security → test-cov; fails fast (recipe dependencies, so first failure stops the chain) |

## test

| Recipe | Behavior |
|--------|----------|
| `test` | `uv run pytest` |
| `test-cov` | `uv run pytest --cov --cov-fail-under=80` (thresholds/branch config live in pyproject) |

## build

| Recipe | Behavior |
|--------|----------|
| `build` | remove `dist/`, `uv build` |
| `build-check` | build, then `uv run twine check dist/*` |
| `clean` | remove dist, caches (`.pytest_cache`, `.ruff_cache`, coverage files) |

## cli

| Recipe | Behavior |
|--------|----------|
| `run *ARGS` | `uv run cli-template {{ARGS}}` — try the CLI without installing globally |

## dev

| Recipe | Behavior |
|--------|----------|
| `deps-update` | `uv lock --upgrade && uv sync` |
| `deps-audit` | `uv run pip-audit` (advisory in CI, blocking locally by choice) |
| `doctor` | Report: uv version, just version, python version, git branch + clean/dirty, prek installed?, `uv run python -c "import cli_template"` OK? Exit non-zero if any hard requirement missing |

## release

All release recipes are POSIX-sh bodies; semver parsing via a
`uv run --no-project python -c` one-liner (dependency-free).

| Recipe | Behavior |
|--------|----------|
| `release-check version` | Validate `^\d+\.\d+\.\d+$`; compare to current `pyproject.toml` version; classify bump as major/minor/patch; reject non-increments |
| `release-status` | Current version, `git describe --tags`, commits since last tag, `gh run list --limit 5` |
| `release version` | Preflight 1–6 (below) then M1–M5 (below) |
| `rollback-release version` | Interactive `read -p` confirmation → verify tag exists → delete remote tag → delete local tag → revert bump commit → `git push --force-with-lease`; truthful state reporting when preconditions differ |

### `release` preflight — each failure aborts with its own message, no mutations

1. `git branch --show-current` == `main` → else "Not on main (on X). Switch to main first."
2. `git status --porcelain` empty → else "Working tree dirty. Commit or stash first."
3. after `git fetch origin main`: local == `origin/main` → else "Local main differs from origin/main. Pull/push first."
4. `gh auth status` → else "GitHub CLI not authenticated. Run: gh auth login"
5. `grep -q "^## \[<version>\]" CHANGELOG.md` → else "CHANGELOG.md has no ## [<version>] section. Add it in the same PR as your changes."
6. tag `v<version>` does not already exist locally or on origin → else distinct message (edge case from spec)
7. `just check` passes → else "Checks failed; release aborted."

(Constitutional checks are 1–5 + check; the tag-existence guard is check 6 from
the spec's edge cases, inserted before the expensive `just check`.)

### `release` mutations + compensations

M1 bump version in `pyproject.toml` (single source of truth) → M2 `uv sync` →
M3 commit `pyproject.toml uv.lock` (emoji-prefixed message per user convention,
e.g. `🔖 release: v<version>`) → M4 `git push` + verify with
`git ls-remote origin refs/heads/main` == local HEAD → M5 tag + push tag.
Push failure at M4: `git reset --hard HEAD~1`, report. Tag-push failure at M5:
delete local tag, report that the bump commit is already on origin and what to
do next.

## docs / help / git groups

| Recipe | Behavior |
|--------|----------|
| `docs` group | v1: `changelog-check` (assert `## [Unreleased]` exists) — placeholder group kept minimal |
| `help` group | `default` → `just --list` |
| `git` group | `hooks-run` → `prek run --all-files` |

## Contract tests (template validation phase)

- `just --list` exit 0, shows all groups.
- Every constitutional recipe name present (scripted grep of `just --summary`).
- Negative release matrix per quickstart.md.
