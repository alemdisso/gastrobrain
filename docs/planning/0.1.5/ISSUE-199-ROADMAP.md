# Issue #199: Add Meal Type Selection When Recording Cooked Meals

**Issue:** [#199](https://github.com/alemdisso/gastrobrain/issues/199)
**Type:** Feature
**Priority:** P2 - Medium
**Estimate:** M = 3 points (~6-8 hours)
**Status:** Planning

---

## Overview

Add the ability to specify meal type (lunch, dinner, or meal prep) when recording cooked meals through the Cook Screen. This metadata improves meal history context and enables better pattern analysis.

**Current Behavior:**
- Meals recorded with timestamp only
- No indication if meal was for lunch, dinner, or prep
- Planned meals have type (from MealPlanItem), spontaneous cooking loses context

**Goal:**
- Add optional meal type selector when recording meals
- Store meal type in database
- Display meal type in meal history

---

## Technical Context

**Existing Pattern:** `MealPlanItem` uses string constants for meal type:
```dart
static const String lunch = 'lunch';
static const String dinner = 'dinner';
```

**Proposed Approach:** Add `MealType` enum and nullable `mealType` field to `Meal` model.

---

## Prerequisites

- Understanding of database migration system
- Familiarity with Meal model and recording workflow

## Dependencies

- **Blocked by:** None
- **Related screens:** CookMealScreen, MealHistoryScreen, MealRecordingDialog

---

## Implementation Phases

### Phase 1: Define MealType Enum

**Objective:** Create the MealType enum for type-safe meal categorization

**File:** `lib/models/meal_type.dart` (new file)

**Implementation:**
```dart
/// Enum representing the type/context of a cooked meal
enum MealType {
  lunch('lunch'),
  dinner('dinner'),
  prep('prep');  // Meal prep / undefined

  final String value;
  const MealType(this.value);

  /// Convert from database string value
  static MealType? fromString(String? value) {
    if (value == null) return null;
    return MealType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MealType.prep,
    );
  }

  /// Get localized display name
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case MealType.lunch:
        return l10n.mealTypeLunch;
      case MealType.dinner:
        return l10n.mealTypeDinner;
      case MealType.prep:
        return l10n.mealTypePrep;
    }
  }
}
```

**Tasks:**
- [ ] Create `lib/models/meal_type.dart`
- [ ] Define enum with lunch, dinner, prep values
- [ ] Add `fromString()` factory for database conversion
- [ ] Add `getDisplayName()` for localized labels
- [ ] Export from models barrel file (if exists)

**Estimated time:** 30 minutes

---

### Phase 2: Add Localization Strings

**Objective:** Add l10n strings for meal type labels and UI

**Files:**
- `lib/l10n/app_en.arb`
- `lib/l10n/app_pt.arb`

**Strings to add:**
```json
// app_en.arb
{
  "mealTypeLunch": "Lunch",
  "mealTypeDinner": "Dinner",
  "mealTypePrep": "Meal Prep",
  "mealTypeQuestion": "When was this meal for?",
  "mealTypeSkip": "Skip",
  "mealTypeSave": "Save"
}

// app_pt.arb
{
  "mealTypeLunch": "Almoço",
  "mealTypeDinner": "Jantar",
  "mealTypePrep": "Preparação",
  "mealTypeQuestion": "Esta refeição foi para quando?",
  "mealTypeSkip": "Pular",
  "mealTypeSave": "Salvar"
}
```

**Tasks:**
- [ ] Add strings to `app_en.arb`
- [ ] Add strings to `app_pt.arb`
- [ ] Run `flutter gen-l10n`
- [ ] Verify generated code compiles

**Estimated time:** 20 minutes

---

### Phase 3: Database Migration

**Objective:** Add `meal_type` column to meals table

**File:** `lib/core/migration/migrations/003_add_meal_type.dart` (new file)

**Migration implementation:**
```dart
import '../database_migration.dart';

class Migration003AddMealType extends DatabaseMigration {
  @override
  int get version => 3;

  @override
  Future<void> up(Database db) async {
    // Add nullable meal_type column
    await db.execute('''
      ALTER TABLE meals ADD COLUMN meal_type TEXT
    ''');
    // Note: existing meals will have NULL meal_type - intentional
  }

  @override
  Future<void> down(Database db) async {
    // SQLite doesn't support DROP COLUMN directly
    // Would need table recreation - not implementing for now
    throw UnimplementedError('Rollback not supported for this migration');
  }
}
```

**Tasks:**
- [ ] Create migration file `003_add_meal_type.dart`
- [ ] Register migration in migration manager
- [ ] Test migration runs without error
- [ ] Verify column exists after migration

**Database considerations:**
- Column is nullable (TEXT type)
- Existing meals keep NULL value (no backfill)
- Valid values: 'lunch', 'dinner', 'prep', NULL

**Estimated time:** 45 minutes

---

### Phase 4: Update Meal Model

**Objective:** Add mealType field to Meal class

**File:** `lib/models/meal.dart`

**Changes:**
```dart
import 'meal_type.dart';

class Meal {
  // ... existing fields ...
  MealType? mealType;  // NEW: nullable meal type

  Meal({
    // ... existing parameters ...
    this.mealType,  // NEW
  });

  Map<String, dynamic> toMap() {
    return {
      // ... existing fields ...
      'meal_type': mealType?.value,  // NEW: store enum value
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      // ... existing fields ...
      mealType: MealType.fromString(map['meal_type']),  // NEW
    );
  }
}
```

**Tasks:**
- [ ] Import MealType enum
- [ ] Add nullable `mealType` field
- [ ] Add to constructor (optional parameter)
- [ ] Update `toMap()` to include meal_type
- [ ] Update `fromMap()` to parse meal_type
- [ ] Update `copyWith()` if it exists

**Estimated time:** 30 minutes

---

### Phase 5: Create Meal Type Selector UI

**Objective:** Create dialog/widget for selecting meal type

**Option A: Dialog after marking as cooked**
```dart
class MealTypeDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.mealTypeQuestion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: MealType.values.map((type) => RadioListTile<MealType>(
          title: Text(type.getDisplayName(l10n)),
          value: type,
          groupValue: _selectedType,
          onChanged: (value) => setState(() => _selectedType = value),
        )).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),  // Skip
          child: Text(l10n.mealTypeSkip),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedType),
          child: Text(l10n.mealTypeSave),
        ),
      ],
    );
  }
}
```

**Tasks:**
- [ ] Create `lib/widgets/meal_type_dialog.dart` (or inline in screen)
- [ ] Implement radio button selection
- [ ] Handle skip (returns null)
- [ ] Handle save (returns selected type)
- [ ] Style consistently with app design

**Estimated time:** 45 minutes

---

### Phase 6: Integrate with Cook Screen

**Objective:** Show meal type selector when recording cooked meal

**File:** `lib/screens/cook_meal_screen.dart`

**Integration point:** After marking recipe as cooked, show dialog

```dart
Future<void> _markAsCooked(Recipe recipe) async {
  // ... existing logic to create meal ...

  // Show meal type selector
  final mealType = await showDialog<MealType>(
    context: context,
    builder: (context) => const MealTypeDialog(),
  );

  // Create meal with type (type can be null if skipped)
  final meal = Meal(
    // ... existing fields ...
    mealType: mealType,
  );

  await _saveMeal(meal);
}
```

**Tasks:**
- [ ] Identify exact integration point in CookMealScreen
- [ ] Show MealTypeDialog after successful cook action
- [ ] Pass selected meal type to Meal creation
- [ ] Handle skip gracefully (null type)
- [ ] Ensure non-intrusive UX (quick interaction)

**Estimated time:** 45 minutes

---

### Phase 7: Display Meal Type in History

**Objective:** Show meal type in meal history screen

**File:** `lib/screens/meal_history_screen.dart`

**Changes:**
- Add meal type indicator to meal list items
- Could be: chip, icon, or text label

**UI mockup:**
```
┌─────────────────────────────────┐
│ Pasta Carbonara                 │
│ Jan 5, 2026 • 2 servings        │
│ [Dinner]  ← NEW: meal type chip │
└─────────────────────────────────┘
```

**Tasks:**
- [ ] Locate meal list item widget in MealHistoryScreen
- [ ] Add conditional meal type display (only if not null)
- [ ] Use Chip widget or similar for type indicator
- [ ] Style consistently (color-coded by type?)
- [ ] Test with meals that have/don't have type

**Estimated time:** 30 minutes

---

### Phase 8: Update Tests

**Objective:** Add tests for new functionality

**Test areas:**

#### Model Tests
- [ ] Test MealType enum values
- [ ] Test MealType.fromString() with valid/invalid/null
- [ ] Test Meal.toMap() includes meal_type
- [ ] Test Meal.fromMap() parses meal_type

#### Widget Tests
- [ ] Test MealTypeDialog renders all options
- [ ] Test selection returns correct type
- [ ] Test skip returns null
- [ ] Test integration with cook flow

#### Database Tests
- [ ] Test migration creates column
- [ ] Test saving meal with type
- [ ] Test saving meal without type (null)
- [ ] Test loading meal preserves type

**Tasks:**
- [ ] Create `test/models/meal_type_test.dart`
- [ ] Update `test/models/meal_test.dart`
- [ ] Create `test/widgets/meal_type_dialog_test.dart`
- [ ] Update database tests if needed

**Estimated time:** 1 hour

---

### Phase 9: Final Verification

**Objective:** Confirm feature works end-to-end

**Tasks:**
- [ ] Run full test suite: `flutter test`
- [ ] Run analysis: `flutter analyze`
- [ ] Manual testing flow:
  - [ ] Cook a recipe → select Lunch → verify in history
  - [ ] Cook a recipe → select Dinner → verify in history
  - [ ] Cook a recipe → Skip → verify null in history
  - [ ] View old meals → verify no type shown
- [ ] Verify localization (EN and PT)

**Estimated time:** 30 minutes

---

## Deliverables Checklist

- [ ] `MealType` enum created with lunch/dinner/prep values
- [ ] Database migration adds `meal_type` column
- [ ] `Meal` model updated with `mealType` field
- [ ] Meal type selector dialog created
- [ ] CookMealScreen integrated with selector
- [ ] MealHistoryScreen displays meal type
- [ ] Localization complete (EN + PT)
- [ ] Unit tests for model and enum
- [ ] Widget tests for dialog
- [ ] All tests pass
- [ ] No analysis issues

---

## Risk Assessment

**Low Risk:**
- Database migration: Adding nullable column is safe
- Model changes: Backward compatible (null allowed)
- UI: Non-blocking dialog, user can skip

**Medium Risk:**
- Integration point in CookMealScreen may need careful placement
- UX balance: Must be quick and non-intrusive

**Mitigations:**
- Keep dialog simple (3 options + skip)
- Don't require selection (skip is valid)
- Test with existing meal data to ensure backward compatibility

---

## Success Criteria

- [ ] Users can select meal type when recording
- [ ] Meal type visible in history for meals that have it
- [ ] Old meals without type display correctly (no crash/error)
- [ ] Skipping selection works smoothly
- [ ] All tests pass
- [ ] Feature feels lightweight and non-intrusive

---

## Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Enum vs String | Enum | Type safety, localization support |
| Nullable | Yes | Backward compat, skip option |
| Migration | Add column | Simple, safe |
| Backfill | No | Existing meals stay NULL |
| UI | Dialog after cook | Non-blocking, optional |
| Values | lunch/dinner/prep | Matches MealPlanItem pattern |

---

## Reference

- Existing pattern: `lib/models/meal_plan_item.dart` (lunch/dinner constants)
- Migration examples: `lib/core/migration/migrations/`
- Current Meal model: `lib/models/meal.dart`
- CookMealScreen: `lib/screens/cook_meal_screen.dart`

---

## Notes

- Keep UI minimal - this should be a quick optional step
- Consider smart defaults (e.g., auto-select based on time of day?)
- Future enhancement: Analytics based on meal type patterns
- Planned meals already have type from MealPlanItem - this is for spontaneous cooking
