# Research: Python CLI Project Template

**Feature**: 001-python-cli-template | **Date**: 2026-07-04

All technical decisions were made in the planning input; research here verifies
the two "flag, do not decide" items and the facts the implementation depends
on. No NEEDS CLARIFICATION items remained in the spec. Sources verified
2026-07-04 via web research.

## R1: ty as a merge-blocking gate (flagged item)

**Decision**: Keep ty as the blocking type checker, in both the hook suite
(via `astral-sh/ty-pre-commit`) and CI (`uv run ty check`). No mypy fallback.

**Findings**:
- ty is in **beta** (0.0.56, 2026-07-01), targeting 1.0 in 2026. PyPI states
  diagnostics may change between any two 0.0.x versions.
- An official pre-commit hook repo exists (`astral-sh/ty-pre-commit`, revs
  track ty releases) and explicitly supports prek runners. Its one caveat —
  incompatibility with the hosted pre-commit.ci runner — does not apply here
  (we run hooks locally via prek and gate in our own CI).
- Known weak spots are Pydantic/Django inference — neither is in this
  template's dependency set (click + rich only), so exposure is minimal.

**Risk + proposed workaround (not a decision change)**: the resolved decision
says dev tool versions float, but ty's changing diagnostics mean a routine
`deps-update` could break `just check` without any code change. If that
occurs in practice, the documented exception is to pin **ty alone** to an
exact version in the dev group (and match the ty-pre-commit rev), recorded in
the generated project's plan per the constitution's deviation rule. We do not
pre-pin; we document the escape hatch in CLAUDE.md.

**Alternatives considered**: mypy (rejected — constitution names ty),
pyright (rejected — same), pinning all tools (rejected — resolved decision).

## R2: zizmor vs. the publish action (flagged item)

**Decision**: No ignore rule is needed. The anticipated conflict does not
materialize.

**Findings**:
- zizmor's default-on `unpinned-uses` audit (Medium) flags tag refs like
  `@release/v1`; its documented compliant form is exactly what the
  constitution mandates: full SHA + `# vX.Y.Z` comment. Since we SHA-pin
  `pypa/gh-action-pypi-publish`, nothing fires.
- `use-trusted-publishing` flags token-based publishing only; a trusted-
  publishing workflow passes clean.
- The predictable findings on a minimal workflow, with standard remediations
  we adopt as contract: `artipacked` → `persist-credentials: false` on every
  checkout; `excessive-permissions` → explicit `permissions` at workflow level
  with job-level elevation; `template-injection` → no `${{ }}` of dynamic
  context inside `run:` blocks (route through `env:`).
- If a future zizmor release introduces a finding with no upstream fix, the
  policy stands: inline ignore comment citing the audit ID and reason; never a
  global severity change.

## R3: prek as the hook manager

**Decision**: Confirmed viable as specified.

**Findings**: prek v0.4.8 (2026-07-04) is a single Rust binary, fully
compatible with `.pre-commit-config.yaml`, commands `prek install` /
`prek run --all-files`, no documented incompatibilities with ruff-pre-commit
or pre-commit-hooks; adopted by CPython, FastAPI, Home Assistant. The
`pre-commit` command will appear nowhere in the repo (hook repo *URLs* like
`pre-commit/pre-commit-hooks` are repository names, not the command —
CLAUDE.md phrases the prohibition as "the pre-commit tool", so the residue
check targets the command, not the repo URL).

## R4: Action pinning targets

**Decision**: Pin these current majors at implementation time; resolve full
SHAs via `gh api` (never from memory), verify with a version comment.

| Action | Current stable (2026-07-04) |
|--------|------------------------------|
| actions/checkout | v7.0.0 |
| astral-sh/setup-uv | v8.2.0 |
| actions/upload-artifact | v7.0.1 |
| actions/download-artifact | v8.0.1 (majors no longer in lockstep with upload) |
| pypa/gh-action-pypi-publish | v1.14.0 |

- setup-uv installs Python itself (`python-version` input) — confirms the
  no-setup-python decision.
- Trusted publishing cannot be used from reusable workflows — ours is not
  reusable; noted so nobody refactors it into one.

## R5: Coverage configuration interaction

**Decision**: Configure branch coverage in exactly one place —
`[tool.coverage.run] branch = true` in pyproject — and do **not** pass
`--cov-branch` on the command line. pytest-cov documents that the CLI flag
overrides file config; mixing the two is the known path to "can't combine
line data with arc data" errors. pytest-randomly has no documented
interaction issues with pytest 8.x or branch coverage.

## R6: Version single-sourcing

**Decision** (from planning input, mechanics confirmed): `version` lives in
`pyproject.toml` only; `src/cli_template/__init__.py` exposes
`__version__ = importlib.metadata.version("cli-template")`. click's
`@click.version_option()` reads package metadata directly (no argument
needed beyond the package name), so `--version` needs no hardcoded string and
the release recipe edits exactly one file (plus the lock).

## R7: In-place substitution fragility check (spec assumption)

**Decision**: In-place substitution stands. The evaluation the spec required:
the token inventory (data-model.md) shows every placeholder is a unique
literal with real-name semantics, enumerable via `git ls-files`, replaceable
with ordered `str.replace` — no templating syntax, no regex on user input, no
binary files in the tree except none (uv.lock is regenerated, not edited).
Failure recovery is git itself (init refuses to run outside a work tree).
No cookiecutter/copier switch is warranted.
