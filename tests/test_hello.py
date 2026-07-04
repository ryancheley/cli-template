"""Tests for the hello command, including the labeled regression-test example."""

from click.testing import CliRunner

from cli_template.cli import cli


def test_hello_default_greets_world(runner: CliRunner) -> None:
    """With no option, hello greets the default target."""
    result = runner.invoke(cli, ["hello"])
    assert result.exit_code == 0
    assert "Hello, World!" in result.output


def test_hello_name_option(runner: CliRunner) -> None:
    """--name changes who gets greeted."""
    result = runner.invoke(cli, ["hello", "--name", "Alice"])
    assert result.exit_code == 0
    assert "Hello, Alice!" in result.output


def test_hello_empty_name_is_actionable_usage_error(runner: CliRunner) -> None:
    """An empty --name fails with exit code 2 and tells the user what to do next."""
    result = runner.invoke(cli, ["hello", "--name", ""])
    assert result.exit_code == 2
    combined = result.output + (result.stderr or "")
    assert "cannot be empty" in combined
    assert "--name Alice" in combined  # the suggestion, per the actionable-error convention


def test_hello_whitespace_name_rejected_regression(runner: CliRunner) -> None:
    """REGRESSION TEST (template convention example).

    Pins the bug class from hypothetical issue #1: a whitespace-only --name
    used to print "Hello,   !" and exit 0 instead of failing with a usage
    error. Every bug fix in a generated project ships a test like this one,
    named and labeled so the pinned bug is obvious.
    """
    result = runner.invoke(cli, ["hello", "--name", "   "])
    assert result.exit_code == 2
