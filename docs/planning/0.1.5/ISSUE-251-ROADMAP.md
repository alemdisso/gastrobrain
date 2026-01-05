# Issue #251: Improve Visual Hierarchy in AddSideDishDialog

**Issue:** [#251](https://github.com/alemdisso/gastrobrain/issues/251)
**Type:** UI Enhancement
**Priority:** P2 - Medium
**Estimate:** S = 2 points (~3-4 hours)
**Status:** Planning

---

## Overview

Improve the visual hierarchy and section separation in the "Manage Side Dishes" dialog to reduce user confusion and improve usability.

**Current Problems:**
- Poor visual hierarchy between sections
- Unclear boundaries between selected side dishes and available recipes
- Search field gets pushed down when many side dishes selected
- Scrollable areas not obvious to users
- Users confused about what to scroll and where

**Goal:** Clear visual separation with fixed search header and distinct sections.

---

## Current Structure Analysis

**File:** `lib/widgets/add_side_dish_dialog.dart` (310 lines)

**Current layout:**
```
┌─────────────────────────────────┐
│  Dialog Title                   │
├─────────────────────────────────┤
│  [Primary Recipe Section]       │  ← Scrolls with content
│  [Selected Side Dishes]         │  ← Scrolls with content
│  "Add Side Dish" label          │  ← Scrolls with content
│  [Search Field]                 │  ← Scrolls with content (PROBLEM)
│  ─────────────────────────────  │
│  [Available Recipes List]       │  ← Separate scroll
└─────────────────────────────────┘
│  [Back] [Save Meal]             │
└─────────────────────────────────┘
```

**Problems with current layout:**
- Search field scrolls away when many side dishes selected
- No clear visual boundaries between sections
- Single ScrollView mixes fixed and scrollable content

---

## Proposed Structure

**New layout:**
```
┌─────────────────────────────────┐
│  Dialog Title                   │
├─────────────────────────────────┤
│  [Search Field]                 │  ← FIXED (always visible)
├─────────────────────────────────┤
│  ┌─────────────────────────┐    │
│  │ Primary: [Recipe Name]  │    │  ← Visually distinct card
│  │ ─────────────────────── │    │
│  │ Side Dishes:            │    │
│  │ • Side 1         [x]    │    │  ← Scrollable if many
│  │ • Side 2         [x]    │    │
│  └─────────────────────────┘    │
├─────────────────────────────────┤
│  Add Side Dish                  │  ← Section header
│  ─────────────────────────────  │  ← Visual divider
│  [Recipe 1]                     │
│  [Recipe 2]                     │  ← Scrollable list
│  [Recipe 3]                     │
│  ...                            │
└─────────────────────────────────┘
│  [Back] [Save Meal]             │
└─────────────────────────────────┘
```

**Key improvements:**
1. Search field FIXED at top
2. Selected dishes in visually distinct container (Card)
3. Clear divider before available recipes
4. Each section has clear boundaries

---

## Prerequisites

- None - independent work item

## Dependencies

- **Blocked by:** None
- **Related to:** None (pure UI work)

---

## Implementation Phases

### Phase 1: Plan Layout Changes

**Objective:** Design the exact layout structure before coding

**Tasks:**
- [ ] Review current `build()` method structure
- [ ] Sketch new widget tree on paper/whiteboard
- [ ] Decide on visual styling:
  - Card vs background color for selected dishes
  - Divider style (Divider widget vs border)
  - Scroll indicator approach
- [ ] Identify any needed new widgets

**Design decisions to make:**
1. **Selected dishes container:** Card or colored Container?
   - Recommendation: Card for clear elevation/separation
2. **Divider style:** Divider widget or Container with border?
   - Recommendation: Divider widget (standard Flutter)
3. **Search field positioning:** In title area or content?
   - Recommendation: In content but FIXED (not in scroll)

**Estimated time:** 30 minutes

---

### Phase 2: Restructure Layout

**Objective:** Implement the new layout structure

**Current build() method structure:**
```dart
AlertDialog(
  title: Text(dialogTitle),
  content: SizedBox(
    child: Column(
      children: [
        Flexible(
          child: SingleChildScrollView(  // ← Problem: search scrolls
            child: Column([
              _buildPrimaryRecipeSection(),
              _buildCurrentSideDishesSection(),
              Text('Add Side Dish'),
              TextField(),  // Search - should be fixed!
            ]),
          ),
        ),
        Expanded(
          child: ListView.builder(),  // Available recipes
        ),
      ],
    ),
  ),
)
```

**New structure:**
```dart
AlertDialog(
  title: Text(dialogTitle),
  content: SizedBox(
    child: Column(
      children: [
        // FIXED: Search field (always visible)
        TextField(),
        const SizedBox(height: 8),

        // SCROLLABLE: Selected dishes section
        if (isMultiRecipeMode && (_currentSideDishes.isNotEmpty || widget.primaryRecipe != null))
          _buildSelectedDishesCard(),

        // DIVIDER
        const Divider(),
        Text('Add Side Dish'),  // Section header

        // SCROLLABLE: Available recipes
        Expanded(
          child: ListView.builder(),
        ),
      ],
    ),
  ),
)
```

**Tasks:**
- [ ] Move search TextField to top of Column (outside ScrollView)
- [ ] Create new `_buildSelectedDishesCard()` method
- [ ] Wrap primary recipe + side dishes in Card widget
- [ ] Add Divider before available recipes section
- [ ] Ensure proper flex/sizing for scrollable areas

**Estimated time:** 1-1.5 hours

---

### Phase 3: Style the Selected Dishes Section

**Objective:** Create visually distinct container for selected dishes

**New method:**
```dart
Widget _buildSelectedDishesCard() {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary recipe
          if (widget.primaryRecipe != null) ...[
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.primaryRecipe!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(label: Text(AppLocalizations.of(context)!.mainDish)),
              ],
            ),
          ],

          // Divider if both primary and sides exist
          if (widget.primaryRecipe != null && _currentSideDishes.isNotEmpty)
            const Divider(),

          // Side dishes
          if (_currentSideDishes.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.sideDishesLabel,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            // Constrain height if many dishes
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView(
                shrinkWrap: true,
                children: _currentSideDishes.map((recipe) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.restaurant_menu, size: 18),
                  title: Text(recipe.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeSideDish(recipe),
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
```

**Tasks:**
- [ ] Implement `_buildSelectedDishesCard()` method
- [ ] Use Card widget for elevation and clear boundaries
- [ ] Add constraints to prevent section from growing too large
- [ ] Style remove buttons consistently
- [ ] Test with 0, 1, 3, 5+ side dishes

**Estimated time:** 45 minutes

---

### Phase 4: Update Existing Tests

**Objective:** Ensure tests still pass with new structure

**Tasks:**
- [ ] Run existing tests: `flutter test test/widgets/add_side_dish_dialog_test.dart`
- [ ] Update any tests that depend on widget structure
- [ ] Verify key interactions still work:
  - Search filtering
  - Adding side dish
  - Removing side dish
  - Save/Cancel actions

**Expected changes:**
- Widget tree structure changed - some `find.byType()` may need updates
- Search field key should remain the same
- ListTile structure should remain similar

**Estimated time:** 30 minutes

---

### Phase 5: Visual Testing & Polish

**Objective:** Verify visual improvements and polish

**Tasks:**
- [ ] Manual visual testing (if possible in local env)
- [ ] Test with various states:
  - No side dishes selected
  - 1 side dish selected
  - 5+ side dishes selected
  - Empty available recipes list
  - Search with results
  - Search with no results
- [ ] Verify search field stays visible in all states
- [ ] Verify scrolling behavior is intuitive
- [ ] Run `flutter analyze`

**Polish items:**
- [ ] Consistent spacing throughout
- [ ] Proper text truncation for long names
- [ ] Accessible touch targets (48dp minimum)
- [ ] Correct color scheme usage

**Estimated time:** 30 minutes

---

### Phase 6: Final Verification

**Objective:** Confirm all requirements met

**Tasks:**
- [ ] Run full test suite: `flutter test`
- [ ] Run analysis: `flutter analyze`
- [ ] Review against issue requirements:
  - [ ] Clear visual hierarchy
  - [ ] Fixed search field (always visible)
  - [ ] Selected dishes in distinct container
  - [ ] Clear dividers between sections
  - [ ] Scrollable areas obvious

**Estimated time:** 15 minutes

---

## Deliverables Checklist

- [ ] Search field fixed at top (never scrolls away)
- [ ] Selected dishes in Card container
- [ ] Clear visual divider before available recipes
- [ ] Proper scrolling for each section
- [ ] All existing tests pass
- [ ] No analysis issues
- [ ] Visual hierarchy significantly improved

---

## Risk Assessment

**Low Risk:**
- UI-only changes, no data model changes
- Existing tests provide safety net
- Widget is self-contained (no external dependencies)

**Potential Issues:**
- Layout might overflow on very small screens
- Card styling might clash with app theme

**Mitigations:**
- Test with constrained sizes
- Use theme colors consistently
- Add overflow handling where needed

---

## Success Criteria

- [ ] Users can clearly distinguish selected vs available dishes
- [ ] Search field always visible
- [ ] Scrolling behavior is intuitive
- [ ] All existing tests pass
- [ ] No visual regressions

---

## Reference

- Current widget: `lib/widgets/add_side_dish_dialog.dart`
- Tests: `test/widgets/add_side_dish_dialog_test.dart`
- Flutter Card: https://api.flutter.dev/flutter/material/Card-class.html
- Flutter Divider: https://api.flutter.dev/flutter/material/Divider-class.html

---

## Notes

- Focus on structure first, polish second
- Keep changes focused - don't refactor unrelated code
- Design decisions (Card vs background color) can be refined during implementation
- Consider accessibility (contrast, touch targets)
