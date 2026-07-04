"""CliRunner tests for the top-level CLI: --version, --help, exit codes."""

from importlib.metadata import version

from click.testing import CliRunner

from cli_template.cli import cli


def test_version_matches_package_metadata(runner: CliRunner) -> None:
    """--version reports the version from installed package metadata, not a hardcoded string."""
    result = runner.invoke(cli, ["--version"])
    assert result.exit_code == 0
    assert version("cli-template") in result.output


def test_help_exits_zero_and_lists_hello(runner: CliRunner) -> None:
    """--help succeeds and shows the available commands."""
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "hello" in result.output


def test_short_help_flag(runner: CliRunner) -> None:
    """-h is wired as an alias for --help."""
    result = runner.invoke(cli, ["-h"])
    assert result.exit_code == 0


def test_unknown_command_is_usage_error(runner: CliRunner) -> None:
    """Unknown commands exit with code 2 (usage error), distinct from runtime failures."""
    result = runner.invoke(cli, ["nope"])
    assert result.exit_code == 2
