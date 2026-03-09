# Issue #311 Roadmap — Simple Sides (Ingredients as Meal Sides)

**Issue**: enhancement: allow adding ingredients as simple sides to meals without requiring a full recipe
**Milestone**: 0.1.13 - Meal Planning & Shopping Enhancements
**Story Points**: 8 (Medium-High)
**Sprint Days**: Day 2 (data layer) + Day 3 (UI layer)

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary

Users can currently only add full recipes to meals, forcing creation of single-ingredient "recipes" (e.g., a "broccoli" recipe) for common accompaniments. A "simple side" — a bare ingredient linked to the DB or entered as free text — removes this friction while preserving data quality through DB ingredient linking and shopping list integration. Two new DB junction tables (`meal_plan_item_ingredients`, `meal_ingredients`) mirror the existing recipe junction pattern.

### Technical Design Decision

**Selected Approach**: Mirror the existing `MealPlanItemRecipe` / `MealRecipe` junction model pattern with dual-mode linking (`ingredientId` nullable + `customName` fallback, matching `RecipeIngredient`).

**Rationale**:
- Pattern already proven in codebase — zero architectural risk
- Dual-mode keeps free-text and DB-linked in one model without separate tables
- `ON DELETE CASCADE` from parent tables ensures no orphaned records
- No quantity field — "lean toward optional" per sprint plan; shopping list uses quantity=1.0 default

**Alternatives Considered**:
- Separate tables for DB-linked vs free-text: Rejected — unnecessary complexity, dual-mode pattern already established

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| Junction model | `lib/models/meal_plan_item_recipe.dart` | Exact template for `MealPlanItemIngredient` |
| Dual-mode model | `lib/models/recipe_ingredient.dart` (lines 3-10) | `ingredientId` nullable + `customName` fallback |
| Idempotent migration | `lib/core/migration/migrations/009_add_planned_servings.dart` | `CREATE TABLE IF NOT EXISTS` pattern |
| Dialog with data passed in | `lib/widgets/add_side_dish_dialog.dart` | Receives `availableRecipes` list — dialog never touches DB |
| CRUD pattern | `lib/database/database_helper.dart` lines 800-844 | `insertMealPlanItemRecipe` / `deleteMealPlanItemRecipesByItemId` |
| ShoppingList integration | `lib/core/services/shopping_list_service.dart` lines 400-432 | `_extractIngredientsInRange` — add simple sides after recipe loop |

### Code Templates

#### MealPlanItemIngredient model
```dart
import 'package:uuid/uuid.dart';

class MealPlanItemIngredient {
  final String id;
  final String mealPlanItemId;
  final String? ingredientId;  // null = free-text entry
  final String? customName;    // non-null when ingredientId is null
  final String? notes;

  bool get isCustom => ingredientId == null;

  MealPlanItemIngredient({
    String? id,
    required this.mealPlanItemId,
    this.ingredientId,
    this.customName,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  factory MealPlanItemIngredient.fromMap(Map<String, dynamic> map) {
    return MealPlanItemIngredient(
      id: map['id'],
      mealPlanItemId: map['meal_plan_item_id'],
      ingredientId: map['ingredient_id'],
      customName: map['custom_name'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'meal_plan_item_id': mealPlanItemId,
    'ingredient_id': ingredientId,
    'custom_name': customName,
    'notes': notes,
  };

  MealPlanItemIngredient copyWith({...}) => ...
}
```

#### Migration 010
```dart
// Two tables, both idempotent
await db.execute('''
  CREATE TABLE IF NOT EXISTS meal_plan_item_ingredients(
    id TEXT PRIMARY KEY,
    meal_plan_item_id TEXT NOT NULL,
    ingredient_id TEXT,
    custom_name TEXT,
    notes TEXT,
    FOREIGN KEY (meal_plan_item_id) REFERENCES meal_plan_items(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE SET NULL
  )
''');
await db.execute('''
  CREATE TABLE IF NOT EXISTS meal_ingredients(
    id TEXT PRIMARY KEY,
    meal_id TEXT NOT NULL,
    ingredient_id TEXT,
    custom_name TEXT,
    notes TEXT,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE SET NULL
  )
''');
```

#### ShoppingListService integration (in `_extractIngredientsInRange`)
```dart
// After the existing recipe loop, add DB-linked simple sides
final simpleSides = await dbHelper.getMealPlanItemIngredientsForItem(item.id);
for (final side in simpleSides) {
  if (side.ingredientId == null) continue; // free-text: skip
  final ingredient = await dbHelper.getIngredient(side.ingredientId!);
  if (ingredient == null) continue; // ingredient deleted — skip gracefully
  allIngredients.add({
    'name': ingredient.name,
    'quantity': 1.0,
    'unit': ingredient.unit?.value ?? 'unit',
    'category': ingredient.category.value,
  });
}
```

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| Free-text side in shopping list | `ingredientId == null` → `continue` (skip) |
| DB ingredient deleted after used as side | `getIngredient()` returns null → skip in shopping list; UI shows customName fallback |
| Meal with only simple sides (no recipes) | `mealPlanItemRecipes` may be empty — display must not require recipes |
| Empty/whitespace free-text | Reject in dialog before confirming; show inline validation error |
| Mix of recipe sides + simple sides | Show both counts separately in calendar widget |
| Delete simple side | `ON DELETE CASCADE` FK ensures no orphaned records |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| `weekly_plan_screen.dart` already 1019 lines (Critical pre-existing) | Medium | Minimize additions; pre-existing violation noted in backlog |
| `shopping_list_service.dart` already 458 lines (Critical pre-existing) | Medium | #315 will extract UnitConverter + IngredientAggregator after this sprint |
| N+1 queries for simple sides in getMealPlanItems | Low | Acceptable at current scale; JOIN optimization available later |
| FK constraints on new tables | Low | Purely additive — no changes to existing schema |

### Testing Requirements

**Unit Tests** (`test/services/shopping_list_service_test.dart`):
- [ ] DB-linked simple side → appears in shopping list with ingredient's unit/category
- [ ] Free-text simple side → skipped in shopping list (no crash)
- [ ] Deleted DB ingredient → skip gracefully (no crash)
- [ ] Meal with only simple sides → shopping list works

**Unit Tests** (`test/database/database_helper_test.dart` or mock equivalent):
- [ ] `insertMealPlanItemIngredient` → round-trip via `getMealPlanItemIngredientsForItem`
- [ ] `insertMealIngredient` → round-trip via `getMealIngredientsForMeal`
- [ ] Delete parent meal plan item → simple sides auto-deleted (CASCADE)
- [ ] Delete parent meal → meal ingredients auto-deleted (CASCADE)

**Widget Tests** (`test/widgets/add_simple_side_dialog_test.dart`):
- [ ] Select DB ingredient → dialog returns correct `ingredientId` + name
- [ ] Enter free text → dialog returns `ingredientId = null` + `customName`
- [ ] Empty/whitespace free text → submit disabled or validation error shown
- [ ] Notes field → returned in result map
- [ ] Cancel → returns null (no side effects)

**Integration Tests** (`test/integration/`):
- [ ] Add DB-linked simple side to planned meal → appears in meal plan item
- [ ] Add free-text simple side to planned meal → appears in meal plan item
- [ ] Delete simple side → removed cleanly (no orphaned records)
- [ ] Meal with only simple sides handled gracefully (no crash)

### Implementation Checklist (for Phase 2)

**Day 2 — Data Layer:**
- [ ] Step 1: Create `lib/models/meal_plan_item_ingredient.dart`
- [ ] Step 2: Create `lib/models/meal_ingredient.dart`
- [ ] Step 3: Update `lib/models/meal_plan_item.dart` — add `mealPlanItemIngredients` field
- [ ] Step 4: Update `lib/models/meal.dart` — add `mealIngredients` field
- [ ] Step 5: Create `lib/core/migration/migrations/010_add_simple_sides_tables.dart`
- [ ] Step 6: Register `AddSimpleSidesMigration()` in `DatabaseHelper._migrations`
- [ ] Step 7: Add CRUD methods to `DatabaseHelper` (4 methods for planning + 4 for recording)
- [ ] Step 8: Extend `getMealPlanItems` to also load `mealPlanItemIngredients`
- [ ] Step 9: Add `ShoppingListService._extractIngredientsInRange` simple sides integration
- [ ] Step 10: Unit tests for DB CRUD and shopping list integration

**Day 3 — UI Layer:**
- [ ] Step 11: Create `lib/widgets/add_simple_side_dialog.dart`
- [ ] Step 12: Add `_availableIngredients` to `weekly_plan_screen.dart` + load in `_loadData()`
- [ ] Step 13: Add "Add Simple Side" action for planning phase (uncooked meal context menu)
- [ ] Step 14: Add "Add Simple Side" action for recording phase (cooked meal context menu)
- [ ] Step 15: Update `weekly_calendar_widget.dart` — show simple sides count
- [ ] Step 16: Add l10n strings to `app_en.arb` + `app_pt.arb`
- [ ] Step 17: Run `flutter gen-l10n`
- [ ] Step 18: Widget tests for `AddSimpleSideDialog`
- [ ] Step 19: Integration tests (add/delete sides, graceful handling)
- [ ] Step 20: `flutter analyze && flutter test` — full suite

### Files Summary

**To Create:**
- `lib/models/meal_plan_item_ingredient.dart`
- `lib/models/meal_ingredient.dart`
- `lib/core/migration/migrations/010_add_simple_sides_tables.dart`
- `lib/widgets/add_simple_side_dialog.dart`
- `test/widgets/add_simple_side_dialog_test.dart`
- `test/services/shopping_list_simple_sides_test.dart` (or extend existing)

**To Modify:**
- `lib/models/meal_plan_item.dart` — add `mealPlanItemIngredients` field
- `lib/models/meal.dart` — add `mealIngredients` field
- `lib/database/database_helper.dart` — register migration + 8 CRUD methods + extend getMealPlanItems
- `lib/core/services/shopping_list_service.dart` — simple sides in `_extractIngredientsInRange`
- `lib/screens/weekly_plan_screen.dart` — ingredients list load + 2 action handlers + display
- `lib/widgets/weekly_calendar_widget.dart` — simple sides count display
- `lib/l10n/app_en.arb` + `lib/l10n/app_pt.arb` — ~10 new strings

---

## Phase 2: Implementation

> **Status**: Pending — start with `feature/311-simple-sides` branch

*See implementation checklist above*

---

## Phase 3: Testing

> **Status**: Pending — use `gastrobrain-testing-implementation` skill

*See testing requirements in Phase 1 above*

---

## Phase 4: Integration & Documentation

- [ ] `flutter analyze` clean
- [ ] `flutter test` full suite passes
- [ ] All acceptance criteria verified
- [ ] l10n verified EN + PT-BR
- [ ] Merge to `develop`, close issue, clean branch

---

*Phase 1 analysis completed on 2026-03-04*
*Ready for Phase 2 implementation*
