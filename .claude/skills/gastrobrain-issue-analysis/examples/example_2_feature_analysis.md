# Example 2: Feature Analysis

This example demonstrates Phase 1 analysis for a feature issue - adding meal type selection to meal recording.

## Context

- **Issue**: #199 - Add meal type selection (breakfast/lunch/dinner/snack)
- **Branch**: `feature/199-add-meal-type`
- **Type**: Feature
- **Roadmap**: `docs/planning/0.1.6/ISSUE-199-ROADMAP.md`

---

## Initial Context

```
Phase 1 Analysis for Issue #199
═══════════════════════════════════════

Branch: feature/199-add-meal-type
Issue: Add meal type selection to meal recording
Type: Feature
Roadmap: docs/planning/0.1.6/ISSUE-199-ROADMAP.md

Phase 1 Checklist (from roadmap):
- [ ] Review acceptance criteria
- [ ] Identify database changes
- [ ] Design UI approach
- [ ] Plan localization needs
- [ ] Identify testing requirements

Analysis Framework:
1. Requirements Deep-Dive
2. Codebase Exploration
3. Technical Design
4. Risk & Edge Case Analysis
5. Implementation Preparation

Ready to start Checkpoint 1/5? (y/n)
```

---

## Checkpoint 1: Requirements Deep-Dive

```
═══════════════════════════════════════
CHECKPOINT 1/5: Requirements Deep-Dive
Goal: Understand feature requirements completely

Reading issue #199 from GitHub...

Issue Type: Feature (Enhancement)

Title: Add meal type selection to meal recording

Description Summary:
Users want to categorize their cooked meals by type (breakfast,
lunch, dinner, snack) for better organization, filtering, and
type-specific analytics in the future.

User Story:
As a user, I want to record what type of meal I cooked
(breakfast, lunch, dinner, or snack) so that I can organize
and filter my cooking history by meal type.

Pain Point:
Currently all meals are recorded without context of when they
were eaten. Users cooking the same recipe for lunch vs dinner
can't distinguish between them in history.

Acceptance Criteria:
- [ ] Dropdown in MealRecordingDialog to select meal type
- [ ] Options: Breakfast, Lunch, Dinner, Snack
- [ ] Field is optional (backward compatible with existing meals)
- [ ] Meal type saved with meal record in database
- [ ] Meal type displayed in meal history/list
- [ ] Bilingual labels (English and Portuguese)
- [ ] Existing meals show "Not specified" if no type

Success Metrics:
- Users can select meal type when recording
- Meal type persists and displays correctly
- No impact on users who don't want to categorize

Scope Boundaries:
IN SCOPE:
- Meal type selection in recording dialog
- Database storage
- Display in meal list
- Localization

OUT OF SCOPE:
- Filtering by meal type (future issue)
- Meal type in weekly plan view (future issue)
- Analytics by meal type (future issue)
- Custom meal types (fixed set for now)

Questions/Clarifications:
- Q: Can users edit meal type after recording?
  A: Yes, via EditMealRecordingDialog (add there too)

Requirements clear? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 2: Codebase Exploration

```
═══════════════════════════════════════
CHECKPOINT 2/5: Codebase Exploration
Goal: Find affected files and patterns to follow

Progress:
✓ Checkpoint 1: Requirements understood
⧗ Checkpoint 2: Codebase exploration [CURRENT]

Analyzing codebase for meal type feature...

Affected Areas:
┌─────────────────────────────────────────────────────────────┐
│ Category     │ Files                        │ Change Type   │
├─────────────────────────────────────────────────────────────┤
│ Models       │ lib/models/meal.dart         │ Modify        │
│              │ lib/models/meal_type.dart    │ Create (NEW)  │
│ Database     │ migrations/migration_v17.dart│ Create (NEW)  │
│ Widgets      │ meal_recording_dialog.dart   │ Modify        │
│              │ edit_meal_recording_dialog.dart│ Modify      │
│              │ meal_list_item.dart          │ Modify        │
│ Screens      │ weekly_plan_screen.dart      │ Modify        │
│ Localization │ app_en.arb, app_pt.arb       │ Modify        │
└─────────────────────────────────────────────────────────────┘

Similar Implementations Found:

1. Pattern: MealType Enum (EXACT MATCH EXISTS!)
   Location: lib/models/meal_type.dart
   Status: ALREADY EXISTS in codebase!

   ```dart
   enum MealType {
     lunch('lunch'),
     dinner('dinner'),
     prep('prep');

     final String value;
     const MealType(this.value);

     static MealType? fromString(String? value) {...}
     String getDisplayName(AppLocalizations l10n) {...}
   }
   ```

   Note: Current enum has lunch, dinner, prep
   Need to ADD: breakfast, snack
   Need to REMOVE/RENAME: prep → consider keeping for compatibility

2. Pattern: Enum in Model
   Location: lib/models/meal_plan_item.dart (mealType field)
   Approach: String storage with enum conversion
   ```dart
   final String mealType; // 'lunch' or 'dinner'
   ```
   Note: MealPlanItem uses STRING, not enum directly

3. Pattern: Dropdown Widget
   Location: lib/widgets/ (various)
   Approach: DropdownButtonFormField with enum values
   ```dart
   DropdownButtonFormField<MealType>(
     value: selectedType,
     items: MealType.values.map((type) {
       return DropdownMenuItem(
         value: type,
         child: Text(type.getDisplayName(l10n)),
       );
     }).toList(),
     onChanged: (value) => setState(() => selectedType = value),
   )
   ```

Key Discovery:
MealType enum already exists but is used for PLANNED meals
(lunch vs dinner slots in weekly plan). This feature is for
COOKED meals (when was it actually eaten).

Options:
A) Extend existing MealType enum with breakfast/snack
B) Create separate CookedMealType enum
C) Rename existing to PlanningMealType, create MealType for cooked

Recommendation: Option A (extend existing)
- MealType is generic enough name
- Adding breakfast/snack makes sense
- Keep 'prep' for backward compatibility

Dependencies:
- MealType enum: Need to extend
- Meal model: Add mealType field
- DatabaseHelper: Save/load meal type
- MealRecordingDialog: Add dropdown
- EditMealRecordingDialog: Add dropdown
- MealListItem: Display meal type

Integration Points:
- Database: New column in meals table
- Model serialization: toMap/fromMap
- UI: Dropdown in both dialogs
- Display: Chip/label in list items

Files to Create:
- lib/core/database/migrations/migration_v17.dart

Files to Modify:
- lib/models/meal_type.dart (add enum values)
- lib/models/meal.dart (add field)
- lib/widgets/meal_recording_dialog.dart (add dropdown)
- lib/widgets/edit_meal_recording_dialog.dart (add dropdown)
- lib/widgets/meal_list_item.dart (display type)
- lib/screens/weekly_plan_screen.dart (pass type to meal creation)
- lib/l10n/app_en.arb (add strings)
- lib/l10n/app_pt.arb (add translations)

Exploration complete? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 3: Technical Design

```
═══════════════════════════════════════
CHECKPOINT 3/5: Technical Design
Goal: Design the implementation approach

Progress:
✓ Checkpoint 1: Requirements understood
✓ Checkpoint 2: Patterns found (MealType exists!)
⧗ Checkpoint 3: Technical design [CURRENT]

For feature #199, I've evaluated the approaches:

══════════════════════════════════════
APPROACH A: Extend Existing MealType Enum
══════════════════════════════════════

Description:
Add breakfast and snack values to existing MealType enum.
Keep 'prep' for backward compatibility. Use enum directly
in Meal model.

Implementation:
1. Add breakfast, snack to MealType enum
2. Add mealType field to Meal model (nullable)
3. Database migration to add meal_type column
4. Add dropdown to MealRecordingDialog
5. Add dropdown to EditMealRecordingDialog
6. Display in MealListItem
7. Add localization strings

MealType Changes:
```dart
enum MealType {
  breakfast('breakfast'),  // NEW
  lunch('lunch'),
  dinner('dinner'),
  snack('snack'),          // NEW
  prep('prep');            // KEEP for compatibility

  // ... existing methods unchanged
}
```

Pros:
✅ Reuses existing enum pattern
✅ Minimal new code
✅ Consistent with codebase
✅ getDisplayName() already works

Cons:
❌ 'prep' is confusing for cooked meals
❌ Mixes planning and cooking contexts

Complexity: Low
Effort: 5 points

══════════════════════════════════════
APPROACH B: Create Separate Enum
══════════════════════════════════════

Description:
Create new CookedMealType enum specifically for recording
what type of meal was cooked, separate from planning.

Implementation:
1. Create CookedMealType enum (breakfast, lunch, dinner, snack)
2. Add cookedMealType field to Meal model
3. Keep existing MealType for planning
4. Rest of implementation same

CookedMealType:
```dart
enum CookedMealType {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  snack('snack');

  // Same pattern as MealType
}
```

Pros:
✅ Clear separation of concerns
✅ No 'prep' confusion
✅ Future flexibility

Cons:
❌ More code duplication
❌ Two similar enums to maintain
❌ Potential confusion which to use where

Complexity: Medium
Effort: 6 points

══════════════════════════════════════
RECOMMENDATION: Approach A (Extend Existing)
══════════════════════════════════════

Rationale:
1. MealType already exists and works well
2. Adding breakfast/snack is natural extension
3. 'prep' can be hidden in UI for cooked meals (filter it out)
4. Less code to maintain
5. Follows existing pattern exactly

Technical Decisions:

1. Extend MealType vs new enum: Extend existing
   Rationale: Less duplication, consistent pattern

2. Nullable field vs default: Nullable
   Rationale: Backward compatibility with existing meals

3. Database storage: TEXT (enum.value)
   Rationale: Matches existing pattern, human-readable

4. UI location: After date picker, before notes
   Rationale: Natural flow of meal metadata

5. Display in list: Chip widget
   Rationale: Compact, follows design patterns

6. Filter 'prep' from dropdown: Yes
   Rationale: 'prep' doesn't make sense for cooked meals

Design Patterns to Apply:
- Enum pattern from lib/models/meal_type.dart
- Model field pattern from lib/models/meal.dart
- Dropdown pattern from existing dialogs
- Migration pattern from recent migrations
- Chip display from recipe list items

Agree with approach? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 4: Risk & Edge Case Analysis

```
═══════════════════════════════════════
CHECKPOINT 4/5: Risk & Edge Case Analysis
Goal: Identify all edge cases and risks

Progress:
✓ Checkpoint 1: Requirements understood
✓ Checkpoint 2: Patterns found
✓ Checkpoint 3: Approach selected
⧗ Checkpoint 4: Risk analysis [CURRENT]

Risk Assessment:

Technical Risks:
┌─────────────────────────────────────────────────────────────┐
│ Risk                    │ Level  │ Mitigation              │
├─────────────────────────────────────────────────────────────┤
│ Database migration      │ 🟡 MED │ Nullable column, test   │
│                         │        │ with existing data      │
│ Breaking existing meals │ 🟢 LOW │ Nullable field, no      │
│                         │        │ changes to existing     │
│ Enum value mismatch     │ 🟢 LOW │ fromString handles      │
│                         │        │ unknown values          │
│ UI space constraints    │ 🟢 LOW │ Dropdown is compact     │
└─────────────────────────────────────────────────────────────┘

Edge Cases to Handle:

1. Existing Meals (No Type)
   Scenario: Meals recorded before this feature
   Expected: Display "Not specified" or hide type
   Implementation: Check for null, show placeholder
   ```dart
   if (meal.mealType != null) {
     Chip(label: Text(meal.mealType!.getDisplayName(l10n)))
   }
   ```

2. Invalid Enum Value in Database
   Scenario: Database has value not in enum (e.g., "brunch")
   Expected: Default to null, don't crash
   Implementation: fromString returns null for unknown
   ```dart
   static MealType? fromString(String? value) {
     if (value == null) return null;
     return MealType.values.cast<MealType?>().firstWhere(
       (e) => e?.value == value,
       orElse: () => null, // Return null for unknown
     );
   }
   ```

3. 'prep' Value in Dropdown
   Scenario: Dropdown shows 'prep' which doesn't make sense
   Expected: Filter out 'prep' from cooked meal options
   Implementation: Filter enum values in dropdown
   ```dart
   items: MealType.values
     .where((t) => t != MealType.prep)
     .map((type) => DropdownMenuItem(...))
     .toList(),
   ```

4. Edit Existing Meal
   Scenario: User edits meal that had no type
   Expected: Dropdown shows "Not specified" as default
   Implementation: Handle null in dropdown value
   ```dart
   DropdownButtonFormField<MealType?>(
     value: meal.mealType, // Can be null
     hint: Text(l10n.notSpecified),
     ...
   )
   ```

5. Long Localized Label
   Scenario: Portuguese translation longer than English
   Expected: UI handles gracefully
   Implementation: Test with actual translations
   Example: "Café da manhã" (breakfast) is longer

6. Meal Type with Weekly Plan Integration
   Scenario: Marking planned meal as cooked
   Expected: Meal type could be inferred from slot
   Implementation: Future enhancement, not in this scope
   Note: Could pre-select based on slot type

Backward Compatibility:
✅ Existing meals: Unaffected (null type)
✅ Existing queries: Work with null
✅ Existing UI: Shows meals without type
✅ Rollback: Down migration removes column

Performance Considerations:
✅ No additional queries (field on existing model)
✅ Minimal UI overhead (one dropdown)
✅ No indexing needed (not filtering yet)

Testing Requirements:

Unit Tests:
- [ ] MealType.fromString handles all values
- [ ] MealType.fromString returns null for invalid
- [ ] Meal.toMap includes mealType
- [ ] Meal.fromMap parses mealType

Widget Tests:
- [ ] Dropdown renders with all types (except prep)
- [ ] Dropdown handles null selection
- [ ] MealListItem shows type chip when present
- [ ] MealListItem hides chip when type is null

Integration Tests:
- [ ] Save meal with type → retrieve with type
- [ ] Save meal without type → retrieve as null
- [ ] Edit meal type → persists change

Migration Tests:
- [ ] Migration up adds column
- [ ] Migration down removes column
- [ ] Existing data unaffected

Edge Case Tests:
- [ ] Invalid enum value handling
- [ ] Null type display
- [ ] Edit meal with/without type

Localization Tests:
- [ ] All 4 meal types have EN translation
- [ ] All 4 meal types have PT translation
- [ ] Labels fit in dropdown UI

All risks identified? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 5: Implementation Preparation

```
═══════════════════════════════════════
CHECKPOINT 5/5: Implementation Preparation
Goal: Prepare detailed guidance for Phase 2

Progress:
✓ Checkpoint 1: Requirements understood
✓ Checkpoint 2: Patterns found
✓ Checkpoint 3: Approach selected
✓ Checkpoint 4: Risks identified
⧗ Checkpoint 5: Implementation prep [CURRENT]

Implementation Plan:

══════════════════════════════════════
STEP 1: Extend MealType Enum
══════════════════════════════════════

File: lib/models/meal_type.dart

Add new values:
```dart
enum MealType {
  breakfast('breakfast'),  // ADD
  lunch('lunch'),
  dinner('dinner'),
  snack('snack'),          // ADD
  prep('prep');

  // ... existing code unchanged

  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case MealType.breakfast:
        return l10n.mealTypeBreakfast;  // ADD
      case MealType.lunch:
        return l10n.mealTypeLunch;
      case MealType.dinner:
        return l10n.mealTypeDinner;
      case MealType.snack:
        return l10n.mealTypeSnack;      // ADD
      case MealType.prep:
        return l10n.mealTypePrep;
    }
  }
}
```

Verification: flutter analyze lib/models/

══════════════════════════════════════
STEP 2: Database Migration
══════════════════════════════════════

Delegate to: gastrobrain-database-migration skill

Migration v17:
```dart
// Up
await db.execute('''
  ALTER TABLE meals ADD COLUMN meal_type TEXT
''');

// Down
await db.execute('''
  ALTER TABLE meals DROP COLUMN meal_type
''');
```

══════════════════════════════════════
STEP 3: Update Meal Model
══════════════════════════════════════

File: lib/models/meal.dart

Add field:
```dart
final MealType? mealType;
```

Update constructor:
```dart
Meal({
  // ... existing
  this.mealType,
});
```

Update toMap:
```dart
'meal_type': mealType?.value,
```

Update fromMap:
```dart
mealType: MealType.fromString(map['meal_type'] as String?),
```

Update copyWith:
```dart
MealType? mealType,
// ...
mealType: mealType ?? this.mealType,
```

══════════════════════════════════════
STEP 4: Update MealRecordingDialog
══════════════════════════════════════

File: lib/widgets/meal_recording_dialog.dart

Add state:
```dart
MealType? _selectedMealType;
```

Add dropdown (after date picker):
```dart
const SizedBox(height: 16),
DropdownButtonFormField<MealType>(
  value: _selectedMealType,
  decoration: InputDecoration(
    labelText: l10n.mealTypeLabel,
    border: const OutlineInputBorder(),
  ),
  hint: Text(l10n.selectMealType),
  items: MealType.values
      .where((t) => t != MealType.prep)
      .map((type) => DropdownMenuItem(
            value: type,
            child: Text(type.getDisplayName(l10n)),
          ))
      .toList(),
  onChanged: (value) => setState(() => _selectedMealType = value),
),
```

Add to result:
```dart
'mealType': _selectedMealType,
```

══════════════════════════════════════
STEP 5: Update EditMealRecordingDialog
══════════════════════════════════════

File: lib/widgets/edit_meal_recording_dialog.dart

Same changes as MealRecordingDialog, plus:
- Initialize _selectedMealType from widget.meal.mealType

══════════════════════════════════════
STEP 6: Update MealListItem
══════════════════════════════════════

File: lib/widgets/meal_list_item.dart

Add chip display:
```dart
if (meal.mealType != null) ...[
  const SizedBox(width: 8),
  Chip(
    label: Text(
      meal.mealType!.getDisplayName(l10n),
      style: Theme.of(context).textTheme.labelSmall,
    ),
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
  ),
],
```

══════════════════════════════════════
STEP 7: Update WeeklyPlanScreen
══════════════════════════════════════

File: lib/screens/weekly_plan_screen.dart

In _handleMarkAsCooked, extract and use mealType from result.

══════════════════════════════════════
STEP 8: Localization
══════════════════════════════════════

app_en.arb:
```json
"mealTypeLabel": "Meal Type",
"selectMealType": "Select meal type",
"mealTypeBreakfast": "Breakfast",
"mealTypeLunch": "Lunch",
"mealTypeDinner": "Dinner",
"mealTypeSnack": "Snack",
"mealTypePrep": "Meal Prep",
"notSpecified": "Not specified"
```

app_pt.arb:
```json
"mealTypeLabel": "Tipo de Refeição",
"selectMealType": "Selecione o tipo",
"mealTypeBreakfast": "Café da Manhã",
"mealTypeLunch": "Almoço",
"mealTypeDinner": "Jantar",
"mealTypeSnack": "Lanche",
"mealTypePrep": "Preparação",
"notSpecified": "Não especificado"
```

Run: flutter gen-l10n

══════════════════════════════════════
IMPLEMENTATION SUMMARY
══════════════════════════════════════

Total Steps: 8
Estimated Checkpoints for Phase 2: 8-10
Skills to Delegate: gastrobrain-database-migration (Step 2)

Files to Create:
- lib/core/database/migrations/migration_v17.dart

Files to Modify:
- lib/models/meal_type.dart (2 new values)
- lib/models/meal.dart (new field)
- lib/widgets/meal_recording_dialog.dart (dropdown)
- lib/widgets/edit_meal_recording_dialog.dart (dropdown)
- lib/widgets/meal_list_item.dart (chip)
- lib/screens/weekly_plan_screen.dart (pass type)
- lib/l10n/app_en.arb (8 strings)
- lib/l10n/app_pt.arb (8 strings)

Ready to update roadmap? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Phase 1 Completion

```
═══════════════════════════════════════
PHASE 1 ANALYSIS COMPLETE
═══════════════════════════════════════

Issue: #199 - Add meal type selection
Type: Feature
Branch: feature/199-add-meal-type

Analysis Summary:
✓ Checkpoint 1: Feature requirements understood
✓ Checkpoint 2: MealType enum already exists (extend it)
✓ Checkpoint 3: Approach selected (extend enum, add field)
✓ Checkpoint 4: 6 edge cases identified, testing planned
✓ Checkpoint 5: 8-step implementation guide prepared

Key Discovery:
MealType enum already exists in codebase - just needs
breakfast and snack values added.

Technical Decisions:
1. Extend existing MealType enum
2. Nullable field for backward compatibility
3. Filter 'prep' from dropdown UI
4. Display as chip in list items

Edge Cases Identified: 6
- Existing meals (null type)
- Invalid enum value
- 'prep' filtering
- Edit existing meal
- Long localized labels
- Weekly plan integration (future)

Files to Create: 1
Files to Modify: 8
Localization Strings: 8

Roadmap Updated:
✓ docs/planning/0.1.6/ISSUE-199-ROADMAP.md
  └─ Phase 1 marked complete
  └─ Technical design documented
  └─ Code examples for each step
  └─ Edge cases listed

Next Steps:
1. → Execute Phase 2 with gastrobrain-senior-dev-implementation
2. → Delegate database migration to migration skill
3. → Follow 8-step implementation plan
4. → Test all edge cases identified

Ready for Phase 2? (y/n)
═══════════════════════════════════════
```

---

## Key Takeaways for Feature Analysis

1. **Check for Existing Code**: MealType already existed!
2. **Understand User Need**: Not just what, but why they need it
3. **Consider Scope Boundaries**: What's in vs out of this issue
4. **Find All Affected Files**: Feature touches many layers
5. **Plan for Backward Compatibility**: Nullable fields, graceful handling
6. **Think About Edge Cases**: Null values, invalid data, UI constraints
7. **Prepare Code Examples**: Makes Phase 2 implementation smoother
8. **Consider Future Extensions**: Note what's out of scope for later
