# Contract: CLAUDE.md (Cold-Start Sufficiency)

**Feature**: 001-python-cli-template

CLAUDE.md is an interface, not prose: a fresh Claude Code session must scaffold
and release a new tool using only in-repo files (FR-010, SC-008). Required
sections, in order:

1. **Purpose** — what this repo is (template vs. initialized project; the file
   ships in both states, so it describes the initialized-project conventions
   and carries a template-mode section that init rewrites/removes).
2. **Directory map** — the src-layout tree with one-line annotations.
3. **Initialization procedure** *(template mode only; removed by init)* — the
   exact `just init name=... author=... email=... github=... description=...`
   command, the placeholder inventory table (mirrors data-model.md), the
   post-init verification sequence (`residue search`, `just check`, CLI smoke
   test), and "what init deletes".
4. **Recipe catalog** — every recipe with when-to-use-it; states that recipes
   are the only sanctioned way to run tools (Principle VI).
5. **Conventions** — src layout; new click commands go in
   `src/<package>/commands/<name>.py` and register on the group in `cli.py`;
   rich output only via `output.py`; exit-code policy (0/1/2); CliRunner-only
   tests; every bug fix ships a regression test; CHANGELOG updated in the same
   PR; commit messages short, declarative, emoji-prefixed.
6. **Non-negotiables** — explicit list: uv (never pip/poetry/pipx), ruff
   (never black/isort/flake8), ty (never mypy/pyright), prek (never the
   pre-commit command), zizmor gate, coverage ≥ 80, SHA-pinned actions,
   trusted publishing. Phrased as "never propose X".
7. **Release procedure** — pre-flight checklist (the six checks), the exact
   commands (`just release-check`, `just release`, `just release-status`,
   `just rollback-release`), and the changelog-first discipline.
8. **Verification** — the command block for proving the project is healthy
   (`just doctor`, `just check`).

Acceptance probe (SC-008): scripted fresh-session run with the prompt
"scaffold a new CLI tool named test-tool by <author> and prepare a 0.1.0
release"; transcript must show zero out-of-repo reads and zero clarifying
questions attributable to missing documentation.
