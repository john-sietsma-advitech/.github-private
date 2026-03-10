---
name: python
description: FastAPI, pytest, ruff, UV package management, and type hints
applyTo: "**/*.py"
---

# Python Development Instructions

## Technology Stack

- **Framework**: FastAPI with uvicorn
- **Python Version**: 3.12+
- **Testing**: pytest
- **Linting**: ruff (configured in ruff.toml)
- **Type Checking**: Standard type annotations with Astral Ty
- **Package Management**: Astral UV
- **Database ORM**: SQLAlchemy

## Code Style & Standards

- Follow PEP 8 conventions
- Use standard type annotations for all function parameters and return values (no `from __future__ import annotations` needed in Python 3.12+)
- **Prefer structured types over plain dictionaries:**
  - Use **Pydantic models** for API request/response schemas and when validation is required
  - Use **dataclasses** for simple data containers with type checking and immutability support
  - Use **TypedDict** when dictionary semantics are needed (e.g., `**kwargs` unpacking, JSON-like structures) while maintaining type safety
  - Reserve plain `dict` only for truly dynamic or arbitrary key-value data
  - This improves type safety, IDE support, code maintainability, and self-documentation
- Target Python 3.12+ features
- Use async/await patterns with FastAPI
- Structure routes in the `routes/` directory
- Write pytest tests in `tests/` directory
- **Prefer one class per file** to improve readability, discoverability, and separation of concerns
- Test class names MUST follow the pattern: `Test<ComponentName><TestScenario>` (e.g., `TestUserServiceCreate`, `TestAuthMiddlewareValidate`)

## Module Structure

Organise Python modules in the following order:

```python
# 1. Variables (Module-level constants or data)
MODULE_VARIABLE = 10
_internal_variable = "don't import this directly"  # convention for "private" variables

# 2. Functions (Reusable blocks of code)
def module_function(arg1: int) -> int:
    """This is a function docstring."""
    return arg1 * 2

# 3. Classes (Blueprints for creating objects)
class ModuleClass:
    """This is a class docstring."""
    class_variable = "shared by all instances"  # Shared across all instances

    def __init__(self, instance_variable: str) -> None:
        """The initialiser method."""
        self.instance_variable = instance_variable  # Unique to each instance

    def module_method(self) -> str:
        """Methods are functions defined within a class."""
        return f"Accessing instance var: {self.instance_variable}"

# 4. Executable statements (often used for module initialisation or testing)
if __name__ == "__main__":
    print("This runs when the module is executed as a script.")
    my_object = ModuleClass("data")
    print(my_object.module_method())
```

## Package Management with UV

- **MUST** use `uv sync` to install all project dependencies from the lockfile (e.g. on a fresh clone or after pulling changes — never `uv pip install`)
- **MUST** use `uv add <package>` for adding new dependencies to the project (never `pip install <package>`)
- **MUST** use `uv run scriptname.py` to run Python scripts (never `python scriptname.py`)
- **MUST** use `uv run -m module.name` to run Python modules (never `python -m module.name`)
- **MUST NOT** include manual venv creation/activation steps (UV handles this automatically)
- **MUST NOT** provide installation instructions for UV (assume it's already installed)
- Use `uv sync --upgrade` for updating all packages
- Use `uv sync --reinstall` for forcing reinstallation
- Use `uv cache clean` for clearing cache (not `uv pip cache purge`)

## Linting & Code Quality

- **Linting**: ruff for Python code quality
- **Type Checking**: Use type hints throughout
- **Commit Linting**: pre-commit hooks with ruff
- **MUST** sort imports according to isort configuration (future → stdlib → third-party → first-party → local)
- **MUST** run `uv run ruff check . --fix` after generating Python code to fix linting errors
- **MUST** run `uv run ty check .` to validate type hints before considering code complete
- **MUST** run `uv run pytest` to execute the test suite
- **MUST** ensure all generated code passes ruff, ty, and pytest checks before considering it complete

## CLI Design

- **MUST** use [Click](https://click.palletsprojects.com/) for all CLI entry points (never `argparse`)
- **MUST** keep CLI logic in a dedicated `src/<package_name>/cli.py` module — never embed `@click.command` or argument parsing inside library modules
- CLI commands are thin wrappers: parse arguments, then call a library function (e.g. `run(...)`) — all business logic lives in the library
- Define the Click group in `src/<package_name>/cli.py` and register subcommands there
- Use `src/<package_name>/__main__.py` solely to import and invoke the group (enables `uv run -m <package_name>`)
- Register the entry point in `pyproject.toml` under `[project.scripts]` pointing to `<package_name>.cli:cli`
- Use `click.Path(path_type=Path)` for path arguments to get `pathlib.Path` objects directly
- Use `click.UsageError` for validation errors that should show usage help (e.g. conflicting flags)
- Prefer `is_flag=True` over `type=bool` for boolean options
- Use `show_default=True` on options with non-obvious defaults

## API Design

- RESTful endpoints using FastAPI
- Use Pydantic models for request/response validation
- **Prefer annotations and fields to custom validators in Pydantic models:**
  - Use `Annotated` from the `typing` module together with Pydantic's `Field` to combine type hints, validation, and metadata whenever possible.
  - Only use custom validators when built-in features are insufficient.
  - This improves readability, maintainability, and leverages Pydantic's native features.
- Proper try/catch blocks and error responses at the endpoint level
