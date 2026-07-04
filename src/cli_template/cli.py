"""Command-line entry point for cli-template."""

import click

from cli_template.commands.hello import hello


@click.group(context_settings={"help_option_names": ["-h", "--help"]})
@click.version_option(package_name="cli-template")
def cli() -> None:
    """A modern Python CLI tool template"""


cli.add_command(hello)


def main() -> None:
    """Console-script entry point (wired in pyproject.toml)."""
    cli()
