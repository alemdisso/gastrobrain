<!-- markdownlint-disable -->
# Gastrobrain Recommendation Engine Analysis

## Executive Summary

This analysis covers the recommendation engine code structure with focus on:
1. ProteinRotationFactor implementation
2. getRecipeProteinTypes() database method
3. VarietyEncouragementFactor implementation
4. RecommendationDatabaseQueries methods
5. Multi-ingredient recipe handling

**Key Finding**: The system properly handles multi-ingredient recipes by:
- Iterating through ALL ingredients in a recipe
- Extracting protein types from each ingredient's `protein_type` field
- Averaging penalties across multiple proteins
- Supporting custom ingredients (with no protein type)

---

## 1. ProteinRotationFactor Implementation

**File**: `/home/rodrigo_machado/dev/gastrobrain/lib/core/services/recommendation_factors/protein_rotation_factor.dart`

### Overview
- **ID**: `'protein_rotation'`
- **Default Weight**: 30% of total recommendation score
- **Purpose**: Encourages protein variety by penalizing recipes with proteins used recently

### Score Calculation Logic

```
Score Range: 0-100 points

Key Decision Tree:
1. No proteins in recipe → 70.0 (neutral)
2. Only non-main proteins → 90.0 (encouraged)
3. Has main proteins → Calculate penalties based on recent usage

Penalty Schedule (graduated, time-based):
├─ 1 day ago: 100% penalty → Score = 0.0
├─ 2 days ago: 75% penalty → Score = 25.0
├─ 3 days ago: 50% penalty → Score = 50.0
├─ 4 days ago: 25% penalty → Score = 75.0
└─ 5+ days ago: 0% penalty → Score = 100.0
```

### Algorithm Steps

**Step 1-2**: Retrieve and validate protein types
```dart
final Map<String, List<ProteinType>> proteinTypesMap = context['proteinTypes'];
final recipeProteinTypes = proteinTypesMap[recipe.id] ?? [];
```
- **Multi-ingredient handling**: This is a **list** of all proteins in the recipe
- Supports recipes with multiple protein-containing ingredients

**Step 3**: Filter for main proteins only
```dart
final mainProteins = recipeProteinTypes.where((p) => p.isMainProtein).toList();
```
- ProteinType enum distinguishes main proteins (beef, chicken, pork, fish, seafood, lamb)
- From non-main proteins (charcuterie, offal, plantBased, other)
- Non-main proteins don't trigger rotation logic

**Step 4**: Build recent usage map
```dart
final Map<ProteinType, int> recentProteinUsage = {};

for (final meal in recentMeals) {
  // For each meal, get its recipe
  final mealProteinTypes = proteinTypesMap[recipe.id] ?? [];
  
  for (var proteinType in mealProteinTypes) {
    if (!proteinType.isMainProtein) continue;
    
    // Store most recent usage
    if (!recentProteinUsage.containsKey(proteinType) ||
        recentProteinUsage[proteinType]! > daysAgo) {
      recentProteinUsage[proteinType] = daysAgo;
    }
  }
}
```
- **Key Point**: Tracks the most recent day each protein was used
- Looks back 4 days (5+ days treated as never used recently)
- Only considers main proteins

**Step 5**: Calculate average penalty across all main proteins
```dart
double totalPenalty = 0.0;
int penaltyCount = 0;

for (var proteinType in mainProteins) {
  if (recentProteinUsage.containsKey(proteinType)) {
    final daysAgo = recentProteinUsage[proteinType]!;
    if (_daysPenalty.containsKey(daysAgo)) {
      totalPenalty += _daysPenalty[daysAgo]!;
      penaltyCount++;
    }
  }
}

final averagePenalty = penaltyCount > 0 ? totalPenalty / penaltyCount : 0.0;
final score = 100.0 - (averagePenalty * 100.0);
```

### Multi-Ingredient Recipe Handling

**Scenario 1: Recipe with multiple different proteins**
```
Recipe: "Chicken and Beef Stir Fry"
├─ Chicken (main protein) - used 1 day ago (100% penalty)
├─ Beef (main protein) - used 3 days ago (50% penalty)
└─ Green Beans (no protein)

Calculation:
├─ Penalties: [100%, 50%]
├─ Average: 75%
└─ Score: 100 - (0.75 * 100) = 25.0
```

**Scenario 2: Recipe with one main + non-main proteins**
```
Recipe: "Tofu and Chicken Bowl"
├─ Chicken (main protein) - used 2 days ago (75% penalty)
├─ Tofu (non-main) - used 1 day ago (ignored)
└─ Rice

Calculation:
├─ Main proteins: [Chicken]
├─ Penalty: 75%
└─ Score: 100 - (0.75 * 100) = 25.0
```

**Scenario 3: Multiple same proteins**
```
Recipe: "Beef Wellington with Beef Stock"
├─ Beef (main) - ingredient 1
├─ Beef (main) - ingredient 2
├─ Mushrooms

Recent Usage Tracking:
├─ First beef: 100% penalty (1 day ago)
├─ Second beef: references same ProteinType.beef
└─ recentProteinUsage[ProteinType.beef] = 1 day

Penalty Application:
├─ Iteration 1: mainProteins[0] (beef) → 100% penalty
├─ Iteration 2: mainProteins[1] (same beef) → DUPLICATE PENALTY
└─ Total Penalties: [100%, 100%]
└─ Average: 100%
└─ Score: 0.0
```
**⚠️ POTENTIAL ISSUE**: Duplicates are counted separately, not deduplicated

### Code Quality Issues

#### Issue 1: No Deduplication of Protein Types
```dart
final mainProteins = recipeProteinTypes.where((p) => p.isMainProtein).toList();
```
- If a recipe has Beef twice (two beef ingredients), both are counted
- Penalty calculation iterates ALL proteins, not unique proteins
- Results in harsher penalties for recipes with multiple instances of same protein

#### Issue 2: Recent Meals Context Loading
From `recommendation_service.dart` line 559-564:
```dart
if (requiredData.contains('recentMeals')) {
  final recentMeals = await _dbQueries.getRecentMeals(
      startDate: DateTime.now().subtract(const Duration(days: 14)),
      limit: 20);
  
  context['recentMeals'] = recentMeals;
}
```
- Loads only **20 recent meals** (hardcoded limit)
- Limits lookback to **14 days**
- Could miss older meals that still have active penalties (up to 4 days = 14 days total is fine)

---

## 2. getRecipeProteinTypes() Method

**File**: `/home/rodrigo_machado/dev/gastrobrain/lib/core/services/recommendation_database_queries.dart` (lines 92-141)

### Method Signature
```dart
Future<Map<String, List<ProteinType>>> getRecipeProteinTypes({
  required List<String> recipeIds,
}) async
```

### Return Value
```
Map<String, List<ProteinType>> {
  'recipe-1': [ProteinType.chicken, ProteinType.beef],  // Multi-protein recipe
  'recipe-2': [ProteinType.fish],                        // Single protein
  'recipe-3': [],                                        // No proteins
}
```

### Implementation Details

**Override Support** (for testing):
```dart
if (proteinTypesOverride != null) {
  final result = <String, List<ProteinType>>{};
  
  for (final id in recipeIds) {
    result[id] = proteinTypesOverride!.containsKey(id)
        ? List<ProteinType>.from(proteinTypesOverride![id]!)
        : [];
  }
  
  return result;
}
```
- Allows tests to inject custom protein mappings
- Creates defensive copy (important for immutability)

**Database Query Process**:
```dart
for (final recipeId in recipeIds) {
  final ingredientMaps = await _dbHelper.getRecipeIngredients(recipeId);
  
  for (final ingredientMap in ingredientMaps) {
    final proteinTypeStr = ingredientMap['protein_type'] as String?;
    
    if (proteinTypeStr != null) {
      final proteinType = ProteinType.values.firstWhere(
        (type) => type.name == proteinTypeStr,
        orElse: () => ProteinType.values.first,
      );
      
      result[recipeId]!.add(proteinType);
    }
  }
}
```

### Multi-Ingredient Processing

**Step 1: Get Recipe Ingredients**
```dart
final ingredientMaps = await _dbHelper.getRecipeIngredients(recipeId);
```
Returns list like:
```
[
  {'protein_type': 'chicken', 'name': 'Chicken Breast', ...},
  {'protein_type': null, 'name': 'Rice', ...},
  {'protein_type': 'beef', 'name': 'Beef Stock', ...},
  {'protein_type': null, 'name': 'Vegetables', ...},
]
```

**Step 2: Extract Protein Types**
- Iterates through ALL ingredients
- Skips ingredients with `protein_type: null`
- Adds each protein type to the recipe's list
- **Result**: Duplicate proteins if recipe has multiple of same type

**Step 3: Return Map**
```
'recipe-123': [
  ProteinType.chicken,  // From ingredient 1
  ProteinType.beef,     // From ingredient 3
]
```

### Database Schema (from database_helper.dart lines 746-768)

```sql
SELECT 
  ri.id as recipe_ingredient_id,
  ri.quantity,
  ri.notes as preparation_notes,
  ri.unit_override,
  ri.custom_name,
  ri.custom_category,
  ri.custom_unit,
  ri.ingredient_id,
  COALESCE(ri.custom_name, i.name) as name,
  COALESCE(ri.custom_category, i.category) as category,
  COALESCE(ri.custom_unit, COALESCE(ri.unit_override, i.unit)) as unit,
  i.protein_type,  -- ← Source of protein data
  i.notes as ingredient_notes
FROM recipe_ingredients ri
LEFT JOIN ingredients i ON ri.ingredient_id = i.id
WHERE ri.recipe_id = ?
```

### Edge Cases

**Case 1: Custom Ingredient (no ingredient_id)**
```
CustomRecipeIngredient {
  ingredient_id: null,
  custom_name: "Homemade Beef Broth",
  custom_category: "Broth",
  // No custom_protein_type field
}
```
**Result**: Not included in protein list (cannot extract protein type from custom ingredients)

**Case 2: Ingredient without protein_type**
```
{protein_type: null, name: "Onion"}
```
**Result**: `ingredientMap['protein_type']` is null → skipped

**Case 3: Duplicate Ingredients**
```
Recipe: "Beef and More Beef"
├─ Ingredient 1: Beef Stew Meat (protein_type: 'beef')
├─ Ingredient 2: Beef Stock (protein_type: 'beef')
```
**Result**: `[ProteinType.beef, ProteinType.beef]` (NOT deduplicated)

---

## 3. VarietyEncouragementFactor Implementation

**File**: `/home/rodrigo_machado/dev/gastrobrain/lib/core/services/recommendation_factors/variety_encouragement_factor.dart`

### Overview
- **ID**: `'variety_encouragement'`
- **Default Weight**: 10% of total recommendation score
- **Purpose**: Boost recipes cooked less frequently to encourage exploration

### Score Calculation

```
Formula: score = 100.0 * exp(-0.07 * cookCount)

Examples:
├─ 0 cooks: 100.0 points (perfect, encourages exploration)
├─ 1 cook: 85.2 points
├─ 2 cooks: 77.4 points
├─ 5 cooks: 63.4 points
├─ 10 cooks: 50.0 points
├─ 20 cooks: 37.1 points
└─ 50 cooks: 19.1 points
```

### Implementation

```dart
Future<double> calculateScore(Recipe recipe, Map<String, dynamic> context) async {
  final Map<String, int> mealCounts = context['mealCounts'] as Map<String, int>;
  final cookCount = mealCounts[recipe.id] ?? 0;
  
  if (cookCount == 0) {
    return 100.0;  // Never cooked
  }
  
  final double baseScore = 100.0 * exp(-0.07 * cookCount);
  return max(0.0, min(100.0, baseScore));
}
```

### Multi-Ingredient Recipe Interaction

**No direct interaction**: This factor operates purely on meal counts
- Counts meals, not ingredients
- One meal of a multi-ingredient recipe increments the count by 1
- Works correctly regardless of ingredient complexity

### Data Source

From `recommendation_database_queries.dart` lines 173-194:
```dart
Future<Map<String, int>> getMealCounts({
  List<String> recipeIds = const [],
}) async {
  try {
    if (recipeIds.isNotEmpty) {
      final result = <String, int>{};
      
      for (final id in recipeIds) {
        final count = await _dbHelper.getTimesCookedCount(id);
        result[id] = count;
      }
      
      return result;
    }
    
    // Otherwise, use the more efficient bulk query
    return await _dbHelper.getAllMealCounts();
  } catch (e) {
    throw GastrobrainException(...);
  }
}
```

**getMealCounts** builds map of recipe ID → total times cooked (aggregation of all meals)

---

## 4. RecommendationDatabaseQueries Methods

**File**: `/home/rodrigo_machado/dev/gastrobrain/lib/core/services/recommendation_database_queries.dart`

### Method 1: getCandidateRecipes()

**Purpose**: Get recipes filtered by various criteria

**Multi-Ingredient Handling**:
```dart
Future<List<Recipe>> getCandidateRecipes({
  List<String> excludeIds = const [],
  int? limit,
  List<ProteinType>? requiredProteinTypes,
  List<ProteinType>? excludedProteinTypes,
}) async
```

**Logic**:
1. Get all recipes
2. Apply exclusion filter
3. If protein filters specified:
   ```dart
   if (requiredProteinTypes != null || excludedProteinTypes != null) {
     final recipeProteinTypes = await getRecipeProteinTypes(
         recipeIds: recipes.map((r) => r.id).toList());
     
     recipes = recipes.where((recipe) {
       final proteinTypes = recipeProteinTypes[recipe.id] ?? [];
       
       // Recipe must contain at least one required protein
       if (requiredProteinTypes != null && requiredProteinTypes.isNotEmpty) {
         if (!proteinTypes.any((type) => requiredProteinTypes.contains(type))) {
           return false;
         }
       }
       
       // Recipe must NOT contain excluded proteins
       if (excludedProteinTypes != null && excludedProteinTypes.isNotEmpty) {
         if (proteinTypes.any((type) => excludedProteinTypes.contains(type))) {
           return false;
         }
       }
       
       return true;
     }).toList();
   }
   ```

**Multi-Ingredient Issue**: Uses `.any()` logic
- **requiredProteinTypes**: Passes if ANY ingredient matches (correct for multi-ingredient)
- **excludedProteinTypes**: Fails if ANY ingredient matches (correct for multi-ingredient)

### Method 2: getRecentMeals()

**File**: Lines 243-292

**Purpose**: Get meals cooked within a date range with associated recipes

```dart
Future<List<Map<String, dynamic>>> getRecentMeals({
  required DateTime startDate,
  DateTime? endDate,
  int limit = 10,
}) async
```

**Multi-Ingredient Meal Handling**:
```dart
for (final meal in meals) {
  // First try to get recipes from junction table (multi-recipe meals)
  final mealRecipes = await _dbHelper.getMealRecipesForMeal(meal.id);
  
  Recipe? primaryRecipe;
  
  if (mealRecipes.isNotEmpty) {
    // Find the primary recipe if one is marked as primary
    final primaryMealRecipe = mealRecipes.firstWhere(
      (mr) => mr.isPrimaryDish,
      orElse: () => mealRecipes.first,
    );
    
    primaryRecipe = await _dbHelper.getRecipe(primaryMealRecipe.recipeId);
  }
  // Fallback to direct recipe_id if available
  else if (meal.recipeId != null) {
    primaryRecipe = await _dbHelper.getRecipe(meal.recipeId!);
  }
  
  if (primaryRecipe != null) {
    result.add({
      'meal': meal,
      'recipe': primaryRecipe,
      'cookedAt': meal.cookedAt,
    });
  }
}
```

**Key Points**:
- Supports **multi-recipe meals** (multiple dishes in one meal)
- Returns **primary recipe only** for ProteinRotationFactor
- Allows fallback to single recipe_id if junction table empty
- Proper handling of meal relationships

### Method 3: getRecipesWithStats()

**File**: Lines 203-238

**Purpose**: Optimized batch query combining recipe data with statistics

```dart
Future<List<Map<String, dynamic>>> getRecipesWithStats({
  List<String> excludeIds = const [],
  bool includeProteinInfo = false,
}) async {
  final recipes = await getCandidateRecipes(excludeIds: excludeIds);
  
  if (recipes.isEmpty) {
    return [];
  }
  
  final recipeIds = recipes.map((r) => r.id).toList();
  final lastCookedDates = await getLastCookedDates(recipeIds: recipeIds);
  final mealCounts = await getMealCounts(recipeIds: recipeIds);
  
  // Get protein information if requested
  final Map<String, List<ProteinType>> proteinTypes = includeProteinInfo
      ? await getRecipeProteinTypes(recipeIds: recipeIds)
      : {};
  
  return recipes.map((recipe) {
    return {
      'recipe': recipe,
      'lastCooked': lastCookedDates[recipe.id],
      'timesCooked': mealCounts[recipe.id] ?? 0,
      if (includeProteinInfo) 'proteinTypes': proteinTypes[recipe.id] ?? [],
    };
  }).toList();
}
```

**Performance Optimization**:
- Single batch call instead of N+1 queries
- Only fetches protein info if specifically requested

---

## 5. Context Building in RecommendationService

**File**: `/home/rodrigo_machado/dev/gastrobrain/lib/core/services/recommendation_service.dart`
**Method**: `_buildContext()` (lines 470-587)

### Context Map Structure

```dart
final context = <String, dynamic>{
  'excludeIds': excludeIds,
  'avoidProteinTypes': avoidProteinTypes,
  'requiredProteinTypes': requiredProteinTypes,
  'forDate': forDate,
  'mealType': mealType,
  'maxDifficulty': maxDifficulty,
  'preferredFrequency': preferredFrequency,
  'weekdayMeal': weekdayMeal,
  'randomSeed': _random.nextInt(1000),
  
  // Loaded conditionally based on factor requirements
  'mealCounts': {...},        // From VarietyEncouragementFactor
  'lastCooked': {...},        // From FrequencyFactor
  'proteinTypes': {...},      // From ProteinRotationFactor
  'recentMeals': [...],       // From ProteinRotationFactor (optional)
  'feedbackHistory': {...},   // From UserFeedbackFactor
  'recipeStats': [...],       // Optimized batch data
};
```

### Protein Data Loading (lines 532-544)

```dart
final needsProteinInfo = requiredData.contains('proteinTypes') ||
    avoidProteinTypes != null ||
    requiredProteinTypes != null;

if (needsProteinInfo) {
  final recipes = await _dbQueries.getCandidateRecipes(excludeIds: excludeIds);
  final recipeIds = recipes.map((r) => r.id).toList();
  
  context['proteinTypes'] = 
      await _dbQueries.getRecipeProteinTypes(recipeIds: recipeIds);
}
```

**Smart Loading**:
- Fetches protein info only if needed
- Includes all recipes (minus excludeIds)
- Returns Map<recipeId, List<ProteinType>>

### Recent Meals Loading (lines 559-565)

```dart
if (requiredData.contains('recentMeals')) {
  final recentMeals = await _dbQueries.getRecentMeals(
      startDate: DateTime.now().subtract(const Duration(days: 14)),
      limit: 20);
  
  context['recentMeals'] = recentMeals;
}
```

**Hardcoded Parameters**:
- **Lookback**: 14 days
- **Limit**: 20 meals
- Sufficient for ProteinRotationFactor (penalty window: 4 days)

---

## Summary of Multi-Ingredient Handling

### How Multi-Ingredient Recipes Are Processed

```
Recipe: "Chicken and Beef Stir Fry"
├─ Ingredient 1: Chicken Breast (protein_type: 'chicken')
├─ Ingredient 2: Beef Stock (protein_type: 'beef')
└─ Ingredient 3: Vegetables (protein_type: null)

Step 1: Database Query (getRecipeIngredients)
├─ Executes LEFT JOIN on ingredients table
├─ Returns ALL recipe_ingredients with protein_type from joined ingredient
└─ Result: [
     {protein_type: 'chicken', ...},
     {protein_type: 'beef', ...},
     {protein_type: null, ...},
   ]

Step 2: Extract Proteins (getRecipeProteinTypes)
├─ Iterates ingredients, skips nulls
├─ Collects: [ProteinType.chicken, ProteinType.beef]
└─ Stores in map: {'recipe-123': [chicken, beef]}

Step 3: Score Calculation (ProteinRotationFactor)
├─ Gets proteins from context['proteinTypes']['recipe-123']
├─ Filters main proteins: [chicken, beef]
├─ For each main protein:
│  ├─ Looks up recent usage from recentMeals
│  └─ Adds penalty if used recently
├─ Averages penalties
└─ Final score: 100.0 - (avg_penalty * 100.0)
```

### Key Design Decisions

1. **List Not Set**: Proteins stored as `List<ProteinType>` not `Set<ProteinType>`
   - Allows duplicates (if recipe has two beef ingredients)
   - Each instance counted separately in penalty calculation

2. **Primary Recipe Only**: Multi-recipe meals return only primary dish for scoring
   - ProteinRotationFactor only sees primary protein
   - Side dishes ignored

3. **No Ingredient Deduplication**: System doesn't deduplicate proteins
   - Multiple beef ingredients → counted twice
   - Harsher penalties for ingredient-heavy recipes

---

## Identified Issues and Recommendations

### Issue 1: Duplicate Protein Penalties
**Severity**: Medium
**Location**: ProteinRotationFactor.calculateScore()

When a recipe has the same protein type in multiple ingredients:
```
Recipe: "Beef Ragù" (2 beef ingredients)
├─ mainProteins list: [ProteinType.beef, ProteinType.beef]
├─ Penalty iteration counts both
└─ Average calculated with duplicates
```

**Recommendation**: Consider using Set or deduplicating before penalty calculation

### Issue 2: Secondary Recipes Ignored
**Severity**: Low
**Location**: getRecentMeals() and ProteinRotationFactor

Multi-recipe meals only return primary recipe for scoring. Side dishes' proteins not considered.

**Current Behavior**:
```
Meal: "Chicken with Beef Side"
├─ Primary: Chicken
├─ Side: Beef (not returned by getRecentMeals)
└─ Factor sees: Chicken protein only
```

**Recommendation**: Consider incorporating all recipes in meal for comprehensive protein tracking

### Issue 3: Custom Ingredients Can't Have Proteins
**Severity**: Low
**Location**: Ingredient model and RecipeIngredient

Custom ingredients (no ingredient_id) cannot specify protein type, only tracked ingredients can.

**Recommendation**: Add custom_protein_type field to RecipeIngredient for completeness

### Issue 4: Hard-coded Limits in Recent Meals Loading
**Severity**: Low
**Location**: RecommendationService._buildContext() line 560-562

```dart
final recentMeals = await _dbQueries.getRecentMeals(
    startDate: DateTime.now().subtract(const Duration(days: 14)),
    limit: 20);  // ← Hard-coded
```

**Impact**: Only 20 recent meals considered. If user cooks 5+ times daily, some history lost.

**Recommendation**: Calculate limits based on penalty window requirements

---

## Testing Coverage

**Unit Tests**: ✓ Comprehensive
- `protein_rotation_factor_test.dart`: Tests single proteins, no proteins, non-main proteins
- `variety_encouragement_factor_test.dart`: Tests cook counts and scoring curves

**Integration Tests**: ✓ Good coverage
- `protein_rotation_integration_test.dart`: Tests recent meal impacts
- Tests single proteins, graduated penalties, trend verification

**Gap**: No explicit tests for multi-ingredient recipe scenarios
- Recipe with 2+ protein ingredients
- Duplicate protein detection
- Multi-recipe meals with different proteins

---

## Conclusion

The recommendation engine successfully handles multi-ingredient recipes through:
1. **Database Query**: Properly fetches all ingredients and their protein types
2. **Protein Type Extraction**: Iterates all ingredients, building complete list
3. **Score Calculation**: Averages penalties across all proteins

The system is robust for typical recipes with 1-3 ingredients but could benefit from:
- Explicit deduplication of protein types
- Consideration of secondary recipes in multi-recipe meals
- Extended testing for complex multi-ingredient scenarios
- Documentation clarifying duplicate handling behavior

