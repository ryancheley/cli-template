# Quickstart: Validating the Template

**Feature**: 001-python-cli-template | **Date**: 2026-07-04

Runnable validation scenarios proving the template meets its success criteria.
Prerequisites everywhere: uv, git, just, prek installed; network access.
Contracts referenced: [cli-contract](contracts/cli-contract.md),
[init-contract](contracts/init-contract.md),
[justfile-contract](contracts/justfile-contract.md),
[workflows-contract](contracts/workflows-contract.md).

## V1 — Template is green out of the box (SC-003, SC-004 pre-init)

```sh
git clone <template-repo> /tmp/v1 && cd /tmp/v1
just install && just install-hooks && just check        # all pass, exit 0
just run -- --help && just run -- --version             # exit 0
just run -- hello --name Validator                      # greets Validator
uv run sh -c '_CLI_TEMPLATE_COMPLETE=bash_source cli-template' >/dev/null  # exit 0; repeat zsh/fish
```

Expected: every command exits 0; coverage report ≥ 80%; randomized-order seed
printed by pytest.

## V2 — Init dry run (SC-001, SC-002, SC-003 post-init)

```sh
cp -R /tmp/v1 /tmp/v2 && cd /tmp/v2
time just init name=demo-tool author="Test Author" email=test@example.com \
               github=testowner description="A demo tool"
# init itself runs the residue search and `just check`; expect exit 0
grep -rn -i -E 'cli[-_]template' --exclude-dir=.git --exclude-dir=.venv . ; test $? -eq 1
test ! -f scripts/init.py                                # init disarmed itself
just --summary | grep -qv '\binit\b'                     # recipe gone
test ! -d .specify && test ! -d specs                    # dev artifacts removed (amendment A1)
grep -c 'SPECKIT' CLAUDE.md ; test $? -eq 1              # speckit markers stripped
uv run demo-tool hello                                   # renamed CLI works
```

Expected: zero residue matches; wall clock for the full V2 block well under
10 minutes (SC-001 measures template→ready; the search exits 1 = no matches).

## V3 — Init refuses bad input and re-runs (edge cases)

```sh
cp -R /tmp/v1 /tmp/v3 && cd /tmp/v3
just init name="9bad name" author=A email=a@b.c github=x description=d
# expect: exit 2, message names `name`, shows a valid example, zero files modified
git status --porcelain | wc -l                           # 0
just init name=ok-tool author="A" email=a@b.co github=x description=d   # succeeds
just init name=other author="A" email=a@b.co github=x description=d 2>&1 | grep -qi "already initialized"  # exit 3 path
```

## V4 — Negative release matrix (SC-005)

Run in a disposable clone with a fake origin (`git remote set-url origin` to a
local bare repo). For each row: expect non-zero exit, the named message, and
`git status --porcelain` + `git tag -l` unchanged.

| Setup | Command | Must abort with |
|-------|---------|-----------------|
| `git checkout -b feature` | `just release 0.1.0` | not on main |
| touch a tracked file | `just release 0.1.0` | dirty tree |
| remove `## [0.1.0]` from CHANGELOG | `just release 0.1.0` | missing changelog section |
| introduce a lint error, commit | `just release 0.1.0` | checks failed |
| `git tag v0.1.0` | `just release 0.1.0` | tag already exists |

## V5 — Rollback (SC-006 inverse)

Against the same local bare origin: perform a full `just release 0.1.0`
(publish workflow won't run — no GitHub), then:

```sh
just rollback-release 0.1.0     # answer y at the prompt
git tag -l v0.1.0 | wc -l                        # 0
git ls-remote origin refs/tags/v0.1.0 | wc -l    # 0
grep 'version = "0.0' pyproject.toml             # bump reverted
```

Also verify declining the prompt changes nothing.

## V6 — Workflow audit (SC-007)

```sh
just security          # zizmor, exit 0, zero findings
grep -E 'uses: .*@[0-9a-f]{40}' .github/workflows/*.yml   # every uses: SHA-pinned
```

## V7 — Cold-start Claude Code probe (SC-008)

Manual/scripted: fresh Claude Code session in a copy of the template, prompt:
"Scaffold a new CLI tool named probe-tool by Probe Author
<probe@example.com>, GitHub owner probeowner, description 'probe', then
prepare (do not push) a 0.1.0 release." Pass = transcript contains no
out-of-repo file reads and no clarifying questions attributable to missing
documentation; init + check + changelog steps run in documented order.

## V8 — Real publish rehearsal (manual, documented, not automated)

TestPyPI rehearsal per README: create a TestPyPI trusted publisher for a
scratch repo generated from the template, push a `v0.1.0` tag, confirm green
publish run and the package on TestPyPI (SC-006). Out of scope for CI
automation by planning decision; deferred to the first real project generated
from the template (plan amendment A2).
