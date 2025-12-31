# Gastrobrain Recommendation Engine

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Scoring Algorithm](#scoring-algorithm)
- [Implementation Details](#implementation-details)
- [Developer Guide](#developer-guide)
- [Known Issues](#known-issues)
- [Testing](#testing)

---

## Overview

The Gastrobrain recommendation system uses a weighted scoring algorithm to suggest recipes based on multiple factors. The system is designed with an extensible architecture that allows for additional factors to be added in the future.

### Key Features
- **Multi-factor scoring**: Combines frequency, protein rotation, rating, variety, and randomization
- **Temporal context awareness**: Adapts recommendations based on weekday/weekend patterns
- **Multi-ingredient support**: Properly handles recipes with multiple protein sources
- **Extensible factor system**: Clean separation of concerns allows easy addition of new factors

### Design Philosophy
- **Frequency-first**: Primary driver is recipe due date based on desired frequency
- **Variety through protein rotation**: Encourages dietary diversity through protein tracking
- **Balanced exploration**: Promotes trying new recipes while respecting user preferences
- **Context-aware**: Adapts to meal type, date, and user constraints

---

## Architecture

### Four-Layer Architecture

```
LAYER 1: DATABASE ACCESS
├── DatabaseHelper.getRecipeIngredients(recipeId)
│   └── Returns: List<Map<String, dynamic>> with protein_type field
│
└── RecommendationDatabaseQueries
    ├── getRecipeProteinTypes(recipeIds) - Extract proteins from ingredients
    ├── getRecentMeals(dateRange, limit) - Load recent cooking history
    ├── getMealCounts(recipeIds) - Count times each recipe was cooked
    └── getCandidateRecipes(filters) - Get filtered recipe list

LAYER 2: CONTEXT BUILDING
RecommendationService._buildContext()
├─ Collects data needed by factors:
│  ├─ proteinTypes: Map<recipeId, List<ProteinType>>
│  ├─ recentMeals: List<{meal, recipe, cookedAt}>
│  ├─ lastCooked: Map<recipeId, DateTime?>
│  ├─ mealCounts: Map<recipeId, int>
│  └─ feedbackHistory, randomSeed, etc.
└─ Smart loading: Only fetches data required by active factors

LAYER 3: RECOMMENDATION FACTORS
├─ FrequencyFactor (35-40%) - Recipe due date calculation
├─ ProteinRotationFactor (25-30%) - Protein variety encouragement
├─ RatingFactor (10-20%) - User preference weighting
├─ VarietyEncouragementFactor (5-15%) - Recipe exploration boost
├─ DifficultyFactor (0-20%) - Temporal complexity consideration
└─ RandomizationFactor (5-10%) - Freshness in recommendations

LAYER 4: SCORING & RANKING
For each Recipe:
  factorScores = {factor.id: factor.calculateScore(recipe, context)}
  weightedScore = Σ(score * weight / 100)
  Sort by weightedScore descending
```

### Data Flow Example

```
User Request: getRecommendations(count: 5, weekdayMeal: true)
    ↓
1. Build Context (_buildContext)
   ├─ Load recent meals (14 days, 20 meals)
   ├─ Extract protein types for all recipes
   ├─ Collect meal counts and last cooked dates
   └─ Apply weekday weight profile
    ↓
2. Get Candidate Recipes
   ├─ Apply exclusion filters
   ├─ Apply protein filters (avoid/required)
   └─ Get recipe list
    ↓
3. Score Each Recipe (_scoreRecipes)
   ├─ For each factor:
   │  └─ Calculate score (0-100)
   ├─ Apply factor weights
   └─ Calculate weighted total
    ↓
4. Sort and Return Top N
```

---

## Scoring Algorithm

### Factor Weights

The recommendation algorithm combines the following factors with their respective weights:

| Factor | Weight | Description |
|--------|--------|-------------|
| Frequency | 35-40% | How "due" a recipe is based on its desired cooking frequency |
| Protein Rotation | 25-30% | Encourages protein variety by penalizing recently used proteins |
| Rating | 10-20% | Considers user ratings to prioritize preferred recipes |
| Variety Encouragement | 5-15% | Boosts recipes cooked less frequently to encourage exploration |
| Difficulty | 0-20% | Temporal consideration (easier recipes on weekdays) |
| Randomization | 5-10% | Adds random factor to prevent identical recommendations |

### Weight Profiles

**Default Profile:**
```
Frequency:     35%
Protein:       30%
Rating:        15%
Variety:       10%
Randomization:  5%
User Feedback:  5%
```

**Weekday Profile:**
```
Frequency:     35%
Protein:       30%
Difficulty:    20%  ← Emphasize simplicity
Rating:        10%
Variety:        5%
```

**Weekend Profile:**
```
Frequency:     25%
Protein:       25%
Rating:        20%  ← Quality matters more
Variety:       15%  ← More exploration
Randomization: 10%
Difficulty:     5%
```

### Factor Details

#### 1. Frequency Factor (35-40%)

Determines when a recipe should be recommended based on when it was last cooked and its desired frequency.

**Scoring Logic:**
```
dueRatio = daysSinceLastCooked / preferredInterval

if never cooked:
    score = 85.0  // High but not perfect (encourages trying)

if dueRatio < 1.0:
    // Not yet due - scale from 0 to 85
    score = dueRatio * 85.0

if dueRatio >= 1.0:
    // Overdue - scale from 85 to 100 based on how overdue
    overdueness = min(dueRatio - 1.0, 7.0)
    score = 85.0 + (15.0 * (log(1.0 + overdueness) / log(8.0)))

if dueRatio < 0.25:
    // Penalty for very recently cooked recipes
    score = score * (0.5 + dueRatio * 2)
```

#### 2. Protein Rotation Factor (25-30%)

Encourages protein variety by penalizing recipes with protein types used recently.

**Penalty Schedule:**

| Days Ago | Penalty | Score |
|----------|---------|-------|
| 1 day | 100% | 0.0 |
| 2 days | 75% | 25.0 |
| 3 days | 50% | 50.0 |
| 4 days | 25% | 75.0 |
| 5+ days | 0% | 100.0 |

**Special Cases:**

| Scenario | Score | Logic |
|----------|-------|-------|
| No proteins | 70.0 | Vegetable dishes neutral |
| Only non-main proteins | 90.0 | Encouraged (no rotation needed) |
| Multiple proteins | Average | Penalties averaged across all proteins |

**Main vs Non-Main Proteins:**

- **Main Proteins** (trigger rotation): beef, chicken, pork, fish, seafood, lamb
- **Non-Main Proteins** (ignored): charcuterie, offal, plantBased, other

**Multi-Protein Example:**
```
Recipe: "Chicken & Beef Stir Fry"
├─ Chicken (used 2 days ago): 75% penalty
├─ Beef (not used): 0% penalty
├─ Average: 37.5% penalty
└─ Score: 62.5
```

#### 3. Rating Factor (10-20%)

Acts as a quality tiebreaker, giving preference to recipes the user has rated highly.

```
No rating (0 stars): 50 points (neutral)
1 star:  20 points
2 stars: 40 points
3 stars: 60 points
4 stars: 80 points
5 stars: 100 points
```

#### 4. Variety Encouragement Factor (5-15%)

Promotes exploration of the full recipe collection by favoring recipes that have been cooked less frequently.

**Formula:** `score = 100.0 * exp(-0.07 * cookCount)`

| Cook Count | Score |
|------------|-------|
| 0 | 100.0 |
| 1 | 85.2 |
| 2 | 77.4 |
| 5 | 63.4 |
| 10 | 50.0 |
| 20 | 37.1 |
| 50 | 19.1 |

#### 5. Randomization Factor (5-10%)

Adds a small random adjustment to prevent identical recommendations and keep suggestions fresh.

### Final Score Calculation

```dart
finalScore = (frequencyScore * frequencyWeight) +
             (proteinRotationScore * proteinWeight) +
             (ratingScore * ratingWeight) +
             (varietyScore * varietyWeight) +
             (randomScore * randomWeight) +
             (difficultyScore * difficultyWeight)
```

Recipes are sorted by their final score in descending order.

---

## Implementation Details

### File Locations

| Component | File Path |
|-----------|-----------|
| Main Service | `lib/core/services/recommendation_service.dart` |
| Protein Rotation Factor | `lib/core/services/recommendation_factors/protein_rotation_factor.dart` |
| Variety Factor | `lib/core/services/recommendation_factors/variety_encouragement_factor.dart` |
| Frequency Factor | `lib/core/services/recommendation_factors/frequency_factor.dart` |
| Database Queries | `lib/core/services/recommendation_database_queries.dart` |
| Protein Type Model | `lib/models/protein_type.dart` |
| Tests | `test/core/services/recommendation_factors/` |

### Multi-Ingredient Recipe Processing

The system properly handles recipes with multiple protein sources:

```
Recipe: "Chicken and Beef Stir Fry"
├─ Ingredient 1: Chicken Breast (protein_type: 'chicken')
├─ Ingredient 2: Beef Stock (protein_type: 'beef')
└─ Ingredient 3: Vegetables (protein_type: null)

Step 1: Database Query (getRecipeIngredients)
└─ LEFT JOIN on ingredients table returns all recipe_ingredients

Step 2: Extract Proteins (getRecipeProteinTypes)
├─ Iterates ingredients, skips nulls
└─ Result: [ProteinType.chicken, ProteinType.beef]

Step 3: Score Calculation (ProteinRotationFactor)
├─ Gets proteins from context
├─ Looks up recent usage for each
├─ Averages penalties
└─ Final score: 100.0 - (avg_penalty * 100.0)
```

### Context Data Structure

```dart
Map<String, dynamic> context = {
  // Request parameters
  'excludeIds': [...],
  'avoidProteinTypes': [...],
  'requiredProteinTypes': [...],
  'forDate': DateTime,
  'mealType': 'lunch',
  'maxDifficulty': 3,
  'weekdayMeal': true,

  // Factor data (loaded conditionally)
  'proteinTypes': {'recipe-1': [ProteinType.chicken]},
  'recentMeals': [{meal, recipe, cookedAt}],
  'lastCooked': {'recipe-1': DateTime},
  'mealCounts': {'recipe-1': 5},
  'feedbackHistory': {...},
  'randomSeed': 123,
};
```

### Database Query Methods

#### getRecipeProteinTypes()
- **Input**: `List<String> recipeIds`
- **Output**: `Map<String, List<ProteinType>>`
- **Behavior**: Fetches ALL ingredients, extracts proteins
- **Multi-ingredient**: Returns list with all proteins (may include duplicates)

#### getRecentMeals()
- **Input**: `startDate`, `endDate` (optional), `limit` (default: 10)
- **Output**: `List<{meal, recipe, cookedAt}>`
- **Multi-recipe meals**: Returns primary recipe only
- **Default range**: 14 days back, 20 meals max

#### getMealCounts()
- **Input**: Optional `recipeIds`
- **Output**: `Map<String, int>` recipe ID → total times cooked
- **Behavior**: Aggregates all meals of each recipe

#### getCandidateRecipes()
- **Input**: `excludeIds`, `limit`, `requiredProteinTypes`, `excludedProteinTypes`
- **Output**: `List<Recipe>`
- **Protein filtering**: Uses `.any()` logic for both required and excluded

---

## Developer Guide

### Basic Usage

```dart
// Get recommendations with temporal context
final recommendations = await service.getRecommendations(
  count: 5,
  avoidProteinTypes: [ProteinType.beef],
  weekdayMeal: true,  // Apply weekday profile
  forDate: DateTime.now(),
);
```

### Getting Detailed Scores

```dart
final detailed = await service.getDetailedRecommendations(count: 5);
for (final rec in detailed.recommendations) {
  print('${rec.recipe.name}: ${rec.totalScore}');
  print('  Protein rotation: ${rec.factorScores['protein_rotation']}');
  print('  Variety: ${rec.factorScores['variety_encouragement']}');
  print('  Frequency: ${rec.factorScores['frequency']}');
}
```

### Debugging Tips

#### Check Protein Types
```dart
final proteinTypes = await _dbQueries.getRecipeProteinTypes(
  recipeIds: ['recipe-id']
);
print('Proteins: ${proteinTypes['recipe-id']}');
```

#### Check Recent Meals
```dart
final recentMeals = await _dbQueries.getRecentMeals(
  startDate: DateTime.now().subtract(Duration(days: 14)),
  limit: 50,
);
for (final meal in recentMeals) {
  print('${meal['recipe'].name}: ${meal['cookedAt']}');
}
```

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

Update `RecommendationService._buildContext()` to provide required data:
```dart
if (requiredData.contains('myData')) {
  context['myData'] = await _dbQueries.getMyData();
}
```

### Performance Notes

- **Context building**: ~50-100ms per request (depends on recipe count)
- **Protein extraction**: O(n*m) where n=recipes, m=avg ingredients per recipe
- **Caching**: Protein types cached in-memory during single recommendation request
- **Database**: Uses batch queries, not N+1 operations

---

## Known Issues

### Custom Ingredients Cannot Specify Protein Type

**Severity**: Low

Custom ingredients (those without `ingredient_id` from the ingredients table) cannot specify protein type. Only tracked ingredients from the database have the `protein_type` field.

**Impact**: When users create custom ingredients that contain proteins (e.g., "Homemade Beef Broth"), the recommendation engine cannot track the protein type for rotation purposes.

**Recommendation**: Add `custom_protein_type` field to `RecipeIngredient` model for completeness.

**Status**: Postponed to future release

---

## Testing

### Test Files
- `test/core/services/recommendation_factors/protein_rotation_factor_test.dart`
- `test/core/services/recommendation_factors/protein_rotation_integration_test.dart`
- `test/core/services/recommendation_factors/variety_encouragement_factor_test.dart`
- `test/core/services/recommendation_factors/frequency_factor_test.dart`
- `test/core/services/recommendation_service_test.dart`

### Running Tests

```bash
# Run all recommendation tests
flutter test test/core/services/recommendation_factors/

# Run specific test
flutter test test/core/services/recommendation_factors/protein_rotation_factor_test.dart

# Run integration tests
flutter test integration_test/
```

### Test Coverage

**Unit Tests**: ✓ Comprehensive
- Tests single proteins, no proteins, non-main proteins
- Tests cook counts and scoring curves
- Tests frequency calculations and overdue logic

**Integration Tests**: ✓ Good coverage
- Tests recent meal impacts
- Tests graduated penalties
- Verifies trend behavior over time

**Gap**: No explicit tests for:
- Recipes with 2+ different protein ingredients
- Duplicate protein detection behavior
- Multi-recipe meals with different proteins

### Mock Database

Tests use `MockDatabaseHelper` for isolated unit testing:
```dart
final mockDb = MockDatabaseHelper();
mockDb.proteinTypesOverride = {
  'recipe-1': [ProteinType.chicken, ProteinType.beef],
};

final service = RecommendationService(dbHelper: mockDb);
```

---

## Future Extensions

The recommendation system is designed to support additional factors such as:

- **Seasonal ingredient availability** - Boost recipes with in-season ingredients
- **Time constraints** - Consider prep/cook time for busy schedules
- **Success rate tracking** - Factor in cooking attempt outcomes
- **Dietary preferences** - Support flexible dietary restrictions
- **Special occasion recommendations** - Holiday and event-specific suggestions
- **Nutritional balance** - Consider macro/micro nutrient distribution
- **Meal plan integration** - Avoid recommending already-planned recipes

---

**Last Updated**: 2025-11-11 (v0.1.0)
