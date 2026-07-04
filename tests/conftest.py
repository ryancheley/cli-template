"""Shared fixtures for the test suite."""

import pytest
from click.testing import CliRunner


@pytest.fixture
def runner() -> CliRunner:
    """Provide a Click test runner (the template's only sanctioned way to invoke the CLI in tests)."""
    return CliRunner()
