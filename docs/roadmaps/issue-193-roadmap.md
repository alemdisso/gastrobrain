# Issue #193 — Ingredient Detail Screen (Used In tab)

| Field       | Value                                      |
|-------------|--------------------------------------------|
| Type        | Feature / UI                               |
| Priority    | P2 Medium                                  |
| Size        | M (2-4 hours)                              |
| Estimate    | 3 points                                   |
| Milestone   | 0.2.3 - UX Polish                          |
| Dependencies| None                                       |

---

## Overview

No ingredient detail screen exists today. This issue builds a tabbed
`IngredientDetailScreen` and implements the first tab: **Used In** — the list
of recipes that contain the ingredient, with name, category, difficulty, rating,
quantity used, and an incomplete indicator for recipes with < 3 ingredients.
Foundation for #329 (Meal History tab).

---

## Phase 1: Analysis ✅

**Technical decisions:**
- `getRecipesByIngredientId` returns `List<Map<String, dynamic>>` — mirrors
  `getRecipeIngredients()` shape; includes `usage_quantity` and `ingredient_count`
- `TabController(length: 1)` with TabBar visible — foundation for #329
- Tab style mirrors `RecipeDetailsScreen` (SingleTickerProviderStateMixin)
- InkWell wraps the list item row in `IngredientsScreen`, not conflicting with
  the trailing `PopupMenuButton`

**Key patterns:**
| Pattern | Reference |
|---------|-----------|
| Tabbed screen | `lib/screens/recipe_details_screen.dart` |
| DB rawQuery JOIN | `getRecipeIngredients()` in `database_helper.dart:1081` |
| Incomplete threshold | `getEnrichedRecipeCount()` — `COUNT >= 3` |
| Mock rawQuery | `getRecipeIngredients()` in `mock_database_helper.dart:853` |

---

## Phase 2: Implementation

### 2.1 — `lib/database/database_helper.dart`
- [x] Add `getRecipesByIngredientId(String ingredientId)` returning
  `Future<List<Map<String, dynamic>>>`:
  ```sql
  SELECT r.*, ri.quantity AS usage_quantity,
    (SELECT COUNT(*) FROM recipe_ingredients WHERE recipe_id = r.id) AS ingredient_count
  FROM recipes r
  JOIN recipe_ingredients ri ON r.id = ri.recipe_id
  WHERE ri.ingredient_id = ?
  ORDER BY r.name ASC
  ```

### 2.2 — `test/mocks/mock_database_helper.dart`
- [x] Add mock implementation of `getRecipesByIngredientId`:
  walks `_recipeIngredients` for matching `ingredientId`, fetches recipe from
  `_recipes`, counts all `_recipeIngredients` for that `recipe_id`

### 2.3 — `lib/l10n/app_en.arb` + `app_pt.arb`
- [x] `usedIn` → "Used In" / "Usado Em"
- [x] `usedInNRecipes` (with `{count}`) → "Used in {count} recipes" / "Usado em {count} receitas"
- [x] `noRecipesUsingIngredient` → "This ingredient hasn't been added to any recipes yet." / "Este ingrediente ainda não foi adicionado a nenhuma receita."
- [x] `incompleteRecipe` → "Incomplete" / "Incompleta"
- [x] Run `flutter gen-l10n`

### 2.4 — `lib/screens/ingredient_detail_screen.dart` (NEW)
- [x] `IngredientDetailScreen(ingredient: Ingredient, databaseHelper: DatabaseHelper?)`
- [x] `State` extends `SingleTickerProviderStateMixin`
- [x] `TabController(length: 1)` with listener → `setState`
- [x] `initState`: init DB, init tab, `_loadUsedInData()`
- [x] `_loadUsedInData()`: calls `getRecipesByIngredientId`, sets `_usedInRecipes`
  and `_isLoading`
- [x] AppBar: `ingredient.name` as title, BackButton
- [x] TabBar: single tab with `Icons.menu_book` + l10n `usedIn`
- [x] Used In tab body:
  - If loading → `CircularProgressIndicator`
  - If empty → centered `noRecipesUsingIngredient` text
  - If data → usage count chip + `ListView.builder` of recipe cards
- [x] Recipe card: name (bold), category chip, difficulty (N★), rating (N★),
  quantity row, orange "Incomplete" chip when `ingredient_count < 3`
- [x] Tap card → `Navigator.push(RecipeDetailsScreen(recipe: ...))`

### 2.5 — `lib/screens/ingredients_screen.dart`
- [x] Wrap each list item `Padding` in `InkWell` with `onTap` →
  `Navigator.push(IngredientDetailScreen(ingredient: ingredient))`
- [x] Ensure `PopupMenuButton` still works (it sits inside the InkWell but its
  own tap area takes precedence)

### 2.6 — `flutter analyze`

---

## Phase 3: Testing

- [x] `test/screens/ingredient_detail_screen_test.dart` (new file):
  - Used In tab renders recipe list from mock data
  - Recipe cards show name, category, difficulty, rating, quantity
  - Incomplete chip shown when ingredient_count < 3
  - No incomplete chip when ingredient_count >= 3
  - Empty state shown when no recipes use ingredient
  - Tap recipe card navigates to RecipeDetailsScreen
- [x] `test/database/database_helper_ingredient_test.dart`:
  - `getRecipesByIngredientId` returns correct recipes
  - `getRecipesByIngredientId` returns empty list for unused ingredient
  - `ingredient_count` and `usage_quantity` fields present
- [x] `flutter test` — full suite passes (1786 tests)

---

## Phase 4: Documentation & Cleanup

- [x] `flutter analyze && flutter test`
- [x] Commit: `feat: ingredient detail screen with Used In tab (#193)`
- [x] Merge to develop, close #193, delete branch

---

## Files

```
lib/screens/ingredient_detail_screen.dart   — NEW
lib/database/database_helper.dart           — add getRecipesByIngredientId
test/mocks/mock_database_helper.dart        — add mock impl
lib/screens/ingredients_screen.dart         — add tap navigation
lib/l10n/app_en.arb                         — 4 new keys
lib/l10n/app_pt.arb                         — 4 new keys
```

---

## Acceptance Criteria

- [x] Tapping ingredient in list navigates to `IngredientDetailScreen`
- [x] "Used In" tab shows recipe list with name, category, difficulty, rating, quantity
- [x] Incomplete indicator shown for recipes with < 3 ingredients
- [x] Tapping recipe navigates to `RecipeDetailsScreen`
- [x] Empty state shown when ingredient is in no recipes
- [x] Usage count visible (e.g. "Used in 5 recipes")
- [x] Tab structure ready for #329 (Meal History) to add second tab
