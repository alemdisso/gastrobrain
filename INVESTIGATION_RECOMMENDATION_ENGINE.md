# Recommendation Engine Investigation Report
## How Planned Meals vs. Cooked Meals Are Handled

Generated: 2025-11-06

---

## Executive Summary

The recommendation engine has **significant gaps in how it handles planned meals during meal planning workflows**:

1. **`getRecentMeals()` does NOT differentiate between planned and cooked meals** - it only queries the `meals` table (cooked meals), completely ignoring `meal_plan_items`
2. **`ProteinRotationFactor` only uses cooked meals** - it doesn't consider planned meals in the current week
3. **`VarietyEncouragementFactor` only counts cooked meals** - planned meals are invisible to it
4. **Context building (`_buildContext`) does not include planned meals** - only historical data
5. **Past planned-but-not-cooked meals have NO special handling** - they're ignored everywhere
6. **Planning workflow lacks planned meal awareness** - recommendations don't account for already-scheduled recipes

---

## Detailed Findings

### 1. getRecentMeals() Implementation

**Location:** `lib/core/services/recommendation_database_queries.dart:243-292`

```dart
Future<List<Map<String, dynamic>>> getRecentMeals({
  required DateTime startDate,
  DateTime? endDate,
  int limit = 10,
}) async {
  final meals = await _dbHelper.getRecentMeals(limit: limit);
  // ... processes only meals from the meals table
  // NO interaction with meal_plan_items table
}
```

**Key Issue:**
- Calls `DatabaseHelper.getRecentMeals()` which only queries the `meals` table
- **Never queries `meal_plan_items` table** where planned meals are stored
- Returns only cooked meals, not planned ones

**Database Location:** `lib/database/database_helper.dart:1119-1127`
```dart
Future<List<Meal>> getRecentMeals({int limit = 10}) async {
  final List<Map<String, dynamic>> maps = await db.query(
    'meals',  // <-- ONLY this table
    orderBy: 'cooked_at DESC',
    limit: limit,
  );
  return List.generate(maps.length, (i) => Meal.fromMap(maps[i]));
}
```

---

### 2. ProteinRotationFactor Analysis

**Location:** `lib/core/services/recommendation_factors/protein_rotation_factor.dart:1-117`

**What it does:**
- Requires `'recentMeals'` data from context
- Assigns penalties to proteins used in the past 4 days
- Only processes meals with `cookedAt` date set

**Gap:**
```dart
// Lines 53-90: Only looks at cooked meals
final recentMeals = context['recentMeals'] as List<Map<String, dynamic>>;
for (final meal in recentMeals) {
  final cookedAt = meal['cookedAt'] as DateTime;
  // Only counts meals that have been cooked
  // NO consideration of planned meals
}
```

**Impact:** When a user is planning the weekly meal plan, protein rotation doesn't account for what they've already planned for the current week.

**Example:**
- User plans "Chicken Curry" for Wednesday lunch
- During planning, system recommends "Grilled Chicken" for Thursday dinner
- Why? Because the planned chicken isn't in the "recent meals" context yet

---

### 3. VarietyEncouragementFactor Analysis

**Location:** `lib/core/services/recommendation_factors/variety_encouragement_factor.dart:1-65`

**What it does:**
- Requires `'mealCounts'` from context
- Gives higher scores to recipes with fewer historical cooking counts
- Uses only cooked meal history

**Gap:**
```dart
// Line 26-27: Gets meal counts from mealCounts context
final Map<String, int> mealCounts =
    context['mealCounts'] as Map<String, int>;
// mealCounts comes from DatabaseHelper.getAllMealCounts()
// which only counts from meals table
```

**Database Implementation:** `lib/database/database_helper.dart:1301-1321`
```dart
Future<Map<String, int>> getAllMealCounts() async {
  final db = await database;
  final List<Map<String, dynamic>> results = await db.rawQuery('''
    SELECT recipe_id, COUNT(*) as count
    FROM (
      SELECT recipe_id FROM meals WHERE recipe_id IS NOT NULL
      UNION ALL
      SELECT recipe_id FROM meal_recipes
    )
    GROUP BY recipe_id
  ''');
  // Counts ONLY from meals and meal_recipes tables
  // Does NOT include meal_plan_item_recipes
}
```

**Impact:** Planned recipes won't reduce variety scores during planning workflow.

---

### 4. Context Building (_buildContext)

**Location:** `lib/core/services/recommendation_service.dart:470-587`

**What it loads:**
- `'mealCounts'` - from cooked history only
- `'lastCooked'` - from cooked history only  
- `'recentMeals'` - from cooked history only (14 days default)
- `'proteinTypes'` - from candidate recipes only
- `'feedbackHistory'` - from user feedback on cooked meals

**Gap:**
```dart
// Lines 559-565: Loads recent meals for factors
if (requiredData.contains('recentMeals')) {
  final recentMeals = await _dbQueries.getRecentMeals(
    startDate: DateTime.now().subtract(const Duration(days: 14)),
    limit: 20);
  context['recentMeals'] = recentMeals;
}
// NO corresponding code for 'plannedMeals'
// NO support for planned meal context in factors
```

**Missing Context:**
- No planned meals context
- No planned recipes exclusion during planning
- No planned protein tracking in recommendation factors
- No temporal awareness (current week vs future)

---

### 5. Meal Plan Item Status Tracking

**Location:** `lib/models/meal_plan_item.dart:1-82`

**Status Field:**
```dart
bool hasBeenCooked; // True if this meal has been cooked
```

**Current Usage:**
- Stored in database: `has_been_cooked INTEGER DEFAULT 0`
- Set when meal is marked as cooked
- **NOT used in recommendation engine at all**

**Gap:** The flag exists but has no integration with:
- ProteinRotationFactor
- VarietyEncouragementFactor
- FrequencyFactor
- RecommendationService._buildContext()

---

### 6. Database Schema Distinction

**Key Tables:**
1. `meals` - completed/cooked meals (used by recommendation engine)
2. `meal_recipes` - recipes in cooked meals (used by recommendation engine)
3. `meal_plan_items` - planned meals (NOT used by recommendation engine)
4. `meal_plan_item_recipes` - recipes in planned meals (NOT used by recommendation engine)

**Relationship:**
```
meals (cooked) ←→ meal_recipes ←→ recipes
  ↑
  | (recommendations use)
  |
meal_plan_items (planned) ←→ meal_plan_item_recipes ←→ recipes
  ↑
  | (recommendations IGNORE)
```

---

### 7. Meal Planning Analysis Service (Correct Implementation)

**Location:** `lib/core/services/meal_plan_analysis_service.dart`

**What it does correctly:**
```dart
// Lines 21-39: Extracts planned recipes
Future<List<String>> getPlannedRecipeIds(MealPlan? mealPlan) async {
  for (final item in mealPlan.items) {
    if (item.mealPlanItemRecipes != null) {
      for (final mealRecipe in item.mealPlanItemRecipes!) {
        recipeIds.add(mealRecipe.recipeId);
      }
    }
  }
  return recipeIds.toList();
}

// Lines 94-126: Extracts recently cooked recipes
Future<List<String>> getRecentlyCookedRecipeIds({
  int dayWindow = 7,
  DateTime? referenceDate,
}) async {
  final recentMeals = await _dbHelper.getRecentMeals(limit: 100);
  for (final meal in recentMeals) {
    if (meal.cookedAt.isAfter(cutoffDate)) {
      // ... adds recipe IDs
    }
  }
  return recipeIds.toList();
}

// Lines 200-244: Calculates combined penalties
Future<ProteinPenaltyStrategy> calculateProteinPenaltyStrategy(
  MealPlan? currentPlan,
  DateTime targetDate,
  String mealType,
) async {
  final plannedProteinsByDate = await getPlannedProteinsByDate(currentPlan);
  final recentProteinsByDate = await getRecentlyCookedProteinsByDate(...);
  
  // Correctly combines both sources:
  if (isPlannedThisWeek) {
    penalty += 0.6; // Planned proteins get penalty
  }
  if (daysSinceLastCooked != null) {
    penalty += recencyPenalty; // Recently cooked proteins get penalty
  }
}
```

**The Problem:** This service exists and works correctly BUT is **NOT integrated into the core recommendation engine**.

---

### 8. Integration Test Evidence

**Location:** `integration_test/meal_plan_analysis_integration_test.dart`

**Test demonstrates:**
- MealPlanAnalysisService CORRECTLY identifies planned vs cooked meals
- Mock implementation (`_buildRecommendationContext`) shows what SHOULD happen
- But main recommendation engine doesn't use this approach

**Mock Implementation (Lines 965-1005):**
```dart
Future<Map<String, dynamic>> _buildRecommendationContext(
  MealPlan? mealPlan,
  MealPlanAnalysisService mealPlanAnalysis,
  {DateTime? forDate, String? mealType,}
) async {
  final plannedRecipeIds = await mealPlanAnalysis.getPlannedRecipeIds(mealPlan);
  final recentRecipeIds = await mealPlanAnalysis.getRecentlyCookedRecipeIds(...);
  final penaltyStrategy = await mealPlanAnalysis.calculateProteinPenaltyStrategy(...);
  
  return {
    'plannedRecipeIds': plannedRecipeIds,
    'recentlyCookedRecipeIds': recentRecipeIds,
    'penaltyStrategy': penaltyStrategy,
    'excludeIds': plannedRecipeIds, // For backward compatibility
  };
}
```

This pattern is **NOT used by the actual RecommendationService**.

---

### 9. FrequencyFactor Analysis

**Location:** `lib/core/services/recommendation_factors/frequency_factor.dart:1-130`

**What it does:**
- Requires `'lastCooked'` context
- Bases scores on last cooked date vs desired frequency
- No differentiation between "planned" and "will be cooked"

**Gap:**
```dart
// Lines 37-46: Only looks at historical data
final Map<String, DateTime?> lastCooked = context['lastCooked'];
final lastCookedDate = lastCooked[recipe.id];

if (lastCookedDate == null) {
  return 85.0; // Never cooked gets high score
}
// No consideration of: "This recipe is planned for 2 days from now"
```

**Impact:** 
- Planned recipes don't get "I'm about to be cooked" consideration
- System might recommend a recipe already in the plan
- Especially problematic for weekly frequency recipes

---

## Status Summary Table

| Component | Cooked Meals | Planned Meals | hasBeenCooked Flag | Notes |
|-----------|-------------|---------------|-------------------|-------|
| `getRecentMeals()` | ✓ | ✗ | - | Only queries `meals` table |
| `ProteinRotationFactor` | ✓ | ✗ | - | Uses `context['recentMeals']` |
| `VarietyEncouragementFactor` | ✓ | ✗ | - | Uses `context['mealCounts']` |
| `FrequencyFactor` | ✓ | ✗ | - | Uses `context['lastCooked']` |
| `UserFeedbackFactor` | ✓ | ✗ | - | Queries meal history |
| `_buildContext()` | ✓ | ✗ | - | No planned meal data loading |
| `MealPlanAnalysisService` | ✓ | ✓ | ✓ | Correctly handles both |
| `RatingFactor` | ✓ | ✗ | - | Uses recipe rating only |
| `DifficultyFactor` | ✓ | ✗ | - | Uses recipe difficulty only |
| `RandomizationFactor` | ✓ | ✗ | - | Pure randomness |

---

## Current Behavior Examples

### Example 1: Protein Rotation During Planning

**Setup:**
- Current week: "Chicken Curry" planned for Wednesday lunch
- Last 7 days: Cooked beef (5 days ago), cooked pork (3 days ago)

**Current Behavior:**
- ProteinRotationFactor only sees beef and pork history
- Chicken appears available (not in recent cooked meals)
- System might recommend Chicken recipes for other days
- Even though chicken is already planned

**Should Be:**
- ProteinRotationFactor should see planned chicken
- Apply penalty to avoid recommending more chicken recipes

---

### Example 2: Variety During Planning

**Setup:**
- Plan: "Spaghetti Carbonara" for Friday dinner (never cooked before)
- History: 0 cooked meals

**Current Behavior:**
- VarietyEncouragementFactor sees 0 cooks
- Gives 100/100 variety score
- Recipe is marked as "not yet done" despite being planned

**Should Be:**
- Consider planned status as partial fulfillment
- Reduce variety boost since we're about to cook it
- Encourage alternatives

---

### Example 3: Frequency During Planning

**Setup:**
- Recipe: "Roast Chicken" with weekly frequency
- Last cooked: 9 days ago
- Plan: Scheduled for next Sunday (6 days from now)

**Current Behavior:**
- FrequencyFactor sees it's "due" (9 days, 1.28x overdue)
- Recommends it for upcoming recommendations
- Doesn't recognize it's already scheduled

**Should Be:**
- Recognize it's in the plan for next week
- Don't overemphasize it in recommendations
- Allow other weekly recipes a chance

---

## Root Causes

1. **Separation of Concerns Issue**
   - Recommendation service is separate from meal plan service
   - No communication channel between them during planning

2. **Data Model Mismatch**
   - Recommendations use `Meal` (cooked) model
   - Planning uses `MealPlanItem` model
   - They're not integrated in factors

3. **Missing Feature Integration**
   - `hasBeenCooked` flag exists but isn't used
   - `MealPlanAnalysisService` exists but recommendation engine doesn't use it
   - Two parallel systems instead of one integrated system

4. **Historical Focus**
   - All factors are retrospective (based on past cooking)
   - No prospective awareness (future planned meals)
   - Designed for "suggest next recipe" not "plan week"

5. **Database Query Gaps**
   - `getRecentMeals()` doesn't query meal_plan_items
   - `getMealCounts()` doesn't count meal_plan_item_recipes
   - `getLastCookedDate()` ignores planned dates

---

## Impact Assessment

### During Meal Planning Workflows
**Severity: HIGH**
- Recommendations don't account for already-planned meals
- User experiences repeated suggestions for same proteins
- Planned variety doesn't get proper representation
- Overlapping meal suggestions possible

### During Normal Recommendation Requests
**Severity: LOW**
- System works as designed (pure history-based)
- Planned meals don't interfere with normal recommendations
- Only an issue when planning creates recommendations context

### For Frequency Maintenance
**Severity: MEDIUM**
- Planned meals don't get credit for upcoming frequency fulfillment
- May lead to over-recommending recipes that are already scheduled
- Frequency calculations don't benefit from planning

---

## Identified Gaps

### Gap 1: No Planned-Meal-Aware Recommendation Context
**Missing:** `MealPlanAnalysisService` integration into `RecommendationService._buildContext()`

### Gap 2: Factors Don't Know About Current Week Plans
**Missing:** No meal plan parameter in recommendation factor calculations

### Gap 3: Database Queries Ignore Meal Plan Tables
**Missing:** Queries for:
- `getMealPlanRecipeIds()` 
- `getMealPlanProteinTypes()`
- `getMealPlanItemsForWeek()`

### Gap 4: No Temporal Awareness in Factors
**Missing:** 
- Distinction between past (cooked), present (being planned), and future
- Date context for planned meals
- "Already scheduled" flag in context

### Gap 5: hasBeenCooked Flag Not Utilized
**Missing:** 
- UI integration to track when planned meals are cooked
- Recommendation engine awareness when plan is executed
- Transition logic from `meal_plan_items` to `meals`

### Gap 6: No Backward-Compatibility for Planning Workflow
**Missing:**
- Optional mealPlan parameter in `getRecommendations()`
- Planning-aware variant of recommendation method
- Temporary exclusion of planned recipes during planning

---

## Correct Approach Identified

The integration test (`meal_plan_analysis_integration_test.dart`) shows the correct pattern:

1. Get current meal plan via `MealPlanAnalysisService.getPlannedRecipeIds()`
2. Get recently cooked via `MealPlanAnalysisService.getRecentlyCookedRecipeIds()`
3. Calculate penalties via `MealPlanAnalysisService.calculateProteinPenaltyStrategy()`
4. Pass to recommendation system as `excludeIds` and penalty context
5. System respects both planned and cooked context

**BUT this pattern is only used in tests, not in production code.**

---

## Code References Summary

| Finding | File | Lines | Issue |
|---------|------|-------|-------|
| getRecentMeals only cooked | recommendation_database_queries.dart | 243-292 | No meal_plan_items query |
| getRecentMeals only cooked | database_helper.dart | 1119-1127 | Query only meals table |
| ProteinRotation ignores plans | protein_rotation_factor.dart | 53-90 | Only uses recentMeals context |
| Variety ignores plans | variety_encouragement_factor.dart | 26-27 | Only uses mealCounts context |
| Context missing planned data | recommendation_service.dart | 470-587 | No plannedMeals loading |
| hasBeenCooked unused | meal_plan_item.dart | 9 | Flag not referenced by engine |
| Correct impl exists | meal_plan_analysis_service.dart | 21-244 | Works but not integrated |
| Test shows pattern | meal_plan_analysis_integration_test.dart | 965-1005 | Mock impl correct |

---

## Conclusion

The recommendation engine is **fully functional for retrospective recommendations** (based on cooking history) but **lacks planned-meal awareness for meal planning workflows**. The `MealPlanAnalysisService` provides a correct implementation that isn't integrated into the core recommendation engine.

To fix this, the recommendation system needs:
1. Integration with `MealPlanAnalysisService`
2. Planned-meal parameters in core methods
3. Context awareness of current meal plans
4. Updated database queries to include meal plan tables
5. Factor updates to handle both planned and cooked meal contexts
