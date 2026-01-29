# Feature Specification: Shopping List Generation

**Issue:** #5
**Milestone:** 0.1.6
**Status:** Planning
**Estimated Effort:** 8 points (12-16 hours)
**Last Updated:** 2026-01-26

---

## Table of Contents

1. [Overview](#overview)
2. [Scope Decisions](#scope-decisions)
3. [Data Model](#data-model)
4. [Business Logic](#business-logic)
5. [User Interface](#user-interface)
6. [Implementation Phases](#implementation-phases)
7. [Testing Requirements](#testing-requirements)
8. [Edge Cases](#edge-cases)
9. [Future Enhancements](#future-enhancements)

---

## Overview

### Goal
Complete the core meal planning → shopping workflow by enabling users to generate shopping lists from their weekly meal plans.

### User Story
As a user, I want to generate a shopping list from my meal plan so that I know what ingredients to buy for the planned meals.

### Success Criteria
- ✅ Generate shopping list from meal plan date range
- ✅ Aggregate identical ingredients with basic metric conversions
- ✅ Group items by category for easier shopping
- ✅ Mark items as purchased/unpurchased
- ✅ Handle "to taste" ingredients appropriately
- ✅ Exclude common staples per "salt rule"

---

## Scope Decisions

### In Scope (MVP)

#### 1. Aggregation
- **Exact ingredient name matching** (case-insensitive)
- **Basic metric unit conversion:**
  - Weight: g ↔ kg
  - Volume: ml ↔ L
  - Example: 200g flour + 1kg flour = 1200g = 1.2kg
- **Display rule:** Auto-convert to larger unit if total ≥1000
  - 1200g → 1.2kg
  - 1100ml → 1.1L

#### 2. Persistence
- Lists persist in database (accumulate over time)
- No automatic cleanup/archiving
- No 1:1 enforcement with meal plans
- UI shows only "current/latest" list
- Old lists remain in database (future: history viewer)

#### 3. Regeneration
- **Behavior:** If list exists for date range, show confirmation dialog
- **Dialog:** "You have a shopping list from [date]. Regenerate? This will create a new list."
- **Result:** Creates new list, old list remains in DB but not shown in UI

#### 4. Data Model
- **Time-period-centric** (not meal-plan-centric)
- Lists defined by date range (startDate, endDate)
- Supports future use case: custom date ranges (e.g., "this week + 3 days next week")
- MVP: Uses meal plan's date range (currently Friday-Thursday)

#### 5. Categories
- Use existing ingredient categories from database
- Group items by category in UI (collapsible sections)
- Single list with category sections
- User manually separates by store (feira vs supermarket)

#### 6. "To Taste" & Exclusions (The "Salt Rule")
- **"To taste" identification:** Ingredients with quantity = 0
- **Exclusion rule:** Exclude if quantity = 0 AND in exclusion list
- **Exclusion list:** Salt, Water, Oil, Black Pepper, Sugar
- **Important:** Include if quantity > 0 even if in exclusion list
  - Example: "2 cups oil" → appears in list
  - Example: "oil to taste" → excluded
- **Display remaining "to taste":** Show with warning indicator
  - Example: `☐ Oregano - to taste ⚠️`

#### 7. User Flow
1. User in WeeklyPlanScreen clicks "Generate Shopping List"
2. System uses meal plan's date range
3. System checks for existing list in that range
4. If exists: show regeneration confirmation
5. Generate list: fetch meals → extract ingredients → aggregate → exclude → group → save
6. Navigate to ShoppingListScreen
7. User can check/uncheck items as purchased

### Out of Scope (Deferred)

#### Deferred to 0.2.0+
- ❌ Complex unit conversions (cups ↔ ml, tbsp ↔ tsp, oz ↔ g)
- ❌ Custom date range picker (beyond current meal plan)
- ❌ Shopping place assignment (feira, supermarket, fish house, etc.)
- ❌ Multiple concurrent lists / list history browser
- ❌ Manual quantity editing in shopping list
- ❌ Export/share functionality (PDF, print, email)
- ❌ Fuzzy ingredient matching (flour vs all-purpose flour)
- ❌ Garbage collection / archiving mechanism
- ❌ User-configurable pantry staples (exclusion list)
- ❌ Recipe-level notes or comments on list
- ❌ Aisle organization within stores

---

## Data Model

### Database Schema

#### ShoppingList Table
```sql
CREATE TABLE shopping_lists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,              -- e.g., "Jan 24-30"
  date_created INTEGER NOT NULL,   -- Unix timestamp
  start_date INTEGER NOT NULL,     -- Unix timestamp (period start)
  end_date INTEGER NOT NULL        -- Unix timestamp (period end)
);
```

#### ShoppingListItem Table
```sql
CREATE TABLE shopping_list_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  shopping_list_id INTEGER NOT NULL,
  ingredient_name TEXT NOT NULL,
  quantity REAL NOT NULL,
  unit TEXT NOT NULL,
  category TEXT NOT NULL,          -- From ingredient.category
  is_purchased INTEGER NOT NULL DEFAULT 0,  -- 0 = false, 1 = true
  FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(id)
);
```

### Dart Models

```dart
class ShoppingList {
  final int? id;
  final String name;
  final DateTime dateCreated;
  final DateTime startDate;
  final DateTime endDate;

  ShoppingList({
    this.id,
    required this.name,
    required this.dateCreated,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap();
  factory ShoppingList.fromMap(Map<String, dynamic> map);
}

class ShoppingListItem {
  final int? id;
  final int shoppingListId;
  final String ingredientName;
  final double quantity;
  final String unit;
  final String category;
  final bool isPurchased;

  ShoppingListItem({
    this.id,
    required this.shoppingListId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isPurchased = false,
  });

  Map<String, dynamic> toMap();
  factory ShoppingListItem.fromMap(Map<String, dynamic> map);
  ShoppingListItem copyWith({bool? isPurchased});
}
```

---

## Business Logic

### Generation Algorithm

**High-level flow:**
```
1. Input: Date range (startDate, endDate)
2. Query all meal plan items in date range
3. Extract all recipes from meal plan items
4. Extract all ingredients from recipes
5. Apply exclusion rule (salt rule)
6. Aggregate ingredients (exact match + unit conversion)
7. Group by category
8. Create ShoppingList and ShoppingListItems
9. Save to database
10. Return ShoppingList ID
```

### Detailed Steps

#### Step 1: Fetch Meal Plan Items
```dart
// Get all meal plan items within date range
final mealPlanItems = await dbHelper.getMealPlanItemsInRange(
  startDate: startDate,
  endDate: endDate,
);
```

#### Step 2: Extract Ingredients
```dart
// For each meal plan item:
//   - Get the meal
//   - Get all recipes in the meal (via MealRecipe junction)
//   - Get all ingredients for each recipe (via RecipeIngredient junction)
//   - Include ingredient details (name, quantity, unit, category)

List<IngredientData> allIngredients = [];
for (var item in mealPlanItems) {
  final meal = await dbHelper.getMeal(item.mealId);
  final recipes = await dbHelper.getRecipesForMeal(meal.id);
  for (var recipe in recipes) {
    final ingredients = await dbHelper.getIngredientsForRecipe(recipe.id);
    allIngredients.addAll(ingredients);
  }
}
```

#### Step 3: Apply Exclusion Rule (Salt Rule)
```dart
const excludedStaples = ['Salt', 'Water', 'Oil', 'Black Pepper', 'Sugar'];

final filteredIngredients = allIngredients.where((ingredient) {
  // Exclude if quantity = 0 (to taste) AND in exclusion list
  if (ingredient.quantity == 0 &&
      excludedStaples.contains(ingredient.name)) {
    return false;
  }
  return true;
}).toList();
```

#### Step 4: Aggregate Ingredients

**Aggregation rules:**
1. Group by ingredient name (case-insensitive)
2. Within each group, convert to common unit
3. Sum quantities
4. Choose display unit

**Pseudocode:**
```dart
Map<String, AggregatedIngredient> aggregated = {};

for (var ingredient in filteredIngredients) {
  final key = ingredient.name.toLowerCase();

  if (!aggregated.containsKey(key)) {
    aggregated[key] = AggregatedIngredient(
      name: ingredient.name,
      quantity: 0,
      unit: ingredient.unit,
      category: ingredient.category,
    );
  }

  // Convert to common unit and add
  final existing = aggregated[key];
  final convertedQuantity = convertToCommonUnit(
    ingredient.quantity,
    ingredient.unit,
    existing.unit,
  );

  existing.quantity += convertedQuantity;
}

// Convert to display units (kg if ≥1000g, L if ≥1000ml)
for (var item in aggregated.values) {
  if (item.unit == 'g' && item.quantity >= 1000) {
    item.quantity /= 1000;
    item.unit = 'kg';
  } else if (item.unit == 'ml' && item.quantity >= 1000) {
    item.quantity /= 1000;
    item.unit = 'L';
  }
}
```

#### Step 5: Unit Conversion Logic

**Simple metric conversions:**
```dart
double convertToCommonUnit(double quantity, String fromUnit, String toUnit) {
  // Normalize to lowercase
  fromUnit = fromUnit.toLowerCase();
  toUnit = toUnit.toLowerCase();

  if (fromUnit == toUnit) return quantity;

  // Weight conversions
  if ((fromUnit == 'g' && toUnit == 'kg') || (fromUnit == 'kg' && toUnit == 'g')) {
    if (fromUnit == 'kg') {
      return quantity * 1000; // kg to g
    } else {
      return quantity; // Already in target unit, will be converted later
    }
  }

  // Volume conversions
  if ((fromUnit == 'ml' && toUnit == 'l') || (fromUnit == 'l' && toUnit == 'ml')) {
    if (fromUnit == 'l') {
      return quantity * 1000; // L to ml
    } else {
      return quantity; // Already in target unit
    }
  }

  // If units don't match and no conversion available, keep separate
  throw UnitConversionException('Cannot convert $fromUnit to $toUnit');
}
```

**Handling non-convertible units:**
- If two items have same ingredient name but incompatible units (e.g., "2 cups flour" + "500g flour")
- Keep as separate items (no aggregation)
- This is acceptable for MVP (user will see both and can manually combine if needed)

#### Step 6: Group by Category
```dart
Map<String, List<ShoppingListItem>> groupedByCategory = {};

for (var ingredient in aggregated.values) {
  if (!groupedByCategory.containsKey(ingredient.category)) {
    groupedByCategory[ingredient.category] = [];
  }
  groupedByCategory[ingredient.category].add(
    ShoppingListItem(
      shoppingListId: shoppingListId,
      ingredientName: ingredient.name,
      quantity: ingredient.quantity,
      unit: ingredient.unit,
      category: ingredient.category,
      isPurchased: false,
    ),
  );
}
```

#### Step 7: Handle "To Taste" Display
```dart
// For ingredients with quantity = 0 that weren't excluded:
if (ingredient.quantity == 0) {
  // Display as "to taste" with warning indicator
  // Store quantity as 0, unit as empty string or "to taste"
  items.add(ShoppingListItem(
    ingredientName: ingredient.name,
    quantity: 0,
    unit: 'to taste',
    category: ingredient.category,
    isPurchased: false,
  ));
}
```

### Service Layer

**ShoppingListService:**
```dart
class ShoppingListService {
  final DatabaseHelper dbHelper;

  Future<ShoppingList> generateFromDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // 1. Check for existing list in range
    final existing = await dbHelper.getShoppingListForDateRange(startDate, endDate);

    // 2. If exists, return it (regeneration handled at UI level)
    if (existing != null) {
      return existing;
    }

    // 3. Generate new list
    final ingredients = await _extractIngredientsInRange(startDate, endDate);
    final filtered = _applyExclusionRule(ingredients);
    final aggregated = _aggregateIngredients(filtered);
    final grouped = _groupByCategory(aggregated);

    // 4. Create and save
    final shoppingList = ShoppingList(
      name: _generateListName(startDate, endDate),
      dateCreated: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
    );

    final listId = await dbHelper.insertShoppingList(shoppingList);

    for (var category in grouped.entries) {
      for (var item in category.value) {
        await dbHelper.insertShoppingListItem(
          item.copyWith(shoppingListId: listId),
        );
      }
    }

    return shoppingList.copyWith(id: listId);
  }

  Future<void> toggleItemPurchased(int itemId) async {
    final item = await dbHelper.getShoppingListItem(itemId);
    await dbHelper.updateShoppingListItem(
      item.copyWith(isPurchased: !item.isPurchased),
    );
  }

  String _generateListName(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM d');
    return '${formatter.format(start)}-${end.day}';
  }
}
```

---

## User Interface

### Access Point

**WeeklyPlanScreen:**
- Add floating action button (FAB) with shopping cart icon
- Label: "Generate Shopping List"
- On tap: Check for existing list → show confirmation if needed → generate → navigate

**Alternative considered but deferred:**
- Tab in WeeklyPlanScreen (alongside "Plan" and "Summary")
- Reason for FAB: Simpler for MVP, doesn't clutter tab bar

### ShoppingListScreen

**Layout:**
```
┌─────────────────────────────────────┐
│ Shopping List - Jan 24-30      [×]  │ ← App bar
├─────────────────────────────────────┤
│ ▼ Vegetables & Fruits              │ ← Collapsible category
│   ☐ Tomato - 500g                  │
│   ☐ Onion - 3 units                │
│   ☑ Lettuce - 1 unit               │ ← Checked (purchased)
│                                     │
│ ▼ Proteins                         │
│   ☐ Chicken breast - 600g          │
│   ☐ Salmon - 400g                  │
│                                     │
│ ▼ Dairy                            │
│   ☐ Milk - 1L                      │
│   ☐ Cheese - 200g                  │
│                                     │
│ ▼ Grains & Flours                  │
│   ☐ Rice - 500g                    │
│   ☐ Flour - 1.2kg                  │ ← Aggregated & converted
│                                     │
│ ▼ Spices & Seasonings             │
│   ☐ Oregano - to taste ⚠️          │ ← "To taste" indicator
│   ☐ Garlic - 6 cloves              │
└─────────────────────────────────────┘
```

**Interactions:**
- Tap checkbox: Toggle purchased state
- Tap item: No action in MVP (future: edit quantity)
- Tap category header: Expand/collapse section
- No quantity editing in MVP

### Regeneration Dialog

```
┌─────────────────────────────────────┐
│ Shopping List Exists                │
├─────────────────────────────────────┤
│                                     │
│ You already have a shopping list    │
│ for Jan 24-30 created on Jan 24.   │
│                                     │
│ Generate a new list? This will     │
│ create a fresh list.                │
│                                     │
│         [Cancel]  [Regenerate]      │
└─────────────────────────────────────┘
```

### Localization

**Strings to add:**

**English (app_en.arb):**
```json
{
  "shoppingListTitle": "Shopping List",
  "generateShoppingList": "Generate Shopping List",
  "shoppingListExists": "Shopping List Exists",
  "shoppingListExistsMessage": "You already have a shopping list for {dateRange} created on {date}. Generate a new list? This will create a fresh list.",
  "regenerate": "Regenerate",
  "toTaste": "to taste",
  "markPurchased": "Mark as purchased",
  "markUnpurchased": "Mark as unpurchased",
  "emptyShoppingList": "No items in this shopping list",
  "noMealsPlanned": "No meals planned for this period"
}
```

**Portuguese (app_pt.arb):**
```json
{
  "shoppingListTitle": "Lista de Compras",
  "generateShoppingList": "Gerar Lista de Compras",
  "shoppingListExists": "Lista de Compras Existe",
  "shoppingListExistsMessage": "Você já tem uma lista de compras para {dateRange} criada em {date}. Gerar uma nova lista? Isso criará uma lista nova.",
  "regenerate": "Regenerar",
  "toTaste": "a gosto",
  "markPurchased": "Marcar como comprado",
  "markUnpurchased": "Marcar como não comprado",
  "emptyShoppingList": "Nenhum item nesta lista de compras",
  "noMealsPlanned": "Nenhuma refeição planejada para este período"
}
```

---

## Implementation Phases

### Phase 1: Data & Database (Day 1, ~4-5 hours)

**Tasks:**
1. Create `ShoppingList` model (`lib/models/shopping_list.dart`)
   - Fields: id, name, dateCreated, startDate, endDate
   - Methods: toMap, fromMap, copyWith
   - Tests: model serialization

2. Create `ShoppingListItem` model (`lib/models/shopping_list_item.dart`)
   - Fields: id, shoppingListId, ingredientName, quantity, unit, category, isPurchased
   - Methods: toMap, fromMap, copyWith
   - Tests: model serialization

3. Database migration
   - Add to `DatabaseHelper._onCreate` or create migration
   - Create `shopping_lists` table
   - Create `shopping_list_items` table
   - Test: verify tables created

4. Add CRUD operations to `DatabaseHelper`
   - `insertShoppingList(ShoppingList)` → int
   - `getShoppingList(int id)` → ShoppingList?
   - `getShoppingListForDateRange(DateTime start, DateTime end)` → ShoppingList?
   - `deleteShoppingList(int id)` → void
   - `insertShoppingListItem(ShoppingListItem)` → int
   - `getShoppingListItem(int id)` → ShoppingListItem?
   - `getShoppingListItems(int shoppingListId)` → List<ShoppingListItem>
   - `updateShoppingListItem(ShoppingListItem)` → void
   - `deleteShoppingListItem(int id)` → void
   - Tests: CRUD operations with MockDatabaseHelper

**Deliverable:** Models and database layer ready, fully tested

---

### Phase 2: Generation Algorithm & Service (Day 2, ~5-6 hours)

**Tasks:**
1. Create `ShoppingListService` (`lib/services/shopping_list_service.dart`)
   - Constructor with DatabaseHelper dependency
   - Basic structure

2. Implement unit conversion helper
   - `_convertToCommonUnit(double quantity, String fromUnit, String toUnit)` → double
   - Support: g↔kg, ml↔L
   - Return original if no conversion possible (will keep items separate)
   - Tests: all conversion cases

3. Implement exclusion rule (salt rule)
   - `_applyExclusionRule(List<Ingredient>)` → List<Ingredient>
   - Exclusion list: Salt, Water, Oil, Black Pepper, Sugar
   - Logic: exclude if quantity == 0 AND name in list
   - Tests: various scenarios

4. Implement aggregation logic
   - `_aggregateIngredients(List<Ingredient>)` → Map<String, AggregatedIngredient>
   - Group by name (case-insensitive)
   - Apply unit conversions within groups
   - Sum quantities
   - Convert to display units (≥1000g → kg, ≥1000ml → L)
   - Tests: exact matches, unit conversions, display conversions, incompatible units

5. Implement grouping by category
   - `_groupByCategory(Map<String, AggregatedIngredient>)` → Map<String, List<ShoppingListItem>>
   - Tests: verify grouping

6. Implement main generation method
   - `generateFromDateRange(DateTime start, DateTime end)` → Future<ShoppingList>
   - Integrate all steps
   - Query meal plan items in range
   - Extract ingredients from recipes
   - Apply exclusion, aggregation, grouping
   - Save to database
   - Tests: integration test with mock database

7. Implement toggle purchased
   - `toggleItemPurchased(int itemId)` → Future<void>
   - Tests: verify state change

8. Add to ServiceProvider
   - Create ShoppingListServiceProvider
   - Register in ServiceProvider initialization
   - Access via: `ServiceProvider.shoppingList.service`

**Deliverable:** Fully functional generation algorithm, well-tested

---

### Phase 3: UI Implementation (Day 3, ~4-5 hours)

**Tasks:**
1. Create `ShoppingListScreen` (`lib/screens/shopping_list_screen.dart`)
   - StatefulWidget
   - Receive shoppingListId in constructor
   - Load shopping list and items on init
   - Display loading state

2. Implement category grouping UI
   - Use `ExpansionTile` for each category
   - Show category name and item count
   - All expanded by default

3. Implement item display
   - `CheckboxListTile` for each item
   - Display: ingredientName - quantity unit
   - Handle "to taste" display (quantity == 0 → show "to taste ⚠️")
   - Wire checkbox to toggleItemPurchased

4. Add to WeeklyPlanScreen
   - Add FloatingActionButton with shopping cart icon
   - Label: AppLocalizations.of(context)!.generateShoppingList
   - On tap: call generation logic

5. Implement generation flow in WeeklyPlanScreen
   - Get current meal plan date range
   - Check for existing list (via service)
   - If exists: show confirmation dialog
   - Generate list
   - Navigate to ShoppingListScreen

6. Create regeneration confirmation dialog
   - Show list date range and creation date
   - Buttons: Cancel, Regenerate
   - If Regenerate: proceed with generation

7. Handle empty states
   - No meals in date range: show message
   - No ingredients after filtering: show message

8. Add localization
   - Update app_en.arb
   - Update app_pt.arb
   - Run `flutter gen-l10n`

**Deliverable:** Complete UI, integrated with weekly plan screen, localized

---

### Phase 4: Testing & Polish (Ongoing + Final Day)

**Tasks:**

**Unit Tests:**
- `test/models/shopping_list_test.dart`
  - Model serialization (toMap, fromMap)
  - copyWith functionality

- `test/models/shopping_list_item_test.dart`
  - Model serialization
  - copyWith functionality

- `test/services/shopping_list_service_test.dart`
  - Unit conversion logic
  - Exclusion rule (salt rule)
  - Aggregation algorithm (exact matches, conversions)
  - Display unit conversion (≥1000)
  - Grouping by category
  - Generation integration (with MockDatabaseHelper)
  - Toggle purchased state

- `test/database/shopping_list_crud_test.dart`
  - All CRUD operations
  - Foreign key constraints
  - Date range queries

**Widget Tests:**
- `test/widgets/shopping_list_screen_test.dart`
  - Display shopping list with categories
  - Checkbox interaction
  - "To taste" display
  - Empty state display
  - Loading state

- `test/widgets/weekly_plan_screen_test.dart` (update existing)
  - FAB visibility
  - Generation flow
  - Regeneration confirmation dialog

**Integration Tests:**
- `test/integration/shopping_list_workflow_test.dart`
  - Full workflow: plan meals → generate list → verify items → toggle purchased
  - Test aggregation with real recipes
  - Test category grouping
  - Test regeneration

**Edge Case Tests:**
- Empty meal plan (no meals in range)
- Recipes with no ingredients
- All ingredients excluded by salt rule
- Mixed units (g and kg together)
- Non-convertible units (cups and g)
- "To taste" ingredients
- Very large quantities (edge of numeric limits)
- Duplicate ingredients in same recipe
- Same ingredient across multiple recipes

**Polish:**
- Review UI with localization in both languages
- Verify category sections look good with various item counts
- Ensure smooth performance with large shopping lists (50+ items)
- Test on small screens (ensure no overflow)
- Verify accessibility (checkbox labels, screen reader support)

**Deliverable:** Comprehensive test coverage, polished UI, all edge cases handled

---

## Testing Requirements

### Test Coverage Goals
- Unit tests: >90% coverage for service layer
- Widget tests: All user-facing screens
- Integration tests: Complete workflow
- Edge cases: All known scenarios documented and tested

### Key Test Scenarios

#### Unit Tests - Aggregation Algorithm
```dart
test('combines same ingredient with same unit', () {
  // 200g flour + 500g flour = 700g flour
});

test('converts and combines compatible units', () {
  // 200g flour + 1kg flour = 1200g = 1.2kg flour
});

test('keeps separate if units incompatible', () {
  // 2 cups flour + 500g flour = 2 separate items
});

test('displays larger unit when quantity >= 1000', () {
  // 1500g → 1.5kg
  // 2500ml → 2.5L
});
```

#### Unit Tests - Exclusion Rule
```dart
test('excludes salt with quantity 0', () {
  // Salt - to taste → excluded
});

test('includes salt with quantity > 0', () {
  // Salt - 5g → included
});

test('excludes all items in exclusion list when to taste', () {
  // Water, Oil, Black Pepper, Sugar - to taste → all excluded
});

test('includes non-excluded to taste items', () {
  // Oregano - to taste → included (with warning)
});
```

#### Widget Tests - Shopping List Screen
```dart
testWidgets('displays items grouped by category', (tester) async {
  // Verify ExpansionTile per category
  // Verify items within categories
});

testWidgets('toggles purchased state on checkbox tap', (tester) async {
  // Tap checkbox
  // Verify state change
  // Verify database updated
});

testWidgets('displays to taste items with indicator', (tester) async {
  // Find item with quantity = 0
  // Verify "to taste ⚠️" displayed
});

testWidgets('shows empty state when no items', (tester) async {
  // Empty shopping list
  // Verify empty message displayed
});
```

#### Integration Tests - Full Workflow
```dart
testWidgets('complete shopping list workflow', (tester) async {
  // 1. Create meal plan with multiple recipes
  // 2. Navigate to WeeklyPlanScreen
  // 3. Tap "Generate Shopping List" FAB
  // 4. Verify ShoppingListScreen displayed
  // 5. Verify correct items with aggregation
  // 6. Tap checkboxes
  // 7. Verify persistence
  // 8. Navigate back to WeeklyPlanScreen
  // 9. Regenerate (confirm dialog)
  // 10. Verify new list created
});
```

#### Edge Case Tests
```dart
test('handles empty meal plan gracefully', () {
  // No meals in date range → empty shopping list or message
});

test('handles recipe with no ingredients', () {
  // Recipe with 0 ingredients → skip in list generation
});

test('handles all ingredients excluded', () {
  // All items are salt/water/etc to taste → empty list message
});

test('handles very large quantities', () {
  // 50000g → 50kg (verify numeric precision)
});

test('handles duplicate ingredients in same recipe', () {
  // Recipe has flour twice (shouldn't happen but handle gracefully)
});
```

---

## Edge Cases

### Data Edge Cases

#### 1. Empty Meal Plan
- **Scenario:** User generates list for date range with no planned meals
- **Behavior:** Show message "No meals planned for this period"
- **Implementation:** Check if mealPlanItems.isEmpty before processing

#### 2. Recipe Without Ingredients
- **Scenario:** Recipe has no ingredients (edge case, but possible)
- **Behavior:** Skip recipe silently, don't fail
- **Implementation:** Handle empty ingredients list gracefully

#### 3. All Ingredients Excluded
- **Scenario:** All ingredients are "to taste" staples (salt, water, etc.)
- **Behavior:** Show empty list with message "No items to purchase"
- **Implementation:** Check if filtered ingredients list is empty

#### 4. Duplicate Ingredients in Same Recipe
- **Scenario:** Recipe has same ingredient listed twice (data error)
- **Behavior:** Aggregate them as normal
- **Implementation:** Aggregation logic handles this naturally

#### 5. Very Large Quantities
- **Scenario:** Aggregated quantity is very large (e.g., 50000g)
- **Behavior:** Convert correctly (50kg), ensure no overflow
- **Implementation:** Use double for quantities, test edge values

#### 6. Mixed Measurement Systems
- **Scenario:** "2 cups flour" + "500g flour"
- **Behavior:** Keep as separate items (no conversion)
- **Implementation:** convertToCommonUnit throws exception, catch and keep separate

### Unit Conversion Edge Cases

#### 7. Fractional Display Units
- **Scenario:** 1200g → 1.2kg (fractional display)
- **Behavior:** Display with appropriate precision (1 decimal place)
- **Implementation:** Format with NumberFormat or round to 1 decimal

#### 8. Borderline Conversion (999g)
- **Scenario:** 999g (just under 1000g threshold)
- **Behavior:** Display as 999g (don't convert)
- **Implementation:** Only convert if >= 1000

#### 9. Exact Conversion (1000g)
- **Scenario:** Exactly 1000g
- **Behavior:** Display as 1kg
- **Implementation:** >= comparison includes equals

### "To Taste" Edge Cases

#### 10. Non-Excluded "To Taste"
- **Scenario:** Oregano - to taste (not in exclusion list)
- **Behavior:** Include with warning indicator
- **Implementation:** Filter only removes excluded items with qty=0

#### 11. Excluded with Quantity
- **Scenario:** Salt - 5g (in exclusion list but has quantity)
- **Behavior:** Include in list (exclusion only applies to qty=0)
- **Implementation:** Both conditions must be true to exclude

#### 12. Zero Quantity Non-Staple
- **Scenario:** Expensive spice - to taste
- **Behavior:** Include with warning (user should remember to buy)
- **Implementation:** Same as #10

### UI Edge Cases

#### 13. Empty Category
- **Scenario:** Category exists but all items filtered out
- **Behavior:** Don't show empty category section
- **Implementation:** Filter categories with empty item lists

#### 14. Very Long Ingredient Name
- **Scenario:** "Extra virgin cold-pressed olive oil from Greece"
- **Behavior:** Text wraps properly, doesn't overflow
- **Implementation:** Use flexible text widgets, test on small screens

#### 15. Many Categories (Long List)
- **Scenario:** 10+ categories with many items each
- **Behavior:** Scrollable, performant
- **Implementation:** Use ListView.builder, test with 50+ items

#### 16. Special Characters in Names
- **Scenario:** Ingredient name with accents, symbols (e.g., "açúcar", "jalapeño")
- **Behavior:** Display correctly, match correctly
- **Implementation:** Use UTF-8, test with Portuguese characters

### Workflow Edge Cases

#### 17. Rapid Regeneration
- **Scenario:** User taps "Regenerate" multiple times quickly
- **Behavior:** Don't create duplicate lists
- **Implementation:** Disable button during generation, use async lock

#### 18. Navigation During Generation
- **Scenario:** User navigates away while list is generating
- **Behavior:** Complete generation in background or cancel gracefully
- **Implementation:** Handle async properly, no orphaned data

#### 19. Database Error During Save
- **Scenario:** DB write fails (disk full, corruption, etc.)
- **Behavior:** Show error message, don't navigate to broken list
- **Implementation:** Wrap in try-catch, show error dialog, rollback if needed

#### 20. Concurrent List Generation
- **Scenario:** Multiple devices/sessions generating lists simultaneously (future)
- **Behavior:** For MVP, not applicable (single device)
- **Implementation:** Defer to multi-user sync in future

### Data Integrity Edge Cases

#### 21. Orphaned Shopping List Items
- **Scenario:** ShoppingList deleted but items remain (shouldn't happen)
- **Behavior:** Prevent via foreign key constraints
- **Implementation:** Database schema enforces referential integrity

#### 22. Missing Ingredient Category
- **Scenario:** Ingredient has null or invalid category
- **Behavior:** Use default category "Other" or "Uncategorized"
- **Implementation:** Null coalescing: `category ?? 'Other'`

#### 23. Invalid Date Range
- **Scenario:** endDate before startDate (shouldn't happen)
- **Behavior:** Validation error or swap dates
- **Implementation:** Validate in service layer, throw ValidationException

---

## Future Enhancements

### Short-term (0.2.0)
- Custom date range picker (select arbitrary date ranges)
- Shopping list history viewer
- Manual quantity editing
- User-configurable pantry staples (customize exclusion list)

### Medium-term (0.3.0)
- Shopping place assignment (feira, supermarket, fish house, etc.)
- Generate separate lists per place
- Export functionality (share via messaging, email, print)
- Complex unit conversions (cups ↔ ml with ingredient density lookup)

### Long-term (0.4.0+)
- Fuzzy ingredient matching (flour vs all-purpose flour)
- Price tracking and budgeting
- Store aisle organization
- Barcode scanning for purchased items
- Voice-activated checkbox toggling
- Smart suggestions based on purchase history
- Integration with delivery services

### Architectural Enhancements
- Garbage collection for old shopping lists
- Archive functionality
- Search within shopping lists
- Multiple concurrent lists
- Collaborative shopping (multi-user sync)
- Offline-first with cloud sync

---

## Implementation Notes

### Code Organization
```
lib/
├── models/
│   ├── shopping_list.dart
│   └── shopping_list_item.dart
├── services/
│   └── shopping_list_service.dart
├── screens/
│   └── shopping_list_screen.dart
└── core/
    └── di/
        └── service_provider.dart (update)

test/
├── models/
│   ├── shopping_list_test.dart
│   └── shopping_list_item_test.dart
├── services/
│   └── shopping_list_service_test.dart
├── widgets/
│   └── shopping_list_screen_test.dart
├── integration/
│   └── shopping_list_workflow_test.dart
└── edge_cases/
    └── shopping_list_edge_cases_test.dart
```

### Dependencies
- No new external dependencies needed
- Use existing: sqflite, provider, intl

### Performance Considerations
- For MVP: In-memory aggregation is fine (meal plans are typically small)
- Future: If performance issues arise, optimize with:
  - Batch database queries
  - Streaming results for large lists
  - Background computation for aggregation

### Accessibility
- Ensure checkboxes have semantic labels
- Category headers should be properly announced by screen readers
- Test with TalkBack (Android) and VoiceOver (iOS) if possible

### Localization Notes
- Date formatting should respect locale
- Decimal separators (1.2kg vs 1,2kg) should use locale
- "To taste" translation in Portuguese: "a gosto"

---

## Definition of Done

- ✅ All models created and tested
- ✅ Database tables created with proper schema
- ✅ All CRUD operations implemented and tested
- ✅ Generation algorithm implemented with unit conversions
- ✅ Exclusion rule (salt rule) working correctly
- ✅ Aggregation logic handles all edge cases
- ✅ Category grouping functional
- ✅ ShoppingListScreen displays items correctly
- ✅ Checkbox interaction updates database
- ✅ "To taste" items display with indicator
- ✅ Integration with WeeklyPlanScreen (FAB)
- ✅ Regeneration dialog functional
- ✅ All localization strings added (EN + PT)
- ✅ Unit tests pass (>90% coverage for service layer)
- ✅ Widget tests pass (all UI scenarios)
- ✅ Integration test passes (full workflow)
- ✅ Edge cases tested and handled
- ✅ Code review passed
- ✅ `flutter analyze` shows no warnings
- ✅ Manual testing on device completed
- ✅ Documentation updated (this file, CHANGELOG.md)

---

## References

- Issue: #5
- Roadmap: docs/planning/ROADMAP-0.1.6.md
- Architecture: docs/architecture/Gastrobrain-Codebase-Overview.md
- Localization: docs/workflows/L10N_PROTOCOL.md
- Testing Guides:
  - docs/testing/DIALOG_TESTING_GUIDE.md
  - docs/testing/EDGE_CASE_TESTING_GUIDE.md
  - docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md

---

**Document Status:** Planning Complete - Ready for Implementation
**Next Step:** Begin Phase 1 - Data & Database implementation
