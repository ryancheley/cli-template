# Feature Specification: Python CLI Project Template

**Feature Branch**: `001-python-cli-template`

**Created**: 2026-07-04

**Status**: Draft

**Input**: User description: "Build cli-template, a GitHub template repository that serves as the starting point for new Python CLI tools. The primary consumer is Claude Code, which will be pointed at this template when scaffolding a new CLI project. The secondary consumer is a human developer cloning it directly."

## Problem Statement

Every new CLI tool currently starts from scratch or from copying files out of an
existing project. That produces inconsistent tooling, forgotten quality gates,
hand-rolled release processes, and drift between projects. Setup work that should
take minutes takes hours, and each project re-litigates decisions the project
constitution has already made. This feature builds the template repository itself:
a complete, working, fully gated Python CLI project that becomes a new project via
a single initialization step.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A working, fully gated project out of the box (Priority: P1)

A developer creates a new repository from the template (or clones it) and, with
nothing installed beyond the four documented prerequisites (uv, git, just, prek),
sets up the environment, installs git hooks, and runs the full quality gate suite.
Everything passes on the first try with zero manual fixes. The example CLI runs
and demonstrates the conventions: a `hello` command with one option, `--version`,
`--help`, rich terminal output, meaningful exit codes, and shell completion.

**Why this priority**: This is the template's core promise. If the scaffold is not
green and runnable before any customization, nothing downstream (init, release,
autonomous scaffolding) can be trusted. It is independently valuable even without
the init step — it is a correct reference project.

**Independent Test**: On a machine with only uv, git, just, and prek, clone the
template and run the setup, hook install, and check commands; then invoke the
example CLI's help, version, and example command. All succeed without edits.

**Acceptance Scenarios**:

1. **Given** a fresh clone on a machine with only the documented prerequisites,
   **When** the developer runs `just install && just install-hooks && just check`,
   **Then** every step succeeds with no warnings that require action.
2. **Given** the environment is installed, **When** the developer runs the example
   CLI with `--help`, `--version`, and the `hello` command, **Then** each responds
   correctly with exit code 0.
3. **Given** the environment is installed, **When** the developer runs the test
   suite with coverage, **Then** tests pass in randomized order and coverage meets
   or exceeds the constitutional threshold (80%).
4. **Given** the example CLI is invoked with an invalid option or induced failure,
   **When** the error is reported, **Then** the message states what went wrong and
   what to do next, and the exit code is non-zero and distinct from success.

---

### User Story 2 - One-command initialization (Priority: P2)

A developer (or Claude Code) who has just created a repo from the template runs a
single, argument-driven initialization command supplying the new project's name,
author, description, and GitHub owner/repo. The command rewrites every placeholder
token across the tree, renames the example package and CLI entry point, rewrites
template-specific documentation (such as the template's own README instructions),
and then removes itself or becomes inert. Afterward, no placeholder token remains
anywhere in the tree and the full gate suite still passes.

**Why this priority**: Initialization is what turns the reference project into
*your* project. It is the step that prevents ever shipping a tool that still says
"cli-template" somewhere.

**Independent Test**: From a fresh copy of the template, run the documented init
command with sample arguments, then search the tree for every placeholder token
(zero matches) and run the full check suite (passes).

**Acceptance Scenarios**:

1. **Given** a fresh copy of the template, **When** the developer runs the init
   command with a project name, author, description, and GitHub owner/repo,
   **Then** all placeholder tokens are replaced in every file, the package
   directory and CLI command are renamed, and a tree-wide search for any
   placeholder token returns zero matches.
2. **Given** an initialized project, **When** the developer runs the full check
   suite and the renamed CLI's `--help`, `--version`, and example command,
   **Then** everything passes with no manual fixes.
3. **Given** init arguments that would produce an invalid package or distribution
   name, **When** the init command runs, **Then** it aborts before modifying any
   file and explains which argument is invalid and what a valid value looks like.
4. **Given** a project where init has already completed, **When** init is invoked
   again, **Then** it refuses with a clear message instead of corrupting files.

---

### User Story 3 - Guarded single-command release (Priority: P3)

A maintainer cuts version 0.1.0 by running one release command. The command runs
pre-flight checks — on main, clean tree, local matches remote, GitHub
authentication works, changelog has a section for the version, full check suite
passes — and aborts with a distinct, actionable message for any unmet
precondition. On success it bumps the version, updates the lockfile, commits,
pushes, verifies the push, and creates and pushes the release tag. The tag push
triggers a publish workflow that lands the package on PyPI via trusted publishing,
with no credentials stored in the repository.

**Why this priority**: The release path is where hand-rolled processes hurt most.
It depends on Stories 1–2 existing but delivers its own value: a bad release
becomes hard to create by accident.

**Independent Test**: In a configured test repo, deliberately violate each
precondition (wrong branch, dirty tree, missing changelog entry, failing check)
and confirm each aborts with a clear message; then satisfy all preconditions and
confirm the release lands: pushed commit, pushed tag, green publish run, package
visible on the index.

**Acceptance Scenarios**:

1. **Given** the current branch is not main, **When** the maintainer runs the
   release command, **Then** it aborts before any mutation and names the branch
   problem.
2. **Given** a dirty working tree, a missing changelog section, or a failing
   check suite, **When** the release command runs, **Then** each condition
   produces its own distinct, actionable abort message.
3. **Given** all preconditions pass, **When** the release command runs, **Then**
   the version is bumped, the lockfile updated, both committed and pushed, the
   `v`-prefixed tag created and pushed, and the publish workflow completes green
   with the package published.
4. **Given** a push fails partway through, **When** the release command detects
   the failure, **Then** it rolls local state back and reports what happened.

---

### User Story 4 - Safe rollback of a bad release (Priority: P4)

A maintainer who cut a bad release runs the rollback command with the version
number. After an interactive confirmation, it deletes the release tag locally and
remotely and reverts the version-bump commit safely. Recovery is one command, not
an afternoon.

**Why this priority**: Rollback is the safety net for Story 3. Rarely used, but
its absence turns one mistake into a manual, error-prone cleanup.

**Independent Test**: After a test release, run the rollback command, confirm
interactively, and verify the tag is gone locally and remotely and the version
bump is reverted.

**Acceptance Scenarios**:

1. **Given** a released version, **When** the maintainer runs the rollback command
   and confirms, **Then** the tag is deleted locally and remotely and the bump
   commit is reverted.
2. **Given** the rollback prompt, **When** the maintainer declines confirmation,
   **Then** nothing is changed.

---

### User Story 5 - Claude Code scaffolds autonomously (Priority: P5)

Claude Code, pointed at a fresh copy of the template with no prior context, reads
the template's CLAUDE.md and from it alone learns the project structure, the
placeholder substitution rules, the initialization command and its arguments, the
recipes to run after scaffolding, and the conventions to follow. It scaffolds and
releases a new tool without consulting any file outside the repository and without
asking clarifying questions.

**Why this priority**: Claude Code is the primary consumer, but this story is the
integration of everything before it — it can only be satisfied once Stories 1–4
exist to be documented.

**Independent Test**: Start a fresh Claude Code session in a copy of the template
with the instruction "scaffold a new CLI tool named X and prepare a 0.1.0
release." Verify it completes using only in-repo files, with zero clarifying
questions attributable to missing documentation.

**Acceptance Scenarios**:

1. **Given** a fresh session with only the repository contents, **When** Claude
   Code is asked to scaffold a new tool, **Then** it runs the documented init and
   verification steps in the documented order without external references.
2. **Given** the scaffold is complete, **When** Claude Code is asked to prepare a
   release, **Then** it follows the documented release flow, including the
   changelog obligation, without guessing.

---

### User Story 6 - Contributor experience (Priority: P6)

A contributor clones an initialized project, reads CONTRIBUTING.md, runs the
documented setup, and starts working. `just --list` shows every available action,
grouped and described. Installed git hooks catch formatting, lint, type, and
workflow-audit problems at commit time, so the contributor's first PR is not a
wall of red CI.

**Why this priority**: Valuable polish for every generated project's community,
but it rides on infrastructure Stories 1–2 already create.

**Independent Test**: Following only CONTRIBUTING.md, a contributor sets up the
project, makes a deliberately non-compliant change, and observes the hooks block
the commit with actionable output; the default recipe shows all recipes grouped
and described.

**Acceptance Scenarios**:

1. **Given** hooks are installed, **When** a commit introduces a formatting, lint,
   type, or workflow-audit violation, **Then** the commit is blocked locally with
   output identifying the problem.
2. **Given** any state of the project, **When** the contributor runs the command
   runner with no arguments, **Then** all recipes are listed with groups and
   descriptions.

---

### Edge Cases

- Init run a second time after completion: must refuse with a clear message, not
  corrupt already-substituted files.
- Init given a name that is not a valid package/command/distribution name (spaces,
  leading digits, hyphens where underscores are required, reserved words): must
  abort before mutating anything and show a valid example.
- Init arguments containing shell-sensitive characters (quotes, ampersands) in the
  author or description fields: substitution must not break files or the command.
- Placeholder tokens that appear in multiple case/format variants (kebab-case
  project name, snake_case package name, human-readable title): each variant must
  be substituted with the correctly formatted value, not a single blind
  find-and-replace.
- Release attempted when the target tag already exists locally or remotely: must
  abort with a distinct message rather than force-moving the tag.
- Release push succeeds but tag push fails (or vice versa): local state must be
  rolled back and the partial-failure state reported.
- Rollback of a version whose tag was already deleted, or that was never released:
  must report the actual state instead of failing cryptically.
- Fresh-machine setup without network access: setup fails; the failure message
  must make the network dependency obvious rather than appearing as a tool bug.
- The template repository itself (pre-init) must keep its own CI green: the
  placeholder names must themselves be valid identifiers so all gates pass before
  initialization ever runs.

## Requirements *(mandatory)*

### Functional Requirements

**Template content**

- **FR-001**: The repository MUST function as a GitHub template repository and as
  a directly cloneable project; both paths lead to the same initialization flow.
- **FR-002**: The template MUST ship a minimal but real example CLI package: a
  `hello` command with one option, plus `--version` and `--help`, demonstrating
  entry-point wiring, command structure, rich terminal output, error handling with
  meaningful and distinct exit codes, and shell completion for bash, zsh, and
  fish.
- **FR-003**: The template MUST ship a test suite for the example CLI that
  demonstrates the constitutional testing conventions — in-process CLI testing
  (no shelling out), randomized test order with a reproducible printed seed, a
  labeled regression-test example — and passes at or above the 80% coverage floor
  out of the box.
- **FR-004**: The template MUST ship the complete quality toolchain configured and
  passing: lint, format, type check, workflow security audit, and git hooks, all
  as mandated by the constitution (Principles III and IV).
- **FR-005**: The template MUST ship a command-runner file implementing every
  recipe the constitution requires (Principle VI), organized into the
  constitutional groups, with the default invocation listing all recipes with
  descriptions.
- **FR-006**: The template MUST ship a CI workflow that runs on every PR and push
  to main, executing all quality gates and the test suite across the supported
  Python version matrix (3.12 and 3.13).
- **FR-007**: The template MUST ship a tag-triggered publish workflow that builds
  the package and publishes to PyPI using trusted publishing (OIDC), with no API
  tokens stored as secrets.
- **FR-008**: All shipped workflows MUST pass the workflow security audit with
  zero findings at default severity, pin third-party actions to full commit SHAs,
  and declare explicit least-privilege permissions — as shipped, before and after
  initialization.
- **FR-009**: The template MUST ship the constitutional documentation set:
  README (features, uv-first install, quick start, development setup), CHANGELOG
  in Keep a Changelog format with an Unreleased section and a 0.1.0 stub,
  CONTRIBUTING, MIT LICENSE, and CLAUDE.md.
- **FR-010**: CLAUDE.md MUST be sufficient for a fresh Claude Code session to
  scaffold and release a new tool without consulting any file outside the
  repository: it documents project structure, the placeholder inventory and
  substitution rules, the initialization command and arguments, the post-scaffold
  verification sequence, and the conventions generated projects must follow.

**Initialization**

- **FR-011**: The template MUST provide a single, argument-driven (non-interactive)
  initialization command that accepts at minimum: project name, author (name and
  email), short description, and GitHub owner/repository. Package name, CLI
  command name, and title-case variants are derived from the project name unless
  explicitly overridden.
- **FR-012**: Initialization MUST replace every placeholder token, in every case
  and format variant, in every file — including renaming the example package
  directory and rewiring the CLI entry point — leaving zero placeholder
  occurrences verifiable by a tree-wide search.
- **FR-013**: Initialization MUST validate its arguments (valid package name,
  valid CLI command name, valid distribution name) and abort before modifying any
  file when validation fails, with a message naming the offending argument and a
  valid example.
- **FR-014**: Initialization MUST rewrite or remove template-specific content
  (such as the template's own README usage instructions) and then remove itself or
  become inert; a second invocation MUST refuse with a clear message.
- **FR-015**: Immediately after initialization, the full gate suite and the
  renamed CLI's `--help`, `--version`, and example command MUST pass with zero
  manual fixes.

**Release and rollback**

- **FR-016**: The release command MUST run all six constitutional pre-flight
  checks (main branch; clean tree; local matches remote after fetch; GitHub
  authentication; changelog section for the version; full check suite) and abort
  with a distinct, actionable message for each unmet precondition, making no
  mutations before all checks pass.
- **FR-017**: On success the release command MUST bump the version, update the
  lockfile, commit both, push, verify the push landed, create and push the
  `v`-prefixed tag, and roll back local state if any push fails.
- **FR-018**: Supporting recipes MUST exist: version validation/classification
  (`release-check`), release status reporting (`release-status`), and interactive
  rollback (`rollback-release`) that deletes the remote and local tag and reverts
  the bump commit only after explicit confirmation.
- **FR-019**: A successful release MUST require no configuration beyond enabling
  trusted publishing on the package index side — no secrets, tokens, or manual
  workflow edits.

**Verifiability**

- **FR-020**: Every acceptance criterion in this spec MUST be verifiable by a
  command or short script documented in this spec (see Verification Commands),
  not by inspection alone.
- **FR-021**: The template repository itself, pre-initialization, MUST pass its
  own full gate suite and CI — placeholder values are real, valid identifiers so
  the template is a permanently green reference project.

### Key Entities

- **Placeholder token set**: The complete inventory of substitutable values and
  their format variants — project/distribution name (kebab-case), package name
  (snake_case), CLI command name, human-readable title, short description, author
  name, author email, GitHub owner, GitHub repository name, copyright year. The
  inventory is documented in CLAUDE.md and is the contract between the template
  and the init command.
- **Template repository**: The permanently green reference project containing the
  example CLI, toolchain configuration, workflows, recipes, and documentation set.
- **Initialization command**: The argument-driven transformer that converts the
  template into a named project exactly once, then disarms itself.
- **Generated project**: The post-init result — a working, installable, fully
  gated CLI project governed by the constitution, containing no template residue.
- **Release pipeline**: The guarded local release command plus the tag-triggered
  publish workflow, and their inverse (rollback).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer or Claude Code goes from "new repo from template" to an
  initialized, fully gated, runnable project in under 10 minutes.
- **SC-002**: After initialization, a tree-wide search for every placeholder token
  variant returns zero matches.
- **SC-003**: On a machine with only the four documented prerequisites installed,
  environment setup, hook installation, and the full check suite succeed on the
  first attempt with zero manual fixes, both pre-init (template as-is) and
  post-init.
- **SC-004**: The example CLI responds correctly to help, version, and the example
  command in both pre-init and post-init states, and completion instructions work
  in all three documented shells.
- **SC-005**: 100% of the four tested unmet release preconditions (non-main
  branch, dirty tree, missing changelog entry, failing checks) abort the release
  with a distinct, actionable message and no repository mutation.
- **SC-006**: A properly configured release lands as: pushed bump commit, pushed
  version tag, green publish workflow, package visible on the public index — with
  zero credential configuration in the repository.
- **SC-007**: All shipped workflows produce zero security-audit findings at
  default severity.
- **SC-008**: A fresh Claude Code session scaffolds and prepares a release for a
  new tool using only files inside the repository, asking zero clarifying
  questions attributable to missing documentation.

### Verification Commands

Each success criterion maps to a command-level check (exact scripts finalized
during planning; placeholders shown as `<...>`):

| Criterion | Verification |
|-----------|--------------|
| SC-001 | Timed end-to-end script: create copy → `just init <args>` → `just install && just install-hooks && just check` → CLI smoke test; wall clock under 10 minutes |
| SC-002 | Recursive search for each token variant over the tree (excluding VCS metadata) exits with "no matches" |
| SC-003 | Clean-environment run (fresh container/VM or temp clone) of `just install && just install-hooks && just check`; exit code 0 |
| SC-004 | `<cli> --help`, `<cli> --version`, `<cli> hello <option>` all exit 0 with expected output; completion generation succeeds for bash, zsh, and fish |
| SC-005 | Scripted matrix: for each violated precondition, run `just release 0.1.0`, assert non-zero exit, assert the message identifies that precondition, assert working tree and tags unchanged |
| SC-006 | After release: remote tag listing shows the tag; publish workflow conclusion is success; package index API returns the version |
| SC-007 | `just security` (workflow audit) exits 0 with zero findings |
| SC-008 | Scripted fresh-session scaffold run; transcript shows no external file access and no clarifying questions |

## Assumptions

- The four developer prerequisites (uv, git, just, prek) are installed by the
  user; the template documents but does not install them.
- Network access to the package index and GitHub is available during setup,
  release, and publish; offline operation is out of scope.
- Enabling trusted publishing on the package index is a one-time manual step
  performed by the maintainer outside the repository; the template documents it.
- The GitHub CLI (`gh`) is available and authenticated for release pre-flight
  checks, consistent with the constitutional release flow.
- The template's own placeholder identity (e.g., a validly named example package)
  is a real, working project so the template's own CI stays green (FR-021).
- In-place substitution (GitHub template repo model) is the chosen approach per
  the resolved decisions; if planning shows it to be too fragile, that finding is
  flagged for an explicit decision rather than silently switching to a generator
  tool (cookiecutter/copier).
- The example `hello` command ships in generated projects and is removed by the
  developer only when the first real command replaces it; init does not strip it.
- Initialization is argument-driven and non-interactive by resolved decision;
  interactive prompting is out of scope.
- Developer tool versions float (no pinning of uv/ruff/ty/zizmor/prek in the
  template); CI actions are SHA-pinned per the constitution.

## Out of Scope

- Cookiecutter/copier or any generator-tool packaging of the template.
- Monorepo or multi-package layouts; anything other than one repo, one package,
  one CLI entry point.
- Web service, TUI, or library templates.
- Publishing anywhere other than PyPI (no Docker images, no Homebrew taps).
- A documentation site (Sphinx/ReadTheDocs); the documentation contract is the
  constitutional file set.
