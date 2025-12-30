<!-- markdownlint-disable -->
# Edge Case Catalog

**Version**: 1.2
**Last Updated**: 2025-12-30
**Issue**: #39 - Edge Case Test Suite
**Milestone**: 0.1.3 - User Features & Critical Foundation

**Progress Update**: Phases 1-5.1 complete (458 tests total)
- Phase 1: Foundation & Catalog ✅
- Phase 2: Empty States & Boundary Conditions ✅ (250 tests)
- Phase 3: Error & Failure Scenarios ✅ (154 tests)
- Phase 4: Interaction & Navigation ✅ (24 tests)
- Phase 5.1: Screen Edge Cases ✅ (30 tests)

## Overview

This document catalogs all identified edge cases, boundary conditions, and error scenarios across the Gastrobrain application. It serves as a comprehensive reference for:

- **Test Planning**: What edge cases need testing
- **Development**: What edge cases to consider when building features
- **Quality Assurance**: Verification checklist for feature completeness
- **Regression Testing**: Known edge cases that have caused issues

---

## How to Use This Catalog

### Priority Levels

Each edge case is marked with a priority level:

- **🔴 CRITICAL**: Must be tested - could cause data loss or app crashes
- **🟠 HIGH**: Should be tested - significant impact on user experience
- **🟡 MEDIUM**: Nice to test - edge cases users may encounter
- **🟢 LOW**: Optional - rare scenarios

### Status Indicators

- ✅ **Tested**: Has automated test coverage
- ⏳ **Planned**: Scheduled for testing
- ❌ **Not Tested**: No coverage yet
- 🐛 **Known Issue**: Bug exists, tracked separately

---

## Edge Case Categories

1. [Empty States](#empty-states)
2. [Boundary Conditions - Numeric](#boundary-conditions---numeric)
3. [Boundary Conditions - Text](#boundary-conditions---text)
4. [Boundary Conditions - Collections](#boundary-conditions---collections)
5. [Error Scenarios](#error-scenarios)
6. [Interaction Patterns](#interaction-patterns)
7. [Data Integrity](#data-integrity)
8. [Performance](#performance)

---

## Empty States

### Recipe Management

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| No recipes in database | 🟠 HIGH | ✅ Tested | `test/edge_cases/empty_states/recipes_empty_state_test.dart` | Shows helpful empty state |
| Search returns no results | 🟡 MEDIUM | ✅ Tested | `test/edge_cases/empty_states/search_empty_state_test.dart` | Clear feedback provided |
| Recipe with no ingredients | 🟠 HIGH | ✅ Tested | `test/edge_cases/boundary_conditions/list_size_boundary_test.dart` | Allowed, 0 ingredients valid |
| Recipe has no instructions | 🟡 MEDIUM | ✅ Tested | Phase 2.3 | Optional field handled |
| Filter returns empty list | 🟡 MEDIUM | ✅ Tested | `test/edge_cases/empty_states/search_empty_state_test.dart` | Shows empty state |

### Ingredient Management

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| No ingredients in database | 🟡 MEDIUM | ✅ Tested | `test/edge_cases/empty_states/ingredients_empty_state_test.dart` | First-time user scenario handled |
| Autocomplete with no matches | 🟡 MEDIUM | ✅ Tested | `test/edge_cases/empty_states/search_empty_state_test.dart` | Clear feedback provided |
| Category has no ingredients | 🟢 LOW | ✅ Tested | Phase 2.1.2 | Valid state |
| Export with no ingredients | 🟢 LOW | ⏳ Planned | Phase 3.3 | Deferred |

### Meal Planning

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| No planned meals in calendar | 🟠 HIGH | ✅ Tested | `test/edge_cases/empty_states/meal_planning_empty_state_test.dart` | Common first-time state |
| Cannot cook meal (no meal planned) | 🔴 CRITICAL | ✅ Tested | Phase 2.1.3 | Prevented with validation |
| Recommendations with no recipes | 🟠 HIGH | ✅ Tested | `test/edge_cases/error_scenarios/recommendation_failures_test.dart` | Graceful degradation |
| Week with no meals | 🟡 MEDIUM | ✅ Tested | `test/edge_cases/empty_states/meal_planning_empty_state_test.dart` | Shows empty calendar |

### Meal History

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Recipe with no cooked meals | 🟡 MEDIUM | ✅ Tested | `test/edge_cases/empty_states/meal_history_empty_state_test.dart` | Shows "never cooked" |
| Date filter returns empty | 🟡 MEDIUM | ✅ Tested | `test/edge_cases/screens/meal_history_screen_edge_cases_test.dart` | Clear date handling |
| No meal history at all | 🟡 MEDIUM | ✅ Tested | `test/edge_cases/empty_states/meal_history_empty_state_test.dart` | New user state handled |
| Statistics with no data | 🟡 MEDIUM | ✅ Tested | Phase 2.1.4 | Prevent divide by zero |

---

## Boundary Conditions - Numeric

### Servings

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Servings = 0 | 🔴 CRITICAL | ⏳ Planned | Phase 2.2.1 | Must reject with validation |
| Servings = 1 (minimum) | 🟠 HIGH | ⏳ Planned | Phase 2.2.1 | Valid edge case |
| Servings = 999 (very high) | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.1 | Should accept |
| Servings negative | 🔴 CRITICAL | ⏳ Planned | Phase 2.2.1 | Must reject |
| Servings decimal (2.5) | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.1 | Should round or accept |
| Servings = 9999+ | 🟢 LOW | ⏳ Planned | Phase 2.2.1 | May need upper limit |

### Times (Prep/Cook)

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Time = 0 | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.2 | Valid for some cases |
| Time negative | 🔴 CRITICAL | ⏳ Planned | Phase 2.2.2 | Must reject |
| Time decimal (15.5 min) | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.2 | Should accept |
| Time = 999+ minutes | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.2 | Long recipes valid |
| Time = 9999 | 🟢 LOW | ⏳ Planned | Phase 2.2.2 | Unrealistic but accept |
| Total time calculation | 🟠 HIGH | ⏳ Planned | Phase 2.2.2 | Prep + cook boundaries |

### Rating

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Rating = 0 (unrated) | 🟠 HIGH | ⏳ Planned | Phase 2.2.3 | Default valid state |
| Rating = 1 (minimum) | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.3 | Valid |
| Rating = 5 (maximum) | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.3 | Valid |
| Rating > 5 | 🔴 CRITICAL | ⏳ Planned | Phase 2.2.3 | Must reject |
| Rating < 0 | 🔴 CRITICAL | ⏳ Planned | Phase 2.2.3 | Must reject |
| Rating in recommendations | 🟠 HIGH | ⏳ Planned | Phase 2.2.3 | Handle unrated recipes |

### Difficulty

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Difficulty = 0 | 🔴 CRITICAL | ⏳ Planned | Phase 2.2.3 | Must reject |
| Difficulty = 1 (minimum) | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.3 | Valid |
| Difficulty = 5 (maximum) | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.3 | Valid |
| Difficulty outside 1-5 | 🔴 CRITICAL | ⏳ Planned | Phase 2.2.3 | Must reject |
| Difficulty in recommendations | 🟠 HIGH | ⏳ Planned | Phase 2.2.3 | Weekday vs weekend |

### Dates

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Date = year 2000 | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.4 | Old meal history |
| Future date for cooked meal | 🔴 CRITICAL | ⏳ Planned | Phase 2.2.4 | Must reject |
| Planned meal in past | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.4 | Should allow |
| Date = year 1900 | 🟢 LOW | ⏳ Planned | Phase 2.2.4 | Unrealistic, handle |
| Date = year 2100 | 🟢 LOW | ⏳ Planned | Phase 2.2.4 | Far future, handle |
| Invalid dates (Feb 30) | 🔴 CRITICAL | ⏳ Planned | Phase 2.2.4 | Must reject |
| Null dates (optional) | 🟡 MEDIUM | ⏳ Planned | Phase 2.2.4 | Handle appropriately |

---

## Boundary Conditions - Text

### Text Length

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Empty recipe name | 🔴 CRITICAL | ⏳ Planned | Phase 2.3.1 | Must reject |
| Single char name | 🟡 MEDIUM | ⏳ Planned | Phase 2.3.1 | Should accept |
| 100+ char name | 🟡 MEDIUM | ⏳ Planned | Phase 2.3.1 | UI should handle |
| 1000+ char name | 🟠 HIGH | ⏳ Planned | Phase 2.3.1 | May need limit |
| Notes 1000+ chars | 🟡 MEDIUM | ⏳ Planned | Phase 2.3.1 | Should accept |
| Notes 10000+ chars | 🟠 HIGH | ⏳ Planned | Phase 2.3.1 | Performance test |
| Instructions extreme length | 🟡 MEDIUM | ⏳ Planned | Phase 2.3.1 | Scrolling needed |
| UI rendering long text | 🟠 HIGH | ⏳ Planned | Phase 2.3.1 | No overflow |

### Special Characters

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| HTML chars (`<>'"&`) | 🔴 CRITICAL | ⏳ Planned | Phase 2.3.2 | Must escape |
| Emoji in name | 🟡 MEDIUM | ⏳ Planned | Phase 2.3.2 | Should support |
| Unicode characters | 🟡 MEDIUM | ⏳ Planned | Phase 2.3.2 | Crème, jalapeño |
| Markdown-like syntax | 🟢 LOW | ⏳ Planned | Phase 2.3.2 | Plain text handling |
| Newlines in notes | 🟡 MEDIUM | ⏳ Planned | Phase 2.3.2 | Should preserve |
| SQL injection patterns | 🔴 CRITICAL | ⏳ Planned | Phase 2.3.2 | Must be safe |
| XSS patterns | 🔴 CRITICAL | ⏳ Planned | Phase 2.3.2 | Must escape |

### Whitespace

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Name only whitespace | 🔴 CRITICAL | ⏳ Planned | Phase 2.3.3 | Must reject |
| Leading/trailing spaces | 🟡 MEDIUM | ⏳ Planned | Phase 2.3.3 | Should trim |
| Multiple consecutive spaces | 🟢 LOW | ⏳ Planned | Phase 2.3.3 | Normalize or allow |
| Empty string vs null | 🟠 HIGH | ⏳ Planned | Phase 2.3.3 | Consistent handling |
| Tabs in text | 🟢 LOW | ⏳ Planned | Phase 2.3.3 | Should handle |

---

## Boundary Conditions - Collections

### List Sizes

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Recipe with 0 ingredients | 🟠 HIGH | ⏳ Planned | Phase 2.4.1 | Warn but allow |
| Recipe with 1 ingredient | 🟡 MEDIUM | ⏳ Planned | Phase 2.4.1 | Valid |
| Recipe with 100+ ingredients | 🟡 MEDIUM | ⏳ Planned | Phase 2.4.1 | UI performance |
| Meal with 0 recipes | 🔴 CRITICAL | ⏳ Planned | Phase 2.4.1 | Must reject |
| Meal with 1 recipe | 🟡 MEDIUM | ⏳ Planned | Phase 2.4.1 | Valid |
| Meal with 10+ side dishes | 🟡 MEDIUM | ⏳ Planned | Phase 2.4.1 | Should support |
| 1000+ recipes in database | 🟠 HIGH | ⏳ Planned | Phase 2.4.1 | Performance critical |
| UI with very long lists | 🟠 HIGH | ⏳ Planned | Phase 2.4.1 | Scrolling smooth |

### Duplicates & Constraints

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Duplicate recipe names | 🟡 MEDIUM | ⏳ Planned | Phase 2.4.2 | Should allow |
| Duplicate ingredient names | 🟡 MEDIUM | ⏳ Planned | Phase 2.4.2 | Different categories OK |
| Same ingredient twice in recipe | 🟡 MEDIUM | ⏳ Planned | Phase 2.4.2 | Should prevent or merge |
| Same side dish multiple times | 🟡 MEDIUM | ⏳ Planned | Phase 2.4.2 | Should allow (portions) |
| Meal in same slot twice | 🔴 CRITICAL | ⏳ Planned | Phase 2.4.2 | Conflict resolution |

---

## Error Scenarios

### Database Errors

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Database not initialized | 🔴 CRITICAL | ⏳ Planned | Phase 3.1.1 | App launch failure |
| Database locked | 🔴 CRITICAL | ⏳ Planned | Phase 3.1.1 | Concurrent access |
| Database corrupted | 🔴 CRITICAL | ⏳ Planned | Phase 3.1.1 | Recovery path needed |
| Migration failure | 🔴 CRITICAL | ⏳ Planned | Phase 3.1.1 | Rollback strategy |
| Insufficient permissions | 🔴 CRITICAL | ⏳ Planned | Phase 3.1.1 | File access error |
| Insert failure | 🟠 HIGH | ⏳ Planned | Phase 3.1.2 | Transaction rollback |
| Update failure | 🟠 HIGH | ⏳ Planned | Phase 3.1.2 | No partial updates |
| Delete failure | 🟠 HIGH | ⏳ Planned | Phase 3.1.2 | Maintain consistency |
| Query timeout | 🟠 HIGH | ⏳ Planned | Phase 3.1.2 | Loading state |
| Constraint violation | 🟠 HIGH | ⏳ Planned | Phase 3.1.2 | Helpful error |
| Foreign key violation | 🟠 HIGH | ⏳ Planned | Phase 3.1.2 | Explain dependencies |

### Concurrent Modifications

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Recipe updated while editing | 🟠 HIGH | ⏳ Planned | Phase 3.1.3 | Last-write-wins |
| Recipe deleted while editing | 🟠 HIGH | ⏳ Planned | Phase 3.1.3 | Graceful error |
| Meal slot conflict | 🟠 HIGH | ⏳ Planned | Phase 3.1.3 | Conflict resolution |
| Ingredient updated mid-add | 🟡 MEDIUM | ⏳ Planned | Phase 3.1.3 | Refresh data |

### Validation Errors

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Invalid recipe data | 🔴 CRITICAL | ⏳ Planned | Phase 3.2.1 | Prevent save |
| Invalid meal data | 🔴 CRITICAL | ⏳ Planned | Phase 3.2.1 | Prevent save |
| Invalid ingredient data | 🔴 CRITICAL | ⏳ Planned | Phase 3.2.1 | Prevent save |
| Multiple validation errors | 🟠 HIGH | ⏳ Planned | Phase 3.2.1 | Show all at once |
| Field-level validation | 🟡 MEDIUM | ⏳ Planned | Phase 3.2.1 | Immediate feedback |

### Business Rule Violations

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Cook meal without recipe | 🔴 CRITICAL | ⏳ Planned | Phase 3.2.2 | Must prevent |
| Meal with only side dishes | 🟠 HIGH | ⏳ Planned | Phase 3.2.2 | Require primary |
| Invalid frequency type | 🟡 MEDIUM | ⏳ Planned | Phase 3.2.2 | Validate enum |
| Protein rotation violation | 🟡 MEDIUM | ⏳ Planned | Phase 3.2.2 | Recommendation logic |

### Service Layer Errors

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Recommendations with no recipes | 🟠 HIGH | ⏳ Planned | Phase 3.3.1 | Empty state |
| All recipes filtered out | 🟡 MEDIUM | ⏳ Planned | Phase 3.3.1 | Relax constraints |
| Recommendation calc error | 🟠 HIGH | ⏳ Planned | Phase 3.3.1 | Fallback algorithm |
| Cache corruption | 🟡 MEDIUM | ⏳ Planned | Phase 3.3.1 | Invalidate/rebuild |
| Parser malformed input | 🟠 HIGH | ⏳ Planned | Phase 3.3.2 | Helpful error message |
| Import invalid format | 🟠 HIGH | ⏳ Planned | Phase 3.3.2 | Format validation |
| Export failure | 🟡 MEDIUM | ⏳ Planned | Phase 3.3.3 | File system error |

---

## Interaction Patterns

### Rapid Interactions

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Save button rapid taps | 🔴 CRITICAL | ⏳ Planned | Phase 4.1.1 | Debounce required |
| Delete confirmation rapid taps | 🟠 HIGH | ⏳ Planned | Phase 4.1.1 | Single action |
| Navigation rapid taps | 🟡 MEDIUM | ⏳ Planned | Phase 4.1.1 | Route protection |
| Dialog open rapid taps | 🟠 HIGH | ⏳ Planned | Phase 4.1.1 | Single dialog |
| Rating rapid changes | 🟢 LOW | ⏳ Planned | Phase 4.1.1 | Last value wins |

### Concurrent Actions

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Multiple dialogs open | 🟠 HIGH | ⏳ Planned | Phase 4.1.2 | Prevent or stack |
| Navigate during async save | 🔴 CRITICAL | ⏳ Planned | Phase 4.1.2 | Complete or cancel |
| Back button during loading | 🟠 HIGH | ⏳ Planned | Phase 4.1.2 | Cancel operation |
| App backgrounded mid-operation | 🟠 HIGH | ⏳ Planned | Phase 4.1.2 | State preservation |
| Orientation change mid-form | 🟡 MEDIUM | ⏳ Planned | Phase 4.1.2 | Preserve data |

### Cancellation

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Cancel during save | 🔴 CRITICAL | ✅ Tested | Dialog tests | No side effects |
| Cancel during import | 🟠 HIGH | ⏳ Planned | Phase 4.1.3 | Cleanup temp data |
| Back button mid-recommendation | 🟡 MEDIUM | ⏳ Planned | Phase 4.1.3 | Cancel calc |
| Cancel during export | 🟢 LOW | ⏳ Planned | Phase 4.1.3 | Cleanup partial file |

### Navigation

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Deep navigation stack (10+ screens) | 🟡 MEDIUM | ⏳ Planned | Phase 4.2.1 | Memory usage |
| Navigate to deleted item | 🟠 HIGH | ⏳ Planned | Phase 4.2.1 | 404 handling |
| Invalid route parameters | 🟠 HIGH | ⏳ Planned | Phase 4.2.1 | Error page |
| Return after long time (stale data) | 🟡 MEDIUM | ⏳ Planned | Phase 4.2.1 | Refresh data |

### State Preservation

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Form data on orientation change | 🟠 HIGH | ⏳ Planned | Phase 4.2.2 | Preserve input |
| Form data on app background | 🟠 HIGH | ⏳ Planned | Phase 4.2.2 | Save temp state |
| Search query on navigation | 🟡 MEDIUM | ⏳ Planned | Phase 4.2.2 | Optional preserve |
| Scroll position on back | 🟢 LOW | ⏳ Planned | Phase 4.2.2 | UX improvement |

---

## Data Integrity

### Orphaned Records

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Meal with deleted recipe | 🔴 CRITICAL | ⏳ Planned | Phase 5.1.1 | Cascade delete or error |
| Recipe ingredient with deleted ingredient | 🟠 HIGH | ⏳ Planned | Phase 3.4.2 | Foreign key handling |
| Meal plan with deleted meal | 🟠 HIGH | ⏳ Planned | Phase 3.4.2 | Consistency check |

### Missing Data

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Missing foreign keys | 🔴 CRITICAL | ⏳ Planned | Phase 3.4.2 | Database integrity |
| Missing required fields | 🔴 CRITICAL | ⏳ Planned | Phase 3.2.1 | Validation |
| Null where not expected | 🟠 HIGH | ⏳ Planned | Phase 3.4.2 | Null safety |

### Stale Data

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Displaying stale data after update | 🟡 MEDIUM | ⏳ Planned | Phase 3.3.1 | Cache invalidation |
| Concurrent modifications conflict | 🟠 HIGH | ✅ Tested | concurrent_modification_test.dart | Last-write-wins behavior |

---

## Performance

### Large Datasets

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| 1000+ recipes | 🟠 HIGH | ⏳ Planned | Phase 5.5.1 | < 2s load time |
| 100+ meal history items | 🟡 MEDIUM | ⏳ Planned | Phase 5.1.1 | Pagination may help |
| Recommendation with 1000 recipes | 🟠 HIGH | ⏳ Planned | Phase 5.5.1 | < 2s calc time |
| Search in large dataset | 🟡 MEDIUM | ⏳ Planned | Phase 5.5.1 | Indexed queries |

### UI Performance

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| List scrolling (100+ items) | 🟠 HIGH | ⏳ Planned | Phase 5.5.1 | Smooth scrolling |
| Long text rendering | 🟡 MEDIUM | ⏳ Planned | Phase 2.3.1 | No jank |
| Complex layouts | 🟡 MEDIUM | ⏳ Planned | Phase 4.3.1 | 60fps target |

### Device Conditions

| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Low memory | 🟠 HIGH | ⏳ Planned | Phase 4.3.1 | Graceful degradation |
| Orientation changes | 🟡 MEDIUM | ⏳ Planned | Phase 4.3.2 | Layout adapts |
| Small screens | 🟡 MEDIUM | 🐛 Known Issue | Issue #246 | Dialog overflow |
| Large screens (tablets) | 🟢 LOW | ⏳ Planned | Phase 4.3.2 | Responsive layout |

---

## Known Issues & Regression Tests

### Controller Disposal Crash (commit 07058a2)

**Priority**: 🔴 CRITICAL
**Status**: ✅ Fixed & Tested
**Test Location**: Dialog regression tests

**Issue**: Dialog cancellation caused crash when disposing controller still in use.

**Fix**:
```dart
if (mounted) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
}
```

**Tests Required**:
- ✅ All 6 dialogs safely dispose controllers on cancellation
- ✅ Rapid dialog open/close cycles
- ✅ Back button, outside tap, and explicit cancel
- ⏳ Verify pattern used app-wide (Phase 3.4)

### Dialog Overflow on Small Screens (Issue #246)

**Priority**: 🟡 MEDIUM
**Status**: 🐛 Known Issue
**Test Location**: Deferred to Issue #246

**Issue**: Some dialogs overflow on small screen sizes.

**Tests Needed**:
- ⏳ Test all dialogs on minimum screen size
- ⏳ Verify scrollable content
- ⏳ Verify proper constraints

---

## Adding New Edge Cases

When you discover a new edge case:

1. **Add to this catalog** in the appropriate category
2. **Set priority** (🔴 CRITICAL, 🟠 HIGH, 🟡 MEDIUM, 🟢 LOW)
3. **Create test** following patterns in `docs/EDGE_CASE_TESTING_GUIDE.md`
4. **Update status** to ✅ Tested when complete
5. **Link regression tests** if it was a bug

---

## Statistics

**Total Edge Cases Cataloged**: ~150+
**Critical Priority**: ~25
**High Priority**: ~40
**Medium Priority**: ~55
**Low Priority**: ~30

**Coverage Status**:
- ✅ Tested: 6 (dialog cancellation)
- ⏳ Planned: 140+
- ❌ Not Tested: 0
- 🐛 Known Issues: 2

---

**Next Update**: After Phase 2 completion
**Maintained By**: Issue #39 implementation team
**Questions?**: Refer to `docs/EDGE_CASE_TESTING_GUIDE.md`
