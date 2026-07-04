---

description: "Task list for cli-template implementation"
---

# Tasks: Python CLI Project Template

**Input**: Design documents from `/specs/001-python-cli-template/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Required per constitution Principle IV. The template's own test suite is built in Phase 1; the template-level validations (negative release matrix, init dry run, acceptance pass) are blocking tasks, not polish.

**Organization**: Ordered by the plan's six implementation phases (the approved ordering backbone), preceded by a preflight phase. Story labels map tasks to spec user stories: US1 = out-of-box green project, US2 = one-command init, US3 = guarded release, US4 = rollback, US5 = Claude Code autonomy, US6 = contributor experience.

**Format**: `- [ ] [ID] [P?] [Story?] Description with file path` — verification command on the following `Verify:` line. Every verification is non-interactive. [P] = parallelizable (disjoint files, no ordering dependency).

**Ground rules** (from the planning input; binding on every task):

- No prohibited tools ever, including as scaffolding: no pip/poetry/pipx, no black/isort/flake8, no mypy/pyright, no `pre-commit` command.
- Any task that touches `pyproject.toml` runs `uv sync` and stages `uv.lock` in the same task.
- Any plan/constitution conflict discovered mid-task: stop, surface it, amend the plan before continuing. Do not improvise.
- Work happens on feature branch `001-python-cli-template`; nothing is pushed to main directly.

---

## Phase 0: Preflight

- [ ] T001 Read `.specify/memory/constitution.md`, `specs/001-python-cli-template/plan.md`, and all five contracts in `specs/001-python-cli-template/contracts/` before writing any code. Standing obligation: re-read CLAUDE.md against the built reality at T033 before Phase 6 finalizes it.
      Verify: `test -f .specify/memory/constitution.md && test -f specs/001-python-cli-template/plan.md && ls specs/001-python-cli-template/contracts/*.md | wc -l | grep -q 5`
- [ ] T002 Create and switch to feature branch `001-python-cli-template` (per global git rules: never commit to main).
      Verify: `git branch --show-current | grep -qx '001-python-cli-template'`

**Checkpoint**: Context loaded, branch active.

---

## Phase 1: Package Skeleton and Example CLI (US1)

- [ ] T003 [US1] Create `pyproject.toml`: PEP 621 metadata (name `cli-template`, version `0.0.0`, description sentinel, authors Ryan Cheley/rcheley@gmail.com, urls with `ryancheley/cli-template`, `requires-python = ">=3.12"`), hatchling backend, runtime deps click + rich only, `[dependency-groups] dev` = pytest, pytest-cov, pytest-randomly, ruff, ty, zizmor, pip-audit, twine; entry point `cli-template = "cli_template.cli:main"`; tool config: ruff (line 120; E,F,I,UP,B,SIM), coverage (`branch = true`, source `src/cli_template`, `fail_under = 80` — branch config here ONLY, never `--cov-branch` on CLI per research R5), pytest (`addopts` for cov). Then `uv sync` and stage `uv.lock`.
      Verify: `uv sync && uv run python -c "import click, rich" && git add uv.lock pyproject.toml && git diff --cached --name-only | grep -q uv.lock`
- [ ] T004 [P] [US1] Create `src/cli_template/__init__.py` with module docstring and `__version__` read via `importlib.metadata.version("cli-template")` (research R6 — no hardcoded version string).
      Verify: `uv run python -c "import cli_template; assert cli_template.__version__ == '0.0.0', cli_template.__version__"`
- [ ] T005 [P] [US1] Create `src/cli_template/output.py`: shared rich `Console` (stdout) and error console (stderr), `error(message, suggestion)` formatter implementing the actionable-error contract, `success(message)` helper. Docstrings on all public functions.
      Verify: `uv run python -c "from cli_template.output import console, error, success"`
- [ ] T006 [US1] Create `src/cli_template/commands/__init__.py` and `src/cli_template/commands/hello.py`: `hello` command with exactly one option `--name TEXT` (default `World`), rich greeting output, empty-name validation error via `output.error` with exit code 2 (contracts/cli-contract.md). Depends on T005.
      Verify: `uv run python -c "from cli_template.commands.hello import hello"`
- [ ] T007 [US1] Create `src/cli_template/cli.py`: click group with `@click.version_option(package_name="cli-template")`, register `hello`, `main()` entry function; module/command docstrings. Depends on T004–T006.
      Verify: `uv run cli-template --version && uv run cli-template hello --name World | grep -q World`
- [ ] T008 [P] [US1] Create `tests/conftest.py` (CliRunner fixture) and `tests/test_cli.py`: `--version` matches installed metadata, `--help` exits 0 and lists `hello`, unknown command exits 2. CliRunner only — no subprocess. Depends on T007.
      Verify: `uv run pytest tests/test_cli.py -q`
- [ ] T009 [P] [US1] Create `tests/test_hello.py`: default greeting, `--name` option, empty-name error path (message + exit code 2), plus one test explicitly labeled as the regression-test example (docstring naming the pinned bug pattern). Depends on T007.
      Verify: `uv run pytest tests/test_hello.py -q`
- [ ] T010 [US1] **Checkpoint Phase 1**: full suite green with randomized order and coverage floor; CLI answers.
      Verify: `uv run pytest --cov --cov-fail-under=80 && uv run cli-template --version`

---

## Phase 2: justfile Core and Hooks (US1, US6)

- [ ] T011 [US1] Create `justfile`: default recipe = `just --list`; groups and recipes per contracts/justfile-contract.md — setup (`install`, `install-hooks`), quality (`lint`, `lint-fix`, `format`, `format-check`, `typecheck`, `security`, `fix`, `check` fail-fast chain), test (`test`, `test-cov`), build (`build`, `build-check`, `clean`), cli (`run`), dev (`deps-update`, `deps-audit`, `doctor`), git (`hooks-run`), docs (`changelog-check`), help. POSIX sh bodies; every tool via `uv run`. Release group and `init` recipe come later (Phases 4–5).
      Verify: `just --list && just lint && just typecheck`
- [ ] T012 [US6] Create `.pre-commit-config.yaml`: trailing-whitespace, end-of-file-fixer, check-yaml, check-toml, check-added-large-files (pre-commit-hooks repo — repo URL, never the `pre-commit` command), ruff + ruff-format (ruff-pre-commit), zizmor (zizmorcore/zizmor-pre-commit), ty as a local hook via `uv run ty check` (planning decision; research R1 confirms prek compatibility).
      Verify: `rg -n 'pre-commit run|pre-commit install' --glob '!*.md' . ; test $? -eq 1`
- [ ] T013 [US6] Install hooks with prek and run the full suite once.
      Verify: `just install-hooks && prek run --all-files`
- [ ] T014 [US1] **Checkpoint Phase 2**: all gates available at this point pass. NOTE: full `just check` includes `security`, which needs `.github/workflows/` to exist; that lands in Phase 3 — this checkpoint runs every other gate, and the Phase 3 checkpoint is the first full `just check`. (Documented sequencing adjustment, not a gate exception.)
      Verify: `just format-check && just lint && just typecheck && just test-cov && prek run --all-files`

---

## Phase 3: CI Workflow (US1)

- [ ] T015 [US1] Resolve full commit SHAs for `actions/checkout` (v7.x), `astral-sh/setup-uv` (v8.x), `actions/upload-artifact` (v7.x), `actions/download-artifact` (v8.x — majors diverged, pin independently per research R4), `pypa/gh-action-pypi-publish` (v1.14.x) via `gh api` (workflows-contract SHA procedure). Record each SHA + version comment for T016/T024. Never pin from memory.
      Verify: `gh api repos/actions/checkout/git/ref/tags/$(gh api repos/actions/checkout/releases/latest --jq .tag_name) --jq .object.sha | grep -Eq '^[0-9a-f]{40}$'`
- [ ] T016 [US1] Create `.github/workflows/ci.yml` per contracts/workflows-contract.md: triggers pull_request + push to main; top-level `permissions: contents: read`; checkout with `persist-credentials: false`; setup-uv managing Pythons (no actions/setup-python); `quality` job (format-check, lint, ty, zizmor, pip-audit with `continue-on-error: true`); `test` matrix job (3.12, 3.13) running `uv run pytest --cov --cov-fail-under=80`; all actions SHA-pinned with `# vX.Y.Z` comments. Depends on T015.
      Verify: `uv run zizmor .github/workflows/`
- [ ] T017 [US1] Push the feature branch and open a draft PR to trigger CI; confirm both jobs green.
      Verify: `git push -u origin 001-python-cli-template && gh pr create --draft --title '🏗️ feat: cli-template scaffold' --body 'WIP' --head 001-python-cli-template ; gh pr checks --watch`
- [ ] T018 [US1] **Checkpoint Phase 3**: first full constitutional gate.
      Verify: `just check`

---

## Phase 4: Release Machinery (US3, US4)

- [ ] T019 [US3] Add `release-check <version>` recipe to `justfile`: semver format validation, proper-increment check against current `pyproject.toml` version, bump classification (major/minor/patch) via `uv run --no-project python -c` one-liner (dependency-free).
      Verify: `just release-check 0.1.0 && ! just release-check 0.0.0 && ! just release-check banana`
- [ ] T020 [P] [US3] Add `release-status` recipe to `justfile`: current version, last tag / commits since, recent `gh run list` output.
      Verify: `just release-status`
- [ ] T021 [US3] Add `release <version>` pre-flight section to `justfile`: the six constitutional checks plus the tag-already-exists guard, each with its own distinct actionable abort message, zero mutations before all pass (contracts/justfile-contract.md preflight table). Depends on T019.
      Verify: `just release 0.1.0 2>&1 | grep -qi 'not on main'`
- [ ] T022 [US3] Add `release` mutation section to `justfile`: bump `pyproject.toml` version → `uv sync` → commit both (emoji-prefixed message) → push → verify via `git ls-remote` → tag `v<version>` → push tag; compensations per data-model.md Release State Machine (reset on push failure; delete local tag + truthful report on tag-push failure). Depends on T021.
      Verify: `sh specs/001-python-cli-template/scripts/release-happy-path.sh` (script: temp clone with local bare origin on main, seeded `## [0.1.0]` changelog → run `just release 0.1.0` → assert bump commit and `v0.1.0` tag exist in the bare origin)
- [ ] T023 [US4] Add `rollback-release <version>` recipe to `justfile`: interactive confirmation (`read`), verify tag exists (truthful message when it doesn't), delete remote tag, delete local tag, revert bump commit, `git push --force-with-lease`. Depends on T022.
      Verify: `sh specs/001-python-cli-template/scripts/rollback-test.sh` (script: after release-happy-path, `echo n |` leaves state unchanged, then `echo y |` removes tag from bare origin and reverts bump; assert both)
- [ ] T024 [US3] Create `.github/workflows/release.yml` per contracts/workflows-contract.md: trigger `v*` tags; `build` job (checkout persist-credentials false → setup-uv → `uv build` → twine check → upload-artifact); `publish` job (`needs: build`, `environment: pypi`, job-scoped `permissions: id-token: write`, download-artifact → pypa/gh-action-pypi-publish, nothing else in the job); SHA-pinned throughout. Depends on T015.
      Verify: `uv run zizmor .github/workflows/`
- [ ] T025 [US3] Create `README.md` initial version containing the one-time PyPI trusted-publisher setup section (PyPI publisher: repo, workflow `release.yml`, environment `pypi`; GitHub: create `pypi` environment). Full README content lands in Phase 6.
      Verify: `rg -qi 'trusted publish' README.md && rg -q 'release.yml' README.md`
- [ ] T026 [US3] Write `specs/001-python-cli-template/scripts/release-negative-tests.sh`: the four BLOCKING negative scenarios from quickstart V4 — non-main branch, dirty tree, missing changelog entry, failing check — each asserting non-zero exit, the precondition named in the message, and zero mutations (`git status --porcelain` and `git tag -l` unchanged). Depends on T021–T022.
      Verify: `sh specs/001-python-cli-template/scripts/release-negative-tests.sh`
- [ ] T027 [US3] **Checkpoint Phase 4**: workflows audited + negative matrix green.
      Verify: `just check && sh specs/001-python-cli-template/scripts/release-negative-tests.sh`

---

## Phase 5: Init Script (US2)

- [ ] T028 [US2] Create `scripts/init.py` (stdlib only: argparse, pathlib, re, shutil, subprocess): argument schema and validation per contracts/init-contract.md (`--name` kebab/PEP 503 + derived identifier check, `--author`, `--email`, `--github` owner[/repo], `--description`, optional `--title`), guards (already-initialized → exit 3; not a git work tree → exit 3), all validation errors collected → exit 2 with zero mutations.
      Verify: `uv run --no-project python scripts/init.py --help && (uv run --no-project python scripts/init.py --name '9bad name' --author A --email a@b.co --github x --description d; test $? -eq 2) && test -z "$(git status --porcelain src/)"`
- [ ] T029 [US2] Implement the transformation pipeline in `scripts/init.py`: ordered literal substitution over `git ls-files` (composites before bare tokens per data-model.md invariants, skip `uv.lock`), rename `src/cli_template/` → `src/<package>/`, rewrite README to project stub, reset CHANGELOG to Unreleased + 0.1.0 stub, delete `scripts/init.py`, splice out the marker-delimited `init` recipe, run `uv sync`, then self-verify: run the residue search and `just check`, print both, exit per init-contract codes. Depends on T028.
      Verify: covered by T031 dry run (pipeline is not independently runnable without mutating; guard tasks T028/T032 cover the non-mutating paths)
- [ ] T030 [US2] Add the `init` recipe to `justfile`, delimited by `# --- init (removed by init) ---` marker comments, passing named args through to `uv run --no-project python scripts/init.py`. Depends on T029.
      Verify: `just --summary | tr ' ' '\n' | grep -qx init && rg -c 'init \(removed by init\)' justfile | grep -q 2`
- [ ] T031 [US2] **BLOCKING dry run** (quickstart V2): copy repo to temp dir, run `just init name=demo-tool author="Test Author" email=test@example.com github=testowner description="A demo tool"`; assert exit 0, zero placeholder residue via `rg`, `scripts/init.py` gone, `init` recipe gone, `just check` green in the copy, `uv run demo-tool hello` works. Depends on T029–T030.
      Verify: `sh specs/001-python-cli-template/scripts/init-dry-run.sh` (script implements quickstart V2 assertions; residue check: `rg -i 'cli[-_]template' --hidden -g '!.git' -g '!.venv'` returns no matches → exit 1)
- [ ] T032 [US2] Negative + idempotency tests (quickstart V3): in a fresh temp copy, invalid name exits 2 with clean `git status --porcelain`; after a successful init, a second init exits 3 with "already initialized". Depends on T031.
      Verify: `sh specs/001-python-cli-template/scripts/init-negative-tests.sh`
- [ ] T033 [US2] Implement template dev-artifact removal in `scripts/init.py` disarm step per plan amendment A1 (RESOLVED 2026-07-04): delete `.specify/` and `specs/`, keep `.claude/` project settings, strip the speckit marker block from `CLAUDE.md`. Depends on T029.
      Verify: re-run `sh specs/001-python-cli-template/scripts/init-dry-run.sh`, which additionally asserts `test ! -d <tmp>/.specify && test ! -d <tmp>/specs && ! rg -q 'SPECKIT' <tmp>/CLAUDE.md`
- [ ] T034 [US2] **Checkpoint Phase 5**: template still green post-init-development; both init test scripts pass.
      Verify: `just check && sh specs/001-python-cli-template/scripts/init-dry-run.sh && sh specs/001-python-cli-template/scripts/init-negative-tests.sh`

---

## Phase 6: Documentation and Acceptance (US5, US6)

- [ ] T035 Re-read constitution, plan, and every contract against the built reality (standing task T001 part 2); reconcile any drift by amending plan.md/contracts BEFORE writing final docs, so documentation reflects what was built.
      Verify: `git status --porcelain | wc -l | grep -qx 0 && just check`
- [ ] T036 [P] [US6] Create `LICENSE`: MIT, copyright 2026 Ryan Cheley (year + author are placeholder tokens per data-model.md).
      Verify: `rg -q 'MIT License' LICENSE && rg -q 'Ryan Cheley' LICENSE`
- [ ] T037 [P] [US6] Create `CHANGELOG.md`: Keep a Changelog format, `## [Unreleased]` section and `## [0.1.0]` stub. Must satisfy the release pre-flight grep.
      Verify: `rg -q '## \[Unreleased\]' CHANGELOG.md && rg -q '## \[0.1.0\]' CHANGELOG.md && just changelog-check`
- [ ] T038 [P] [US6] Create `CONTRIBUTING.md`: prerequisites (uv, git, just, prek), setup (`just install`, `just install-hooks`), workflow (feature branch, `just check` before push, changelog-in-same-PR rule), hook behavior. No `pre-commit` command anywhere.
      Verify: `rg -q 'prek install|just install-hooks' CONTRIBUTING.md && (rg -n 'pre-commit run|pre-commit install' CONTRIBUTING.md; test $? -eq 1)`
- [ ] T039 [US6] Complete `README.md`: features, uv-first install, quick start, development setup, shell completion instructions for bash, zsh, AND fish, the trusted-publisher section from T025, template-usage instructions (marked as the section init rewrites). Depends on T025.
      Verify: `rg -q 'bash' README.md && rg -q 'zsh' README.md && rg -q 'fish' README.md && rg -qi 'uv sync' README.md`
- [ ] T040 [US5] Rewrite `CLAUDE.md` per contracts/claude-md-contract.md: purpose, directory map, init procedure (template-mode section) with exact command and placeholder inventory, recipe catalog, conventions (command placement, output via output.py, exit codes, CliRunner, regression tests, changelog discipline, emoji commits), non-negotiables ("never propose pip/black/mypy/pre-commit"), release procedure with pre-flight checklist, verification block. Replaces the speckit pointer stub. Depends on T035.
      Verify: `rg -q 'just init' CLAUDE.md && rg -qi 'never' CLAUDE.md && rg -q 'release' CLAUDE.md && rg -q 'doctor' CLAUDE.md`
- [ ] T041 [US5] Acceptance AC1 — zero placeholder residue after init (spec SC-002).
      Verify: `sh specs/001-python-cli-template/scripts/init-dry-run.sh`
- [ ] T042 [US1] Acceptance AC2 — clean-machine setup (spec SC-003): fresh `git clone` to temp + `just install && just install-hooks && just check` with no pre-existing `.venv` (documented approximation of a clean machine; full-isolation container run optional on this platform).
      Verify: `sh specs/001-python-cli-template/scripts/clean-machine-test.sh`
- [ ] T043 [US1] Acceptance AC3 — CLI responds + completion works (spec SC-004).
      Verify: `uv run cli-template --help && uv run cli-template --version && uv run cli-template hello --name Alice | grep -q Alice && _CLI_TEMPLATE_COMPLETE=bash_source uv run cli-template >/dev/null && _CLI_TEMPLATE_COMPLETE=zsh_source uv run cli-template >/dev/null && _CLI_TEMPLATE_COMPLETE=fish_source uv run cli-template >/dev/null`
- [ ] T044 [US3] Acceptance AC4 — release aborts on each unmet precondition (spec SC-005).
      Verify: `sh specs/001-python-cli-template/scripts/release-negative-tests.sh`
- [ ] T045 [US3] Acceptance AC5 — real release lands on PyPI (spec SC-006). MANUAL, deferred to the first real project generated from the template per plan amendment A2; this task verifies the TestPyPI rehearsal procedure is documented in the README.
      Verify: `rg -qi 'testpypi' README.md`
- [ ] T046 [US4] Acceptance AC6 — rollback removes tag and reverts bump (spec SC-006 inverse).
      Verify: `sh specs/001-python-cli-template/scripts/rollback-test.sh`
- [ ] T047 [US1] Acceptance AC7 — workflows zizmor-clean, SHA-pinned, explicit permissions (spec SC-007).
      Verify: `uv run zizmor .github/workflows/ && test -z "$(rg 'uses:' .github/workflows/ | rg -v '@[0-9a-f]{40}')" && rg -q 'permissions:' .github/workflows/ci.yml && rg -q 'permissions:' .github/workflows/release.yml`
- [ ] T048 [US5] Acceptance AC8 — CLAUDE.md cold-start sufficiency (spec SC-008): scripted fresh Claude Code session per quickstart V7; pass = zero out-of-repo reads, zero clarifying questions attributable to missing docs.
      Verify: `sh specs/001-python-cli-template/scripts/cold-start-probe.sh` (drives a headless session in a temp copy and greps the transcript)
- [ ] T049 Acceptance AC9 — every criterion above verifiable by documented command: confirm each of T041–T048's verification script/command exists and is referenced in spec.md's Verification Commands table.
      Verify: `ls specs/001-python-cli-template/scripts/*.sh | wc -l | grep -q 6 && rg -c 'SC-00' specs/001-python-cli-template/spec.md | grep -qv '^0$'`
- [ ] T050 Mark the repository as a GitHub template after the PR merges to main (requires repo settings write).
      Verify: `gh api repos/ryancheley/cli-template --jq .is_template | grep -qx true`
- [ ] T051 **Checkpoint Phase 6 / FINAL**: full gate + entire validation suite in one pass.
      Verify: `just check && sh specs/001-python-cli-template/scripts/release-negative-tests.sh && sh specs/001-python-cli-template/scripts/init-dry-run.sh && sh specs/001-python-cli-template/scripts/init-negative-tests.sh && sh specs/001-python-cli-template/scripts/clean-machine-test.sh`

---

## Dependencies & Execution Order

- **Phase 0 → 1 → 2 → 3 → 4 → 5 → 6**: strictly sequential at phase boundaries; every checkpoint (T010, T014, T018, T027, T034, T051) must pass before the next phase starts.
- Within Phase 1: T003 blocks everything; T004/T005 parallel; T006 needs T005; T007 needs T004–T006; T008/T009 parallel after T007.
- Within Phase 4: T019 → T021 → T022 → T023/T026; T020 and T024 parallel to the recipe chain (T024 needs T015 from Phase 3).
- Within Phase 5: T028 → T029 → T030 → T031 → T032; T033 needs the plan amendment resolved first.
- Within Phase 6: T035 gates T040; T036/T037/T038 parallel; T039 needs T025; acceptance tasks T041–T049 run in order after all docs; T050 after merge.
- **Story completion**: US1 closes at T018 (usable MVP), US6 at T039, US3 at T044 (AC5 deferred-manual), US4 at T046, US2 at T034, US5 at T048.

## Parallel Example: Phase 1

```text
After T003:
  T004 "src/cli_template/__init__.py"   [P]
  T005 "src/cli_template/output.py"     [P]
After T007:
  T008 "tests/conftest.py + test_cli.py"  [P]
  T009 "tests/test_hello.py"              [P]
```

## Implementation Strategy

- **MVP = Phases 0–3 (US1)**: a green, CI-gated, runnable reference project. Stop-and-validate point: T018.
- **Incremental delivery**: Phase 4 adds the release path (US3/US4), Phase 5 makes it a template (US2), Phase 6 makes it autonomous and contributor-ready (US5/US6). Each checkpoint is a potential PR-merge point on the feature branch flow.
- **T033 decision resolved** as plan amendment A1 (2026-07-04): init deletes `.specify/` + `specs/`, keeps `.claude/`, strips CLAUDE.md speckit markers. The init dry-run assertions include these checks.
- **Validation scripts** live in `specs/001-python-cli-template/scripts/` (six: release-happy-path, release-negative-tests, rollback-test, init-dry-run, init-negative-tests, clean-machine-test, plus cold-start-probe) — they validate the template and are NOT shipped into generated projects (they live under specs/, which T033 removes at init).

## Notes

- T014's checkpoint intentionally runs the gate subset (full `just check` needs `security`, which needs workflows that land in Phase 3) — documented sequencing adjustment, not a gate exception; T018 is the first full `just check`.
- T045 (AC5) and T048 (AC8) end in manual/semi-manual verification by explicit planning decision; both have their procedure documented and everything up to the manual step scripted.
- Emoji-prefixed commit messages and feature-branch-only pushes apply to every commit in this work (user's global git rules + CLAUDE.md conventions).
