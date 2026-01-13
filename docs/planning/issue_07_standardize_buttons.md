# Issue 7: Standardize Button Styles

## Prompt for Agent

Create a GitHub issue to standardize button styles across the app.

**Context:**
- Buttons are used throughout the app for primary actions
- Need consistent visual patterns (primary, secondary, tertiary)
- Should follow design tokens
- Creates reusable patterns for future development

**Issue Requirements:**
- Title: "Standardize Button Styles Across App"
- Labels: `enhancement`, `UI`, `P2-Medium`
- Milestone: `0.1.7 - Visual Foundations & Polish`
- Depends on: Issue #3 (ThemeData Implementation)

**Issue Description Should Include:**

1. **Objective**: Create and apply consistent button styling patterns throughout Gastrobrain

2. **Button Types Needed**:
   - Primary buttons (main actions)
   - Secondary buttons (alternative actions)
   - Tertiary/text buttons (minor actions)
   - Icon buttons (when applicable)
   - Destructive buttons (delete, cancel actions)

3. **Tasks**:
   - Define button styles in theme configuration
   - Standardize sizing and padding
   - Ensure proper touch targets (minimum 48x48dp)
   - Apply consistent elevation/shadow where needed
   - Configure disabled states
   - Update all existing buttons to use standardized styles
   - Verify accessibility (contrast ratios)
   - Test on different screen sizes

4. **Styling Requirements**:
   - Follow design tokens (colors, spacing, typography)
   - Clear visual hierarchy between button types
   - Consistent with Gastrobrain's personality
   - Appropriate hover/press states (for interactive feedback)

5. **Success Criteria**:
   - All buttons follow standardized patterns
   - Clear visual distinction between button types
   - Consistent sizing and spacing
   - Proper accessibility (touch targets, contrast)
   - No custom button styling outside theme
   - All tests passing

6. **Deliverable**:
   - Updated button theme configuration
   - All existing buttons updated
   - Documentation of button patterns for future use
   - All tests passing
