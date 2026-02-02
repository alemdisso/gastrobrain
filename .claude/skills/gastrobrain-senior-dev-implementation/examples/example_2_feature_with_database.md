# Example 2: Feature with Database Changes

This example demonstrates implementing a Phase 2 feature that requires database schema changes, with 8 checkpoints including delegation to the database migration skill.

## Context

- **Issue**: #175 - Add meal type (breakfast/lunch/dinner) to meals
- **Branch**: `feature/175-add-meal-type`
- **Roadmap**: `docs/planning/0.1.4/ISSUE-175-ROADMAP.md`
- **Category**: Feature with Database (8 checkpoints)

---

## Initial Context Detection

```
Phase 2 Implementation for Issue #175
═══════════════════════════════════════

Branch: feature/175-add-meal-type
Roadmap: docs/planning/0.1.4/ISSUE-175-ROADMAP.md

Phase 2 Requirements Summary:
- Add meal_type column to meals table
- Create MealType enum
- Update Meal model with type field
- Update UI to show/select meal type
- Add localization for meal type labels

Implementation Categories Detected:
├─ Database: Yes → Delegate to gastrobrain-database-migration
├─ Models: MealType enum, Meal model update
├─ Services: None needed
├─ Widgets: MealRecordingDialog, MealListItem
├─ Providers: No changes needed
└─ Localization: 5 strings (3 meal types + 2 labels)

Pattern References Found:
- Similar enum: lib/models/protein_type.dart
- Similar model field: lib/models/meal_plan_item.dart
- Similar dialog field: lib/widgets/meal_recording_dialog.dart

Checkpoint Plan:
1. [DELEGATE] Database migration → gastrobrain-database-migration
2. Create MealType enum
3. Update Meal model
4. Update MealRecordingDialog UI
5. Update MealListItem display
6. Wire up selection and saving
7. Add localization strings
8. Integration verification

Total: 8 checkpoints (Checkpoint 1 delegated)

Ready to start Checkpoint 1/8? (y/n)
```

---

## Checkpoint 1: Database Migration (DELEGATION)

```
═══════════════════════════════════════
CHECKPOINT 1/8: Database Schema Changes
Goal: Add meal_type column to meals table

⚠️ DELEGATION REQUIRED

This checkpoint requires database migration work. Delegating to:
→ gastrobrain-database-migration skill

The database migration skill will:
1. Create migration file (v16) for adding meal_type column
2. Implement up() method with ALTER TABLE
3. Implement down() method for rollback
4. Test migration applies correctly

Migration Requirements:
- Table: meals
- New column: meal_type TEXT NULL
- Default: NULL (existing meals have no type)
- Rollback: DROP COLUMN meal_type

After database migration completes:
- Migration file created: lib/core/database/migrations/migration_v16.dart
- Column verified in schema
- Return here for Checkpoint 2/8

Hand off to database migration skill? (y/n)
═══════════════════════════════════════
```

**User Response**: y

*[Database migration skill handles checkpoints 1-6 of migration]*

**After delegation returns:**

```
✅ DELEGATION COMPLETE

Database migration skill completed:
✓ Migration v16 created
✓ meals.meal_type column added (TEXT NULL)
✓ Rollback verified
✓ Tests passing

Resuming Phase 2 implementation at Checkpoint 2/8

Ready to proceed to Checkpoint 2/8? (y/n)
```

---

## Checkpoint 2: Create MealType Enum

```
═══════════════════════════════════════
CHECKPOINT 2/8: Create MealType Enum
Goal: Create enum with database value mapping and localization

Pattern Context:
- Similar implementation: lib/models/protein_type.dart
- Key patterns:
  • String value field for database storage
  • fromString() static method for parsing
  • getDisplayName() with AppLocalizations

Progress:
✓ Checkpoint 1: Database migration [DELEGATED]
⧗ Checkpoint 2: Create MealType enum [CURRENT]
○ Checkpoint 3: Update Meal model
○ Checkpoint 4: Update MealRecordingDialog
○ Checkpoint 5: Update MealListItem
○ Checkpoint 6: Wire up selection
○ Checkpoint 7: Add localization
○ Checkpoint 8: Integration verification

Tasks:
- [ ] Create MealType enum file
- [ ] Add string value mapping
- [ ] Add fromString() method
- [ ] Add getDisplayName() method

Implementation:

File: lib/models/meal_type.dart (NEW)

```dart
import '../l10n/app_localizations.dart';

/// Enum representing the type/context of a cooked meal
enum MealType {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  snack('snack');

  /// The database/storage value
  final String value;

  const MealType(this.value);

  /// Convert from database string value
  /// Returns null if value is null
  static MealType? fromString(String? value) {
    if (value == null) return null;
    return MealType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MealType.lunch, // Default fallback
    );
  }

  /// Get localized display name for UI
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case MealType.breakfast:
        return l10n.mealTypeBreakfast;
      case MealType.lunch:
        return l10n.mealTypeLunch;
      case MealType.dinner:
        return l10n.mealTypeDinner;
      case MealType.snack:
        return l10n.mealTypeSnack;
    }
  }
}
```

Files Created:
- lib/models/meal_type.dart [NEW]

Verification Steps:
1. flutter analyze lib/models/meal_type.dart
2. Verify enum compiles (will have l10n warnings until step 7)

Ready to proceed to Checkpoint 3/8? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 3: Update Meal Model

```
═══════════════════════════════════════
CHECKPOINT 3/8: Update Meal Model
Goal: Add mealType field to Meal model

Pattern Context:
- Similar field addition: lib/models/meal_plan_item.dart (notes field)
- Key patterns:
  • Nullable field for backward compatibility
  • toMap() uses .value for enum
  • fromMap() uses fromString()

Progress:
✓ Checkpoint 1: Database migration [DELEGATED]
✓ Checkpoint 2: Create MealType enum [COMPLETE]
⧗ Checkpoint 3: Update Meal model [CURRENT]
○ Checkpoint 4: Update MealRecordingDialog
○ Checkpoint 5: Update MealListItem
○ Checkpoint 6: Wire up selection
○ Checkpoint 7: Add localization
○ Checkpoint 8: Integration verification

Tasks:
- [ ] Add mealType field to Meal class
- [ ] Update constructor
- [ ] Update toMap()
- [ ] Update fromMap()
- [ ] Update copyWith()

Implementation:

File: lib/models/meal.dart

ADD import at top:
```dart
import 'meal_type.dart';
```

ADD field in class:
```dart
/// Type of meal (breakfast, lunch, dinner, snack)
final MealType? mealType;
```

UPDATE constructor:
```dart
Meal({
  required this.id,
  required this.recipeId,
  required this.cookedAt,
  this.servings,
  this.notes,
  this.wasSuccessful = true,
  this.actualPrepTime,
  this.actualCookTime,
  this.mealType, // Add this
});
```

UPDATE toMap():
```dart
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'recipe_id': recipeId,
    'cooked_at': cookedAt.toIso8601String(),
    'servings': servings,
    'notes': notes,
    'was_successful': wasSuccessful ? 1 : 0,
    'actual_prep_time': actualPrepTime,
    'actual_cook_time': actualCookTime,
    'meal_type': mealType?.value, // Add this
  };
}
```

UPDATE fromMap():
```dart
factory Meal.fromMap(Map<String, dynamic> map) {
  return Meal(
    id: map['id'] as String,
    recipeId: map['recipe_id'] as String?,
    cookedAt: DateTime.parse(map['cooked_at'] as String),
    servings: map['servings'] as int?,
    notes: map['notes'] as String?,
    wasSuccessful: (map['was_successful'] as int?) == 1,
    actualPrepTime: (map['actual_prep_time'] as num?)?.toDouble(),
    actualCookTime: (map['actual_cook_time'] as num?)?.toDouble(),
    mealType: MealType.fromString(map['meal_type'] as String?), // Add this
  );
}
```

UPDATE copyWith():
```dart
Meal copyWith({
  String? id,
  String? recipeId,
  DateTime? cookedAt,
  int? servings,
  String? notes,
  bool? wasSuccessful,
  double? actualPrepTime,
  double? actualCookTime,
  MealType? mealType, // Add this
}) {
  return Meal(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    cookedAt: cookedAt ?? this.cookedAt,
    servings: servings ?? this.servings,
    notes: notes ?? this.notes,
    wasSuccessful: wasSuccessful ?? this.wasSuccessful,
    actualPrepTime: actualPrepTime ?? this.actualPrepTime,
    actualCookTime: actualCookTime ?? this.actualCookTime,
    mealType: mealType ?? this.mealType, // Add this
  );
}
```

Files Modified:
- lib/models/meal.dart: Added mealType field

Verification Steps:
1. flutter analyze lib/models/meal.dart
2. Verify no type errors

Ready to proceed to Checkpoint 4/8? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 4: Update MealRecordingDialog UI

```
═══════════════════════════════════════
CHECKPOINT 4/8: Update MealRecordingDialog UI
Goal: Add meal type selection dropdown

Pattern Context:
- Similar dropdown: lib/widgets/recipe_selection_dialog.dart
- Key patterns:
  • DropdownButtonFormField for form integration
  • items from enum.values
  • value tracks selection state

Progress:
✓ Checkpoint 1: Database migration [DELEGATED]
✓ Checkpoint 2: Create MealType enum [COMPLETE]
✓ Checkpoint 3: Update Meal model [COMPLETE]
⧗ Checkpoint 4: Update MealRecordingDialog [CURRENT]
○ Checkpoint 5: Update MealListItem
○ Checkpoint 6: Wire up selection
○ Checkpoint 7: Add localization
○ Checkpoint 8: Integration verification

Tasks:
- [ ] Add state variable for selected meal type
- [ ] Add dropdown widget
- [ ] Place appropriately in form

Implementation:

File: lib/widgets/meal_recording_dialog.dart

ADD import:
```dart
import '../models/meal_type.dart';
```

ADD state variable in _MealRecordingDialogState:
```dart
MealType? _selectedMealType;
```

ADD in initState() after other initializations:
```dart
_selectedMealType = null; // Default to no selection
```

ADD dropdown widget in build() form (after date picker, before notes):
```dart
const SizedBox(height: 16),
DropdownButtonFormField<MealType>(
  value: _selectedMealType,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.mealTypeLabel,
    border: const OutlineInputBorder(),
  ),
  items: MealType.values.map((type) {
    return DropdownMenuItem<MealType>(
      value: type,
      child: Text(type.getDisplayName(AppLocalizations.of(context)!)),
    );
  }).toList(),
  onChanged: (MealType? value) {
    setState(() {
      _selectedMealType = value;
    });
  },
),
```

Files Modified:
- lib/widgets/meal_recording_dialog.dart: Added meal type dropdown

Verification Steps:
1. flutter analyze lib/widgets/meal_recording_dialog.dart
2. Note: l10n errors expected until Checkpoint 7

Ready to proceed to Checkpoint 5/8? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 5: Update MealListItem Display

```
═══════════════════════════════════════
CHECKPOINT 5/8: Update MealListItem Display
Goal: Show meal type in meal list items

Pattern Context:
- Similar display: lib/widgets/recipe_list_item.dart (shows protein type)
- Key patterns:
  • Chip widget for type display
  • Conditional display (only show if not null)

Progress:
✓ Checkpoint 1: Database migration [DELEGATED]
✓ Checkpoint 2: Create MealType enum [COMPLETE]
✓ Checkpoint 3: Update Meal model [COMPLETE]
✓ Checkpoint 4: Update MealRecordingDialog [COMPLETE]
⧗ Checkpoint 5: Update MealListItem [CURRENT]
○ Checkpoint 6: Wire up selection
○ Checkpoint 7: Add localization
○ Checkpoint 8: Integration verification

Tasks:
- [ ] Add meal type display in list item
- [ ] Show as chip or label
- [ ] Handle null case (hide if not set)

Implementation:

File: lib/widgets/meal_list_item.dart

ADD import:
```dart
import '../models/meal_type.dart';
```

ADD in Row children (after date, before trailing icons):
```dart
if (meal.mealType != null) ...[
  const SizedBox(width: 8),
  Chip(
    label: Text(
      meal.mealType!.getDisplayName(AppLocalizations.of(context)!),
      style: Theme.of(context).textTheme.labelSmall,
    ),
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
  ),
],
```

Files Modified:
- lib/widgets/meal_list_item.dart: Added meal type chip

Verification Steps:
1. flutter analyze lib/widgets/meal_list_item.dart
2. Note: l10n errors expected until Checkpoint 7

Ready to proceed to Checkpoint 6/8? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 6: Wire Up Selection and Saving

```
═══════════════════════════════════════
CHECKPOINT 6/8: Wire Up Selection and Saving
Goal: Connect meal type selection to data saving

Pattern Context:
- Similar save flow: MealRecordingDialog._handleSave()
- Key patterns:
  • Include in result map
  • Pass through to Meal creation

Progress:
✓ Checkpoint 1: Database migration [DELEGATED]
✓ Checkpoint 2: Create MealType enum [COMPLETE]
✓ Checkpoint 3: Update Meal model [COMPLETE]
✓ Checkpoint 4: Update MealRecordingDialog [COMPLETE]
✓ Checkpoint 5: Update MealListItem [COMPLETE]
⧗ Checkpoint 6: Wire up selection [CURRENT]
○ Checkpoint 7: Add localization
○ Checkpoint 8: Integration verification

Tasks:
- [ ] Add mealType to dialog result
- [ ] Update caller to use mealType
- [ ] Verify save works end-to-end

Implementation:

File: lib/widgets/meal_recording_dialog.dart

UPDATE _handleSave() result map:
```dart
Navigator.of(context).pop({
  'cookedAt': _selectedDate,
  'servings': int.tryParse(_servingsController.text) ?? 1,
  'notes': _notesController.text,
  'wasSuccessful': _wasSuccessful,
  'actualPrepTime': _actualPrepTime,
  'actualCookTime': _actualCookTime,
  'primaryRecipe': widget.primaryRecipe,
  'additionalRecipes': _additionalRecipes,
  'mealType': _selectedMealType, // Add this
});
```

File: lib/screens/weekly_plan_screen.dart

UPDATE _handleMarkAsCooked() to include mealType:

After extracting result values:
```dart
final MealType? mealType = result['mealType'];
```

In Meal creation:
```dart
final meal = Meal(
  id: mealId,
  recipeId: null,
  cookedAt: cookedAt,
  servings: servings,
  notes: notes,
  wasSuccessful: wasSuccessful,
  actualPrepTime: actualPrepTime,
  actualCookTime: actualCookTime,
  mealType: mealType, // Add this
);
```

Files Modified:
- lib/widgets/meal_recording_dialog.dart: Added mealType to result
- lib/screens/weekly_plan_screen.dart: Added mealType to Meal creation

Verification Steps:
1. flutter analyze lib/widgets/meal_recording_dialog.dart
2. flutter analyze lib/screens/weekly_plan_screen.dart
3. Note: l10n errors expected until Checkpoint 7

Ready to proceed to Checkpoint 7/8? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 7: Add Localization Strings

```
═══════════════════════════════════════
CHECKPOINT 7/8: Add Localization Strings
Goal: Add all user-facing strings to ARB files

Pattern Context:
- Similar strings: mealTypeLunch, mealTypeDinner in existing ARB
- Key patterns:
  • Add to both app_en.arb and app_pt.arb
  • Run flutter gen-l10n

Progress:
✓ Checkpoint 1: Database migration [DELEGATED]
✓ Checkpoint 2: Create MealType enum [COMPLETE]
✓ Checkpoint 3: Update Meal model [COMPLETE]
✓ Checkpoint 4: Update MealRecordingDialog [COMPLETE]
✓ Checkpoint 5: Update MealListItem [COMPLETE]
✓ Checkpoint 6: Wire up selection [COMPLETE]
⧗ Checkpoint 7: Add localization [CURRENT]
○ Checkpoint 8: Integration verification

Tasks:
- [ ] Add strings to app_en.arb
- [ ] Add strings to app_pt.arb
- [ ] Run flutter gen-l10n
- [ ] Verify all l10n errors resolved

Implementation:

File: lib/l10n/app_en.arb

ADD:
```json
"mealTypeLabel": "Meal Type",
"@mealTypeLabel": {
  "description": "Label for meal type selection"
},
"mealTypeBreakfast": "Breakfast",
"@mealTypeBreakfast": {
  "description": "Breakfast meal type"
},
"mealTypeLunch": "Lunch",
"@mealTypeLunch": {
  "description": "Lunch meal type"
},
"mealTypeDinner": "Dinner",
"@mealTypeDinner": {
  "description": "Dinner meal type"
},
"mealTypeSnack": "Snack",
"@mealTypeSnack": {
  "description": "Snack meal type"
}
```

File: lib/l10n/app_pt.arb

ADD:
```json
"mealTypeLabel": "Tipo de Refeição",
"mealTypeBreakfast": "Café da Manhã",
"mealTypeLunch": "Almoço",
"mealTypeDinner": "Jantar",
"mealTypeSnack": "Lanche"
```

Run command:
```bash
flutter gen-l10n
```

Files Modified:
- lib/l10n/app_en.arb: Added 5 strings
- lib/l10n/app_pt.arb: Added 5 strings

Verification Steps:
1. flutter gen-l10n (should complete without errors)
2. flutter analyze lib/models/meal_type.dart
3. flutter analyze lib/widgets/meal_recording_dialog.dart
4. flutter analyze lib/widgets/meal_list_item.dart
5. All l10n errors should be resolved

Ready to proceed to Checkpoint 8/8? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 8: Integration Verification

```
═══════════════════════════════════════
CHECKPOINT 8/8: Integration Verification
Goal: Verify complete feature works end-to-end

Progress:
✓ Checkpoint 1: Database migration [DELEGATED]
✓ Checkpoint 2: Create MealType enum [COMPLETE]
✓ Checkpoint 3: Update Meal model [COMPLETE]
✓ Checkpoint 4: Update MealRecordingDialog [COMPLETE]
✓ Checkpoint 5: Update MealListItem [COMPLETE]
✓ Checkpoint 6: Wire up selection [COMPLETE]
✓ Checkpoint 7: Add localization [COMPLETE]
⧗ Checkpoint 8: Integration verification [CURRENT]

Tasks:
- [ ] Run full flutter analyze
- [ ] Verify all files < 400 lines
- [ ] Run existing tests
- [ ] Manual smoke test (if applicable)

Verification Steps:

1. Full static analysis:
```bash
flutter analyze
```

2. File length check:
- lib/models/meal_type.dart: ~35 lines ✓
- lib/models/meal.dart: ~85 lines ✓
- lib/widgets/meal_recording_dialog.dart: ~350 lines ✓
- lib/widgets/meal_list_item.dart: ~120 lines ✓

3. Run existing tests:
```bash
flutter test
```

4. Manual smoke test flow:
- Open meal recording dialog
- Verify meal type dropdown appears
- Select a meal type
- Save meal
- Verify meal list shows meal type chip
- Check database has meal_type value

Expected Results:
- flutter analyze: No errors
- flutter test: All existing tests pass
- Manual test: Feature works as expected

═══════════════════════════════════════
```

---

## Phase 2 Completion Summary

```
═══════════════════════════════════════
PHASE 2 IMPLEMENTATION SUMMARY
═══════════════════════════════════════

Issue: #175 - Add meal type to meals
Branch: feature/175-add-meal-type

Checkpoints Completed:
✓ Checkpoint 1: Database migration [DELEGATED]
✓ Checkpoint 2: Create MealType enum
✓ Checkpoint 3: Update Meal model
✓ Checkpoint 4: Update MealRecordingDialog UI
✓ Checkpoint 5: Update MealListItem display
✓ Checkpoint 6: Wire up selection and saving
✓ Checkpoint 7: Add localization strings
✓ Checkpoint 8: Integration verification

Files Created:
- lib/models/meal_type.dart [NEW]
- lib/core/database/migrations/migration_v16.dart [NEW - via delegation]

Files Modified:
- lib/models/meal.dart [MODIFIED]
- lib/widgets/meal_recording_dialog.dart [MODIFIED]
- lib/widgets/meal_list_item.dart [MODIFIED]
- lib/screens/weekly_plan_screen.dart [MODIFIED]
- lib/l10n/app_en.arb [MODIFIED]
- lib/l10n/app_pt.arb [MODIFIED]

Quality Verification:
✓ flutter analyze passes
✓ All files < 400 lines
✓ Pattern compliance (matches protein_type.dart)
✓ DI in place for testing

Roadmap Updated:
- docs/planning/0.1.4/ISSUE-175-ROADMAP.md
  └─ Phase 2 checkboxes marked complete

Next Steps:
1. ○ Hand off to gastrobrain-testing-implementation for Phase 3
   Test areas:
   - MealType enum unit tests
   - Meal model serialization tests
   - MealRecordingDialog widget tests
   - Edge cases: null meal type, all meal types
2. ○ After testing, proceed to Phase 4 (Documentation & Cleanup)

═══════════════════════════════════════
```

---

## Key Takeaways

1. **Delegation**: Database work delegated to specialized skill
2. **Pattern Detection**: Used protein_type.dart as enum pattern
3. **Incremental Building**: Each checkpoint built on previous
4. **Localization Last**: UI code written first, l10n added after
5. **Integration Check**: Final checkpoint verified end-to-end flow
6. **Quality Gates**: Every checkpoint verified with flutter analyze
