# Contract: GitHub Actions Workflows

**Feature**: 001-python-cli-template

Both workflows must pass `zizmor` at default severity **as shipped** (FR-008,
SC-007). All third-party actions SHA-pinned with a trailing `# vX.Y.Z` comment.
Explicit least-privilege `permissions` at top level; job-level elevation only
where required.

## ci.yml

| Aspect | Contract |
|--------|----------|
| Triggers | `pull_request`, `push` to `main` |
| Top-level permissions | `contents: read` |
| Python setup | `astral-sh/setup-uv` (SHA-pinned) with uv-managed Pythons; **no** `actions/setup-python` |
| Checkout | `actions/checkout` (SHA-pinned) with `persist-credentials: false` (zizmor artipacked audit) |
| Job `quality` (single Python, 3.13) | `ruff format --check .` → `ruff check .` → `ty check` → `zizmor .github/workflows/` → `pip-audit` (non-blocking: `continue-on-error: true`, annotate only) |
| Job `test` (matrix 3.12, 3.13) | `uv run pytest --cov --cov-fail-under=80` |
| Runner | ubuntu-latest only (v1; matrix rows are Python versions, not OSes) |
| Concurrency | cancel-in-progress per ref (cost hygiene; not constitutionally required) |

## release.yml

| Aspect | Contract |
|--------|----------|
| Trigger | `push` on tags `v*` |
| Top-level permissions | `contents: read` |
| Job `build` | checkout (persist-credentials: false) → setup-uv → `uv build` → `uv run --with twine twine check dist/*` → `actions/upload-artifact` (SHA-pinned) |
| Job `publish` | `needs: build`; `environment: pypi`; job-level `permissions: id-token: write` **only on this job**; `actions/download-artifact` → `pypa/gh-action-pypi-publish` (SHA-pinned). No other steps in this job (keeps the OIDC-privileged job minimal). |
| Secrets | none — trusted publishing (OIDC) only (FR-007, FR-019) |

## SHA pinning procedure (implementation-time)

Resolve at implementation, never from memory:

```sh
gh api repos/{owner}/{repo}/git/ref/tags/{tag} --jq .object.sha
# for annotated tags, dereference:
gh api repos/{owner}/{repo}/git/tags/{sha} --jq .object.sha
```

Actions to pin: `actions/checkout`, `astral-sh/setup-uv`,
`actions/upload-artifact`, `actions/download-artifact`,
`pypa/gh-action-pypi-publish`.

## zizmor acceptance

- Gate: `zizmor .github/workflows/` exits 0 with zero findings at default
  severity.
- If a finding originates from `pypa/gh-action-pypi-publish` usage itself and
  has no upstream remediation, the specific audit is ignored **inline** with a
  comment citing the zizmor audit ID and the reason — never by lowering the
  global severity/persona (flag-don't-decide item; see research.md R4).

## One-time manual setup (documented in README, not automatable)

PyPI → project → Publishing → add GitHub publisher: owner, repo,
workflow `release.yml`, environment `pypi`. GitHub → repo settings →
Environments → create `pypi`.
