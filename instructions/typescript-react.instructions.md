---
name: typescript-react
description: React 18, Hooks, PrimeReact, Vite, and ESLint configuration
applyTo: "**/*.{ts,tsx}"
---

# TypeScript & React Development Instructions

## Technology Stack

- **Framework**: React 18 with Hooks
- **Language**: TypeScript
- **Node Version**: 20.19+ or 22.12+
- **UI Components**: PrimeReact 9.x
- **Charts**: Chart.js, ECharts, Plotly, react-chartjs-2
- **Build Tool**: Vite
- **Linting**: ESLint 9.x
- **State Management**: Zustand (preferred; use when a state management library is needed)

## Code Style & Standards

- Use React 18 with Hooks
- Follow TypeScript strict mode practices
- Use PrimeReact components for UI consistency
- Keep components in `src/components/`
- Use Zustand for state management (preferred library; use when global or shared state is needed)
- ESLint with React plugin configuration
- Prefer hooks and functional components

## Linting & Code Quality

- **Linting**: ESLint 9.x
- **Type Checking**: `tsc --noEmit` via the project's TypeScript config
- **Testing**: Vitest (preferred) or Jest
- **Commit Linting**: pre-commit hooks with ESLint for TypeScript
- **MUST** run `npx eslint . --fix` (or `pnpm exec eslint . --fix`) after generating TypeScript/TSX code to fix linting errors
- **MUST** run `npx tsc --noEmit` to validate type correctness before considering code complete
- **MUST** run `npx vitest run` (or `npx jest`) to execute the test suite
- **MUST** ensure all generated code passes ESLint and type checks before considering it complete
