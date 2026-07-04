# Contract: Initialization Script (`scripts/init.py`)

**Feature**: 001-python-cli-template

Stdlib-only (argparse, pathlib, re, shutil, subprocess for `git ls-files` /
`uv sync` / `just check`). Python ≥ 3.12. Invoked via the `init` recipe; also
directly runnable.

## Invocation

```sh
just init name=foo-tool author="Ada Lovelace" email="ada@example.com" \
          github=adalovelace description="Does the thing"
# recipe body passes through to:
uv run --no-project python scripts/init.py \
  --name foo-tool --author "Ada Lovelace" --email ada@example.com \
  --github adalovelace --description "Does the thing" [--title "Foo Tool"]
```

## Arguments

| Flag | Required | Validation (abort exit 2, name field, show valid example) |
|------|----------|----------------------------------------------------------|
| `--name` | yes | PEP 503 name AND valid CLI command: `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$` (lowercase kebab enforced for v1 simplicity); derived package `name.replace('-','_')` must be a valid non-keyword Python identifier |
| `--author` | yes | non-empty |
| `--email` | yes | contains `@` and `.` after it |
| `--github` | yes | `owner` or `owner/repo`; owner: `^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$`; repo defaults to `--name` |
| `--description` | yes | non-empty, single line |
| `--title` | no | non-empty; default derived from name |

## Behavior (ordered)

1. **Guard**: refuse (exit 3, "already initialized") unless both
   `scripts/init.py` and `src/cli_template/` exist and `pyproject.toml`
   contains `name = "cli-template"`.
2. **Guard**: refuse (exit 3) if not inside a git work tree — git is the undo
   mechanism and `git ls-files` is the file enumerator.
3. **Validate** all arguments; collect ALL validation errors, print together,
   exit 2. Zero mutations before this point.
4. **Substitute** over `git ls-files` output (text files only; skip `uv.lock`):
   ordered replacements — composite `ryancheley/cli-template` first, then
   `cli_template`, `cli-template`, title variants, author/email/owner/
   description sentinels, LICENSE year → current year. Pure literal
   replacement (`str.replace`), no regex on user input.
5. **Rename** `src/cli_template/` → `src/<package>/` via `shutil/os.rename`.
6. **Rewrite** `README.md` → project stub (title, description, install,
   quickstart, dev setup, completion, trusted-publishing setup note);
   reset `CHANGELOG.md` → `[Unreleased]` + `[0.1.0]` stub with today's date
   placeholder text per Keep a Changelog.
7. **Disarm**: delete `scripts/init.py`; drop the `init` recipe block from
   `justfile` (delimited by `# --- init (removed by init) ---` marker
   comments so removal is a literal splice, not parsing); delete the
   template's development artifacts `.specify/` and `specs/`; strip the
   speckit marker block from `CLAUDE.md`; keep `.claude/` project settings
   (plan amendment A1).
8. **Sync**: run `uv sync` (regenerates `uv.lock` under the new name).
9. **Verify**: run the residue search itself and print it for the user:
   `grep -rn -i -E 'cli[-_]template' --exclude-dir=.git --exclude-dir=.venv .`
   plus each sentinel; then run `just check`. Exit 0 only if residue count is
   zero AND check passes; otherwise exit 1 with a loud failure summary and
   the git-reset guidance.

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | Initialized, residue-free, checks green |
| 1 | Initialized but verification failed (residue found or `just check` failed) |
| 2 | Validation error — nothing modified |
| 3 | Guard refusal (already initialized / not a git tree) — nothing modified |

## Output contract

Plain text (stdlib `print`, no rich — the script must run with
`--no-project`): step-by-step progress lines, then a final block showing the
verification commands run, their results, and next steps (commit, create
GitHub repo, enable trusted publishing).
