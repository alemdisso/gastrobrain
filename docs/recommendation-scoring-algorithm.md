# Gastrobrain Recommendation Scoring Algorithm

## Overview

The Gastrobrain recommendation system uses a weighted scoring algorithm to suggest recipes based on multiple factors. Each factor contributes to the final score with a specific weight, creating a balanced approach that considers frequency preferences, protein variety, user ratings, and recipe variety.

## Scoring Factors

The recommendation algorithm combines the following factors with their respective weights:

| Factor | Weight | Description |
|--------|--------|-------------|
| Frequency | 40% | How "due" a recipe is based on its desired cooking frequency |
| Protein Rotation | 30% | Encourages protein variety by penalizing recently used proteins |
| Rating | 15% | Considers user ratings to prioritize preferred recipes |
| Variety Encouragement | 10% | Boosts recipes cooked less frequently to encourage exploration |
| Randomization | 5% | Adds a small random factor to prevent identical recommendations |

## Factor Details

### 1. Frequency Factor (40%)

This is the primary factor that determines when a recipe should be recommended based on when it was last cooked and its desired frequency.

- **Basis**: Recipe's `desiredFrequency` setting (daily, weekly, biweekly, monthly, etc.)
- **Calculation**:
  - For recipes never cooked: 85 points (high but not perfect)
  - For recipes not yet due: Score from 0-85 based on how close they are to being due
  - For overdue recipes: Score from 85-100 using a logarithmic scale based on how overdue
  - Recipes cooked very recently (< 25% of their cycle) receive a penalty

```
dueRatio = daysSinceLastCooked / preferredInterval

if dueRatio < 1.0:
    // Not yet due - scale from 0 to 85
    score = dueRatio * 85.0
else:
    // Recipe is overdue - scale from 85 to 100 based on how overdue
    overdueness = min(dueRatio - 1.0, 7.0)
    overdueScore = 85.0 + (15.0 * (log(1.0 + overdueness) / log(8.0)))
    score = overdueScore

if dueRatio < 0.25:
    // Apply penalty for very recently cooked recipes
    score = score * (0.5 + dueRatio * 2)
```

### 2. Protein Rotation Factor (30%)

This factor encourages protein variety by penalizing recipes with protein types that have been used recently.

- **Basis**: Protein types in the recipe and in recently cooked meals
- **Calculation**:
  - Recipes with no proteins: 70 points (neutral)
  - Recipes with non-main proteins only: 90 points (high)
  - Otherwise, apply graduated penalties based on how recently each protein was used:
    - 1 day ago: 100% penalty (0 points)
    - 2 days ago: 75% penalty (25 points)
    - 3 days ago: 50% penalty (50 points)
    - 4 days ago: 25% penalty (75 points)
    - 5+ days ago: No penalty (100 points)

The system averages the penalties for all proteins in a recipe with multiple protein types.

### 3. Rating Factor (15%)

This factor acts as a quality tiebreaker, giving preference to recipes the user has rated highly.

- **Basis**: User's 1-5 star rating for each recipe
- **Calculation**:
  - No rating (0 stars): 50 points (neutral)
  - 1 star rating: 20 points
  - 2 star rating: 40 points
  - 3 star rating: 60 points
  - 4 star rating: 80 points
  - 5 star rating: 100 points

### 4. Variety Encouragement Factor (10%)

This factor promotes exploration of the full recipe collection by favoring recipes that have been cooked less frequently.

- **Basis**: Total number of times a recipe has been cooked
- **Calculation**:
  - Never cooked: 100 points (perfect score)
  - Otherwise, uses an exponential decay formula:
    ```
    score = 100.0 * exp(-0.07 * cookCount)
    ```
  This creates a curve where:
  - 0 cooks = 100 points
  - 1 cook = 85 points
  - 2 cooks = 77 points
  - 5 cooks = 63 points
  - 10 cooks = 50 points
  - 20 cooks = 37 points
  - 50 cooks = 19 points

### 5. Randomization Factor (5%)

This factor adds a small random adjustment to prevent identical recommendations and keep suggestions fresh.

- **Calculation**: Small random adjustment between 0-5 points
- **Purpose**: Creates variety in recommendations even when other factors are similar

## Final Score Calculation

The final recommendation score is a weighted average of all factor scores:

```
finalScore = (frequencyScore * 0.40) + 
             (proteinRotationScore * 0.30) + 
             (ratingScore * 0.15) + 
             (varietyScore * 0.10) + 
             (randomScore * 0.05)
```

Recipes are then sorted by their final score in descending order, with the highest-scoring recipes recommended first.

## Context-Aware Recommendations

The recommendation system can be further customized with additional context parameters:

- **Meal Type**: Different preferences for lunch vs. dinner
- **Date**: Target date for the recommendation
- **Exclusions**: Recipes to exclude from recommendations
- **Protein Avoidance**: Specific protein types to avoid

These context parameters allow the system to provide tailored recommendations for specific meal planning scenarios.

## Performance Optimization

- The system employs caching mechanisms to store intermediate calculations
- It uses batch loading of data to minimize database queries
- Protein types and meal counts are pre-loaded for efficient scoring
- Results can be cached when generating recommendations for similar contexts

## Future Extensions

The recommendation system is designed with an extensible architecture that allows for additional factors to be added in the future, such as:

- Seasonal ingredient availability
- Time constraints (weekday vs. weekend cooking)
- Success rate of previous cooking attempts
- Dietary preferences
- Special occasion recommendations
