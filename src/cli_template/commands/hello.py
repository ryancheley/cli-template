"""The example command: option handling, rich output, and meaningful exit codes.

Replace this with your first real command; keep the conventions it shows.
"""

import click

from cli_template.output import error, success


@click.command()
@click.option("--name", default="World", show_default=True, help="Who to greet.")
def hello(name: str) -> None:
    """Greet someone by name."""
    if not name.strip():
        error("--name cannot be empty.", "Pass a non-empty name, e.g. --name Alice.")
        raise SystemExit(2)
    success(f"Hello, {name}!")
