# Issue #258: Polish Weekly Meal Planning Screen - Analysis

**Status:** In Progress - Analysis Phase
**Created:** 2026-01-30
**Branch:** `feature/258-polish-weekly-meal-planning-screen`
**Issue:** [#258 - Polish Weekly Meal Planning Screen UI](https://github.com/alemdisso/gastrobrain/issues/258)

---

## Executive Summary

Issue #258 requires polishing the weekly meal planning screen, which is the **primary interface** of Gastrobrain. Initial analysis reveals this is a **dual-scope issue** requiring both:

1. **Visual Polish** - Apply design tokens from #255-#257
2. **Structural Refactoring** - Address file size and code organization issues

**Key Finding:** `weekly_plan_screen.dart` is **2,370 lines** - well beyond the 300-400 line refactoring threshold defined in the gastrobrain-refactoring skill.

---

## Code Structure Analysis

### File Complexity

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| `lib/screens/weekly_plan_screen.dart` | 2,370 | 🔴 Critical | Far exceeds 300-400 line threshold |
| `lib/widgets/weekly_calendar_widget.dart` | ~500+ | 🟡 Warning | Approaching threshold |
| Related dialogs & widgets | Various | ✅ OK | Multiple supporting components |

### Code Smells Identified (Refactoring Lens)

**1. God Class Pattern**
- `WeeklyPlanScreen` handles too many responsibilities:
  - Meal plan management
  - Navigation & week selection
  - Recommendation fetching & caching
  - Dialog coordination
  - Summary data calculation
  - Shopping list generation
  - Context color/styling logic
  - Recipe selection
  - Meal recording orchestration

**2. Long Methods**
- `_handleMarkAsCooked()` - Lines 714-843 (129 lines)
- `_handleAddSideDish()` - Lines 845-971 (126 lines)
- `_handleEditCookedMeal()` - Lines 973-1093 (120 lines)
- `_buildSummaryView()` - Complex rendering logic
- `_calculateSummaryData()` - Lines 1330-1448 (118 lines)

**3. Code Duplication**
- Meal lookup logic repeated across handlers
- Recipe fetching patterns duplicated
- Context color logic scattered (lines 184-229)
- Similar dialog patterns across meal actions

**4. Feature Envy**
- Heavy database access throughout (should be in services)
- Direct `_dbHelper` usage instead of service layer
- Recommendation logic mixed with UI

**5. Magic Numbers & Hardcoded Values**
- Numerous hardcoded colors (see Visual Issues section)
- Hardcoded spacing values
- Magic numbers in calculations

---

## Visual Issues Analysis (UI Polish Lens)

### Hardcoded Colors

#### WeeklyPlanScreen (`lib/screens/weekly_plan_screen.dart`)

**Context Indicators (Lines 184-229):**
```dart
// Line 187-193
Color _getContextColor() {
  switch (_currentWeekContext) {
    case TimeContext.past:
      return Colors.grey.withAlpha(51);  // ❌ Hardcoded
    case TimeContext.current:
      return Theme.of(context).colorScheme.primaryContainer.withAlpha(128);  // ⚠️ Partial
    case TimeContext.future:
      return Theme.of(context).colorScheme.primary.withAlpha(76);  // ⚠️ Partial
  }
}

// Line 196-205
Color _getContextBorderColor() {
  // Similar hardcoded color patterns
  return Colors.grey.withAlpha(128);  // ❌ Hardcoded
}

// Line 208-217
Color _getContextTextColor() {
  case TimeContext.past:
    return Colors.grey[700] ?? Colors.grey;  // ❌ Hardcoded
  // ...
}
```

**Summary View (Lines 1522-1720):**
```dart
// Line 1524: Icon color
color: Color(0xFF6B8E23),  // ❌ Hardcoded "olive" color

// Line 1533: Text color
color: Color(0xFF2C2C2C),  // ❌ Hardcoded "charcoal" color

// Line 1594: Accent color
color: Color(0xFF6B8E23),  // ❌ Hardcoded (repeated)

// Line 1719: Decorative line
color: const Color(0xFFD4755F), // ❌ Hardcoded "terracotta"

// Line 1712: Another charcoal
color: Color(0xFF2C2C2C),  // ❌ Hardcoded (repeated)
```

#### WeeklyCalendarWidget (`lib/widgets/weekly_calendar_widget.dart`)

**Context Styling (Lines 223-247):**
```dart
// Line 226-234
Color _getContextBackgroundColor(BuildContext context) {
  switch (widget.timeContext) {
    case TimeContext.past:
      return Colors.grey.withAlpha(25);  // ❌ Hardcoded
    case TimeContext.current:
      return Colors.transparent;  // ✅ OK
    case TimeContext.future:
      return Theme.of(context).colorScheme.primary.withAlpha(15);  // ⚠️ Partial
  }
}

// Line 238-246
Color _getContextBorderColor(BuildContext context) {
  // Similar patterns with hardcoded Colors.grey.withAlpha()
}
```

### Hardcoded Typography

**Font Sizes:**
- Line 1530: `fontSize: 16` - Should use `DesignTokens.bodyLargeSize`
- Line 1564: `fontSize: 16` - Should use textTheme
- Line 1592: `fontSize: 14` - Should use `DesignTokens.bodySize`
- Line 1680: `fontSize: 14` - Multiple instances
- Line 1711: `fontSize: 18` - Should use `DesignTokens.heading3Size`

**Font Weights:**
- Line 1532: `fontWeight: FontWeight.w600` - Should use `DesignTokens.weightSemibold`
- Line 1566: `fontWeight: FontWeight.w600` - Repeated
- Line 1594: `fontWeight: FontWeight.w500` - Should use `DesignTokens.weightMedium`

### Hardcoded Spacing

**Padding Values:**
- Line 1498: `padding: const EdgeInsets.all(16)` - Should use `DesignTokens.spacingMd`
- Line 1503: `const SizedBox(height: 20)` - Non-standard value
- Line 1506: `const SizedBox(height: 24)` - Should use `DesignTokens.spacingLg`
- Various `padding`, `EdgeInsets`, `SizedBox` with hardcoded values throughout

---

## Architectural Issues

### Missing Service Layer Abstractions

**Current:** Screen directly accesses `DatabaseHelper`
```dart
final recipe = await _dbHelper.getRecipe(recipeId);
final meals = await _dbHelper.getMealsForRecipe(recipeId);
```

**Should be:** Screen calls service, service handles database
```dart
final recipe = await _recipeService.getRecipe(recipeId);
final meals = await _mealHistoryService.getMealsForRecipe(recipeId);
```

### Violation of Single Responsibility Principle

The `WeeklyPlanScreen` class is responsible for:
1. UI rendering & layout
2. Data fetching & caching
3. Business logic (meal planning rules)
4. Navigation coordination
5. Dialog management
6. Summary calculations
7. Shopping list generation
8. Recommendation management

**Each of these should be separate concerns.**

---

## Refactoring Opportunities

### High-Priority Refactorings

**1. Extract MealPlanService**
- Move meal plan CRUD operations
- Handle caching logic
- Manage meal planning business rules
- **Impact:** Reduces screen by ~300-400 lines

**2. Extract SummaryCalculationService**
- Move `_calculateSummaryData()` logic
- Handle protein sequence analysis
- Calculate variety metrics
- **Impact:** Reduces screen by ~150-200 lines

**3. Extract WeekNavigationWidget**
- Move week navigation UI & logic
- Handle context indicators
- Manage relative time display
- **Impact:** Reduces screen by ~100-150 lines

**4. Extract MealActionHandler Service**
- Consolidate `_handleMarkAsCooked`, `_handleAddSideDish`, `_handleEditCookedMeal`
- Remove duplication in meal lookup patterns
- **Impact:** Reduces screen by ~400-500 lines

**5. Consolidate Context Color Logic**
- Create `TimeContextTheme` helper class
- Use design tokens instead of hardcoded colors
- **Impact:** Improves maintainability, reduces duplication

### Medium-Priority Refactorings

**6. Extract RecipeSelectionDialog to Separate File**
- Currently embedded in screen file (lines 1950-2369)
- Should be standalone widget
- **Impact:** Reduces screen by ~400 lines

**7. Create Recommendation Caching Service**
- Extract `_recommendationCache` logic
- Handle cache invalidation strategy
- **Impact:** Better separation of concerns

### Low-Priority (Can Defer)

**8. Extract Summary View Widgets**
- Break down `_buildSummaryView()` into smaller widgets
- Create reusable summary components

---

## Recommended Approach

### Option A: Refactor-First Strategy (Recommended)

**Rationale:** Refactoring before polish makes visual changes easier and cleaner.

**Phase 1: Structural Cleanup (Separate Issue/Branch)**
1. Extract services (MealPlanService, SummaryCalculationService, MealActionHandler)
2. Extract large widgets to separate files (RecipeSelectionDialog, WeekNavigationWidget)
3. Consolidate duplicated logic
4. Run all tests, ensure passing
5. **Result:** Screen reduced from 2,370 to ~800-1,000 lines

**Phase 2: Visual Polish (Issue #258)**
1. Apply design tokens to remaining screen code
2. Polish extracted widgets with consistent styling
3. Update WeeklyCalendarWidget with design tokens
4. Test visual consistency across all components

**Estimated Effort:**
- Phase 1: 4-6 hours
- Phase 2: 2-3 hours
- **Total:** 6-9 hours

### Option B: Incremental Polish Strategy

**Rationale:** Quick wins first, defer refactoring.

**Phase 1: High-Impact Visual Polish**
1. Replace hardcoded colors with design tokens (context indicators, summary view)
2. Apply typography tokens to headings and body text
3. Standardize spacing using spacing scale
4. **Result:** Visual consistency without structural changes

**Phase 2: Refactoring (Separate Issue)**
1. File still 2,370 lines (technical debt remains)
2. Create follow-up issue for structural refactoring
3. Address when time permits

**Estimated Effort:**
- Phase 1: 3-4 hours
- Phase 2: Deferred to future issue

**Trade-off:** Faster completion but leaves structural debt.

### Option C: Hybrid Approach

**Phase 1: Extract RecipeSelectionDialog (Quick Win)**
1. Move embedded dialog to separate file
2. Reduces screen by ~400 lines immediately
3. Low risk, high impact
4. **Result:** Screen becomes more manageable (~1,970 lines)

**Phase 2: Visual Polish**
1. Apply design tokens to screen and dialog
2. Update WeeklyCalendarWidget styling
3. Ensure consistency

**Phase 3: Defer Remaining Refactoring**
1. Create follow-up issue for service extraction
2. Address when prioritized

**Estimated Effort:**
- Phase 1: 1 hour
- Phase 2: 2-3 hours
- **Total:** 3-4 hours

---

## Design Token Application Plan

Once structural approach is decided, apply tokens systematically:

### Color Replacements

| Current | Replacement | Location |
|---------|-------------|----------|
| `Colors.grey.withAlpha(51)` | `DesignTokens.disabled.withAlpha(76)` | Context colors |
| `Colors.grey[700]` | `DesignTokens.textSecondary` | Text colors |
| `Color(0xFF6B8E23)` | `DesignTokens.accent` or custom token | Summary icons |
| `Color(0xFF2C2C2C)` | `DesignTokens.textPrimary` | Headings |
| `Color(0xFFD4755F)` | `DesignTokens.primary` or custom | Decorative elements |

### Typography Replacements

| Current | Replacement |
|---------|-------------|
| `fontSize: 16, fontWeight: FontWeight.w600` | `Theme.of(context).textTheme.titleMedium` |
| `fontSize: 14, fontWeight: FontWeight.w500` | `Theme.of(context).textTheme.bodyLarge` |
| `fontSize: 18, fontWeight: FontWeight.bold` | `Theme.of(context).textTheme.headlineSmall` |

### Spacing Replacements

| Current | Replacement |
|---------|-------------|
| `EdgeInsets.all(16)` | `EdgeInsets.all(DesignTokens.spacingMd)` |
| `SizedBox(height: 20)` | `SizedBox(height: DesignTokens.spacingLg)` or `spacingMd` |
| `SizedBox(height: 24)` | `SizedBox(height: DesignTokens.spacingLg)` |

---

## Testing Strategy

### Pre-Refactoring
- ✅ All 1623 tests currently passing
- Document baseline visual appearance (screenshots if needed)

### During Refactoring
- Run `flutter test` after each extraction
- Run `flutter analyze` to catch issues
- Verify no behavioral changes

### Post-Polish
- Verify all tests still passing
- Visual inspection on different screen sizes
- Test with Portuguese locale (longer text)
- Verify touch targets remain ≥44px

---

## Decision Required

**Which approach should we take?**

1. **Option A (Recommended):** Refactor structure first, then polish
   - Cleanest result
   - Most work upfront
   - Better long-term maintainability

2. **Option B:** Polish now, refactor later
   - Quick completion
   - Technical debt remains
   - Harder to maintain going forward

3. **Option C:** Hybrid - extract dialog, polish, defer services
   - Balanced approach
   - Moderate effort
   - Some structural improvement

**Recommendation:** Option A with checkpoint-driven approach from refactoring skill.

---

## Files to Modify (Regardless of Approach)

### Visual Polish Changes
- `lib/screens/weekly_plan_screen.dart` - Apply design tokens
- `lib/widgets/weekly_calendar_widget.dart` - Apply design tokens
- `lib/widgets/recipe_selection_card.dart` - Likely needs token application
- Potentially others discovered during implementation

### Refactoring Changes (If Option A)
- Create `lib/core/services/meal_plan_service.dart`
- Create `lib/core/services/summary_calculation_service.dart`
- Create `lib/core/services/meal_action_handler.dart`
- Create `lib/widgets/week_navigation_widget.dart`
- Extract `lib/widgets/recipe_selection_dialog.dart`
- Update tests for new services

---

## Next Steps

1. **User Decision:** Choose approach (A, B, or C)
2. **Create Roadmap:** Detailed task breakdown based on chosen approach
3. **Implementation:** Execute with checkpoints
4. **Testing:** Verify at each checkpoint
5. **Documentation:** Update patterns as needed

---

**Session Status:** Paused - Awaiting decision on approach
**Prepared By:** Claude Sonnet 4.5
**Date:** 2026-01-30
