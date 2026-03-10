---
name: general
description: Version control, CI/CD, containerisation, and general practices
---

# General Infrastructure Standards

## Version Control & CI/CD

- **Version Control**: Git with Bitbucket repository
- **CI/CD**: Bitbucket Pipelines
- **Commit Messages**: Conventional Commits style
- **Commit Linting**: pre-commit hooks with commitizen for commit messages
- **Auto-commit**: Do not automatically commit changes without explicit user confirmation

## Branching Strategy

- **Default branch**: `main` or `master` (production)
- **Integration branch**: `develop` (default target for pull requests)
- **Working branches**: **MUST** use one of the following conventional prefixes:
  - `feature/` — new features or capabilities
  - `bugfix/` — bug fixes
  - `hotfix/` — urgent production fixes (targets `main` directly)
  - `refactor/` — code restructuring without behaviour change
  - `chore/` — maintenance tasks (dependencies, configs, cleanup)
  - `docs/` — documentation-only changes
  - `test/` — adding or updating tests
  - `ci/` — CI/CD pipeline changes
  - `release/` — release preparation branches
- **Branch naming format**: `<prefix>/<TICKET-ID>-<short-slug>` (e.g. `feature/VAC-123-add-user-authentication`)
- **MUST NOT** commit directly to `main`, `master`, or `develop`

## Containerisation

- **Containerisation**: Docker and Docker Compose
- **Container Databases**: MySQL
- **File System**: CIFS mount for NAS access (not SMB/NFS)
- **NAS Access**: Via Docker volumes only (no manual mount instructions)

## Commit Workflow

When the user requests a commit:

1. Run `git status --short` to see the full working tree — this includes both modified tracked files **and** untracked new files. Do NOT rely solely on diff tools that omit untracked files.
2. Group all changes (tracked modifications + new untracked files) into logical commits by concern (e.g. feature code + its tests together, config separately).
3. Stage each group with `git add <specific files>` — do NOT use `git add -A` unless all pending changes belong to a single commit.
4. Run `uv run pre-commit run` to execute pre-commit hooks against staged files. Fix any reported errors, re-stage the fixes, and re-run until hooks pass.
5. Commit each group in turn with a Conventional Commits message.
6. Repeat until `git status --short` is clean.

**Key rule**: newly created files (e.g. a test file paired with its implementation) MUST be staged and committed alongside the code they relate to, not left untracked or batched into a later commit.

## General Code Practices

- **Removed or moved code**: **MUST NOT** add comments explaining that code was removed or moved (e.g. `# removed`, `# no longer needed`, `# derived from`, `# was previously`). Delete the code; let version control track the change.
- **Linting**: All code **MUST** be linted using language-specific tools before committing
- **Type Checking**: All typed languages **MUST** pass type checking (Python, TypeScript, etc.)
- **Quality Gates**: Linting and type checking are mandatory; code is incomplete until passing
- See language-specific instruction files for exact linting commands and tools
- Use async/await patterns with async frameworks
- Use type hints throughout all code
- Follow strict mode practices for typed languages
