# Example: Bug Report from User Feedback

This example shows how to transform an informal user bug report into a well-structured GitHub issue using the 6-checkpoint process.

---

## User Input

```
User: "Hey, I found a bug. When I edit a meal that has side dishes,
the side dishes just disappear after I save. Really annoying because
I have to add them back every time."
```

---

## Skill Response

### Checkpoint 1: Understanding the Problem

```
Issue Creation: Bug Report

CHECKPOINT 1: Understanding the Problem
─────────────────────────────────────────

Let me make sure I understand:

Type: Bug (data loss)
Scope: UI/Data persistence
Affected area: Meal editing functionality
Priority: P1-High (data loss, impacts user workflow)

Specifics:
- Happens when: Editing existing meals
- Condition: Meal must have side dishes (secondary recipes)
- Result: Side dishes are lost after saving
- Impact: Users must re-add side dishes, data loss
- Frequency: Every time meal is edited

My understanding:
1. User creates meal with main recipe + side dishes
2. User edits the meal (e.g., changes servings, date, notes)
3. User saves changes
4. Side dishes are no longer associated with the meal
5. Main recipe is preserved correctly

Is this correct? Any other details I should know? (y/n/more details)
```

**User:** y

---

### Checkpoint 2: Issue Details

```
─────────────────────────────────────────
CHECKPOINT 2: Issue Details

Title: "bug: side dishes disappear when editing meal records"

Context:
Users can add side dishes (secondary recipes) to meals for more complex
meal planning. When editing a meal that has side dishes, the side dishes
are lost upon saving, forcing users to re-add them. This creates a poor
user experience and potential data loss.

Current Behavior:

**Steps to Reproduce:**
1. Create a meal with a main recipe and 1+ side dishes
2. View the meal in meal history (confirm side dishes are present)
3. Edit the meal (e.g., change servings or add notes)
4. Save the changes
5. View the meal again

**Actual Result:** Side dishes are no longer associated with the meal

**Expected Result:** Side dishes should be preserved when editing meals

Does this capture the issue correctly? Any adjustments needed? (y/n/edit)
```

**User:** y

---

### Checkpoint 3: Implementation Guidance

```
─────────────────────────────────────────
CHECKPOINT 3: Implementation Guidance

Proposed Solution:
Likely issue in the meal update logic where side dishes are not being
persisted when the meal is updated. The MealEditService or the dialog
may not be passing side dishes to the update method, or the update
method may not be handling them correctly.

Tasks:
- [ ] Reproduce bug with test case
- [ ] Review EditMealRecordingDialog side dish handling
- [ ] Review MealEditService.updateMealWithRecipes() method
- [ ] Identify why side dishes are being dropped during update
- [ ] Fix update logic to preserve side dishes
- [ ] Add regression test
- [ ] Test with various side dish counts (1, 2, 3+)
- [ ] Run flutter analyze && flutter test

Technical Notes:
- **Affected files:**
  - lib/widgets/edit_meal_recording_dialog.dart (UI)
  - lib/core/services/meal_edit_service.dart (business logic)
- **Related issues:**
  - #237: MealEditService consolidation (recent work on this service)
  - Check: Are side dishes being passed to updateMealWithRecipes()?
- **Data model:** MealRecipe junction table with isPrimaryDish flag
- **Testing pattern:** See docs/testing/DIALOG_TESTING_GUIDE.md

Debugging approach:
1. Add logging to see what data is passed to update method
2. Check if EditMealRecordingDialog includes side dishes in update call
3. Verify MealEditService handles side dishes in update path

Is this implementation direction helpful? (y/n/adjust)
```

**User:** y

---

### Checkpoint 4: Acceptance & Testing

```
─────────────────────────────────────────
CHECKPOINT 4: Acceptance & Testing

Acceptance Criteria:
- [ ] Editing a meal preserves all side dishes
- [ ] Works for meals with 1, 2, or 3+ side dishes
- [ ] Main recipe is not affected by the fix
- [ ] Meal history displays side dishes correctly after edit
- [ ] All meal fields can be edited without losing side dishes
- [ ] Regression test added to prevent recurrence
- [ ] All existing tests pass

Test Cases:
- **Main scenario:** Create meal with 1 side dish, edit meal (change servings), verify side dish persists
- **Multiple sides:** Create meal with 3 side dishes, edit meal, verify all 3 persist
- **No sides baseline:** Edit meal with no side dishes (should continue to work)
- **Edit each field:** Test editing date, servings, notes - all should preserve sides
- **Edge case:** Edit meal and remove a side dish intentionally (should work correctly)
- **Regression:** Verify main recipe isn't duplicated or lost

Reference: docs/testing/DIALOG_TESTING_GUIDE.md for dialog testing patterns

Are these acceptance criteria complete? Need more? (y/n/add)
```

**User:** y

---

### Checkpoint 5: Labels & Priority

```
─────────────────────────────────────────
CHECKPOINT 5: Labels & Priority

Recommended labels:
- Type: bug (data loss issue)
- Scope: UI (affects meal editing dialog/screen)
- Priority: P1-High

Priority reasoning:
- **Impact:** Data loss - users lose work (side dishes)
- **Frequency:** Happens every time meal is edited
- **Workaround:** Users must re-add side dishes manually (annoying but possible)
- **Severity:** High - affects users who use side dishes feature
- **Not P0:** Doesn't block all usage, only affects editing with side dishes

Story Point Estimate: 3 points

Estimation reasoning:
- **Complexity:** Moderate - need to debug service/dialog interaction
- **Files affected:** 2 main files (dialog + service)
- **Testing required:** Comprehensive - multiple scenarios with varying side dish counts
- **Uncertainty:** Medium - need to investigate root cause
- **Similar work:** #237 touched MealEditService recently, context exists
- **Estimated effort:** 4-6 hours
  - 1 hour: Reproduce and debug
  - 2 hours: Implement fix
  - 1-2 hours: Write comprehensive tests
  - 1 hour: Verify and edge case testing

Agree with labels and estimate? (y/n/adjust)
```

**User:** y

---

### Checkpoint 6: Final Review

```
─────────────────────────────────────────
CHECKPOINT 6: Final Review

Here's the complete issue:

─────────────────────────────────────────
## Context
Users can add side dishes (secondary recipes) to meals for more complex meal planning. When editing a meal that has side dishes, the side dishes are lost upon saving, forcing users to re-add them manually. This creates a poor user experience and causes data loss.

## Current Behavior

**Steps to Reproduce:**
1. Create a meal with a main recipe and 1+ side dishes
2. View the meal in meal history (confirm side dishes are present)
3. Edit the meal (e.g., change servings or add notes)
4. Save the changes
5. View the meal again

**Actual Result:** Side dishes are no longer associated with the meal

**Expected Result:** Side dishes should be preserved when editing meals

## Proposed Solution
Likely issue in the meal update logic where side dishes are not being persisted when the meal is updated. The MealEditService or EditMealRecordingDialog may not be passing side dishes to the update method, or the update method may not be handling them correctly.

## Tasks
- [ ] Reproduce bug with test case
- [ ] Review EditMealRecordingDialog side dish handling
- [ ] Review MealEditService.updateMealWithRecipes() method
- [ ] Identify why side dishes are being dropped during update
- [ ] Fix update logic to preserve side dishes
- [ ] Add regression test
- [ ] Test with various side dish counts (1, 2, 3+)
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] Editing a meal preserves all side dishes
- [ ] Works for meals with 1, 2, or 3+ side dishes
- [ ] Main recipe is not affected by the fix
- [ ] Meal history displays side dishes correctly after edit
- [ ] All meal fields can be edited without losing side dishes
- [ ] Regression test added to prevent recurrence
- [ ] All existing tests pass

## Technical Notes
- **Affected files:**
  - lib/widgets/edit_meal_recording_dialog.dart (UI)
  - lib/core/services/meal_edit_service.dart (business logic)
- **Related issues:**
  - #237: MealEditService consolidation (recent work on this service)
- **Data model:** MealRecipe junction table with isPrimaryDish flag
- **Testing pattern:** See docs/testing/DIALOG_TESTING_GUIDE.md
- **Debugging approach:**
  1. Add logging to see what data is passed to update method
  2. Check if EditMealRecordingDialog includes side dishes in update call
  3. Verify MealEditService handles side dishes in update path

## Test Cases
- **Main scenario:** Create meal with 1 side dish, edit meal (change servings), verify side dish persists
- **Multiple sides:** Create meal with 3 side dishes, edit meal, verify all 3 persist
- **No sides baseline:** Edit meal with no side dishes (should continue to work)
- **Edit each field:** Test editing date, servings, notes - all should preserve sides
- **Edge case:** Edit meal and remove a side dish intentionally (should work correctly)
- **Regression:** Verify main recipe isn't duplicated or lost

─────────────────────────────────────────

Ready to create this issue? (y/n/revise)
```

**User:** y

---

### GitHub CLI Commands

```bash
# Create the issue
gh issue create \
  --title "bug: side dishes disappear when editing meal records" \
  --body "$(cat <<'EOF'
## Context
Users can add side dishes (secondary recipes) to meals for more complex meal planning. When editing a meal that has side dishes, the side dishes are lost upon saving, forcing users to re-add them manually. This creates a poor user experience and causes data loss.

## Current Behavior

**Steps to Reproduce:**
1. Create a meal with a main recipe and 1+ side dishes
2. View the meal in meal history (confirm side dishes are present)
3. Edit the meal (e.g., change servings or add notes)
4. Save the changes
5. View the meal again

**Actual Result:** Side dishes are no longer associated with the meal

**Expected Result:** Side dishes should be preserved when editing meals

## Proposed Solution
Likely issue in the meal update logic where side dishes are not being persisted when the meal is updated. The MealEditService or EditMealRecordingDialog may not be passing side dishes to the update method, or the update method may not be handling them correctly.

## Tasks
- [ ] Reproduce bug with test case
- [ ] Review EditMealRecordingDialog side dish handling
- [ ] Review MealEditService.updateMealWithRecipes() method
- [ ] Identify why side dishes are being dropped during update
- [ ] Fix update logic to preserve side dishes
- [ ] Add regression test
- [ ] Test with various side dish counts (1, 2, 3+)
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] Editing a meal preserves all side dishes
- [ ] Works for meals with 1, 2, or 3+ side dishes
- [ ] Main recipe is not affected by the fix
- [ ] Meal history displays side dishes correctly after edit
- [ ] All meal fields can be edited without losing side dishes
- [ ] Regression test added to prevent recurrence
- [ ] All existing tests pass

## Technical Notes
- **Affected files:**
  - lib/widgets/edit_meal_recording_dialog.dart (UI)
  - lib/core/services/meal_edit_service.dart (business logic)
- **Related issues:**
  - #237: MealEditService consolidation (recent work on this service)
- **Data model:** MealRecipe junction table with isPrimaryDish flag
- **Testing pattern:** See docs/testing/DIALOG_TESTING_GUIDE.md
- **Debugging approach:**
  1. Add logging to see what data is passed to update method
  2. Check if EditMealRecordingDialog includes side dishes in update call
  3. Verify MealEditService handles side dishes in update path

## Test Cases
- **Main scenario:** Create meal with 1 side dish, edit meal (change servings), verify side dish persists
- **Multiple sides:** Create meal with 3 side dishes, edit meal, verify all 3 persist
- **No sides baseline:** Edit meal with no side dishes (should continue to work)
- **Edit each field:** Test editing date, servings, notes - all should preserve sides
- **Edge case:** Edit meal and remove a side dish intentionally (should work correctly)
- **Regression:** Verify main recipe isn't duplicated or lost
EOF
)"

# This will return an issue number, e.g., #267

# Add labels
gh issue edit 267 --add-label "bug,UI,P1-High"

# Optional: Add to project (can be done during sprint planning)
gh project item-add 3 --owner alemdisso \
  --url https://github.com/alemdisso/gastrobrain/issues/267
```

---

## Key Takeaways from This Example

1. **Informal input translated:** User's casual report became structured issue
2. **Interactive checkpoints:** User confirmed understanding at each stage
3. **Technical context added:** Files, related issues, debugging approach provided
4. **Comprehensive testing:** Multiple test scenarios identified
5. **Clear priority reasoning:** P1-High justified with impact analysis
6. **Story point estimate:** 3 points with detailed reasoning
7. **Actionable tasks:** Clear implementation path
8. **Acceptance criteria:** Specific, testable outcomes defined

The checkpoint process ensured accuracy and allowed the user to provide input at each stage, resulting in a high-quality, actionable issue.
