"""Initialize a new project from the cli-template template.

Argument-driven, stdlib-only. Rewrites every placeholder token, renames the
package, removes template-specific content, then deletes itself. Runs exactly
once; git is the undo mechanism if anything goes wrong mid-flight.

Exit codes: 0 = initialized and verified; 1 = initialized but verification
failed; 2 = invalid arguments (nothing modified); 3 = guard refusal (nothing
modified).
"""

import argparse
import keyword
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# The template's real working names double as its placeholder tokens.
OLD_DIST = "cli-template"
OLD_PACKAGE = "cli_template"
OLD_OWNER = "ryancheley"
OLD_AUTHOR = "Ryan Cheley"
OLD_EMAIL = "rcheley@gmail.com"
OLD_DESCRIPTION = "A modern Python CLI tool template"

NAME_RE = re.compile(r"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")
OWNER_RE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$")


def run(*cmd: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    """Run a subprocess from the repo root, capturing text output."""
    return subprocess.run(cmd, cwd=ROOT, check=check, capture_output=True, text=True)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--name", required=True, help="Project/CLI name, lowercase kebab-case (e.g. foo-tool)")
    parser.add_argument("--author", required=True, help="Author display name")
    parser.add_argument("--email", required=True, help="Author email")
    parser.add_argument("--github", required=True, help="GitHub owner or owner/repo (repo defaults to --name)")
    parser.add_argument("--description", required=True, help="One-line project description")
    parser.add_argument("--title", default="", help="Human-readable title (default: derived from --name)")
    return parser.parse_args(argv)


def validate(args: argparse.Namespace) -> list[str]:
    """Collect every validation error; nothing is modified while any exist."""
    errors: list[str] = []
    package = args.name.replace("-", "_")
    if not NAME_RE.fullmatch(args.name):
        errors.append(f"--name {args.name!r} must be lowercase kebab-case matching {NAME_RE.pattern} (e.g. foo-tool)")
    elif not package.isidentifier() or keyword.iskeyword(package):
        errors.append(f"--name {args.name!r} derives package {package!r}, which is not a usable Python identifier")
    if not args.author.strip():
        errors.append('--author must not be empty (e.g. --author "Ada Lovelace")')
    if "@" not in args.email or "." not in args.email.rsplit("@", 1)[-1]:
        errors.append(f"--email {args.email!r} does not look like an email (e.g. ada@example.com)")
    owner = args.github.split("/", 1)[0]
    if not OWNER_RE.fullmatch(owner):
        errors.append(f"--github owner {owner!r} is not a valid GitHub username (e.g. adalovelace or adalovelace/foo)")
    if not args.description.strip() or "\n" in args.description:
        errors.append("--description must be a non-empty single line")
    if args.title and not args.title.strip():
        errors.append("--title, when given, must not be blank")
    return errors


def guard() -> None:
    """Refuse to run twice or outside a git work tree (exit 3)."""
    tree_ok = run("git", "rev-parse", "--is-inside-work-tree", check=False)
    if tree_ok.returncode != 0 or tree_ok.stdout.strip() != "true":
        print(
            "ERROR: not inside a git work tree. Git is the undo mechanism, so init only runs "
            "in a checkout; nothing was modified.",
            file=sys.stderr,
        )
        raise SystemExit(3)
    pyproject = ROOT / "pyproject.toml"
    initialized = (
        not (ROOT / "src" / OLD_PACKAGE).is_dir()
        or not pyproject.exists()
        or f'name = "{OLD_DIST}"' not in pyproject.read_text(encoding="utf-8")
    )
    if initialized:
        print(
            "ERROR: this project looks already initialized (no cli-template placeholders left). "
            "Init runs exactly once; nothing was modified.",
            file=sys.stderr,
        )
        raise SystemExit(3)


def tracked_files() -> list[Path]:
    """Tracked, existing, substitutable files (excludes the lock and this script)."""
    out = run("git", "ls-files").stdout.splitlines()
    skip = {"uv.lock", "scripts/init.py"}
    return [ROOT / line for line in out if line not in skip and (ROOT / line).is_file()]


def substitute(files: list[Path], replacements: list[tuple[str, str]]) -> int:
    """Apply ordered literal replacements to every text file; return files changed."""
    changed = 0
    for path in files:
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        new_text = text
        for old, new in replacements:
            new_text = new_text.replace(old, new)
        if new_text != text:
            path.write_text(new_text, encoding="utf-8")
            changed += 1
    return changed


def splice_init_recipe() -> None:
    """Remove the marker-delimited init recipe block from the justfile."""
    justfile = ROOT / "justfile"
    lines = justfile.read_text(encoding="utf-8").splitlines(keepends=True)
    marker = "# --- init (removed by init) ---"
    idx = [i for i, line in enumerate(lines) if line.strip() == marker]
    if len(idx) >= 2:
        del lines[idx[0] : idx[1] + 1]
    justfile.write_text("".join(lines), encoding="utf-8")


def strip_marked_block(path: Path, start: str, end: str) -> None:
    """Delete everything from a start marker line through an end marker line."""
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(re.escape(start) + r".*?" + re.escape(end) + r"\n?", re.S)
    path.write_text(pattern.sub("", text), encoding="utf-8")


def write_readme(name: str, title: str, description: str, owner: str, repo: str, package: str) -> None:
    env_prefix = f"_{package.upper()}_COMPLETE"
    (ROOT / "README.md").write_text(
        f"""# {title}

{description}

## Install

```sh
uv tool install {name}
```

## Quick start

```sh
{name} --help
{name} --version
{name} hello --name You
```

## Shell completion

```sh
# bash (~/.bashrc)
eval "$({env_prefix}=bash_source {name})"
# zsh (~/.zshrc)
eval "$({env_prefix}=zsh_source {name})"
# fish (~/.config/fish/completions/{name}.fish)
{env_prefix}=fish_source {name} | source
```

## Development

Prerequisites: [uv](https://docs.astral.sh/uv/), git, [just](https://just.systems/), [prek](https://prek.j178.dev/).

```sh
just install        # sync all dependencies
just install-hooks  # install git hooks
just                # list every available recipe
just check          # run every quality gate + tests
```

## Releasing

One-time setup: on PyPI add a trusted publisher (project `{name}`, owner
`{owner}`, repository `{repo}`, workflow `release.yml`, environment `pypi`),
and create a GitHub environment named `pypi`. To rehearse first, do the same
on <https://test.pypi.org> and temporarily point the publish step at
`https://test.pypi.org/legacy/`. No API tokens are stored anywhere.

Then, from `main`:

```sh
just release 0.1.0
```
""",
        encoding="utf-8",
    )


def write_changelog() -> None:
    (ROOT / "CHANGELOG.md").write_text(
        """# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0]

### Added

- Initial project scaffold.
""",
        encoding="utf-8",
    )


def verify(new_values: list[str]) -> int:
    """Residue scan + full gate. Returns the process exit code (0 or 1)."""
    old_tokens = [OLD_DIST, OLD_PACKAGE, OLD_OWNER, OLD_AUTHOR, OLD_EMAIL, OLD_DESCRIPTION]
    reused = {v.lower() for v in new_values}
    tokens = [t for t in old_tokens if t.lower() not in reused]
    skip_dirs = {".git", ".venv", "dist", ".pytest_cache", ".ruff_cache", "__pycache__"}
    skip_files = {"uv.lock"}
    hits: list[str] = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or skip_dirs & set(path.relative_to(ROOT).parts):
            continue
        if path.name in skip_files:
            continue
        try:
            text = path.read_text(encoding="utf-8").lower()
        except (UnicodeDecodeError, OSError):
            continue
        hits.extend(f"{path.relative_to(ROOT)}: {tok}" for tok in tokens if tok.lower() in text)

    print(
        "\nVerification 1/2 — placeholder residue scan "
        f"(equivalent to: grep -ri {'|'.join(tokens)!r} . --exclude-dir=.git --exclude-dir=.venv)"
    )
    if hits:
        print("RESIDUE FOUND — init FAILED to replace every placeholder:", file=sys.stderr)
        for hit in hits:
            print(f"  {hit}", file=sys.stderr)
    else:
        print("  zero placeholder occurrences ✓")

    print("\nVerification 2/2 — just check")
    check = subprocess.run(["just", "check"], cwd=ROOT)
    if check.returncode != 0:
        print("'just check' FAILED in the initialized project.", file=sys.stderr)

    if hits or check.returncode != 0:
        print(
            "\nInit completed with verification FAILURES (exit 1). To start over:\n  git checkout . && git clean -fd",
            file=sys.stderr,
        )
        return 1
    return 0


def main(argv: list[str]) -> int:
    guard()
    args = parse_args(argv)
    errors = validate(args)
    if errors:
        print("Invalid arguments — nothing was modified:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 2

    name = args.name
    package = name.replace("-", "_")
    title = args.title.strip() or name.replace("-", " ").title()
    owner, _, repo = args.github.partition("/")
    repo = repo or name

    print(f"Initializing: {name} (package {package}) by {args.author} <{args.email}> → github.com/{owner}/{repo}")

    # 1. Remove template development artifacts first (plan amendment A1) so
    #    they are neither substituted nor scanned.
    for dev_dir in (".specify", "specs"):
        shutil.rmtree(ROOT / dev_dir, ignore_errors=True)
    print("  removed template dev artifacts: .specify/ specs/")

    # 2. Ordered literal substitution — composites before bare tokens.
    replacements = [
        (f"{OLD_OWNER}/{OLD_DIST}", f"{owner}/{repo}"),
        (OLD_PACKAGE.upper(), package.upper()),  # completion env prefix
        (OLD_PACKAGE, package),
        (OLD_DIST, name),
        ("Cli Template", title),
        (OLD_DESCRIPTION, args.description),
        (OLD_AUTHOR, args.author),
        (OLD_EMAIL, args.email),
        (OLD_OWNER, owner),
    ]
    files = tracked_files()
    changed = substitute(files, replacements)
    print(f"  substituted placeholders in {changed} files")

    # 3. Rename the package directory.
    if package != OLD_PACKAGE:
        (ROOT / "src" / OLD_PACKAGE).rename(ROOT / "src" / package)
    print(f"  renamed src/{OLD_PACKAGE}/ -> src/{package}/")

    # 4. Rewrite template-specific documents.
    write_readme(name, title, args.description, owner, repo, package)
    write_changelog()
    license_path = ROOT / "LICENSE"
    if license_path.exists():
        license_path.write_text(
            re.sub(
                r"Copyright \(c\) \d{4}", f"Copyright (c) {date.today().year}", license_path.read_text(encoding="utf-8")
            ),
            encoding="utf-8",
        )
    strip_marked_block(ROOT / "CLAUDE.md", "<!-- template-only:start -->", "<!-- template-only:end -->")
    strip_marked_block(ROOT / "CLAUDE.md", "<!-- SPECKIT START -->", "<!-- SPECKIT END -->")
    print("  rewrote README.md and CHANGELOG.md; stripped template-only docs")

    # 5. Disarm: remove the init recipe and this script.
    splice_init_recipe()
    Path(__file__).resolve().unlink()
    scripts_dir = ROOT / "scripts"
    if scripts_dir.is_dir() and not any(scripts_dir.iterdir()):
        scripts_dir.rmdir()
    print("  removed scripts/init.py and the justfile init recipe")

    # 6. Regenerate the lockfile under the new name.
    print("  running uv sync...")
    sync = subprocess.run(["uv", "sync"], cwd=ROOT)
    if sync.returncode != 0:
        print("'uv sync' failed after renaming — fix pyproject.toml, then re-run: uv sync", file=sys.stderr)
        return 1

    # 7. Self-verify: residue scan + full gate.
    rc = verify([name, package, args.author, args.email, owner, repo, args.description])
    if rc == 0:
        print(f"""
{title} is initialized and green. Next steps:
  git add -A && git commit -m "🎉 chore: initialize {name} from cli-template"
  git push
  # then enable PyPI trusted publishing (see README) and, when ready:
  just release 0.1.0
""")
    return rc


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
