# Quick Reference: Recommendation Engine Planned vs Cooked Meals

## TL;DR

The recommendation engine **only uses cooked meal history**. When planning meals, it doesn't know about recipes you've already scheduled. This can lead to duplicate recommendations.

## The Problem in 30 Seconds

```
Planning a week menu:
  1. User plans "Chicken Curry" for Wednesday lunch
  2. User asks "What should I cook Thursday dinner?"
  3. System recommends "Chicken Stir Fry"
  4. Why? Because it doesn't see the planned chicken curry

What's missing:
  - getRecentMeals() only queries cooked meals, not planned meals
  - ProteinRotationFactor only sees cooking history
  - VarietyEncouragementFactor only counts cooked meals
  - No "planned meals" context in recommendation factors
```

## Key Files

| What | File | Key Lines |
|------|------|-----------|
| The gap | `recommendation_service.dart` | 470-587 (_buildContext) |
| Only cooked | `recommendation_database_queries.dart` | 243-292 (getRecentMeals) |
| Ignores plans | `protein_rotation_factor.dart` | 53-90 (uses recentMeals) |
| Also ignores | `variety_encouragement_factor.dart` | 26-27 (uses mealCounts) |
| Missing flag | `meal_plan_item.dart` | 9 (hasBeenCooked unused) |
| Correct method | `meal_plan_analysis_service.dart` | 200-244 (but not used!) |
| Shows how | `meal_plan_analysis_integration_test.dart` | 965-1005 |

## What Needs to Change

### Short Term (Quick Fix)
1. When planning a meal, pass `excludeIds` with already-planned recipes
2. Use `MealPlanAnalysisService.getPlannedRecipeIds()`
3. This avoids duplicates but is temporary

### Long Term (Real Fix)
1. Add optional `mealPlan` parameter to `getRecommendations()`
2. Integrate `MealPlanAnalysisService` into `_buildContext()`
3. Load planned meals into recommendation context
4. Let factors process both planned and cooked meals

## The Correct Pattern (Already in Tests!)

```dart
// This is what SHOULD happen (from integration test):
Future<Map<String, dynamic>> _buildRecommendationContext(
  MealPlan? mealPlan,
  MealPlanAnalysisService mealPlanAnalysis,
  {DateTime? forDate, String? mealType,}
) async {
  // Get what's planned
  final plannedRecipeIds = await mealPlanAnalysis.getPlannedRecipeIds(mealPlan);
  
  // Get what was cooked
  final recentRecipeIds = await mealPlanAnalysis.getRecentlyCookedRecipeIds(...);
  
  // Calculate penalties for both
  final penaltyStrategy = await mealPlanAnalysis.calculateProteinPenaltyStrategy(...);
  
  // Use both in recommendations
  return {
    'plannedRecipeIds': plannedRecipeIds,
    'recentRecipeIds': recentRecipeIds,
    'penaltyStrategy': penaltyStrategy,
    'excludeIds': plannedRecipeIds,
  };
}
```

This pattern IS PROVEN CORRECT (in tests) but NOT USED IN PRODUCTION.

## Current Behavior vs Expected

### Scenario: Planning a week with protein variety

**Current Behavior (WRONG):**
- User plans: "Chicken Curry" (Wed lunch)
- System doesn't know
- System recommends: "Chicken Stir Fry" (Thu dinner)
- Result: Too much chicken recommended

**Expected Behavior (RIGHT):**
- User plans: "Chicken Curry" (Wed lunch)  
- System knows about planned chicken
- ProteinRotationFactor applies penalty
- System recommends: "Beef Tacos" or "Fish Stew"
- Result: Good protein variety

## Database Table Reality

```
meals (cooked) ←→ meal_recipes ←→ recipes
  ✓ Used by recommendation engine
  
meal_plan_items (planned) ←→ meal_plan_item_recipes ←→ recipes
  ✗ Ignored by recommendation engine
```

## All Affected Factors

| Factor | Handles Planned? | Issue |
|--------|-----------------|-------|
| ProteinRotation | NO | Uses context['recentMeals'] |
| Variety | NO | Uses context['mealCounts'] |
| Frequency | NO | Uses context['lastCooked'] |
| Rating | - | Recipe rating only |
| Difficulty | - | Recipe difficulty only |
| Randomization | - | Pure randomness |
| UserFeedback | NO | Queries meal history |

## Context Missing

```dart
// These are loaded:
context['mealCounts']        // Cooked meal counts only
context['lastCooked']         // Last cooked dates only
context['recentMeals']        // Recent cooked meals only
context['feedbackHistory']    // Feedback on cooked meals

// These are NOT loaded:
context['plannedMeals']       // Missing!
context['plannedRecipeIds']   // Missing!
context['plannedProteins']    // Missing!
context['penaltyStrategy']    // Missing!
```

## The Flag That's Ignored

```dart
// This exists in MealPlanItem:
bool hasBeenCooked; // True if this meal has been cooked

// But it's never used by:
- ProteinRotationFactor
- VarietyEncouragementFactor
- FrequencyFactor
- RecommendationService._buildContext()
- Any database query for recommendations
```

## When This Is a Problem

**HIGH IMPACT:**
- Meal planning workflows
- Building a weekly menu
- User wants variety for the week

**LOW IMPACT:**
- Getting a single recommendation
- Using app outside of planning
- History-based suggestions

**NO IMPACT:**
- Normal recommendation requests without planning

## To Verify the Issue

1. Plan 5 chicken recipes in one week
2. Get recommendations for the same week
3. Notice system recommends more chicken
4. Expected: System should avoid chicken

## To Test the Solution

The integration test shows exactly how it should work:
```bash
flutter test integration_test/meal_plan_analysis_integration_test.dart
```

Look at the `_buildRecommendationContext` helper function (line 965-1005).
This pattern is what needs to be in production.

## Files to Understand the Gap

**Start here (5 min):**
- `recommendation_service.dart` line 470-587 (_buildContext method)

**Understand the scope (10 min):**
- `recommendation_database_queries.dart` line 243-292
- `protein_rotation_factor.dart` line 53-90

**See the solution (5 min):**
- `meal_plan_analysis_integration_test.dart` line 965-1005

**Total time to understand: ~20 minutes**

## Executive Summary

| Aspect | Status | Evidence |
|--------|--------|----------|
| Cooked meal handling | ✓ Working | Database queries, factors process meals |
| Planned meal handling | ✗ Missing | No queries, no context, no factor awareness |
| Service exists | ✓ Yes | MealPlanAnalysisService works correctly |
| Integration | ✗ No | Service not used by RecommendationService |
| Tests show it | ✓ Yes | Integration test demonstrates correct pattern |
| In production | ✗ No | Pattern only in tests, not in code |

## Impact Summary

- **Users planning meals**: May see duplicate suggestions
- **Protein rotation**: Doesn't account for planned proteins
- **Variety**: Doesn't see planned recipes in variety calc
- **Frequency**: Over-emphasizes recipes already scheduled
- **System stability**: No impact, works as designed for history

## Next Steps

1. Understand the gap (read this doc + investigation report)
2. Study the correct pattern (integration test)
3. Integrate MealPlanAnalysisService into recommendations
4. Add mealPlan parameter to getRecommendations()
5. Update _buildContext() to load planned meals
6. Test with existing integration test pattern
