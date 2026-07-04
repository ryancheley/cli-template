# CLAUDE.md

Everything a Claude Code session needs to work in this repository. Read this
before proposing any tooling or workflow.

## Purpose

Cli Template — A modern Python CLI tool template. An installable Python CLI
built on click and rich, managed end-to-end with uv, gated by ruff/ty/zizmor/
pytest, driven entirely through `just` recipes, and released to PyPI via
trusted publishing.

## Directory map

```text
src/cli_template/
├── __init__.py          # __version__ from package metadata — never hardcode
├── cli.py               # click group; commands register here
├── commands/
│   └── hello.py         # example command — the conventions reference
└── output.py            # ALL rich output goes through these helpers
tests/
├── conftest.py          # CliRunner fixture
├── test_cli.py          # --version/--help/exit-code tests
└── test_hello.py        # command tests + labeled regression example
.github/workflows/       # ci.yml (PR + main), release.yml (v* tags)
.pre-commit-config.yaml  # prek-managed hook suite
justfile                 # THE interface — run `just` to list recipes
pyproject.toml           # metadata + ALL tool config; version lives here only
```

## Recipe catalog (use these, never raw commands)

| When you want to… | Run |
|---|---|
| Set up after clone | `just install && just install-hooks` |
| See every action | `just` |
| Run all gates before push (matches CI exactly) | `just check` |
| Auto-fix lint + format | `just fix` |
| Test / test with coverage | `just test` / `just test-cov` |
| Type check / lint only | `just typecheck` / `just lint` |
| Audit workflows / dependencies | `just security` / `just deps-audit` |
| Try the CLI | `just run -- hello --name You` |
| Build + validate artifacts | `just build-check` |
| Diagnose the environment | `just doctor` |
| Update dependencies | `just deps-update` |
| Release / undo a release | `just release X.Y.Z` / `just rollback-release X.Y.Z` |

## Conventions

- **src layout.** New click commands: one module in
  `src/cli_template/commands/<name>.py`, registered with `cli.add_command()`
  in `cli.py`. Docstrings on every public function, class, and command.
- **Output** only via `cli_template.output` helpers (`console`, `success`,
  `error`). Errors state what went wrong AND what to do next, to stderr.
- **Exit codes**: 0 success, 1 runtime failure, 2 usage error. Distinct codes
  for distinct failure classes.
- **Tests** use `CliRunner` — never subprocess. Every bug fix ships a
  regression test (see the labeled example in `tests/test_hello.py`).
  Coverage floor: 80% branch coverage; test order is randomized (seed printed
  for reproduction).
- **CHANGELOG.md** is updated under `## [Unreleased]` in the same PR as the
  change. The release pre-flight enforces a `## [X.Y.Z]` section.
- **Commits**: short, declarative, emoji-prefixed (`🐛 fix: …`). Always work
  on a feature branch; never push to main.
- **Secrets** never appear in code, config, or logs — use keyring or
  environment variables.

## Non-negotiables (constitutional — do not propose alternatives)

- uv for everything. **Never** pip, poetry, pipx, or manual venv activation.
- ruff for lint AND format. **Never** black, isort, or flake8.
- ty for type checking. **Never** mypy or pyright.
- prek manages hooks (config stays `.pre-commit-config.yaml`). **Never** run
  the `pre-commit` tool itself.
- zizmor must report zero findings; GitHub Actions stay SHA-pinned with
  explicit least-privilege permissions.
- Nothing merges with a failing gate. There is no "fix it later" lane.
- If a floating tool update breaks `just check` through no code change (ty is
  pre-1.0), the sanctioned escape hatch is pinning that one tool with a
  documented justification — not swapping tools.

## Release procedure

1. Ensure `CHANGELOG.md` has a `## [X.Y.Z]` section (added in the feature PR).
2. From a clean, up-to-date `main`: `just release-check X.Y.Z` (validates
   semver + proper increment), then `just release X.Y.Z`.
3. Pre-flight runs automatically and aborts if any of these fail: on main;
   clean tree; local matches origin/main; `gh auth status`; changelog section
   present; tag doesn't already exist; `just check` passes.
4. On success it bumps `pyproject.toml`, runs `uv sync`, commits, pushes,
   verifies, tags `vX.Y.Z`, pushes the tag. The tag triggers `release.yml`,
   which builds with uv and publishes to PyPI via trusted publishing.
5. Bad release? `just rollback-release X.Y.Z` (interactive) deletes the tag
   remote+local and reverts the bump.

## Verification

```sh
just doctor   # environment sanity
just check    # the full gate — identical to CI
```

<!-- template-only:start -->
## Template mode — initializing a new project

This repository is currently the **un-initialized template**. To turn it into
a real project, run exactly one command (arguments, not prompts):

```sh
just init name=foo-tool author="Ada Lovelace" email=ada@example.com \
          github=adalovelace description="Does the thing"
# optional: title="Foo Tool" (default: derived from name)
```

Validation: `name` must be lowercase kebab-case yielding a valid Python
identifier when hyphens become underscores; `github` is `owner` or
`owner/repo` (repo defaults to name). Invalid input aborts with exit 2 and
zero files modified. Re-running after success refuses with exit 3.

### Placeholder inventory (init replaces every occurrence, all files)

| Token | Meaning | Becomes |
|---|---|---|
| `cli-template` | dist/CLI/repo name | `name` |
| `cli_template` | import package | `name` with `-` → `_` |
| `CLI_TEMPLATE` | completion env prefix | package uppercased |
| `Cli Template` | human title | `title` |
| `A modern Python CLI tool template` | description | `description` |
| `Ryan Cheley` / `rcheley@gmail.com` | author | `author` / `email` |
| `ryancheley` | GitHub owner | `github` owner |
| LICENSE year | copyright year | current year |

### What init does (in order)

deletes `.specify/` and `specs/` → substitutes all tokens over tracked files
→ renames `src/cli_template/` → rewrites README.md and CHANGELOG.md → updates
the LICENSE year → strips this section and the SPECKIT block from CLAUDE.md →
deletes `scripts/init.py` and the `init` recipe → runs `uv sync` → verifies
itself (placeholder residue scan + `just check`) and prints both results.

### After init

```sh
just install && just install-hooks && just check   # must pass with no fixes
uv run <name> hello                                # smoke test
git add -A && git commit -m "🎉 chore: initialize <name> from cli-template"
```

Then create the GitHub repo, push, and set up PyPI trusted publishing
(README → Releasing) before the first `just release 0.1.0`.
<!-- template-only:end -->

<!-- SPECKIT START -->
Template development context (removed from generated projects):
[plan](specs/001-python-cli-template/plan.md) ·
[constitution](.specify/memory/constitution.md) ·
[spec](specs/001-python-cli-template/spec.md) ·
[contracts](specs/001-python-cli-template/contracts/) ·
[validation quickstart](specs/001-python-cli-template/quickstart.md)
<!-- SPECKIT END -->
