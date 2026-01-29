# Example: Technical Debt Discovered During Work

This example shows how to create a technical debt issue when discovering code quality problems during active development on another issue.

---

## Context

You're working on issue #250 (fixing a save button bug) and notice that protein counting logic is duplicated in three different places in the recommendation service.

---

## User Input

```
Developer: "While working on #250, I noticed the recommendation service
has the same protein counting logic copied in three different methods.
This is making the code hard to maintain. We should consolidate this."
```

---

## Skill Response

### Checkpoint 1: Understanding the Problem

```
Issue Creation: Technical Debt

Detecting active work context...
- Current branch: feature/250-save-button-fix
- Working on: Issue #250
- Current milestone: 0.1.6

CHECKPOINT 1: Understanding the Problem
─────────────────────────────────────────

Let me make sure I understand:

Type: Technical Debt (code quality, DRY violation)
Scope: Architecture (service refactoring)
Affected area: RecommendationService
Priority: P3-Low (doesn't block features, but impacts maintainability)

Specifics:
- Location: lib/core/services/recommendation_service.dart
- Problem: Protein counting logic duplicated in 3 methods
- Impact: Makes maintenance difficult, risk of inconsistency
- Discovered during: Work on #250
- Risk: Changes to protein logic must be made in 3 places

Context detected:
- Discovered while working on #250
- Should reference #250 in new issue
- Doesn't block #250 completion
- Can be addressed after #250

My understanding:
1. RecommendationService has protein counting logic
2. Same logic appears in multiple methods (likely copy-pasted)
3. This violates DRY principle
4. Should extract to single method/helper
5. All callers should use extracted method

Questions:
- Which 3 methods have the duplicate logic?
- Is the logic exactly the same, or slightly different?
- Is this blocking your work on #250?

Is this correct? Any details I should know? (y/n/more details)
```

**User:** "The methods are _scoreByProteinRotation, _calculateProteinDiversity, and _filterByProteinBalance. The logic is almost identical with minor variations. Not blocking #250, but annoying."

---

### Checkpoint 2: Issue Details

```
─────────────────────────────────────────
CHECKPOINT 2: Issue Details

Title: "refactor: consolidate duplicate protein counting logic in recommendation service"

Context:
The RecommendationService contains duplicate protein counting logic in three
separate methods (_scoreByProteinRotation, _calculateProteinDiversity, and
_filterByProteinBalance). This duplication makes the code harder to maintain,
increases the risk of inconsistencies when changes are needed, and violates
the DRY (Don't Repeat Yourself) principle.

This was discovered while working on #250 and should be addressed to improve
long-term code maintainability.

Current Behavior:
- Protein counting logic is copy-pasted in three methods:
  - `_scoreByProteinRotation()`
  - `_calculateProteinDiversity()`
  - `_filterByProteinBalance()`
- Each implementation is almost identical with minor variations
- Changes to protein logic must be made in three places
- Risk of inconsistency if one location is updated but others aren't

Expected Behavior:
- Protein counting logic extracted to a single method
- All three methods use the extracted helper
- Logic is consistent across all use cases
- Single source of truth for protein counting
- Easier to maintain and test

Does this capture the issue correctly? Any adjustments? (y/n/edit)
```

**User:** y

---

### Checkpoint 3: Implementation Guidance

```
─────────────────────────────────────────
CHECKPOINT 3: Implementation Guidance

Proposed Solution:
Extract the protein counting logic into a private helper method
`_countProteinsByType()` or similar, then update all three methods to
use this helper instead of their own implementations.

Refactoring approach:
1. Analyze the three implementations to identify common logic
2. Identify variations (if any) and parameterize them
3. Extract to new method: `_countProteinsByType(List<Recipe> recipes, ...)`
4. Update _scoreByProteinRotation to use helper
5. Update _calculateProteinDiversity to use helper
6. Update _filterByProteinBalance to use helper
7. Ensure all existing tests still pass (behavior unchanged)
8. Consider adding unit test for the extracted method

Tasks:
- [ ] Analyze duplicate logic in the three methods
- [ ] Identify common pattern and any variations
- [ ] Design extracted method signature
- [ ] Extract logic to new private method `_countProteinsByType()`
- [ ] Update `_scoreByProteinRotation()` to use helper
- [ ] Update `_calculateProteinDiversity()` to use helper
- [ ] Update `_filterByProteinBalance()` to use helper
- [ ] Verify all existing tests still pass
- [ ] Add unit test for extracted method (if not covered)
- [ ] Run flutter analyze && flutter test
- [ ] Document the extracted method with clear comments

Technical Notes:
- **File to refactor:** lib/core/services/recommendation_service.dart
- **Pattern:** Extract Method refactoring
- **Discovered in:** #250 (save button fix)
- **Related work:** Recommendation engine has been stable, this is pure refactoring
- **Testing:** Existing recommendation tests should all pass (no behavior change)
- **Benefits:**
  - Single source of truth for protein counting
  - Easier to maintain and update
  - Reduced risk of inconsistency
  - Better testability
- **Caution:** This is a pure refactoring - no functionality changes

Is this implementation direction helpful? (y/n/adjust)
```

**User:** y

---

### Checkpoint 4: Acceptance & Testing

```
─────────────────────────────────────────
CHECKPOINT 4: Acceptance & Testing

Acceptance Criteria:
- [ ] Protein counting logic extracted to single method
- [ ] All three methods use the extracted helper
- [ ] All existing tests pass (no behavior changes)
- [ ] Test coverage maintained or improved
- [ ] Code is more maintainable and readable
- [ ] No functionality regressions
- [ ] flutter analyze passes with no new warnings

Test Cases:

**Regression tests (must pass):**
- All existing recommendation service tests
- Protein rotation scoring works correctly
- Protein diversity calculation works correctly
- Protein balance filtering works correctly
- End-to-end recommendation tests

**New test (if needed):**
- Unit test for `_countProteinsByType()` helper method
  - Test with various recipe lists
  - Test with different protein types
  - Test with empty list
  - Test with recipes having multiple proteins

**Verification:**
- Compare recommendation results before and after refactoring
- Ensure identical behavior in all scenarios
- No performance regression

**Code quality:**
- Extracted method has clear name and purpose
- Method has documentation comment
- Parameters are well-named
- Logic is easier to understand

Are these acceptance criteria complete? Need more? (y/n/add)
```

**User:** y

---

### Checkpoint 5: Labels & Priority

```
─────────────────────────────────────────
CHECKPOINT 5: Labels & Priority

Recommended labels:
- Type: technical-debt (code quality improvement)
- Scope: architecture (service refactoring)
- Priority: P3-Low

Priority reasoning:
- **User impact:** None - internal code quality only
- **Developer impact:** Moderate - easier maintenance in future
- **Urgency:** Low - not blocking any work
- **Risk:** Low - well-defined refactoring with clear test coverage
- **Technical debt:** Yes, but not critical
- **Good time to do it:** After current sprint, or when touching this code next
- **Not P2:** No immediate user value, pure code quality

Story Point Estimate: 2 points

Estimation reasoning:
- **Complexity:** Low-moderate
  - Simple extract method refactoring
  - Well-defined scope (one file, three methods)
  - Clear pattern to follow
- **Files affected:** 1 file (recommendation_service.dart)
- **Testing required:** Minimal - verify existing tests pass
  - May add one new unit test
  - No integration testing needed
- **Uncertainty:** Very low - standard refactoring task
- **Similar work:** Common refactoring pattern
- **Estimated effort:** 1-2 hours
  - 30 min: Analyze and design extraction
  - 30 min: Extract method and update call sites
  - 30 min: Verify tests, add test if needed
  - 30 min: Review and ensure quality

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
The RecommendationService contains duplicate protein counting logic in three separate methods (_scoreByProteinRotation, _calculateProteinDiversity, and _filterByProteinBalance). This duplication makes the code harder to maintain, increases the risk of inconsistencies when changes are needed, and violates the DRY (Don't Repeat Yourself) principle.

This technical debt was discovered while working on #250 and should be addressed to improve long-term code maintainability.

## Current Behavior
- Protein counting logic is copy-pasted in three methods:
  - `_scoreByProteinRotation()`
  - `_calculateProteinDiversity()`
  - `_filterByProteinBalance()`
- Each implementation is almost identical with minor variations
- Changes to protein logic must be made in three places
- Risk of inconsistency if one location is updated but others aren't

## Expected Behavior
- Protein counting logic extracted to a single method
- All three methods use the extracted helper
- Logic is consistent across all use cases
- Single source of truth for protein counting
- Easier to maintain and test

## Proposed Solution
Extract the protein counting logic into a private helper method `_countProteinsByType()` or similar, then update all three methods to use this helper instead of their own implementations.

Refactoring approach:
1. Analyze the three implementations to identify common logic
2. Identify variations (if any) and parameterize them
3. Extract to new method: `_countProteinsByType(List<Recipe> recipes, ...)`
4. Update all three methods to use the helper
5. Ensure all existing tests still pass (behavior unchanged)

## Tasks
- [ ] Analyze duplicate logic in the three methods
- [ ] Identify common pattern and any variations
- [ ] Design extracted method signature
- [ ] Extract logic to new private method `_countProteinsByType()`
- [ ] Update `_scoreByProteinRotation()` to use helper
- [ ] Update `_calculateProteinDiversity()` to use helper
- [ ] Update `_filterByProteinBalance()` to use helper
- [ ] Verify all existing tests still pass
- [ ] Add unit test for extracted method (if not already covered)
- [ ] Run flutter analyze && flutter test
- [ ] Document the extracted method with clear comments

## Acceptance Criteria
- [ ] Protein counting logic extracted to single method
- [ ] All three methods use the extracted helper
- [ ] All existing tests pass (no behavior changes)
- [ ] Test coverage maintained or improved
- [ ] Code is more maintainable and readable
- [ ] No functionality regressions
- [ ] flutter analyze passes with no new warnings

## Technical Notes
- **File to refactor:** lib/core/services/recommendation_service.dart
- **Refactoring pattern:** Extract Method (Martin Fowler)
- **Discovered in:** #250 (save button fix work)
- **Related work:** Recommendation engine has been stable, this is pure refactoring
- **Testing approach:** Existing tests should all pass (no behavior change)
- **Benefits:**
  - Single source of truth for protein counting
  - Easier to maintain and update
  - Reduced risk of inconsistency
  - Better testability
- **Caution:** This is a pure refactoring - no functionality changes
- **When to do:** Good candidate for: (1) during next work on recommendation service, or (2) slow development period

## Test Cases

**Regression tests (must pass):**
- All existing recommendation service tests
- Protein rotation scoring works correctly
- Protein diversity calculation works correctly
- Protein balance filtering works correctly
- End-to-end recommendation tests

**New test (if needed):**
- Unit test for `_countProteinsByType()` helper method
  - Test with various recipe lists
  - Test with different protein types
  - Test with empty list
  - Test with recipes having multiple proteins

**Verification:**
- Compare recommendation results before and after refactoring
- Ensure identical behavior in all scenarios
- No performance regression

─────────────────────────────────────────

Ready to create this issue? (y/n/revise)
```

**User:** y

---

### GitHub CLI Commands

```bash
# Create the issue
gh issue create \
  --title "refactor: consolidate duplicate protein counting logic in recommendation service" \
  --body "$(cat <<'EOF'
[Complete markdown from Checkpoint 6 above]
EOF
)"

# This will return an issue number, e.g., #269

# Add labels
gh issue edit 269 --add-label "technical-debt,architecture,P3-Low"

# Add comment to reference discovery context
gh issue comment 269 --body "Discovered while working on #250. This doesn't block #250 but should be addressed for better long-term maintainability."

# Optional: Add to project (can be done during future sprint planning)
gh project item-add 3 --owner alemdisso \
  --url https://github.com/alemdisso/gastrobrain/issues/269
```

---

## Key Takeaways from This Example

1. **Context preserved:** Detected active work on #250 and referenced it
2. **Technical debt classification:** Clearly identified as P3-Low (not urgent)
3. **Specific refactoring:** Named exact methods and proposed clear solution
4. **Pure refactoring emphasized:** Made clear this doesn't change behavior
5. **Test strategy:** Focus on regression tests to ensure no changes
6. **Realistic priority:** P3-Low justified - code quality but not blocking
7. **Timing suggestion:** "When to do" guidance provided
8. **Low estimate:** 2 points for well-defined, single-file refactoring

The checkpoint process captured technical context from active development work and created a well-scoped technical debt issue that can be addressed at an appropriate time.

---

## Additional Context Handling

When creating issues during active work:

**Branch detection:**
```bash
# Detect current branch
git branch --show-current

# Example: feature/250-save-button-fix
# Extract issue number: 250
```

**Issue relationship:**
- **"Discovered during #250"** - Not blocking, but related context
- **"Blocks #250"** - Must fix before completing #250
- **"Related to #250"** - Same component/area

**Priority consideration:**
- If blocks current work: Upgrade to P1-High
- If discovered but not blocking: Keep at natural priority (often P3-Low for tech debt)
- If affects same component: Consider doing together for efficiency
