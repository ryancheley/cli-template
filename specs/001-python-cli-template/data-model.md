# Data Model: Python CLI Project Template

**Feature**: 001-python-cli-template | **Date**: 2026-07-04

This feature has no runtime database. Its "data" is the set of structured
artifacts the template manipulates: placeholder tokens, init inputs and their
derivations, and the state machines of init and release. These are the entities
every contract and task traces back to.

## Placeholder Token Set

The template uses its **real working names as placeholders** (resolved decision).
Each token is a literal string that exists in the tree today and is rewritten by
init. The inventory is the contract between the template, `scripts/init.py`, and
CLAUDE.md — all three MUST agree.

| Token | Kind | Example occurrences | Replaced by |
|-------|------|--------------------|-------------|
| `cli-template` | Distribution / CLI command / repo name (kebab-case) | `pyproject.toml` `[project] name`, entry-point key, README, justfile, workflows, CLAUDE.md | `name` argument, verbatim |
| `cli_template` | Import package name (snake_case) | `src/cli_template/`, imports, entry-point value, coverage config, doctor recipe | `name` with hyphens → underscores |
| `Cli Template` / `CLI Template` | Human-readable title | README heading, CLAUDE.md | Title-cased `name` (override: `title=`) |
| `A modern Python CLI tool template` (description sentinel) | Short description | `pyproject.toml` `description`, README tagline, CLI help epilog | `description` argument |
| `Ryan Cheley` (author name sentinel) | Author name | `pyproject.toml` `[project] authors`, LICENSE copyright line, CONTRIBUTING | `author` argument |
| `rcheley@gmail.com` (author email sentinel) | Author email | `pyproject.toml` authors | `email` argument |
| `ryancheley` | GitHub owner | README badges/links, `pyproject.toml` `[project.urls]`, CONTRIBUTING | `github` argument (owner part) |
| `ryancheley/cli-template` | GitHub owner/repo | urls, badge paths, release-status recipe | `github` owner + new repo name |
| `2026` (LICENSE year) | Copyright year | LICENSE | Current year at init time |

**Invariants**:

- Every token literal is unique enough to be safely replaced tree-wide
  (`cli_template` is never a substring of an unrelated word; sentinels are exact
  phrases).
- Replacement order matters: longer/more-specific tokens first
  (`ryancheley/cli-template` before `cli-template` before `cli_template` is NOT
  safe in the wrong order — init replaces `cli_template` and `cli-template` as
  distinct tokens and processes owner/repo composites before bare owner).
- Post-init, a tree-wide case-insensitive search for `cli-template`,
  `cli_template`, and each sentinel MUST return zero hits (SC-002); the searched
  tree excludes `.git/`, `.venv/`, and `uv.lock` is regenerated rather than
  searched.

## Init Input Schema

| Field | Required | Validation | Derivations |
|-------|----------|------------|-------------|
| `name` | yes | PEP 503 normalizable distribution name: `^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$`; also must yield a valid CLI command (no dots) | package = `name.replace("-", "_")` (must be a valid Python identifier, not a keyword, not shadowing stdlib top-level like `test`/`json` — warn); title = `name.replace("-", " ").title()` |
| `author` | yes | non-empty | — |
| `email` | yes | contains `@` (light validation) | — |
| `github` | yes | `owner` or `owner/repo`; owner matches GitHub username rules | repo defaults to `name` |
| `description` | yes | non-empty, single line | — |
| `title` | no | non-empty | overrides derived title |

Validation failures abort with exit code 2, name the offending field, and show a
valid example (FR-013). No file is modified before all validation passes.

## Init State Machine

States: `TEMPLATE` → (init) → `INITIALIZED`. One-way; a second run must detect
`INITIALIZED` and refuse (FR-014).

Ordered operations (each step idempotent-unsafe, hence the guard):

1. **Guard**: `scripts/init.py` exists and `src/cli_template/` exists → else
   refuse: "already initialized".
2. **Validate** all inputs (no mutations yet).
3. **Substitute** tokens across all tracked text files (git ls-files; skip
   binary, skip `uv.lock`).
4. **Rename** `src/cli_template/` → `src/<package>/`.
5. **Rewrite** README (template usage instructions → project README stub) and
   reset CHANGELOG to `Unreleased` + `0.1.0` stub.
6. **Disarm**: delete `scripts/init.py` (and `scripts/` if empty); remove the
   `init` recipe from the justfile; delete `.specify/` and `specs/`; strip
   the speckit marker block from CLAUDE.md (plan amendment A1).
7. **Regenerate**: `uv sync` (rewrites `uv.lock` under the new name).
8. **Verify**: run the residue search (zero placeholder hits) and `just check`;
   print both commands and their results; exit non-zero if either fails.

Failure between steps 3–6 leaves a partially transformed tree; init prints the
git command to reset (`git checkout . && git clean -fd` guidance) — git is the
undo mechanism, which is why init requires running inside a git checkout.

## Release State Machine

States: `IDLE` → `PREFLIGHT` → `MUTATING` → `PUSHED` → `TAGGED` (terminal
success), with rollback edges back to `IDLE`.

**Preflight (read-only, all six must pass, distinct abort message each)**:

1. branch == main
2. working tree clean
3. local main == origin/main after fetch
4. `gh auth status` succeeds
5. `CHANGELOG.md` contains `## [<version>]`
6. `just check` passes

**Mutations (ordered, with compensations)**:

| Step | Action | Compensation on later failure |
|------|--------|-------------------------------|
| M1 | bump `version` in `pyproject.toml` | `git checkout pyproject.toml uv.lock` |
| M2 | `uv sync` (lock update) | same as M1 |
| M3 | commit both files | `git reset --hard HEAD~1` |
| M4 | push; verify landed | if push fails → M3 compensation |
| M5 | tag `v<version>`; push tag | if tag push fails → delete local tag, report (commit already public — do not auto-revert remote) |

**Rollback recipe** (`rollback-release <version>`): interactive confirmation →
delete remote tag → delete local tag → revert bump commit → push with
`--force-with-lease`. Preconditions checked first (tag exists? bump commit is
HEAD?) with truthful reporting when state differs (edge cases in spec).

## Recipe Catalog (summary)

Full contract in `contracts/justfile-contract.md`. Groups: setup, quality, test,
build, cli, dev, git, release, docs, help. Constitutional minimum recipes plus
`init` (self-removing) and the release quartet.

## Document Set

README, CHANGELOG (Keep a Changelog; `## [Unreleased]` + `## [0.1.0]` stub),
CONTRIBUTING, LICENSE (MIT, year + author tokens), CLAUDE.md (cold-start
contract, see `contracts/claude-md-contract.md` section in contracts). Each doc
carries placeholder tokens per the inventory above.
