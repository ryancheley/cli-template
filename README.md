# Cli Template

A modern Python CLI tool template

*(Placeholder README — features/install/quick-start sections completed in Phase 6.)*

## Releasing (one-time PyPI setup)

Publishing uses [trusted publishing](https://docs.pypi.org/trusted-publishers/)
(OIDC) — no API tokens are stored anywhere in this repository. Before the first
release, do this once:

1. On PyPI: **Your account → Publishing → Add a new pending publisher** with:
   - PyPI project name: `cli-template`
   - Owner: `ryancheley`, Repository: `cli-template`
   - Workflow name: `release.yml`
   - Environment name: `pypi`
2. On GitHub: **Settings → Environments → New environment** named `pypi`.

To rehearse against TestPyPI first (recommended for projects generated from
this template): create the same pending publisher on <https://test.pypi.org>,
temporarily point the publish step at TestPyPI
(`repository-url: https://test.pypi.org/legacy/`), push a `v0.1.0` tag, and
confirm the workflow lands the package there before doing it for real.

After setup, releasing is one command from `main`:

```sh
just release 0.1.0
```
