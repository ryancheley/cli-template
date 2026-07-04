# Cli Template

[![CI](https://github.com/ryancheley/cli-template/actions/workflows/ci.yml/badge.svg)](https://github.com/ryancheley/cli-template/actions/workflows/ci.yml)

A modern Python CLI tool template

A GitHub template repository for Python CLI tools that are ready for PyPI
from day one: lintable, type-checked, tested, security-audited, and
releasable with a single command — before you write any feature code.

## Features

- **click + rich** example CLI with `--version`, `--help`, shell completion,
  actionable errors, and meaningful exit codes (0 success, 1 runtime, 2 usage)
- **uv end to end** — dependencies, virtualenvs, builds; no pip, no poetry
- **Quality gates that ship green**: ruff (lint + format), ty, zizmor,
  prek-managed git hooks, pytest with randomized order and an enforced 80%
  branch-coverage floor
- **justfile interface** — every dev and CI action is a discoverable recipe
- **Guarded releases**: `just release X.Y.Z` runs six pre-flight checks, then
  bumps, commits, tags, and pushes; a tag-triggered workflow publishes to
  PyPI via trusted publishing (no tokens); `just rollback-release` undoes it
- **SHA-pinned, zizmor-clean GitHub Actions** with least-privilege permissions

## Using this template

1. Create your repo from this template (GitHub → **Use this template**), or
   clone it.
2. Initialize it — one command replaces every placeholder, renames the
   package, rewrites the docs, and deletes itself:

   ```sh
   just init name=foo-tool author="Ada Lovelace" email=ada@example.com \
             github=adalovelace description="Does the thing"
   ```

3. Verify everything is green (init already ran this, but trust nothing):

   ```sh
   just install && just install-hooks && just check
   uv run foo-tool hello
   ```

`CLAUDE.md` documents the full procedure and conventions for Claude Code
sessions — this note and the init instructions disappear after `just init`.

## Install (the example CLI)

```sh
uv tool install cli-template   # or: uvx cli-template --help
```

## Quick start

```sh
cli-template --help
cli-template --version
cli-template hello --name You
```

## Shell completion

```sh
# bash (~/.bashrc)
eval "$(_CLI_TEMPLATE_COMPLETE=bash_source cli-template)"
# zsh (~/.zshrc)
eval "$(_CLI_TEMPLATE_COMPLETE=zsh_source cli-template)"
# fish (~/.config/fish/completions/cli-template.fish)
_CLI_TEMPLATE_COMPLETE=fish_source cli-template | source
```

## Development

Prerequisites (installed once): [uv](https://docs.astral.sh/uv/), git,
[just](https://just.systems/), [prek](https://prek.j178.dev/).

```sh
just install        # sync all dependencies
just install-hooks  # install git hooks
just                # list every available recipe
just check          # run every quality gate + tests, fail fast
just doctor         # environment health check
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.

## Releasing

Publishing uses [trusted publishing](https://docs.pypi.org/trusted-publishers/)
(OIDC) — no API tokens are stored anywhere in this repository. One-time setup:

1. On PyPI: **Your account → Publishing → Add a new pending publisher** with:
   - PyPI project name: `cli-template`
   - Owner: `ryancheley`, Repository: `cli-template`
   - Workflow name: `release.yml`
   - Environment name: `pypi`
2. On GitHub: **Settings → Environments → New environment** named `pypi`.

To rehearse first (recommended): create the same pending publisher on
TestPyPI (<https://test.pypi.org>), temporarily add
`repository-url: https://test.pypi.org/legacy/` to the publish step, push a
`v0.1.0` tag, and confirm the workflow lands the package there.

Then, from a clean `main`:

```sh
just release-check 0.1.0   # validate + classify the bump
just release 0.1.0         # pre-flight, bump, commit, tag, push, publish
just release-status        # current version, commits since tag, CI runs
just rollback-release 0.1.0  # if it went wrong
```

## License

[MIT](LICENSE)
