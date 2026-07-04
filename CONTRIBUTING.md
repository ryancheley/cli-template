# Contributing

Thanks for helping improve Cli Template!

## Prerequisites

Four tools, installed once: [uv](https://docs.astral.sh/uv/), git,
[just](https://just.systems/), and [prek](https://prek.j178.dev/).
Everything else is managed by uv — never activate a virtualenv manually and
never use pip or poetry here.

## Setup

```sh
just install        # uv sync --dev
just install-hooks  # prek install — do this before your first commit
just doctor         # confirm your environment is healthy
```

## Workflow

1. Create a feature branch — nothing is committed to `main` directly.
2. Make your change. New CLI commands go in `src/cli_template/commands/`,
   one module per command, registered in `src/cli_template/cli.py`.
3. Add or update tests (CliRunner-based; every bug fix ships a regression
   test). Keep coverage at or above 80%.
4. Update `CHANGELOG.md` under `## [Unreleased]` **in the same PR** — the
   release process enforces this.
5. Run `just check` before pushing. It runs exactly what CI runs; if it
   passes locally, CI should be green.
6. Open a PR. All quality gates must pass before merge — there is no
   "fix it later" lane.

## Git hooks

`just install-hooks` wires the prek-managed hook suite (whitespace, EOF,
YAML/TOML validation, ruff check + format, zizmor, ty). Hooks catch problems
before CI does; if a hook rewrites a file, re-stage it and commit again.

## Commit messages

Short, declarative, emoji-prefixed: `🐛 fix: reject empty --name`.

## Releases (maintainers)

Releases are one command from a clean `main`: `just release <version>`.
See README for the one-time PyPI trusted-publisher setup, and
`just rollback-release <version>` if something goes wrong.
