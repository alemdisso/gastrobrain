# Issue 2: Create Design Tokens System

## Prompt for Agent

Create a GitHub issue to establish the design tokens system for Gastrobrain.

**Context:**
- Design tokens are the concrete visual values (colors, typography, spacing) that implement the visual identity
- These will be used consistently across all UI components
- Must align with the visual identity defined in Issue #1
- Flutter/Material Design 3 implementation

**Issue Requirements:**
- Title: "Create Design Tokens System (Colors, Typography, Spacing)"
- Labels: `enhancement`, `UI`, `P1-High`
- Milestone: `0.1.7 - Visual Foundations & Polish`
- Depends on: Issue #1 (Visual Identity)

**Issue Description Should Include:**

1. **Objective**: Define concrete, reusable design tokens that implement Gastrobrain's visual identity

2. **Tasks**:
   - Define color palette:
     * Primary color(s)
     * Secondary/accent colors
     * Neutral palette (backgrounds, borders, disabled states)
     * Semantic colors (success, warning, error, info)
   - Define typography system:
     * Font family choices
     * Size scale (headings, body, caption)
     * Weight scale (regular, medium, bold)
     * Line heights
   - Define spacing system:
     * Base unit (4px or 8px)
     * Spacing scale (xs, sm, md, lg, xl)
     * Padding/margin standards
   - Define component styling patterns:
     * Border radius values
     * Shadow/elevation system
     * Border widths
     * Icon sizing standards

3. **Success Criteria**:
   - All design tokens documented with specific values
   - Values align with visual identity from Issue #1
   - Clear usage guidelines for each token category
   - Ready for implementation in Flutter ThemeData

4. **Deliverable**:
   - Design tokens document (markdown) with all values specified
   - Should be referenced during implementation and future UI work
