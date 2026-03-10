---
name: language
description: Australian English spelling, documentation style, and RFC2119 keywords
---

# Language and Documentation Standards

## English Language

**MUST** use Australian English spelling throughout all code, documentation, and comments:

- Use -ise/-isation (organise, optimise, normalise, customise, authorise, initialise, analyse)
- NOT -ize/-ization (organize, optimize, normalize, customize, authorize, initialize, analyze)

Do not use filler words like "comprehensively", "thoroughly", "extensively", "unique". Be concise and to the point.

**MUST NOT** use emoji or unicode symbol characters in responses, documentation, or code comments.

Use imperative keywords based on [RFC2119](https://www.ietf.org/rfc/rfc2119.txt) when describing instructions. For example, use "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", "MAY", "RECOMMENDED", "OPTIONAL".

## Naming Conventions

Apply the following conventions consistently across all code. See the language-specific instruction files for full details.

| Construct | Python | TypeScript |
| --- | --- | --- |
| Variables & functions | `snake_case` | `camelCase` |
| Classes | `PascalCase` | `PascalCase` |
| Constants | `UPPER_SNAKE_CASE` | `UPPER_SNAKE_CASE` |
| Files & modules | `snake_case` | `kebab-case` |
| React components | — | `PascalCase` |

- See [python.instructions.md](python.instructions.md) for Python-specific conventions
- See [typescript-react.instructions.md](typescript-react.instructions.md) for TypeScript/React-specific conventions

## Documentation Standards

- **Documentation Format**: Markdown files in `docs/` directory
- **Docstrings**: Add docstrings to Python functions
- **JSDoc**: Add JSDoc comments to TypeScript functions
- **Documentation Content**: Only include project-specific instructions and configuration; never include general technology tutorials or guides that duplicate official documentation
- **No Troubleshooting Sections**: Never add troubleshooting sections to documentation
- **No Support Sections**: Never add "Getting Help" or "Support" sections to documentation
- **Diagram Exports**: Each file in `docs/diagrams/` MUST contain exactly one Mermaid diagram. After editing, regenerate the PNG export using `mmdc -i <file>.md -o <file>-1.png -t neutral -b transparent`. The `-1` suffix is the expected filename — no renaming required.
