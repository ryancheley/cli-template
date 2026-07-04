# Implementation Plan: Python CLI Project Template

**Branch**: `001-python-cli-template` | **Date**: 2026-07-04 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-python-cli-template/spec.md`

## Summary

Build the cli-template repository itself: a permanently green, src-layout
Python CLI reference project (click + rich, hatchling, uv-only) with the full
constitutional toolchain (ruff, ty, zizmor, prek, pytest with randomized order
and 80% branch coverage), a complete justfile including the guarded
release/rollback flow, SHA-pinned zizmor-clean GitHub Actions (CI + trusted-
publishing release), the constitutional document set, and a stdlib-only
`scripts/init.py` that transforms the template into a named project in one
argument-driven pass and then disarms itself. All architectural decisions were
made in the planning input; this plan sequences them, records verification, and
resolves the two flagged risks (ty maturity, zizmor vs. publish action — see
research.md R1/R2; neither blocks).

## Technical Context

**Language/Version**: Python 3.12 minimum; CI matrix 3.12 + 3.13; modern syntax (PEP 604, `type` statements)

**Primary Dependencies**: Runtime: click, rich — nothing else. Dev group (PEP 735): pytest, pytest-cov, pytest-randomly, ruff, ty, zizmor, pip-audit, twine. Build backend: hatchling.

**Storage**: N/A (filesystem artifacts only)

**Testing**: pytest via `uv run`, CliRunner-only CLI tests, pytest-randomly, pytest-cov with branch coverage configured solely in pyproject (`--cov-fail-under=80`; see research.md R5)

**Target Platform**: Developer machines (macOS/Linux, POSIX sh recipes) + GitHub Actions ubuntu-latest

**Project Type**: Single package, single CLI entry point (`cli-template = "cli_template.cli:main"`), GitHub template repository

**Performance Goals**: Template→initialized, fully gated project in under 10 minutes (SC-001); `just check` fast enough to run as a pre-release gate

**Constraints**: Template's own CI permanently green pre-init (FR-021); zero placeholder residue post-init (SC-002); zizmor zero findings as shipped (SC-007); no secrets anywhere (trusted publishing only); `scripts/init.py` stdlib-only; recipes POSIX sh (no fish assumptions); version single-sourced in pyproject.toml with `__version__` via importlib.metadata (research.md R6)

**Scale/Scope**: ~20 files; one example command; 5 contracts; 8 success criteria with scripted validation (quickstart.md V1–V8)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Evidence in this plan |
|---|-----------|--------|-----------------------|
| I | Python Version Policy | ✅ PASS | `requires-python = ">=3.12"`, matrix 3.12/3.13, modern syntax mandated in Technical Context |
| II | Tooling is uv, End to End | ✅ PASS | hatchling built via `uv build`; PEP 621 + PEP 735 dev group; `uv.lock` committed; every recipe uses `uv run`; init runs `uv sync` after touching pyproject |
| III | Code Quality Gates | ✅ PASS | ruff (lint+format), ty, zizmor, prek with the full constitutional hook suite; ty beta risk assessed and accepted with documented escape hatch (research.md R1) — gate unchanged |
| IV | Testing Discipline | ✅ PASS | pytest + pytest-randomly + pytest-cov, `--cov-fail-under=80`, CliRunner-only, labeled regression-test example (cli-contract.md) |
| V | CLI Design Standards | ✅ PASS | click + rich; `--version`/`--help`/completion for bash/zsh/fish; exit-code policy 0/1/2; actionable errors via `output.py`; no secrets (keyring/env convention documented in CLAUDE.md) |
| VI | The justfile is the Interface | ✅ PASS | Full constitutional recipe set + groups (justfile-contract.md); default recipe lists; `check` fail-fast chain |
| VII | Release via a Single Recipe | ✅ PASS | Six pre-flight checks + tag-exists guard, compensation table (data-model.md Release State Machine), release-check/-status/rollback recipes, v-prefixed tags, trusted publishing |
| VIII | CI/CD Standards | ✅ PASS | CI on PR + push to main with full gates + matrix; all actions SHA-pinned (R4 targets, resolved via `gh api` at implementation); explicit least-privilege permissions; zizmor-clean as shipped (R2: no ignores needed) |
| IX | Documentation Contract | ✅ PASS | Full document set incl. CHANGELOG discipline enforced by release pre-flight; docstring requirement flows into example code; CLAUDE.md cold-start contract (claude-md-contract.md) |

**Post-design re-check (after Phase 1 artifacts)**: PASS — no design element
introduced a violation; Complexity Tracking is empty. The two "flag, do not
decide" items resolved without gate exceptions (R1, R2).

## Project Structure

### Documentation (this feature)

```text
specs/001-python-cli-template/
├── plan.md              # This file
├── research.md          # R1–R7: flagged-item resolutions + verified facts
├── data-model.md        # Token inventory, init/release state machines
├── quickstart.md        # V1–V8 validation scenarios
├── contracts/
│   ├── cli-contract.md          # Example CLI surface, exit codes, completion
│   ├── init-contract.md         # init.py arguments, ordering, exit codes
│   ├── justfile-contract.md     # Recipe catalog incl. release preflight/compensations
│   ├── workflows-contract.md    # ci.yml + release.yml, pinning, zizmor acceptance
│   └── claude-md-contract.md    # Cold-start sufficiency requirements
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
cli-template/
├── src/
│   └── cli_template/
│       ├── __init__.py          # __version__ via importlib.metadata (R6)
│       ├── cli.py               # click group, version/help wiring, main()
│       ├── commands/
│       │   ├── __init__.py
│       │   └── hello.py         # example command, exactly one option (--name)
│       └── output.py            # rich console helpers, error formatting
├── tests/
│   ├── conftest.py
│   ├── test_cli.py              # CliRunner: --version, --help, exit codes
│   └── test_hello.py            # command tests + labeled regression example
├── scripts/
│   └── init.py                  # stdlib-only; deletes itself on success
├── .github/workflows/
│   ├── ci.yml                   # quality job + test matrix
│   └── release.yml              # build → publish (trusted publishing)
├── .pre-commit-config.yaml      # prek-managed hook suite
├── justfile                     # the interface (contracts/justfile-contract.md)
├── pyproject.toml               # PEP 621/735, hatchling, all tool config
├── uv.lock
├── CLAUDE.md  README.md  CHANGELOG.md  CONTRIBUTING.md  LICENSE
```

**Structure Decision**: src layout, single package, per planning input. The
template's real working names (`cli-template`/`cli_template`) double as the
placeholder tokens (data-model.md), which is what keeps the template itself
permanently green (FR-021).

## Implementation Sequencing (input to /speckit-tasks)

1. **Phase 1 — Package core**: pyproject (metadata, tool config), package
   skeleton, example CLI, `output.py`, tests green locally at ≥80% branch
   coverage.
2. **Phase 2 — Interface + hooks**: justfile setup/quality/test/build/cli/dev
   groups; `.pre-commit-config.yaml`; `prek run --all-files` green.
3. **Phase 3 — CI**: ci.yml per workflows-contract; SHA resolution via
   `gh api`; zizmor clean; matrix green.
4. **Phase 4 — Release path**: release group recipes (preflight, mutations,
   compensations, rollback) + release.yml; negative matrix V4 passes locally
   against a bare-repo origin.
5. **Phase 5 — Init**: `scripts/init.py` per init-contract; dry-run validation
   V2/V3 passes.
6. **Phase 6 — Documentation + acceptance**: README, CHANGELOG, CONTRIBUTING,
   LICENSE, CLAUDE.md per claude-md-contract; full quickstart V1–V7 pass;
   V8 documented as manual.

Each phase ends green: the repo is never left in a state where `just check`
(once it exists, Phase 2+) fails on main — matching the constitution's
no-failing-gates rule and the user's branch discipline.

## Risks & Flagged Items (resolved, not re-decided)

- **ty (beta) as blocking gate** — accepted; official prek-compatible hook
  exists; escape hatch = pin ty alone with documented justification if a
  floating upgrade ever breaks `check` (research.md R1). No mypy substitution.
- **zizmor vs. publish action** — non-issue once SHA-pinned; standard
  remediations (persist-credentials: false, explicit permissions, no template
  injection) adopted as contract (research.md R2). No global gate loosening.
- **In-place substitution fragility** — evaluated per spec assumption; stands
  (research.md R7). No cookiecutter switch.
- **upload/download-artifact major versions diverged** (v7 vs v8) — noted so
  implementation pins each independently (research.md R4).

## Amendments

- **A1 (2026-07-04, resolves tasks.md T033)**: Init's disarm step additionally
  deletes the template's development artifacts — `.specify/` and `specs/` —
  keeps `.claude/` project settings, and strips the speckit marker block from
  CLAUDE.md. Generated projects do not inherit the template's spec history.
  init-contract.md §Behavior step 7 updated to match.
- **A2 (2026-07-04)**: TestPyPI release rehearsal (AC5 manual step, quickstart
  V8) is deferred to the first real project generated from the template, by
  owner decision. The procedure stays documented in the README.
- **A3 (2026-07-04)**: Template ships at `version = "0.0.0"` so the first
  `just release 0.1.0` is a valid increment under `release-check`; the
  CHANGELOG still carries the `[0.1.0]` stub section the release pre-flight
  requires.
- **A4 (2026-07-04, implementation drift record)**: (a) The `init` recipe
  parses `key=value` pairs itself via `[positional-arguments]` + `*ARGS` —
  just only honors variable overrides *before* the recipe name, so recipe
  parameters could not deliver the mandated `just init name=…` shape.
  (b) Validation scripts use portable `grep -riE`, not `rg` (rg is a
  fish-only function on the reference machine; scripts run under sh).
  (c) `release.yml` sets `enable-cache: false` on setup-uv — zizmor's
  cache-poisoning audit (High) flags caching in publishing workflows; this is
  the upstream remediation, not an ignore. (d) `rollback-release` writes an
  explicit `⏪ revert:` commit message because git's default `Revert "…"`
  message violates the emoji-first commit-msg hook active in this
  environment. All four are recorded in CLAUDE.md/contracts where relevant.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No violations — table intentionally empty.*
