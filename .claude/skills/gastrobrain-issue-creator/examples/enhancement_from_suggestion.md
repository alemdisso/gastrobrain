# Example: Enhancement from User Suggestion

This example shows how to transform a user feature request into a well-structured enhancement issue using the 6-checkpoint process.

---

## User Input

```
User: "It would be really helpful if I could duplicate my meal plan
to the next week. I usually eat similar stuff week to week, so starting
from scratch every time is tedious. Could we add a 'copy to next week'
button or something?"
```

---

## Skill Response

### Checkpoint 1: Understanding the Problem

```
Issue Creation: Feature Request

CHECKPOINT 1: Understanding the Problem
─────────────────────────────────────────

Let me make sure I understand:

Type: Enhancement (new feature)
Scope: UX/UI (meal planning workflow improvement)
Affected area: Weekly meal plan screen
Priority: P2-Medium (nice-to-have, improves workflow)

Specifics:
- User pain point: Must manually plan each week from scratch
- Common pattern: Users eat similar meals week to week
- Desired feature: Ability to duplicate current week's plan to next week
- Benefit: Saves time, reduces repetitive work
- Use case: User can copy plan, then modify as needed

My understanding:
1. User has a meal plan for current week
2. User wants to use same/similar plan for next week
3. Instead of adding each meal manually, user clicks "Copy to next week"
4. System duplicates all meals from current week to next week
5. User can then modify individual meals as needed

Questions:
- Should this copy only the main recipes, or include side dishes too?
- Should it preserve servings and notes?
- Should it work for any week, or only "current → next"?

Is this correct? Any clarifications? (y/n/more details)
```

**User:** "Yes, that's it. It should copy everything - main recipe, side dishes, servings, all of it. And yeah, I think just 'copy to next week' is fine, don't need to copy to arbitrary weeks."

---

### Checkpoint 2: Issue Details

```
─────────────────────────────────────────
CHECKPOINT 2: Issue Details

Title: "feat: add duplicate week feature to meal planning"

Context:
Users often eat similar meals week to week and currently must manually
recreate their meal plans each week. This is tedious and time-consuming,
especially for users with consistent eating patterns. Adding a "duplicate
week" feature would significantly improve the meal planning workflow by
allowing users to copy the current week's plan to the next week, then
modify individual meals as needed.

Current Behavior:
- Users must manually add each meal for each week
- No way to reuse previous week's plan
- Repetitive work for users with consistent meal patterns

Expected Behavior:
- Provide a "Duplicate to Next Week" action in the weekly plan screen
- Copy all meals from current week to next week
- Include main recipes, side dishes, servings, and notes
- Allow users to modify the duplicated plan as needed
- Preserve all meal details (servings, preparation notes, etc.)

Does this capture the feature correctly? Any adjustments? (y/n/edit)
```

**User:** y

---

### Checkpoint 3: Implementation Guidance

```
─────────────────────────────────────────
CHECKPOINT 3: Implementation Guidance

Proposed Solution:
Add a "Duplicate to Next Week" button/action to the WeeklyPlanScreen
that calls a new service method to copy all meal plan items from the
current week to the next week.

Implementation approach:
1. Add UI action (button or menu item) in WeeklyPlanScreen
2. Create MealPlanService.duplicateWeekToNext() method
3. Query all meal_plan_items for current week
4. Create new meal_plan_items for next week with same recipes/settings
5. Handle success/error feedback to user

Tasks:
- [ ] Design UI placement for "Duplicate Week" action
- [ ] Add strings to app_en.arb and app_pt.arb
  - "duplicateWeekToNext": "Duplicate to Next Week"
  - "weekDuplicatedSuccess": "Week duplicated successfully"
  - "weekDuplicateError": "Failed to duplicate week"
- [ ] Run flutter gen-l10n
- [ ] Create MealPlanService.duplicateWeekToNext() method
- [ ] Implement database logic to copy meal plan items
- [ ] Handle meal_plan_item_recipe junction (side dishes)
- [ ] Add UI button/action in WeeklyPlanScreen
- [ ] Show confirmation dialog before duplicating
- [ ] Show success/error feedback
- [ ] Add unit tests for service method
- [ ] Add widget tests for UI interaction
- [ ] Add integration test for full workflow
- [ ] Test edge cases (empty week, partial week)
- [ ] Run flutter analyze && flutter test

Technical Notes:
- **New service method:** lib/core/services/meal_plan_service.dart
- **Affected screen:** lib/screens/weekly_plan_screen.dart
- **Database tables:**
  - meal_plan_items (main table)
  - meal_plan_item_recipe (junction for side dishes)
- **Key considerations:**
  - Use transactions to ensure atomic operation
  - Copy all fields: meal_type, day_of_week, cooked_at, servings, notes
  - Handle side dishes through meal_plan_item_recipe junction
  - Generate new IDs for duplicated items
- **Similar pattern:** Meal recording uses similar multi-recipe logic
- **Confirmation:** Ask user to confirm before duplicating (prevent accidents)
- **Error handling:** What if next week already has meals? (Append or error?)

Decision needed: If next week already has some meals, should we:
A) Append to existing meals
B) Show error and refuse to duplicate
C) Show warning and allow user to choose

What do you think? (A/B/C)
```

**User:** "C - show a warning but let them proceed if they want"

---

### Checkpoint 3 (Updated)

```
Updated Technical Notes:
- **Duplicate behavior:** If next week has existing meals, show warning dialog:
  "Next week already has X meals. Duplicating will add more meals. Continue?"
  - User can proceed (append) or cancel

Continuing to Checkpoint 4...
```

---

### Checkpoint 4: Acceptance & Testing

```
─────────────────────────────────────────
CHECKPOINT 4: Acceptance & Testing

Acceptance Criteria:
- [ ] "Duplicate to Next Week" action visible in weekly plan screen
- [ ] Action duplicates all meals from current week to next week
- [ ] Main recipes duplicated correctly
- [ ] Side dishes duplicated correctly
- [ ] Servings preserved
- [ ] Preparation notes preserved
- [ ] Day-of-week mappings correct (Monday → Monday, etc.)
- [ ] Confirmation dialog shown before duplicating
- [ ] Warning shown if next week has existing meals
- [ ] Success message shown after duplication
- [ ] Error message shown if duplication fails
- [ ] Localized in EN and PT-BR
- [ ] All tests pass

Test Cases:

**Happy path:**
- Current week has 7 meals (1 per day, some with side dishes)
- Click "Duplicate to Next Week"
- Confirm dialog
- Verify next week now has 7 meals matching current week
- Verify all fields preserved (servings, notes, side dishes)

**Edge cases:**
- Empty week: Duplicate empty week → show message "No meals to duplicate"
- Partial week: Duplicate week with 3 meals → next week gets those 3 meals
- Next week has meals: Show warning, user proceeds → meals appended
- Next week has meals: Show warning, user cancels → no changes

**Error scenarios:**
- Database error during duplication → show error, no partial duplication (transaction rollback)
- Invalid week dates → handle gracefully

**UI tests:**
- Button/action is visible and enabled when week has meals
- Button/action is disabled when week is empty
- Confirmation dialog appears before duplication
- Warning dialog appears if next week has meals
- Success snackbar shown after successful duplication

**Integration test:**
- End-to-end: Create meals, duplicate, verify in next week
- Test with various meal configurations (main only, main+sides, multiple sides)

Reference: docs/testing/EDGE_CASE_TESTING_GUIDE.md for empty state testing

Are these acceptance criteria complete? Need more? (y/n/add)
```

**User:** y

---

### Checkpoint 5: Labels & Priority

```
─────────────────────────────────────────
CHECKPOINT 5: Labels & Priority

Recommended labels:
- Type: enhancement (new feature)
- Scope: UX (workflow improvement)
- Priority: P2-Medium

Priority reasoning:
- **User value:** High - significantly improves workflow for users
- **Frequency:** Used weekly by active users
- **Workaround:** Users can manually add meals (tedious but possible)
- **Complexity:** Moderate - not trivial but not highly complex
- **Not P1:** Nice-to-have improvement, not critical functionality
- **Good for P2:** Valuable feature for next milestone after core features

Story Point Estimate: 5 points

Estimation reasoning:
- **Complexity:** Moderate
  - New service method with database operations
  - UI changes (button + dialogs)
  - Localization
  - Transaction handling for data consistency
- **Files affected:** 2-3 files (service, screen, possibly new service file)
- **Database operations:** Moderate complexity
  - Query current week meals
  - Copy to new records with new IDs
  - Handle junction table for side dishes
  - Use transaction for atomicity
- **Testing required:** Comprehensive
  - Unit tests for service method
  - Widget tests for UI
  - Integration test for full workflow
  - Multiple edge cases
- **Uncertainty:** Low - well-understood requirement and approach
- **Similar work:** Similar to meal recording logic
- **Estimated effort:** 6-8 hours
  - 2 hours: Service method + database logic
  - 2 hours: UI integration + dialogs
  - 1 hour: Localization
  - 2-3 hours: Comprehensive testing

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
Users often eat similar meals week to week and currently must manually recreate their meal plans each week. This is tedious and time-consuming, especially for users with consistent eating patterns. Adding a "duplicate week" feature would significantly improve the meal planning workflow by allowing users to copy the current week's plan to the next week, then modify individual meals as needed.

## Current Behavior
- Users must manually add each meal for each week
- No way to reuse previous week's plan
- Repetitive work for users with consistent meal patterns

## Expected Behavior
- Provide a "Duplicate to Next Week" action in the weekly plan screen
- Copy all meals from current week to next week
- Include main recipes, side dishes, servings, and notes
- Allow users to modify the duplicated plan as needed
- Preserve all meal details (servings, preparation notes, etc.)

## Proposed Solution
Add a "Duplicate to Next Week" button/action to the WeeklyPlanScreen that calls a new service method to copy all meal plan items from the current week to the next week.

Implementation approach:
1. Add UI action (button or menu item) in WeeklyPlanScreen
2. Create MealPlanService.duplicateWeekToNext() method
3. Query all meal_plan_items for current week
4. Create new meal_plan_items for next week with same recipes/settings
5. Handle success/error feedback to user

## Tasks
- [ ] Design UI placement for "Duplicate Week" action
- [ ] Add strings to app_en.arb and app_pt.arb
  - "duplicateWeekToNext": "Duplicate to Next Week"
  - "weekDuplicatedSuccess": "Week duplicated successfully"
  - "weekDuplicateError": "Failed to duplicate week"
  - "weekAlreadyHasMeals": "Next week already has {count} meals. Duplicating will add more meals. Continue?"
- [ ] Run flutter gen-l10n
- [ ] Create MealPlanService.duplicateWeekToNext() method
- [ ] Implement database logic to copy meal plan items
- [ ] Handle meal_plan_item_recipe junction (side dishes)
- [ ] Add UI button/action in WeeklyPlanScreen
- [ ] Show confirmation dialog before duplicating
- [ ] Show warning if next week has existing meals (allow proceed or cancel)
- [ ] Show success/error feedback
- [ ] Add unit tests for service method
- [ ] Add widget tests for UI interaction
- [ ] Add integration test for full workflow
- [ ] Test edge cases (empty week, partial week, week with existing meals)
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] "Duplicate to Next Week" action visible in weekly plan screen
- [ ] Action duplicates all meals from current week to next week
- [ ] Main recipes duplicated correctly
- [ ] Side dishes duplicated correctly
- [ ] Servings preserved
- [ ] Preparation notes preserved
- [ ] Day-of-week mappings correct (Monday → Monday, etc.)
- [ ] Confirmation dialog shown before duplicating
- [ ] Warning shown if next week has existing meals (with option to proceed or cancel)
- [ ] Success message shown after duplication
- [ ] Error message shown if duplication fails
- [ ] Localized in EN and PT-BR
- [ ] All tests pass

## Technical Notes
- **New service method:** lib/core/services/meal_plan_service.dart (or create if doesn't exist)
- **Affected screen:** lib/screens/weekly_plan_screen.dart
- **Database tables:**
  - meal_plan_items (main table)
  - meal_plan_item_recipe (junction for side dishes)
- **Key considerations:**
  - Use database transactions to ensure atomic operation
  - Copy all fields: meal_type, day_of_week, cooked_at, servings, notes
  - Handle side dishes through meal_plan_item_recipe junction
  - Generate new IDs for duplicated items (IDGenerator)
- **Duplicate behavior:** If next week has existing meals, show warning dialog allowing user to proceed (append) or cancel
- **Similar pattern:** Meal recording uses similar multi-recipe logic
- **Error handling:** Use try-catch with transaction rollback on error

## Test Cases

**Happy path:**
- Current week has 7 meals (1 per day, some with side dishes)
- Click "Duplicate to Next Week"
- Confirm dialog
- Verify next week now has 7 meals matching current week
- Verify all fields preserved (servings, notes, side dishes)

**Edge cases:**
- Empty week: Duplicate empty week → show message "No meals to duplicate"
- Partial week: Duplicate week with 3 meals → next week gets those 3 meals
- Next week has meals: Show warning, user proceeds → meals appended correctly
- Next week has meals: Show warning, user cancels → no changes made

**Error scenarios:**
- Database error during duplication → show error, no partial duplication (transaction rollback)
- Invalid week dates → handle gracefully

**UI tests:**
- Button/action is visible and enabled when week has meals
- Button/action is disabled when week is empty
- Confirmation dialog appears before duplication
- Warning dialog appears if next week has meals
- Success snackbar shown after successful duplication

**Integration test:**
- End-to-end: Create meals, duplicate, verify in next week
- Test with various meal configurations (main only, main+sides, multiple sides)

─────────────────────────────────────────

Ready to create this issue? (y/n/revise)
```

**User:** y

---

### GitHub CLI Commands

```bash
# Create the issue
gh issue create \
  --title "feat: add duplicate week feature to meal planning" \
  --body "$(cat <<'EOF'
[Complete markdown from Checkpoint 6 above]
EOF
)"

# This will return an issue number, e.g., #268

# Add labels
gh issue edit 268 --add-label "enhancement,UX,P2-Medium"

# Optional: Add to project (can be done during sprint planning)
gh project item-add 3 --owner alemdisso \
  --url https://github.com/alemdisso/gastrobrain/issues/268
```

---

## Key Takeaways from This Example

1. **Clarifying questions asked:** Agent asked about details (side dishes, servings, which weeks)
2. **User input incorporated:** Warning dialog behavior (option C) added based on user preference
3. **Comprehensive tasks:** Included localization, confirmation dialogs, warning logic
4. **Edge cases identified:** Empty week, partial week, existing meals in target week
5. **Technical details:** Database transactions, junction tables, ID generation
6. **User-centric:** Framed around user pain point and workflow improvement
7. **Clear priority reasoning:** P2-Medium justified as valuable but not critical
8. **Realistic estimate:** 5 points (6-8 hours) with detailed breakdown

The checkpoint process allowed the agent to ask clarifying questions and incorporate user preferences, resulting in a well-defined, implementable enhancement issue.
