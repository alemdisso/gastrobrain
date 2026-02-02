# Example 3: Service Integration

This example demonstrates implementing a Phase 2 service extraction and integration with 6 checkpoints, showing ServiceProvider integration and proper DI patterns.

## Context

- **Issue**: #230 - Extract recommendation caching into dedicated service
- **Branch**: `feature/230-extract-recommendation-cache`
- **Roadmap**: `docs/planning/0.1.6/ISSUE-230-ROADMAP.md`
- **Category**: Service Logic (6 checkpoints)

---

## Initial Context Detection

```
Phase 2 Implementation for Issue #230
═══════════════════════════════════════

Branch: feature/230-extract-recommendation-cache
Roadmap: docs/planning/0.1.6/ISSUE-230-ROADMAP.md

Phase 2 Requirements Summary:
- Extract caching logic from WeeklyPlanScreen into RecommendationCacheService
- Create service with proper DI pattern
- Integrate with ServiceProvider
- Update WeeklyPlanScreen to use extracted service

Implementation Categories Detected:
├─ Database: No
├─ Models: No
├─ Services: RecommendationCacheService (NEW)
├─ Widgets: WeeklyPlanScreen (UPDATE)
├─ Providers: No
└─ Localization: No

Pattern References Found:
- Similar service: lib/core/services/meal_plan_analysis_service.dart
- DI pattern: lib/core/di/service_provider.dart
- Extraction target: lib/screens/weekly_plan_screen.dart (lines 75-130)

Checkpoint Plan:
1. Create RecommendationCacheService class
2. Implement core caching logic
3. Add context building methods
4. Integrate with ServiceProvider
5. Update WeeklyPlanScreen to use service
6. Verify integration

Total: 6 checkpoints

Ready to start Checkpoint 1/6? (y/n)
```

---

## Checkpoint 1: Create RecommendationCacheService Class

```
═══════════════════════════════════════
CHECKPOINT 1/6: Create RecommendationCacheService Class
Goal: Create service class structure with proper DI

Pattern Context:
- Similar implementation: lib/core/services/meal_plan_analysis_service.dart
- Key patterns:
  • Constructor dependency injection
  • Private dependencies with _prefix
  • Documentation comments

Progress:
⧗ Checkpoint 1: Create service class [CURRENT]
○ Checkpoint 2: Implement caching logic
○ Checkpoint 3: Add context building
○ Checkpoint 4: Integrate with ServiceProvider
○ Checkpoint 5: Update WeeklyPlanScreen
○ Checkpoint 6: Verify integration

Tasks:
- [ ] Create service file
- [ ] Define class with dependencies
- [ ] Add constructor with DI
- [ ] Add documentation

Implementation:

File: lib/core/services/recommendation_cache_service.dart (NEW)

```dart
import '../../database/database_helper.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_plan_item.dart';
import '../../models/protein_type.dart';
import '../../models/recipe.dart';
import '../../models/recipe_recommendation.dart';
import '../../models/recommendation_results.dart' as model;
import 'recommendation_service.dart';
import 'meal_plan_analysis_service.dart';

/// Service for managing recommendation caching and context building
///
/// Provides caching, context building, and retrieval of recipe recommendations
/// for meal planning slots. Handles both simple and detailed recommendations.
class RecommendationCacheService {
  final DatabaseHelper _dbHelper;
  final RecommendationService _recommendationService;
  final MealPlanAnalysisService _mealPlanAnalysis;

  /// Cache for recommendations to improve performance
  final Map<String, List<Recipe>> _recommendationCache = {};

  RecommendationCacheService(
    this._dbHelper,
    this._recommendationService,
    this._mealPlanAnalysis,
  );

  // Methods will be added in subsequent checkpoints
}
```

Files Created:
- lib/core/services/recommendation_cache_service.dart [NEW]

Verification Steps:
1. flutter analyze lib/core/services/recommendation_cache_service.dart
2. Verify class structure compiles

Ready to proceed to Checkpoint 2/6? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 2: Implement Core Caching Logic

```
═══════════════════════════════════════
CHECKPOINT 2/6: Implement Core Caching Logic
Goal: Add cache management methods

Pattern Context:
- Similar caching: Current implementation in weekly_plan_screen.dart
- Key patterns:
  • Cache key generation from date + mealType
  • Map-based cache storage
  • Invalidation methods

Progress:
✓ Checkpoint 1: Create service class [COMPLETE]
⧗ Checkpoint 2: Implement caching logic [CURRENT]
○ Checkpoint 3: Add context building
○ Checkpoint 4: Integrate with ServiceProvider
○ Checkpoint 5: Update WeeklyPlanScreen
○ Checkpoint 6: Verify integration

Tasks:
- [ ] Add cache key generation
- [ ] Add cache invalidation methods
- [ ] Add cache retrieval with fallback

Implementation:

File: lib/core/services/recommendation_cache_service.dart

ADD after constructor:

```dart
/// Creates a cache key for a specific meal slot
String _getRecommendationCacheKey(DateTime date, String mealType) {
  return '${date.toIso8601String()}-$mealType';
}

/// Invalidates the cached recommendations for a specific meal slot
void invalidateSlotCache(DateTime date, String mealType) {
  final cacheKey = _getRecommendationCacheKey(date, mealType);

  // Remove this specific slot from the cache
  if (_recommendationCache.containsKey(cacheKey)) {
    _recommendationCache.remove(cacheKey);
  }
}

/// Clears all cached recommendations
void clearAllCache() {
  _recommendationCache.clear();
}

/// Checks if recommendations are cached for a slot
bool hasCachedRecommendations(DateTime date, String mealType) {
  final cacheKey = _getRecommendationCacheKey(date, mealType);
  return _recommendationCache.containsKey(cacheKey);
}
```

Files Modified:
- lib/core/services/recommendation_cache_service.dart: Added cache methods

Verification Steps:
1. flutter analyze lib/core/services/recommendation_cache_service.dart
2. Verify methods compile correctly

Ready to proceed to Checkpoint 3/6? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 3: Add Context Building Methods

```
═══════════════════════════════════════
CHECKPOINT 3/6: Add Context Building Methods
Goal: Add recommendation context and retrieval methods

Pattern Context:
- Extracted from: lib/screens/weekly_plan_screen.dart (lines 200-250)
- Key patterns:
  • Async method with Future return
  • Context map building
  • Integration with MealPlanAnalysisService

Progress:
✓ Checkpoint 1: Create service class [COMPLETE]
✓ Checkpoint 2: Implement caching logic [COMPLETE]
⧗ Checkpoint 3: Add context building [CURRENT]
○ Checkpoint 4: Integrate with ServiceProvider
○ Checkpoint 5: Update WeeklyPlanScreen
○ Checkpoint 6: Verify integration

Tasks:
- [ ] Add buildRecommendationContext method
- [ ] Add getSlotRecommendations method
- [ ] Add getDetailedSlotRecommendations method

Implementation:

File: lib/core/services/recommendation_cache_service.dart

ADD after cache methods:

```dart
/// Build enhanced context for recipe recommendations using dual-context analysis
Future<Map<String, dynamic>> buildRecommendationContext({
  required MealPlan? mealPlan,
  DateTime? forDate,
  String? mealType,
}) async {
  // Get planned context (current meal plan) - handle null case
  final plannedRecipeIds = mealPlan != null
      ? await _mealPlanAnalysis.getPlannedRecipeIds(mealPlan)
      : <String>[];
  final plannedProteins = mealPlan != null
      ? await _mealPlanAnalysis.getPlannedProteinsForWeek(mealPlan)
      : <ProteinType>[];

  // Get recently cooked context (meal history)
  final recentRecipeIds =
      await _mealPlanAnalysis.getRecentlyCookedRecipeIds(dayWindow: 5);
  final recentProteins =
      await _mealPlanAnalysis.getRecentlyCookedProteins(dayWindow: 5);

  // Calculate penalty strategy - handle null meal plan
  final penaltyStrategy = mealPlan != null
      ? await _mealPlanAnalysis.calculateProteinPenaltyStrategy(
          mealPlan,
          forDate ?? DateTime.now(),
          mealType ?? MealPlanItem.lunch,
        )
      : null;

  return {
    'forDate': forDate,
    'mealType': mealType,
    'plannedRecipeIds': plannedRecipeIds,
    'recentlyCookedRecipeIds': recentRecipeIds,
    'plannedProteins': plannedProteins,
    'recentProteins': recentProteins,
    'penaltyStrategy': penaltyStrategy,
    // Backward compatibility
    'excludeIds': plannedRecipeIds,
  };
}

/// Returns simple recipes without scores for caching.
Future<List<Recipe>> getSlotRecommendations({
  required MealPlan? mealPlan,
  required DateTime date,
  required String mealType,
  int count = 5,
}) async {
  final cacheKey = _getRecommendationCacheKey(date, mealType);

  // Check if we have cached recommendations
  if (_recommendationCache.containsKey(cacheKey)) {
    return _recommendationCache[cacheKey]!;
  }

  // Build context for recommendations
  final context = await buildRecommendationContext(
    mealPlan: mealPlan,
    forDate: date,
    mealType: mealType,
  );

  // Determine if this is a weekday
  final isWeekday = date.weekday >= 1 && date.weekday <= 5;

  // Get recommendations with meal plan integration
  final recommendations = await _recommendationService.getRecommendations(
    count: count,
    excludeIds: context['plannedRecipeIds'] ?? [],
    mealPlan: mealPlan,
    forDate: date,
    mealType: mealType,
    weekdayMeal: isWeekday,
    maxDifficulty: isWeekday ? 4 : null,
  );

  // Cache the recommendations
  _recommendationCache[cacheKey] = recommendations;

  return recommendations;
}

/// Gets detailed recommendations with scores and saves to recommendation history
Future<({List<RecipeRecommendation> recommendations, String historyId})>
    getDetailedSlotRecommendations({
  required MealPlan? mealPlan,
  required DateTime date,
  required String mealType,
  int count = 5,
}) async {
  // Build context for recommendations
  final context = await buildRecommendationContext(
    mealPlan: mealPlan,
    forDate: date,
    mealType: mealType,
  );

  // Determine if this is a weekday
  final isWeekday = date.weekday >= 1 && date.weekday <= 5;

  // Get detailed recommendations with scores
  final recommendations =
      await _recommendationService.getDetailedRecommendations(
    count: count,
    excludeIds: context['plannedRecipeIds'] ?? [],
    mealPlan: mealPlan,
    forDate: date,
    mealType: mealType,
    weekdayMeal: isWeekday,
    maxDifficulty: isWeekday ? 4 : null,
  );

  // Convert and save to history
  final modelResults = model.RecommendationResults(
    recommendations: recommendations.recommendations,
    totalEvaluated: recommendations.totalEvaluated,
    queryParameters: recommendations.queryParameters,
    generatedAt: recommendations.generatedAt,
  );

  final historyId = await _dbHelper.saveRecommendationHistory(
    modelResults,
    'meal_planning',
    targetDate: date,
    mealType: mealType,
  );

  return (
    recommendations: recommendations.recommendations,
    historyId: historyId
  );
}

/// Refreshes detailed recommendations for a slot
Future<({List<RecipeRecommendation> recommendations, String historyId})>
    refreshDetailedRecommendations({
  required MealPlan? mealPlan,
  required DateTime date,
  required String mealType,
}) async {
  // Clear the cache for this slot
  invalidateSlotCache(date, mealType);

  // Get fresh detailed recommendations
  return await getDetailedSlotRecommendations(
    mealPlan: mealPlan,
    date: date,
    mealType: mealType,
    count: 8,
  );
}
```

Files Modified:
- lib/core/services/recommendation_cache_service.dart: Added context and retrieval methods

Verification Steps:
1. flutter analyze lib/core/services/recommendation_cache_service.dart
2. Verify all async methods compile

Ready to proceed to Checkpoint 4/6? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 4: Integrate with ServiceProvider

```
═══════════════════════════════════════
CHECKPOINT 4/6: Integrate with ServiceProvider
Goal: Register service in ServiceProvider for DI access

Pattern Context:
- Similar registration: lib/core/di/service_provider.dart
- Key patterns:
  • Lazy initialization in getter
  • Dependencies passed to constructor
  • Grouped with related services

Progress:
✓ Checkpoint 1: Create service class [COMPLETE]
✓ Checkpoint 2: Implement caching logic [COMPLETE]
✓ Checkpoint 3: Add context building [COMPLETE]
⧗ Checkpoint 4: Integrate with ServiceProvider [CURRENT]
○ Checkpoint 5: Update WeeklyPlanScreen
○ Checkpoint 6: Verify integration

Tasks:
- [ ] Add import in service_provider.dart
- [ ] Add lazy field for service
- [ ] Add getter method

Implementation:

File: lib/core/di/service_provider.dart

ADD import:
```dart
import '../services/recommendation_cache_service.dart';
```

In the _RecommendationServices class, ADD field and getter:

```dart
// Lazy instance of recommendation cache service
RecommendationCacheService? _recommendationCacheService;

/// Get the recommendation cache service instance
RecommendationCacheService get cacheService {
  _recommendationCacheService ??= RecommendationCacheService(
    ServiceProvider.database.dbHelper,
    recommendationService,
    MealPlanAnalysisService(ServiceProvider.database.dbHelper),
  );
  return _recommendationCacheService!;
}
```

Usage will be:
```dart
ServiceProvider.recommendations.cacheService
```

Files Modified:
- lib/core/di/service_provider.dart: Added RecommendationCacheService registration

Verification Steps:
1. flutter analyze lib/core/di/service_provider.dart
2. Verify service can be accessed

Ready to proceed to Checkpoint 5/6? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 5: Update WeeklyPlanScreen to Use Service

```
═══════════════════════════════════════
CHECKPOINT 5/6: Update WeeklyPlanScreen to Use Service
Goal: Replace inline caching logic with service calls

Pattern Context:
- Current implementation: lib/screens/weekly_plan_screen.dart
- Key patterns:
  • Initialize service in initState
  • Call service methods instead of inline logic
  • Keep DI option for testing

Progress:
✓ Checkpoint 1: Create service class [COMPLETE]
✓ Checkpoint 2: Implement caching logic [COMPLETE]
✓ Checkpoint 3: Add context building [COMPLETE]
✓ Checkpoint 4: Integrate with ServiceProvider [COMPLETE]
⧗ Checkpoint 5: Update WeeklyPlanScreen [CURRENT]
○ Checkpoint 6: Verify integration

Tasks:
- [ ] Add import for new service
- [ ] Add service field
- [ ] Initialize in initState
- [ ] Replace inline cache logic with service calls
- [ ] Update dispose to clear cache

Implementation:

File: lib/screens/weekly_plan_screen.dart

ADD import:
```dart
import '../core/services/recommendation_cache_service.dart';
```

In _WeeklyPlanScreenState, ADD field:
```dart
late RecommendationCacheService _recommendationCache;
```

In initState(), ADD initialization:
```dart
// After _mealPlanAnalysis initialization
_recommendationCache = RecommendationCacheService(
  _dbHelper,
  _recommendationService,
  _mealPlanAnalysis,
);
```

REMOVE inline cache code (the Map and methods that are now in service)

UPDATE _loadData() to use service:
```dart
Future<void> _loadData() async {
  _recommendationCache.clearAllCache(); // Use service method
  setState(() {
    _isLoading = true;
  });
  // ... rest of method
}
```

UPDATE _changeWeek() to use service:
```dart
void _changeWeek(int weekOffset) {
  _recommendationCache.clearAllCache(); // Use service method
  // ... rest of method
}
```

UPDATE _handleSlotTap() to use service:
```dart
final recommendationContext =
    await _recommendationCache.buildRecommendationContext(
  mealPlan: _currentMealPlan,
  forDate: date,
  mealType: mealType,
);
```

UPDATE dispose() to use service:
```dart
@override
void dispose() {
  _scrollController.dispose();
  _tabController.dispose();
  _recommendationCache.clearAllCache(); // Use service method
  super.dispose();
}
```

Files Modified:
- lib/screens/weekly_plan_screen.dart: Updated to use RecommendationCacheService

Verification Steps:
1. flutter analyze lib/screens/weekly_plan_screen.dart
2. Verify no references to removed inline cache code
3. File should be shorter after extraction

Ready to proceed to Checkpoint 6/6? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 6: Verify Integration

```
═══════════════════════════════════════
CHECKPOINT 6/6: Verify Integration
Goal: Ensure complete integration works correctly

Progress:
✓ Checkpoint 1: Create service class [COMPLETE]
✓ Checkpoint 2: Implement caching logic [COMPLETE]
✓ Checkpoint 3: Add context building [COMPLETE]
✓ Checkpoint 4: Integrate with ServiceProvider [COMPLETE]
✓ Checkpoint 5: Update WeeklyPlanScreen [COMPLETE]
⧗ Checkpoint 6: Verify integration [CURRENT]

Tasks:
- [ ] Run full flutter analyze
- [ ] Check file sizes
- [ ] Run existing tests
- [ ] Verify no functionality regressions

Verification Steps:

1. Full static analysis:
```bash
flutter analyze
```

2. File size verification:
- lib/core/services/recommendation_cache_service.dart: ~210 lines ✓
- lib/screens/weekly_plan_screen.dart: Should be ~80 lines shorter ✓

3. Run existing tests:
```bash
flutter test
```

4. SOLID Principles Check:
- Single Responsibility: ✓
  RecommendationCacheService: caching and context building
  WeeklyPlanScreen: UI and user interaction only
- Open/Closed: ✓
  Service can be extended without modifying screen
- Dependency Inversion: ✓
  Screen depends on service abstraction via constructor

5. DI Verification:
- Service can be injected for testing
- ServiceProvider access works for production

Expected Results:
- flutter analyze: No errors
- flutter test: All existing tests pass
- WeeklyPlanScreen cleaner, focused on UI
- Caching logic isolated and testable

═══════════════════════════════════════
```

---

## Phase 2 Completion Summary

```
═══════════════════════════════════════
PHASE 2 IMPLEMENTATION SUMMARY
═══════════════════════════════════════

Issue: #230 - Extract recommendation caching into dedicated service
Branch: feature/230-extract-recommendation-cache

Checkpoints Completed:
✓ Checkpoint 1: Create RecommendationCacheService class
✓ Checkpoint 2: Implement core caching logic
✓ Checkpoint 3: Add context building methods
✓ Checkpoint 4: Integrate with ServiceProvider
✓ Checkpoint 5: Update WeeklyPlanScreen to use service
✓ Checkpoint 6: Verify integration

Files Created:
- lib/core/services/recommendation_cache_service.dart [NEW]

Files Modified:
- lib/core/di/service_provider.dart [MODIFIED]
  └─ Added RecommendationCacheService registration
- lib/screens/weekly_plan_screen.dart [MODIFIED]
  └─ Removed ~80 lines of inline caching logic
  └─ Now uses RecommendationCacheService

Quality Verification:
✓ flutter analyze passes
✓ All files < 400 lines
✓ SOLID principles followed
✓ DI pattern correctly implemented
✓ Service can be tested in isolation

Metrics:
- Lines extracted: ~80
- New service lines: ~210
- Net reduction in screen: ~80 lines
- Improved testability: High

Roadmap Updated:
- docs/planning/0.1.6/ISSUE-230-ROADMAP.md
  └─ Phase 2 checkboxes marked complete

Next Steps:
1. ○ Hand off to gastrobrain-testing-implementation for Phase 3
   Test areas:
   - RecommendationCacheService unit tests
   - Cache key generation
   - Cache invalidation
   - Context building
   - Integration with mock services
2. ○ After testing, proceed to Phase 4 (Documentation & Cleanup)

═══════════════════════════════════════
```

---

## Key Takeaways

1. **Proper Extraction**: Moved logic without changing behavior
2. **DI Pattern**: Service initialized with dependencies via constructor
3. **ServiceProvider Integration**: Registered for app-wide access
4. **SOLID Adherence**: Clear single responsibility for each class
5. **Testability**: Service can be unit tested with mocked dependencies
6. **Code Reduction**: Screen is now cleaner and more focused
