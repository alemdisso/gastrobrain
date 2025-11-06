<!-- markdownlint-disable -->
# Recommendation Engine Quick Reference Guide

## File Locations

| Component | File Path |
|-----------|-----------|
| Protein Rotation Factor | `/lib/core/services/recommendation_factors/protein_rotation_factor.dart` |
| Variety Factor | `/lib/core/services/recommendation_factors/variety_encouragement_factor.dart` |
| Database Queries | `/lib/core/services/recommendation_database_queries.dart` |
| Main Service | `/lib/core/services/recommendation_service.dart` |
| Protein Type Model | `/lib/models/protein_type.dart` |
| Integration Tests | `/test/core/services/recommendation_factors/protein_rotation_integration_test.dart` |
| Algorithm Docs | `/docs/recommendation-scoring-algorithm.md` |

## Key Methods Reference

### Getting Recipe Proteins
```dart
// Get protein types for a list of recipes
final proteinMap = await _dbQueries.getRecipeProteinTypes(
  recipeIds: ['recipe-1', 'recipe-2']
);

// Result: {'recipe-1': [ProteinType.chicken, ProteinType.beef], ...}
```

### Building Recommendation Context
```dart
// Context is built automatically with data needed by factors
final context = await _buildContext(
  excludeIds: [],
  avoidProteinTypes: [ProteinType.beef],
  requiredProteinTypes: [ProteinType.chicken],
  forDate: DateTime.now(),
  weekdayMeal: true,
);

// Contains: proteinTypes, recentMeals, mealCounts, lastCooked, etc.
```

### Scoring Recipes
```dart
// Get recommendations with temporal context
final recommendations = await service.getRecommendations(
  count: 5,
  avoidProteinTypes: [ProteinType.beef],
  weekdayMeal: true,  // Apply weekday profile
  forDate: DateTime.now(),
);
```

## Protein Rotation Factor Details

### Score Calculation Quick Reference

| Scenario | Score | Logic |
|----------|-------|-------|
| No proteins | 70.0 | Vegetable dishes neutral |
| Only non-main proteins | 90.0 | Encouraged (no rotation needed) |
| Main protein used 1 day ago | 0.0 | 100% penalty |
| Main protein used 2 days ago | 25.0 | 75% penalty |
| Main protein used 3 days ago | 50.0 | 50% penalty |
| Main protein used 4 days ago | 75.0 | 25% penalty |
| Main protein not used recently | 100.0 | No penalty |

### Multi-Protein Recipes
```
Recipe: Chicken & Beef Stir Fry
├─ Chicken (used 2 days ago): 75% penalty
├─ Beef (not used): 0% penalty
├─ Average: 37.5% penalty
└─ Score: 62.5
```

### Main vs Non-Main Proteins

**Main Proteins** (trigger rotation):
- beef
- chicken
- pork
- fish
- seafood
- lamb

**Non-Main Proteins** (ignored by rotation factor):
- charcuterie
- offal
- plantBased
- other

## Variety Encouragement Factor Details

### Score Calculation

```
Formula: score = 100.0 * exp(-0.07 * cookCount)

Cook Count | Score
-----------|-------
0 | 100.0
1 | 85.2
2 | 77.4
5 | 63.4
10 | 50.0
20 | 37.1
```

## Context Data Structure

```dart
Map<String, dynamic> context = {
  // Parameters
  'excludeIds': [...],
  'avoidProteinTypes': [...],
  'requiredProteinTypes': [...],
  'forDate': DateTime,
  'mealType': 'lunch',
  'maxDifficulty': 3,
  'weekdayMeal': true,
  
  // ProteinRotationFactor
  'proteinTypes': {'recipe-1': [ProteinType.chicken]},
  'recentMeals': [{meal, recipe, cookedAt}],
  
  // FrequencyFactor
  'lastCooked': {'recipe-1': DateTime},
  
  // VarietyEncouragementFactor
  'mealCounts': {'recipe-1': 5},
  
  // Other factors
  'feedbackHistory': {...},
  'randomSeed': 123,
};
```

## Database Query Methods

### getRecipeProteinTypes()
- **Input**: List<String> recipeIds
- **Output**: Map<String, List<ProteinType>>
- **Behavior**: Fetches ALL ingredients, extracts proteins
- **Multi-ingredient**: Returns list with all proteins (including duplicates)

### getRecentMeals()
- **Input**: startDate, endDate (optional), limit (default: 10)
- **Output**: List<{meal, recipe, cookedAt}>
- **Multi-recipe meals**: Returns primary recipe only
- **Default range**: 14 days back, 20 meals max

### getMealCounts()
- **Input**: Optional recipeIds
- **Output**: Map<String, int> recipe ID → total times cooked
- **Behavior**: Aggregates all meals of each recipe

### getCandidateRecipes()
- **Input**: excludeIds, limit, requiredProteinTypes, excludedProteinTypes
- **Output**: List<Recipe>
- **Protein filtering**: Uses .any() logic for both required and excluded

## Known Issues & Notes

### Issue 1: Duplicate Proteins
Recipes with multiple instances of the same protein type (e.g., beef meat + beef stock) have each instance counted separately in penalty calculation.

**Example**:
```
Beef Ragù (2 beef ingredients):
├─ Penalties: [100%, 100%] (beef used yesterday)
├─ Average: 100%
└─ Score: 0.0
```

**Workaround**: Use Set-based deduplication if stricter behavior needed.

### Issue 2: Custom Ingredients
Custom ingredients cannot specify protein type—only tracked ingredients from the ingredient database can have protein_type set.

### Issue 3: Secondary Recipes in Multi-Recipe Meals
Only the primary recipe's proteins are considered. Side dish proteins are not tracked for rotation.

## Testing

### Test Files
- `/test/core/services/recommendation_factors/protein_rotation_factor_test.dart`
- `/test/core/services/recommendation_factors/protein_rotation_integration_test.dart`
- `/test/core/services/recommendation_factors/variety_encouragement_factor_test.dart`

### Running Tests
```bash
flutter test test/core/services/recommendation_factors/

# Specific test
flutter test test/core/services/recommendation_factors/protein_rotation_factor_test.dart
```

## Performance Notes

- **Context building**: ~50-100ms per request (depends on recipe count)
- **Protein extraction**: O(n*m) where n=recipes, m=avg ingredients per recipe
- **Caching**: Protein types cached in-memory during single recommendation request
- **Database**: Uses batch queries, not N+1 operations

## Debugging Tips

### Check Protein Types Being Extracted
```dart
final proteinTypes = await _dbQueries.getRecipeProteinTypes(
  recipeIds: ['recipe-id']
);
print('Proteins: ${proteinTypes['recipe-id']}');
```

### Check Recent Meals
```dart
final recentMeals = await _dbQueries.getRecentMeals(
  startDate: DateTime.now().subtract(Duration(days: 14)),
  limit: 50,
);
for (final meal in recentMeals) {
  print('${meal['recipe'].name}: ${meal['cookedAt']}');
}
```

### Check Recommendation Scoring
```dart
final detailed = await service.getDetailedRecommendations(count: 5);
for (final rec in detailed.recommendations) {
  print('${rec.recipe.name}: ${rec.totalScore}');
  print('  Protein rotation: ${rec.factorScores['protein_rotation']}');
  print('  Variety: ${rec.factorScores['variety_encouragement']}');
}
```

## Weight Profiles

### Default Weights
- Frequency: 35%
- Protein Rotation: 30%
- Rating: 15%
- Variety: 10%
- Randomization: 5%
- User Feedback: 5%

### Weekday Profile
- Frequency: 35%
- Protein Rotation: 30%
- Rating: 10%
- Difficulty: 20%
- Variety: 5%

### Weekend Profile
- Frequency: 25%
- Protein Rotation: 25%
- Rating: 20%
- Variety: 15%
- Randomization: 10%
- Difficulty: 5%

## Extending the System

### Adding a New Factor
```dart
class MyCustomFactor implements RecommendationFactor {
  @override
  String get id => 'my_factor';
  
  @override
  int get defaultWeight => 10;
  
  @override
  Set<String> get requiredData => {'myData'};
  
  @override
  Future<double> calculateScore(Recipe recipe, Map<String, dynamic> context) async {
    final myData = context['myData'] as Map<String, dynamic>;
    // ... scoring logic ...
    return score; // 0-100
  }
}

// Register it
service.registerFactor(MyCustomFactor());
```

### Adding Context Data
In `RecommendationService._buildContext()`:
```dart
if (requiredData.contains('myData')) {
  context['myData'] = await _dbQueries.getMyData();
}
```
