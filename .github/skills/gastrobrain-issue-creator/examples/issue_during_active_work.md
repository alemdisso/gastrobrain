# Example: Issue Discovered During Active Work

This example shows how to create an issue when you discover a blocking bug while working on another issue, including proper relationship handling.

---

## Context

You're actively working on issue #250 (implementing recipe navigation from meal plan). While testing your changes, you discover that the RecipeCard component shows the wrong ingredient count when a recipe has side dishes.

---

## User Input

```
Developer: "Found a bug while testing #250. The RecipeCard is showing
the wrong ingredient count when recipes have side dishes. It's only
counting the main recipe ingredients, not including the side dish
ingredients. This is breaking my navigation feature."
```

---

## Skill Response

### Checkpoint 1: Understanding the Problem

```
Issue Creation: Bug Report

Detecting active work context...
✓ Current branch: feature/250-recipe-navigation
✓ Working on: Issue #250
✓ Current milestone: 0.1.6

CHECKPOINT 1: Understanding the Problem
─────────────────────────────────────────

Let me make sure I understand:

Type: Bug (incorrect data display)
Scope: UI (RecipeCard component)
Affected area: RecipeCard widget
Priority: ? (need to determine if this blocks #250)

Specifics:
- Component: RecipeCard widget
- Problem: Ingredient count only includes main recipe
- Missing: Side dish ingredients not counted
- Impact: Incorrect information shown to users
- Discovery: Found while testing #250 (recipe navigation)

Relationship to #250:
- Discovered during: #250 work
- Affects: Same component (RecipeCard)
- Blocking #250?: Need to determine

Questions:
1. Does this incorrect count block completion of #250?
   - If yes: This becomes P1-High and should be fixed first
   - If no: Can be tracked separately for later

2. Is this a new bug introduced by #250 work?
   - If yes: Must fix as part of #250
   - If no: Pre-existing bug, separate issue

3. Where is RecipeCard used?
   - Just in recipe navigation?
   - Multiple places in the app?

Please clarify: Is this blocking #250, and is it pre-existing or new?
```

**User:** "It's pre-existing - was there before I started. And technically it doesn't block #250 since the navigation works, but it looks bad to navigate to a recipe and see wrong ingredient counts. Should probably fix it."

---

### Checkpoint 1 (Updated)

```
─────────────────────────────────────────
CHECKPOINT 1 Updated: Understanding the Problem

Type: Bug (incorrect data display)
Scope: UI (RecipeCard component)
Affected area: RecipeCard widget
Priority: P1-High (affects feature quality in #250, highly visible)

Specifics:
- Component: lib/widgets/recipe_card.dart (likely)
- Problem: Ingredient count only includes main recipe ingredients
- Missing: Side dish ingredients not counted in total
- Impact: Users see incorrect ingredient count on recipe cards
- Discovery: Found while testing #250 (recipe navigation)
- Status: Pre-existing bug (not introduced by #250)
- Visibility: High - shown prominently on recipe cards

Relationship to #250:
- Discovered during: #250 (recipe navigation work)
- Related to: Same component displayed by navigation
- Not blocking: #250 can be completed without this fix
- Should fix: Improves quality of #250 feature
- Recommendation: Fix before or alongside #250 completion

My understanding:
1. RecipeCard displays ingredient count badge/text
2. Count calculation only looks at main recipe
3. When recipe has side dishes, those ingredients aren't included
4. Result: Users see "12 ingredients" when there are really 18
5. This was already broken, #250 just made it more visible

Is this correct? Any other details? (y/n/more details)
```

**User:** y

---

### Checkpoint 2: Issue Details

```
─────────────────────────────────────────
CHECKPOINT 2: Issue Details

Title: "bug: recipe card shows incorrect ingredient count with side dishes"

Context:
RecipeCard components display an ingredient count badge showing the total
number of ingredients in a recipe. Currently, this count only includes
ingredients from the main recipe and does not include ingredients from
any side dishes associated with the recipe. This results in users seeing
incomplete and inaccurate ingredient counts.

This bug was discovered during testing of #250 (recipe navigation feature)
and affects the quality of that feature, though it's a pre-existing issue
not introduced by #250.

Current Behavior:

**Steps to Reproduce:**
1. View a recipe card for a recipe that has side dishes
2. Observe the ingredient count displayed on the card
3. Navigate to recipe details and manually count all ingredients (main + sides)
4. Compare counts

**Actual Result:**
Ingredient count only shows main recipe ingredients (e.g., "12 ingredients")

**Expected Result:**
Ingredient count should include all ingredients from main recipe plus all
side dishes (e.g., "18 ingredients")

**Example:**
- Main recipe: Grilled Chicken (10 ingredients)
- Side dish 1: Caesar Salad (5 ingredients)
- Side dish 2: Garlic Bread (3 ingredients)
- Card shows: "10 ingredients" ✗
- Should show: "18 ingredients" ✓

Does this capture the issue correctly? Any adjustments? (y/n/edit)
```

**User:** y

---

### Checkpoint 3: Implementation Guidance

```
─────────────────────────────────────────
CHECKPOINT 3: Implementation Guidance

Proposed Solution:
Update RecipeCard's ingredient count calculation to include ingredients
from associated side dishes, not just the main recipe.

Implementation approach:
1. Locate ingredient count calculation in RecipeCard
2. Query for associated side dishes (meal_recipe or recipe_ingredient_recipe junction)
3. Sum ingredient counts: main recipe + all side dishes
4. Update display

Tasks:
- [ ] Locate RecipeCard widget ingredient count logic
- [ ] Identify current ingredient count query/calculation
- [ ] Determine how to query side dishes for a recipe
- [ ] Update count calculation to include side dish ingredients
- [ ] Handle edge cases (recipes with no sides, multiple sides)
- [ ] Update RecipeCard to use new calculation
- [ ] Test with recipes having 0, 1, 2, 3+ side dishes
- [ ] Verify performance (query efficiency)
- [ ] Add/update tests for ingredient count calculation
- [ ] Run flutter analyze && flutter test

Technical Notes:
- **Affected files:**
  - lib/widgets/recipe_card.dart (primary)
  - Possibly: lib/models/recipe.dart (if count is model property)
  - Database query logic (if count is queried)
- **Data model consideration:**
  - How are side dishes associated? (MealRecipe? RecipeIngredientRecipe?)
  - Are side dishes always available when RecipeCard is shown?
  - Should count be calculated or cached?
- **Related issues:**
  - #250: Recipe navigation (where this was discovered)
  - Check: Are there other places showing ingredient count?
- **Performance:**
  - If count requires additional queries, consider caching
  - Or pre-calculate at recipe creation/update time
- **Discovered in:** #250 (recipe navigation work)

Investigation needed:
- Where exactly is ingredient count calculated?
- What data is available to RecipeCard?
- How are side dishes queried/loaded?

Is this implementation direction helpful? (y/n/adjust)
```

**User:** "Actually, side dishes might not always be loaded when showing recipe cards. We might need to load them first or pass them in. Let me think about the best approach."

---

### Checkpoint 3 (Updated)

```
─────────────────────────────────────────
CHECKPOINT 3 Updated: Implementation Guidance

Added consideration:
- Side dishes may not be loaded when RecipeCard is displayed
- Options:
  A) Always load side dishes before showing RecipeCard
  B) Pass side dishes to RecipeCard as parameter (if available)
  C) Make ingredient count optional/cached in Recipe model
  D) Load side dishes on-demand in RecipeCard (might be slow)

Recommendation: Analyze current RecipeCard usage patterns first to
determine best approach. Option C (cached count) might be cleanest.

Updated tasks include:
- [ ] Analyze how RecipeCard is currently used
- [ ] Determine if side dishes are available in all contexts
- [ ] Choose implementation approach (A/B/C/D)
- [ ] [Rest of tasks based on chosen approach]

Continuing to Checkpoint 4...
```

---

### Checkpoint 4: Acceptance & Testing

```
─────────────────────────────────────────
CHECKPOINT 4: Acceptance & Testing

Acceptance Criteria:
- [ ] RecipeCard displays correct total ingredient count
- [ ] Count includes main recipe ingredients
- [ ] Count includes all side dish ingredients
- [ ] Works for recipes with no side dishes (count = main only)
- [ ] Works for recipes with 1+ side dishes
- [ ] Performance is acceptable (no slow queries)
- [ ] Existing RecipeCard functionality unchanged
- [ ] All tests pass

Test Cases:

**Main scenarios:**
- Recipe with no side dishes: Count = main recipe ingredients only
- Recipe with 1 side dish: Count = main + side 1 ingredients
- Recipe with 3 side dishes: Count = main + all side ingredients

**Edge cases:**
- Recipe with 0 ingredients (unlikely but possible)
- Side dish with 0 ingredients (e.g., "to taste" only)
- Recipe with duplicate ingredients in main + sides (count all)

**Integration:**
- Verify RecipeCard in all contexts:
  - Recipe list screen
  - Search results
  - Recommendations
  - Meal plan (if shown)
  - Recipe navigation in #250

**Performance:**
- Ensure no N+1 query problems
- Verify count calculation is efficient
- Consider caching if needed

**Regression:**
- RecipeCard still displays all other info correctly
- No layout issues from updated count
- No changes to recipe model break other features

Are these acceptance criteria complete? Need more? (y/n/add)
```

**User:** y

---

### Checkpoint 5: Labels & Priority

```
─────────────────────────────────────────
CHECKPOINT 5: Labels & Priority

Recommended labels:
- Type: bug (incorrect data display)
- Scope: UI (RecipeCard widget)
- Priority: P1-High

Priority reasoning:
- **Visibility:** High - ingredient count is prominently displayed
- **Impact:** Users see incorrect information (data accuracy issue)
- **Frequency:** Every recipe card with side dishes
- **User trust:** Incorrect counts reduce confidence in app
- **Related to:** #250 (recipe navigation) - affects feature quality
- **Not P0:** Doesn't block usage, but affects user experience
- **P1 justified:** Pre-existing bug made more visible by new feature

Relationship to #250:
- Should ideally fix before completing #250
- Or note in #250 that this known issue exists
- Improves overall quality of navigation feature

Story Point Estimate: 3 points

Estimation reasoning:
- **Complexity:** Moderate
  - Need to analyze current implementation first
  - May need to refactor count calculation approach
  - Side dish loading considerations
  - Multiple RecipeCard usage contexts to verify
- **Files affected:** 2-3 files (widget, possibly model, queries)
- **Testing required:** Comprehensive
  - Multiple scenarios (0, 1, 3+ sides)
  - All RecipeCard usage contexts
  - Performance testing
  - Regression testing
- **Uncertainty:** Medium
  - Need to investigate current implementation
  - Need to determine best approach for side dish loading
  - May uncover related issues
- **Similar work:** Similar to recipe display logic
- **Estimated effort:** 4-6 hours
  - 1-2 hours: Investigation and design approach
  - 2-3 hours: Implementation
  - 1-2 hours: Testing and verification across contexts

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
RecipeCard components display an ingredient count badge showing the total number of ingredients in a recipe. Currently, this count only includes ingredients from the main recipe and does not include ingredients from any side dishes associated with the recipe. This results in users seeing incomplete and inaccurate ingredient counts.

This bug was discovered during testing of #250 (recipe navigation feature) and affects the quality of that feature, though it's a pre-existing issue not introduced by #250.

## Current Behavior

**Steps to Reproduce:**
1. View a recipe card for a recipe that has side dishes
2. Observe the ingredient count displayed on the card
3. Navigate to recipe details and manually count all ingredients (main + sides)
4. Compare counts

**Actual Result:**
Ingredient count only shows main recipe ingredients (e.g., "12 ingredients")

**Expected Result:**
Ingredient count should include all ingredients from main recipe plus all side dishes (e.g., "18 ingredients")

**Example:**
- Main recipe: Grilled Chicken (10 ingredients)
- Side dish 1: Caesar Salad (5 ingredients)
- Side dish 2: Garlic Bread (3 ingredients)
- Card shows: "10 ingredients" ✗
- Should show: "18 ingredients" ✓

## Proposed Solution
Update RecipeCard's ingredient count calculation to include ingredients from associated side dishes, not just the main recipe.

Implementation approach:
1. Locate ingredient count calculation in RecipeCard
2. Query for associated side dishes (meal_recipe or recipe_ingredient_recipe junction)
3. Sum ingredient counts: main recipe + all side dishes
4. Update display

**Important consideration:** Side dishes may not always be loaded when RecipeCard is displayed. Need to analyze current usage patterns and choose best approach:
- Option A: Always load side dishes before showing RecipeCard
- Option B: Pass side dishes to RecipeCard as parameter (if available)
- Option C: Cache ingredient count in Recipe model
- Option D: Load side dishes on-demand in RecipeCard

## Tasks
- [ ] Analyze how RecipeCard is currently used across the app
- [ ] Locate RecipeCard widget ingredient count logic
- [ ] Identify current ingredient count query/calculation
- [ ] Determine how to query side dishes for a recipe
- [ ] Choose implementation approach (A/B/C/D above)
- [ ] Update count calculation to include side dish ingredients
- [ ] Handle edge cases (recipes with no sides, multiple sides)
- [ ] Update RecipeCard to use new calculation
- [ ] Test with recipes having 0, 1, 2, 3+ side dishes
- [ ] Verify performance (query efficiency)
- [ ] Test in all RecipeCard contexts (list, search, recommendations)
- [ ] Add/update tests for ingredient count calculation
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] RecipeCard displays correct total ingredient count
- [ ] Count includes main recipe ingredients
- [ ] Count includes all side dish ingredients
- [ ] Works for recipes with no side dishes (count = main only)
- [ ] Works for recipes with 1+ side dishes
- [ ] Performance is acceptable (no slow queries)
- [ ] Existing RecipeCard functionality unchanged
- [ ] All tests pass

## Technical Notes
- **Affected files:**
  - lib/widgets/recipe_card.dart (primary)
  - Possibly: lib/models/recipe.dart (if count is model property)
  - Database query logic (if count is queried)
- **Discovered in:** #250 (recipe navigation work)
- **Related issues:** #250 - Recipe navigation from meal plan
- **Relationship:** Pre-existing bug made more visible by #250 navigation feature
- **Recommendation:** Fix before or alongside completing #250 for better feature quality
- **Data model consideration:**
  - How are side dishes associated? (MealRecipe? RecipeIngredientRecipe?)
  - Should count be calculated or cached?
- **Performance consideration:**
  - If count requires additional queries, consider caching
  - Or pre-calculate at recipe creation/update time
- **Testing contexts:** Verify in recipe list, search, recommendations, meal plan, navigation

## Test Cases

**Main scenarios:**
- Recipe with no side dishes: Count = main recipe ingredients only
- Recipe with 1 side dish: Count = main + side 1 ingredients
- Recipe with 3 side dishes: Count = main + all side ingredients

**Edge cases:**
- Recipe with 0 ingredients (unlikely but possible)
- Side dish with 0 ingredients (e.g., "to taste" only)
- Recipe with duplicate ingredients in main + sides (count all)

**Integration:**
- Verify RecipeCard in all contexts:
  - Recipe list screen
  - Search results
  - Recommendations
  - Meal plan (if shown)
  - Recipe navigation in #250

**Performance:**
- Ensure no N+1 query problems
- Verify count calculation is efficient
- Consider caching if needed

**Regression:**
- RecipeCard still displays all other info correctly
- No layout issues from updated count
- No changes to recipe model break other features

─────────────────────────────────────────

Ready to create this issue? (y/n/revise)
```

**User:** y

---

### GitHub CLI Commands

```bash
# Create the issue
gh issue create \
  --title "bug: recipe card shows incorrect ingredient count with side dishes" \
  --body "$(cat <<'EOF'
[Complete markdown from Checkpoint 6 above]
EOF
)"

# This will return an issue number, e.g., #270

# Add labels
gh issue edit 270 --add-label "bug,UI,P1-High"

# Add comment to establish relationship with #250
gh issue comment 270 --body "Discovered while testing #250 (recipe navigation). This is a pre-existing bug, not introduced by #250, but fixing it would improve the quality of the navigation feature. Recommend fixing before or alongside completing #250."

# Optional: Reference #270 in #250
gh issue comment 250 --body "Note: Discovered related bug #270 (ingredient count with side dishes). This is pre-existing and doesn't block this issue, but affects display quality."

# Optional: Add to project (current milestone)
gh project item-add 3 --owner alemdisso \
  --url https://github.com/alemdisso/gastrobrain/issues/270

# Optional: Add to same milestone as #250
gh issue edit 270 --milestone "0.1.6 - Shopping List & Polish"
```

---

## Key Takeaways from This Example

1. **Active work context detected:** Identified current branch and issue #250
2. **Blocking analysis:** Determined this doesn't block #250 but affects quality
3. **Pre-existing vs. new bug:** Clarified this isn't introduced by current work
4. **Relationship established:** Clear link between #250 and new issue
5. **Priority adjusted:** P1-High because highly visible, even though pre-existing
6. **Implementation uncertainty:** Noted need to investigate approach first
7. **Cross-reference comments:** Provided commands to link issues both ways
8. **Milestone consideration:** Suggested adding to same milestone

## Relationship Types Demonstrated

**"Discovered during #250"**
- Bug found while working on another issue
- Not caused by #250
- Affects same component/feature
- Should be tracked separately
- May want to fix together for quality

**Commands for linking issues:**
```bash
# In new issue #270:
gh issue comment 270 --body "Discovered during #250..."

# In original issue #250:
gh issue comment 250 --body "Related: #270 (ingredient count bug)"
```

## Decision Points During Active Work

When discovering issues during active work, consider:

1. **Is it blocking?**
   - Yes → High priority, fix first
   - No → Can track separately

2. **Did I introduce it?**
   - Yes → Fix as part of current issue
   - No → Separate issue, but may fix together

3. **Should I fix it now?**
   - If blocking: Yes
   - If highly visible in my feature: Consider it
   - If unrelated: Track for later

4. **How to prioritize?**
   - P0 if blocking release/critical path
   - P1 if affects feature quality significantly
   - P2 if discovered but not urgent
   - P3 if minor/cosmetic

This example shows proper handling of related work discovery without derailing the current task.
