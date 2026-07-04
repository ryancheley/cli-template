<!--
Sync Impact Report
==================
Version change: (template, unversioned) → 1.0.0 (initial ratification)
Modified principles: n/a (initial adoption)
Added sections:
  - Purpose
  - Core Principles I–IX (Python Version Policy; Tooling is uv, End to End;
    Code Quality Gates; Testing Discipline; CLI Design Standards; The justfile
    is the Interface; Release via a Single Recipe; CI/CD Standards;
    Documentation Contract)
  - Governance
Removed sections: template placeholder slots (PRINCIPLE_1..5, SECTION_2, SECTION_3)
Templates:
  ✅ .specify/templates/plan-template.md — Constitution Check gate is generic and
     resolves against this file; no change required.
  ✅ .specify/templates/tasks-template.md — updated: tests are no longer marked
     OPTIONAL; aligned with Principle IV (Testing Discipline).
  ✅ .specify/templates/spec-template.md — no constitution-specific sections
     required; no change needed.
  ⚠ CLAUDE.md (project) — currently a stub pointing at "the current plan";
     regenerate per Principle IX when the template scaffolding lands.
Follow-up TODOs: none.
-->

# cli-template Constitution

## Purpose

cli-template is the project template Claude Code uses as the starting point for
all new Python CLI tools. This constitution governs every project generated from
the template. Its principles are non-negotiable defaults: deviations require an
explicit, documented justification in the generated project's plan (Complexity
Tracking table).

The template produces installable Python CLI tools that are ready for open
source release on PyPI from day one. Every generated project MUST be lintable,
type-checked, tested, security-audited, and releasable with a single `just`
command before any feature code is written.

## Core Principles

### I. Python Version Policy

- Python 3.12 is the minimum supported version: `requires-python = ">=3.12"`.
- CI MUST test against 3.12 and 3.13. Newer versions are added to the matrix as
  they reach stable release.
- Code MUST use modern syntax available at the floor version: PEP 604 unions
  (`X | None`), `type` statements, and structural pattern matching where it
  improves clarity. `typing.Optional` is prohibited. `from __future__ import
  annotations` is prohibited unless a concrete need requires it.

**Rationale**: A single modern floor keeps generated code idiomatic and avoids
compatibility shims that add noise without adding users.

### II. Tooling is uv, End to End

- `uv` is the only tool for dependency management, virtual environments,
  builds, and tool execution. pip, poetry, and pipx are prohibited.
- Dependencies are declared in `pyproject.toml` using PEP 621 metadata and
  PEP 735 dependency groups (`[dependency-groups]` with a `dev` group). No
  `requirements.txt` files.
- `uv.lock` is committed and kept in sync. Any recipe that changes
  `pyproject.toml` MUST run `uv sync` and stage `uv.lock`.
- All commands run through `uv run`. Contributors never activate a venv
  manually.
- Package builds use `uv build`.

**Rationale**: One tool with one lockfile eliminates an entire class of
"works on my machine" drift and keeps the justfile recipes deterministic.

### III. Code Quality Gates

- **ruff** handles both linting and formatting. black, isort, and flake8 are
  prohibited; ruff's isort rules replace isort. Configuration lives in
  `pyproject.toml`.
- **ty** is the type checker (not mypy, not pyright). All code is fully
  type-annotated. `ty check` MUST pass with zero errors before merge.
- **zizmor** audits all GitHub Actions workflows. Zero findings at the default
  severity level before merge.
- **prek** manages git hooks (drop-in pre-commit replacement, no Python needed
  to bootstrap). Hooks are defined in `.pre-commit-config.yaml` and installed
  via `prek install`. The hook suite includes at minimum: trailing whitespace,
  end-of-file fixer, YAML/TOML validation, ruff check, ruff format, ty check,
  and zizmor.
- Nothing merges to main with a failing quality gate. There is no
  "fix it later" lane.

**Rationale**: Quality gates only work when they are absolute; a single
exception becomes the precedent for the next ten.

### IV. Testing Discipline

- pytest is the test runner. `pytest-randomly` shuffles test order on every run
  to surface order-dependent bugs; the seed is printed and reusable for
  reproduction.
- Coverage is measured with `pytest-cov`. A minimum coverage threshold (default
  80 percent) is enforced in CI via `--cov-fail-under`.
- CLI behavior is tested through the framework's test runner (e.g.,
  `CliRunner`), not by shelling out.
- Every bug fix ships with a regression test.

**Rationale**: Randomized order and enforced coverage catch the failures that
convenient defaults hide until they reach users.

### V. CLI Design Standards

- Tools are built on **click** with **rich** for terminal output.
- Every tool provides `--version`, `--help`, and shell completion for bash,
  zsh, and fish.
- Output is human-readable by default. Any command whose output someone might
  pipe or script against MUST offer `--format json` (or equivalent).
- Exit codes are meaningful: 0 for success, non-zero for failure, distinct
  codes for distinct failure classes where practical.
- Errors are actionable. Every error message states what went wrong and
  suggests what to do next.
- Secrets never appear in code, config files, or logs. Credentials use keyring
  or environment variables.

**Rationale**: These are the behaviors that separate a scriptable, trustworthy
CLI from a demo; they are cheap at scaffold time and expensive to retrofit.

### VI. The justfile is the Interface

- Every developer and CI action is a `just` recipe. If you have to remember a
  raw command, that is a missing recipe.
- The default recipe is `just --list`.
- Recipes are organized with `[group('...')]` annotations: setup, quality,
  test, build, cli, dev, git, release, docs, help.
- Required recipes at minimum:
  - `install` (uv sync --dev), `install-hooks` (prek install)
  - `lint`, `lint-fix`, `format`, `format-check`, `typecheck`,
    `security` (zizmor), `check` (runs all of the above plus tests, fails fast)
  - `fix` (lint-fix + format)
  - `test`, `test-cov`
  - `build` (clean dist, uv build), `build-check` (build +
    `uv run twine check dist/*`)
  - `clean`, `deps-update`, `deps-audit` (pip-audit)
  - `doctor` (environment health check: python, uv, git status, package
    importability)

**Rationale**: A single discoverable command surface means CI, contributors,
and Claude Code all run exactly the same steps.

### VII. Release via a Single Recipe

- `just release <version>` performs the entire release. It MUST run these
  pre-flight checks and abort on any failure:
  1. Current branch is main.
  2. Working tree is clean.
  3. Local main matches origin/main after a fetch.
  4. `gh auth status` succeeds.
  5. `CHANGELOG.md` contains a `## [<version>]` section.
  6. `just check` passes.
- On success it then: bumps `version` in `pyproject.toml`, runs `uv sync` to
  update the lock, commits both files, pushes, verifies the push landed,
  creates and pushes tag `v<version>`, and rolls back local state if any push
  fails.
- Supporting recipes: `release-check <version>` (validates semver format,
  confirms it is a proper increment, classifies it as major/minor/patch),
  `release-status` (current version, commits since last tag, recent CI runs),
  and `rollback-release <version>` (interactive confirmation, deletes remote
  and local tag, reverts the bump commit with `--force-with-lease`).
- Versioning follows semantic versioning. Tags are `v` prefixed.
- The tag push triggers a GitHub Actions workflow that builds with uv and
  publishes to PyPI using **trusted publishing** (OIDC via
  `pypa/gh-action-pypi-publish`). No API tokens stored in secrets.

**Rationale**: Releases fail at the seams between manual steps; one recipe with
pre-flight checks and rollback removes the seams.

### VIII. CI/CD Standards

- The CI workflow runs on every PR and push to main: ruff check,
  `ruff format --check`, ty, zizmor, and the pytest suite across the supported
  Python matrix.
- All third-party actions are pinned to full commit SHAs, not tags.
- Workflows declare least-privilege `permissions` blocks explicitly.
- Workflows MUST pass zizmor. This is what keeps Principle III honest.

**Rationale**: SHA pinning and least privilege close the supply-chain and
token-scope holes that tag-pinned, default-permission workflows leave open.

### IX. Documentation Contract

- Every generated project ships with: `README.md` (features, uv-first install,
  quick start, development setup), `CHANGELOG.md` in Keep a Changelog format,
  `CONTRIBUTING.md`, `LICENSE` (MIT default), and `CLAUDE.md` describing
  project structure, commands, and conventions for Claude Code sessions.
- `CHANGELOG.md` is updated in the same PR as the change it documents. The
  release recipe enforces this (pre-flight check 5 in Principle VII).
- All public functions, classes, and CLI commands carry docstrings.

**Rationale**: Documentation written alongside the change is accurate;
documentation written at release time is archaeology.

## Governance

- This constitution supersedes ad hoc preferences. Speckit plans and specs MUST
  include a constitution compliance check; violations require a documented
  justification in the plan's Complexity Tracking table.
- Amendments require updating this document, the template's justfile, and
  `.pre-commit-config.yaml` together so the enforced reality never drifts from
  the stated principles.
- When a principle and a convenience conflict, the principle wins. When two
  principles conflict, security and correctness (III, VIII) outrank velocity.
- Versioning of this constitution follows semantic versioning: MAJOR for
  removals or redefinitions of principles, MINOR for new or materially expanded
  principles, PATCH for clarifications.

**Version**: 1.0.0 | **Ratified**: 2026-07-04 | **Last Amended**: 2026-07-04
