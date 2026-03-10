---
name: swe
description: SOLID, DRY, and other high-level software engineering principles
---

# Software Engineering Principles

## SOLID Principles

### Single Responsibility Principle (SRP)

- Each class, module, or function should have ONE reason to change
- A component should do ONE thing well
- Separate concerns into distinct, focused units
- Example: Separate data access, business logic, and presentation logic

### Interface Segregation Principle (ISP)

- Clients should not be forced to depend on interfaces they don't use
- Create focused, specific interfaces rather than large, general-purpose ones
- Split large interfaces into smaller, more cohesive ones
- Avoid "fat" interfaces with many unrelated methods

### Dependency Inversion Principle (DIP)

- High-level modules should not depend on low-level modules; both should depend on abstractions
- Abstractions should not depend on details; details should depend on abstractions
- Use dependency injection to provide dependencies
- Program to interfaces, not implementations

## DRY (Don't Repeat Yourself)

- Every piece of knowledge should have a single, unambiguous representation
- Avoid code duplication through abstraction and reuse
- Extract common functionality into shared functions, classes, or modules
- Maintain a single source of truth for each piece of logic
- **Balance**: Don't over-abstract; some duplication is acceptable if it increases clarity

## KISS (Keep It Simple, Stupid)

- Favour simplicity over complexity
- Write code that is easy to understand and maintain
- Avoid over-engineering solutions
- Choose the simplest approach that solves the problem effectively
- Complexity should be justified by clear benefits

## YAGNI (You Aren't Gonna Need It)

- Don't add functionality until it's necessary
- Avoid speculative generality
- Build what you need now, not what you might need later
- Focus on current requirements, not anticipated future needs
- Refactor when requirements change, don't pre-emptively design for them

## Separation of Concerns

- Divide a system into distinct sections, each addressing a separate concern
- Each section should encapsulate a specific aspect of functionality
- Minimise overlap between concerns
- Examples:
  - Separate business logic from data access
  - Separate UI from business logic
  - Separate configuration from code

## Prefer Functional Over Object-Oriented Style

- Favour pure functions over stateful objects when possible
- Use immutable data structures to reduce side effects
- Prefer functions that transform data rather than mutate it
- Keep functions small, focused, and composable
- Use functional patterns: map, filter, reduce, comprehensions
- Avoid unnecessary classes; simple functions often suffice
- Reserve OOP for cases where encapsulation and state management add clear value
- Benefits:
  - Easier to test (no mocked dependencies)
  - Easier to reason about (no hidden state)
  - Better composability and reusability
  - Naturally supports parallelism and concurrency

## Fail Fast

- Detect and report errors as early as possible
- Validate inputs immediately
- Use assertions and guard clauses
- Throw exceptions when preconditions aren't met
- Don't allow invalid state to propagate

## Low Coupling, High Cohesion

- **Low Coupling**: Minimise dependencies between modules
  - Use interfaces and abstractions
  - Avoid tight coupling to specific implementations
  - Reduce the impact of changes

- **High Cohesion**: Keep related functionality together
  - Group related methods and data in the same module/class
  - Each module should have a clear, focused purpose
  - Avoid mixing unrelated concerns

## Defensive Programming

- Anticipate potential errors and handle them gracefully
- Validate all inputs
- Check preconditions and postconditions
- Use type hints and static analysis tools
- Write comprehensive tests
- Handle edge cases explicitly

## Code for Readability

- Code is read more often than it's written
- Use descriptive names for variables, functions, and classes
- Write self-documenting code
- Add comments for complex logic or non-obvious decisions
- Keep functions and methods short and focused
- Use consistent formatting and style

## Domain-Specific Naming

Names MUST reflect what a thing _is_ or _does_ in the domain, not its structural role in the codebase.

- **MUST NOT** use generic suffixes that carry no domain meaning: `Manager`, `Service`, `Handler`, `Helper`, `Util`, `Processor`, `Controller` (unless mandated by a framework convention)
- These names are a symptom of unclear responsibility — if you cannot name something without a generic suffix, the abstraction likely needs rethinking (apply SRP first)
- **Instead**, use names that describe the domain concept:

  | Avoid            | Prefer                                 |
  | ---------------- | -------------------------------------- |
  | `UserManager`    | `UserRegistry`, `Roster`, `Enrolment`  |
  | `PaymentService` | `PaymentGateway`, `Billing`, `Invoice` |
  | `DataProcessor`  | `ReportBuilder`, `TransactionParser`   |
  | `EmailHelper`    | `Mailer`, `NotificationSender`         |
  | `FileHandler`    | `ArtifactStore`, `LogArchive`          |

- If a framework requires a suffix (e.g. Django `View`, FastAPI `Router`), retain it — the rule targets names that are _only_ a suffix with no domain signal
- When naming is genuinely unclear, treat it as a design smell and resolve the responsibility before naming

## Boolean Naming

Boolean variables, parameters, and properties MUST use a prefix that implies a truth value, so that the name reads as a yes/no statement at the call site.

- **Approved prefixes**: `is`, `has`, `can`, `should`, `was`, `will`, `needs`, `allows`, `supports`
- The name MUST read naturally as a question or assertion: `isActive`, `hasPermission`, `shouldRetry`, `canEdit`
- **MUST NOT** use names that are ambiguous as booleans: `active`, `permission`, `retry`, `edit`, `status`, `flag`, `value`
- Negated names (`isNotReady`, `hasNoResults`) MUST be avoided — invert the condition and use a positive name instead (`isReady`, `hasResults`)

## Code Quality Standards

- **MUST** lint all code changes using language-specific tools before committing
- **MUST** type-check all typed languages (Python, TypeScript, etc.)
- **MUST** resolve all linting errors and warnings (not optional)
- **MUST** follow language-specific linting configurations defined in instruction files
- Linting and type checking are non-negotiable quality gates
- See language-specific instruction files for exact tools and commands
- Consider code incomplete until it passes all quality checks
- Configure pre-commit hooks to catch issues early

## Test-Driven Development (TDD) Principles

- Write tests before writing implementation code
- Tests should be automated and repeatable
- Each test should verify one specific behaviour
- Keep tests independent and isolated
- Use descriptive test names that explain what is being tested
- Refactor with confidence when tests are comprehensive
- Only generate tests for our custom business logic; do not write tests that merely verify framework functionality

## Dependency Management

- Minimise external dependencies
- Keep dependencies up to date
- Pin dependency versions for reproducibility
- Understand the cost and benefit of each dependency
- Prefer standard library solutions when appropriate
- Isolate third-party dependencies behind abstractions
