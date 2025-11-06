<!-- markdownlint-disable -->
# Recommendation Engine Analysis - Executive Summary

## Analysis Scope

This comprehensive analysis covers the Gastrobrain recommendation engine with focus on:

1. **ProteinRotationFactor** - 30% weight scoring factor that encourages protein variety
2. **getRecipeProteinTypes()** - Database method extracting proteins from ingredients
3. **VarietyEncouragementFactor** - 10% weight factor promoting recipe exploration
4. **RecommendationDatabaseQueries** - Database access layer for recommendation data
5. **Multi-ingredient recipe processing** - How complex recipes are handled

## Key Findings

### Positive: Multi-Ingredient Support Works Well

The system properly processes recipes with multiple ingredients:

```
Recipe: Chicken & Beef Stir Fry
├─ Database: getRecipeIngredients() returns ALL ingredients
├─ Extraction: getRecipeProteinTypes() iterates ALL ingredients
├─ Scoring: ProteinRotationFactor averages penalties across proteins
└─ Result: Both proteins correctly considered
```

**Strengths:**
- Uses LEFT JOIN to fetch ingredients with protein_type from database
- Iterates all ingredients, not just first or primary
- Handles null protein_type gracefully
- Averages penalties across multiple proteins (correct approach)

### Issues Identified

#### 1. **Duplicate Protein Counting** (Medium Severity)
Recipes with same protein in multiple ingredients count each instance separately.

```
Beef Ragù (Beef + Beef Stock):
├─ Beef ingredient 1: 100% penalty (if used yesterday)
├─ Beef ingredient 2: 100% penalty (same ingredient counted again!)
└─ Average: 100% (correct answer but for wrong reason)
```

**Impact**: Recipes with ingredient quantity lists (2 beef steaks) get harsher penalties than intended.

#### 2. **Secondary Recipes Ignored** (Low Severity)
Multi-recipe meals only contribute their primary recipe's proteins.

```
Meal: Chicken + Beef Side
├─ getRecentMeals() returns: {recipe: Chicken, ...}
├─ ProteinRotationFactor sees: [Chicken] only
└─ Beef proteins: Not tracked
```

**Impact**: Incomplete protein history for multi-recipe meals.

#### 3. **Custom Ingredients Unsupported** (Low Severity)
Custom ingredients (no ingredient_id) cannot specify protein type.

**Impact**: Users can't track proteins in custom-created ingredients.

#### 4. **Hard-coded Limits** (Low Severity)
Recent meals limited to 20 meals, 14-day lookback (hardcoded in _buildContext).

**Impact**: High-frequency cooks may lose meal history.

## Code Architecture Overview

```
Database Layer
    ↓
RecommendationDatabaseQueries
    ├─ getRecipeProteinTypes()      ← Multi-ingredient extraction
    ├─ getRecentMeals()             ← Primary recipe only
    ├─ getMealCounts()              ← Aggregation
    └─ getCandidateRecipes()        ← Filtering
    ↓
RecommendationService._buildContext()
    │ (Collects all data needed by factors)
    ↓
Scoring Factors
    ├─ ProteinRotationFactor        ← 30% weight
    ├─ VarietyEncouragementFactor   ← 10% weight
    ├─ FrequencyFactor              ← 35% weight
    └─ [Others]                     ← Remaining weights
    ↓
Weighted Average Score
    ↓
Ranked Recommendations
```

## File Structure

| Component | File | Lines | Purpose |
|-----------|------|-------|---------|
| Protein Rotation | `protein_rotation_factor.dart` | 118 | Score 0-100 based on protein recency |
| Variety | `variety_encouragement_factor.dart` | 66 | Score 0-100 based on cook frequency |
| DB Queries | `recommendation_database_queries.dart` | 293 | Data access for recommendation system |
| Main Service | `recommendation_service.dart` | 800+ | Orchestrates scoring and context building |
| Protein Type | `protein_type.dart` | 78 | Enum with main/non-main distinction |

## Critical Code Sections

### getRecipeProteinTypes() - Multi-Ingredient Processing
```dart
// Line 119-132: Core extraction logic
for (final recipeId in recipeIds) {
  final ingredientMaps = await _dbHelper.getRecipeIngredients(recipeId);
  
  for (final ingredientMap in ingredientMaps) {
    final proteinTypeStr = ingredientMap['protein_type'] as String?;
    
    if (proteinTypeStr != null) {
      // Convert string to enum
      final proteinType = ProteinType.values.firstWhere(...);
      // Add to list (allows duplicates)
      result[recipeId]!.add(proteinType);
    }
  }
}
```

**Key**: Adds ALL proteins to list - duplicates NOT deduplicated

### ProteinRotationFactor - Penalty Averaging
```dart
// Line 92-104: Penalty calculation
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

**Key**: Averages penalties across proteins - good approach for multi-protein recipes

## Test Coverage Analysis

### Existing Tests
- Unit tests for single-protein recipes ✓
- Unit tests for non-protein recipes ✓
- Unit tests for non-main proteins ✓
- Integration tests for penalty calculations ✓
- Tests for graduated penalties over 4-day window ✓

### Test Gaps
- No explicit tests for recipes with 2+ of same protein type ✗
- No tests for multi-recipe meals ✗
- No tests for duplicate protein deduplication ✗
- No tests for custom ingredient handling ✗

## Recommendations

### High Priority
**Fix Duplicate Protein Counting**
- Deduplicate proteins before penalty calculation
- Use `Set<ProteinType>` instead of `List<ProteinType>`
- Or: deduplicate in getRecipeProteinTypes()

### Medium Priority
**Extend Secondary Recipe Support**
- Modify getRecentMeals() to return all recipes in meal
- Update ProteinRotationFactor to consider all proteins
- Add tests for multi-recipe meal scenarios

**Add Custom Ingredient Protein Support**
- Add `customProteinType` field to RecipeIngredient
- Update database schema if needed
- Modify getRecipeProteinTypes() to check custom field

### Low Priority
**Parameterize Recent Meals Limits**
- Move hardcoded 20/14 to configuration
- Calculate based on penalty window (4 days) + margin

## Generated Documentation

Three new documentation files created:

1. **recommendation-engine-analysis.md** (900+ lines)
   - Comprehensive technical analysis
   - Detailed code flow documentation
   - Issue identification with examples
   - Testing coverage assessment

2. **recommendation-architecture-diagram.txt**
   - ASCII architecture visualizations
   - Multi-ingredient flow diagram
   - Duplicate protein issue illustration

3. **recommendation-quick-reference.md**
   - Quick lookup for developers
   - Code examples and debugging tips
   - Performance notes
   - Extension guidelines

All files located in `/docs/` directory.

## Conclusion

The recommendation engine is well-designed and handles multi-ingredient recipes correctly through its averaging approach. The system is robust for typical recipes (1-3 ingredients) but would benefit from:

1. **Explicit duplicate handling** to ensure recipes with repeated proteins (e.g., "Beef & Beef Stock") score correctly
2. **Secondary recipe consideration** for accurate protein tracking in multi-recipe meals
3. **Custom ingredient support** for complete user flexibility
4. **Extended test coverage** for edge cases

The averaging approach for multi-protein recipes is mathematically sound and the database queries properly fetch all ingredients. These are good foundations for building out the identified improvements.

---

**Analysis Date**: 2025-11-06
**Analysis Tool**: Claude Code (Haiku 4.5)
**Repository**: https://github.com/rodrigo-machado/gastrobrain
