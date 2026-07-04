# Contract: Example CLI Interface

**Feature**: 001-python-cli-template

The example CLI is the reference implementation generated projects inherit. Its
observable behavior is a contract because the template's tests, docs, and
CLAUDE.md all describe it, and init renames it without changing behavior.

## Invocation surface

Entry point: console script `cli-template` → `cli_template.cli:main`
(post-init: `<name>` → `<package>.cli:main`).

| Invocation | Behavior | Exit code |
|------------|----------|-----------|
| `cli-template --help` | Usage, command list, description | 0 |
| `cli-template --version` | `cli-template, version X.Y.Z` (version read from installed package metadata, not a hardcoded string) | 0 |
| `cli-template hello` | Greets default target (`World`) with rich-formatted output | 0 |
| `cli-template hello --name Alice` | Greets `Alice` | 0 |
| `cli-template hello --shout` *(if the "one option" is implemented as a flag, pick exactly one option — see note)* | n/a | n/a |
| `cli-template hello --name ""` | Actionable error: what's wrong (empty name) + what to do | 2 (usage error) |
| `cli-template <unknown-command>` | click usage error with suggestion | 2 |
| Internal/unexpected failure path (demonstrated in code) | Error rendered via `output.py` helper to stderr; message = what happened + suggested next step | 1 |

**Note**: FR-002 requires the `hello` command to have exactly one option. The
option is `--name TEXT` (default `World`). No second option ships.

## Exit code policy (inherited by generated projects)

- `0` success
- `1` runtime failure (operation attempted and failed)
- `2` usage error (click's default for bad invocation/validation)

Distinct codes for distinct failure classes; documented in CLAUDE.md.

## Output conventions

- Human-readable rich output to stdout by default; errors to stderr.
- `output.py` exposes the shared `Console`, an error formatter (message +
  suggestion), and is the only place rich is configured.
- The `hello` example does not need `--format json` (nothing to script
  against); the convention is documented in CLAUDE.md for real commands.

## Shell completion

Click's built-in completion, documented in README for bash, zsh, and fish
(fish documented explicitly since the maintainer uses it; recipes themselves
stay POSIX sh). Verification: completion source generation command exits 0 for
each shell:

```sh
_CLI_TEMPLATE_COMPLETE=bash_source cli-template   # exit 0, non-empty output
_CLI_TEMPLATE_COMPLETE=zsh_source cli-template
_CLI_TEMPLATE_COMPLETE=fish_source cli-template
```

(Env var prefix follows the CLI name; init's rename must keep README
instructions in sync — covered by token substitution since the prefix contains
`CLI_TEMPLATE`.)

## Test contract (tests/)

- All CLI tests use `click.testing.CliRunner` — never subprocess (FR-003).
- `test_cli.py`: `--version` matches installed metadata; `--help` exits 0 and
  lists `hello`; unknown command exits 2.
- `test_hello.py`: default greeting; `--name` option; error path message +
  exit code; one test explicitly labeled as the regression-test example
  (docstring links a hypothetical issue and states the bug it pins).
- Coverage ≥ 80% branch coverage over `src/cli_template` out of the box.
