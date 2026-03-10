---
name: css
description: Flexbox best practices, relative units, and responsive design
applyTo: "**/*.css"
---

# CSS Layout & Styling Instructions

## General Principles

- **MUST** use relative units (rem, em, %, vh, vw) instead of fixed pixel values for dimensions, spacing, and font sizes
- **MUST** check for and reuse existing CSS classes, variables, and utility classes before creating new styles
- **SHOULD** use CSS custom properties (variables) for consistent theming and reusable values
- **SHOULD** use rem units for font sizes and spacing to respect user font size preferences
- **SHOULD** use em units for component-relative spacing
- **SHOULD** use % or vw/vh for responsive container sizes
- **MUST NOT** create duplicate styles when existing classes can be reused or extended
- Prefer flexbox and grid layouts over absolute positioning

## Flexbox Best Practices

- **MUST** use `gap` property for spacing between flex items instead of margins
- **SHOULD** use `flex-wrap: wrap` for responsive layouts that adapt to container width
- **SHOULD** use `align-items` and `justify-content` for alignment instead of manual positioning
- **SHOULD** use `flex: 1` or `flex-grow` for flexible item sizing rather than fixed widths
- **SHOULD** use `flex-direction: column` for vertical layouts instead of nested containers
- **MUST NOT** use `float` or `display: inline-block` when flexbox achieves the same result
- Use `align-self` to override alignment for specific flex items
- Prefer `min-width`/`max-width` with flexbox over fixed widths for responsive components
