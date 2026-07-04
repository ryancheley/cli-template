"""Rich console helpers shared by all commands.

All terminal output goes through this module so formatting stays consistent
and rich is configured in exactly one place.
"""

from rich.console import Console

console = Console()
error_console = Console(stderr=True)


def success(message: str) -> None:
    """Print a success message to stdout."""
    console.print(f"[green]:heavy_check_mark:[/green] {message}")


def error(message: str, suggestion: str) -> None:
    """Print an actionable error to stderr.

    Every error states what went wrong (``message``) and what to do next
    (``suggestion``) — the template's error-handling convention.
    """
    error_console.print(f"[bold red]Error:[/bold red] {message}")
    error_console.print(f"[yellow]Try:[/yellow] {suggestion}")
