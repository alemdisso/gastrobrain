# Recommendation Engine: Files to Review

This document lists all relevant files for understanding how the recommendation engine handles planned vs cooked meals.

## Core Recommendation Engine Files

### Primary Service
- **lib/core/services/recommendation_service.dart** (782 lines)
  - `getRecommendations()` - main entry point
  - `getDetailedRecommendations()` - with scoring details
  - `_buildContext()` - builds context for factors (MISSING planned meals)
  - `_scoreRecipes()` - applies factor weights

### Database Queries  
- **lib/core/services/recommendation_database_queries.dart** (293 lines)
  - `getRecentMeals()` - queries only cooked meals (line 243-292)
  - `getMealCounts()` - counts only cooked meals (line 173-194)
  - `getLastCookedDates()` - gets only cooked dates (line 146-168)
  - `getRecipesWithStats()` - combines stats (line 203-238)

### Database Helper
- **lib/database/database_helper.dart** (1,699 lines)
  - `getRecentMeals()` - queries meals table only (line 1119-1127)
  - `getAllMealCounts()` - counts only meals + meal_recipes (line 1301-1321)
  - `getAllLastCooked()` - gets only cooked dates (line 1323-1349)

## Recommendation Factors

### ProteinRotationFactor
- **lib/core/services/recommendation_factors/protein_rotation_factor.dart** (117 lines)
  - Requires: `'recentMeals'` (line 20)
  - Uses: `context['recentMeals']` (line 54)
  - Issue: Only processes cooked meals (line 53-90)

### VarietyEncouragementFactor  
- **lib/core/services/recommendation_factors/variety_encouragement_factor.dart** (65 lines)
  - Requires: `'mealCounts'` (line 20)
  - Uses: `context['mealCounts']` (line 27)
  - Issue: Only counts cooked meals (line 26-30)

### FrequencyFactor
- **lib/core/services/recommendation_factors/frequency_factor.dart** (130+ lines)
  - Requires: `'lastCooked'` (line 22)
  - Uses: `context['lastCooked']` (line 38-40)
  - Issue: No plan awareness (line 37-46)

### Other Factors
- **lib/core/services/recommendation_factors/rating_factor.dart**
  - Uses recipe rating only, no context needed
  
- **lib/core/services/recommendation_factors/difficulty_factor.dart**
  - Uses recipe difficulty only, no context needed
  
- **lib/core/services/recommendation_factors/randomization_factor.dart**
  - Pure randomness, no context needed
  
- **lib/core/services/recommendation_factors/user_feedback_factor.dart**
  - Uses feedback history, queries meal history

## Data Models

### Meal Model (Cooked)
- **lib/models/meal.dart** (62 lines)
  - Represents cooked meals
  - Used in: recommendation engine, database

### MealPlanItem Model (Planned)
- **lib/models/meal_plan_item.dart** (82 lines)
  - Represents planned meals
  - Has: `hasBeenCooked` flag (line 9) - UNUSED by recommendation engine
  - Used in: meal planning, NOT in recommendations

### Supporting Models
- **lib/models/meal_plan.dart** - collection of meal plan items
- **lib/models/meal_plan_item_recipe.dart** - junction table for planned recipes
- **lib/models/meal_recipe.dart** - junction table for cooked meal recipes

## Meal Planning Analysis Service

### The Correct Implementation (But Unused)
- **lib/core/services/meal_plan_analysis_service.dart** (377 lines)
  - `getPlannedRecipeIds()` - extracts planned recipes (line 21-39)
  - `getRecentlyCookedRecipeIds()` - extracts cooked recipes (line 94-126)
  - `getPlannedProteinsForWeek()` - gets planned proteins (line 42-55)
  - `getRecentlyCookedProteins()` - gets cooked proteins (line 129-142)
  - `calculateProteinPenaltyStrategy()` - combines both contexts (line 200-244)

## Tests (Demonstration of Correct Behavior)

### Integration Tests
- **integration_test/meal_plan_analysis_integration_test.dart** (1,005 lines)
  - Test: `extracts planned and recently cooked context correctly` (line 75-436)
  - Helper: `_buildRecommendationContext()` shows correct pattern (line 965-1005)
  - Demonstrates how planned and cooked meals SHOULD be combined

### Unit Tests for Factors
- **test/core/services/recommendation_protein_rotation_test.dart**
  - Tests protein rotation with cooked meals only
  
- **test/core/services/recommendation_service_test.dart**
  - Tests recommendation service
  
- **test/core/services/recommendation_factor_interaction_test.dart**
  - Tests factor interactions

### Mock Database
- **test/mocks/mock_database_helper.dart** (500+ lines)
  - `getRecentMeals()` - mock implementation (line 290-305)
  - Used in all unit tests

## Configuration & Setup

### Service Provider
- **lib/core/di/service_provider.dart**
  - Provides singleton instances
  - Provides RecommendationService access

## Summary of Changes Needed

### To Fix Planned Meal Awareness:

1. **RecommendationService**
   - Add optional `mealPlan` parameter to `getRecommendations()`
   - Integrate MealPlanAnalysisService into `_buildContext()`
   - Load planned meal data into context

2. **Database Queries**
   - Add method to get planned recipe IDs
   - Add method to get planned protein types
   - Extend getRecentMeals() or create separate method for planned meals

3. **Factors**
   - Update to use planned meal context
   - Modify penalty calculations for planned meals
   - Add temporal awareness (past vs planned)

4. **Context Building**
   - Load planned meals when mealPlan parameter is provided
   - Include planned protein penalties
   - Add "excludeIds" for planned recipes

## File Statistics

| File | Lines | Type | Issue |
|------|-------|------|-------|
| recommendation_service.dart | 782 | Core | Missing planned meal context |
| recommendation_database_queries.dart | 293 | Queries | Only cooked meals |
| database_helper.dart | 1,699 | DB | Only cooked meal queries |
| protein_rotation_factor.dart | 117 | Factor | Ignores planned meals |
| variety_encouragement_factor.dart | 65 | Factor | Ignores planned meals |
| frequency_factor.dart | 130+ | Factor | No plan awareness |
| meal_plan_analysis_service.dart | 377 | Service | Correct but unused |
| meal_plan_analysis_integration_test.dart | 1,005 | Test | Shows correct pattern |

Total affected code: 3,968+ lines
Files with gaps: 6
Files showing correct approach: 2

## Quick File Navigation

### If you want to understand the problem:
1. Start: `recommendation_service.dart:470-587` (_buildContext)
2. Check: `recommendation_database_queries.dart:243-292` (getRecentMeals)
3. See: `protein_rotation_factor.dart:53-90` (how factors use context)

### If you want to see the correct solution:
1. Study: `meal_plan_analysis_service.dart:200-244` (combined penalties)
2. Review: `meal_plan_analysis_integration_test.dart:965-1005` (usage pattern)
3. Understand: How planned + cooked contexts are combined

### To implement the fix:
1. Update: `recommendation_service.dart` (add mealPlan parameter)
2. Integrate: `meal_plan_analysis_service.dart` (into _buildContext)
3. Modify: Each factor to use new context
4. Test: Verify with existing integration test pattern

