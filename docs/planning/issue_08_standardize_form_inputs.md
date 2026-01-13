# Issue 8: Standardize Form Input Styles

## Prompt for Agent

Create a GitHub issue to standardize form input styles across the app.

**Context:**
- Form inputs are used for recipe editing, meal planning, filters, etc.
- Need consistent visual patterns for text fields, dropdowns, date pickers
- Should follow design tokens
- Includes error states and validation messaging

**Issue Requirements:**
- Title: "Standardize Form Input Styles Across App"
- Labels: `enhancement`, `UI`, `P2-Medium`
- Milestone: `0.1.7 - Visual Foundations & Polish`
- Depends on: Issue #3 (ThemeData Implementation)

**Issue Description Should Include:**

1. **Objective**: Create and apply consistent form input styling patterns throughout Gastrobrain

2. **Input Types to Standardize**:
   - Text fields (single-line, multi-line)
   - Dropdowns/select menus
   - Date pickers
   - Number inputs
   - Search fields
   - Checkboxes and radio buttons (if applicable)

3. **Tasks**:
   - Define input styles in theme configuration
   - Standardize borders, padding, sizing
   - Configure label styles and positioning
   - Define error state styling
   - Configure disabled state styling
   - Standardize validation message appearance
   - Update all existing form inputs
   - Ensure proper focus indicators
   - Verify accessibility

4. **State Requirements**:
   - Default state
   - Focus state (clear visual indicator)
   - Error state (clear error messaging)
   - Disabled state (visually distinct)
   - Filled state (if different from default)

5. **Success Criteria**:
   - All form inputs follow standardized patterns
   - Clear visual feedback for all states
   - Consistent error messaging style
   - Proper accessibility (focus indicators, labels)
   - Follows design tokens
   - No custom input styling outside theme
   - All tests passing

6. **Deliverable**:
   - Updated input theme configuration
   - All existing inputs updated
   - Documentation of input patterns
   - All tests passing
