# Example 3: Refactoring Analysis

This example demonstrates Phase 1 analysis for a refactoring issue - extracting a service from a screen.

## Context

- **Issue**: #230 - Extract recommendation caching from WeeklyPlanScreen
- **Branch**: `feature/230-extract-recommendation-cache`
- **Type**: Refactor
- **Roadmap**: `docs/planning/0.1.6/ISSUE-230-ROADMAP.md`

---

## Initial Context

```
Phase 1 Analysis for Issue #230
═══════════════════════════════════════

Branch: feature/230-extract-recommendation-cache
Issue: Extract recommendation caching into dedicated service
Type: Refactor
Roadmap: docs/planning/0.1.6/ISSUE-230-ROADMAP.md

Phase 1 Checklist (from roadmap):
- [ ] Identify code to extract
- [ ] Define service interface
- [ ] Plan extraction strategy
- [ ] Verify behavior preservation
- [ ] Update dependency injection

Analysis Framework:
1. Requirements Deep-Dive
2. Codebase Exploration
3. Technical Design
4. Risk & Edge Case Analysis
5. Implementation Preparation

Ready to start Checkpoint 1/5? (y/n)
```

---

## Checkpoint 1: Requirements Deep-Dive

```
═══════════════════════════════════════
CHECKPOINT 1/5: Requirements Deep-Dive
Goal: Understand the refactoring goals

Reading issue #230 from GitHub...

Issue Type: Refactor (Code Quality)

Title: Extract recommendation caching into dedicated service

Description Summary:
WeeklyPlanScreen has grown too large (1000+ lines) and contains
recommendation caching logic that should be extracted into a
dedicated service for better separation of concerns.

Code Smell:
- WeeklyPlanScreen is 1019 lines (exceeds 400 line guideline)
- Recommendation caching mixed with UI logic
- Cache management duplicated across methods
- Hard to test caching independently

Refactoring Goals:
1. Reduce WeeklyPlanScreen size to < 400 lines
2. Extract caching into RecommendationCacheService
3. Improve testability of caching logic
4. Follow Single Responsibility Principle
5. Maintain existing behavior exactly

Acceptance Criteria:
- [ ] New RecommendationCacheService class created
- [ ] Caching logic moved from screen to service
- [ ] WeeklyPlanScreen uses service via DI
- [ ] All existing tests still pass
- [ ] No behavior changes
- [ ] Screen file < 400 lines after extraction

Behavior to Preserve:
- Recommendations cached per slot (date + mealType)
- Cache invalidated when week changes
- Cache cleared on manual refresh
- Context building for recommendations
- Detailed recommendations with history saving

Scope:
IN SCOPE:
- Extract caching logic
- Create new service
- Update WeeklyPlanScreen to use service
- Register in ServiceProvider

OUT OF SCOPE:
- Adding new features
- Changing caching behavior
- UI modifications
- Other screen refactoring

Requirements clear? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 2: Codebase Exploration

```
═══════════════════════════════════════
CHECKPOINT 2/5: Codebase Exploration
Goal: Identify code to extract and patterns to follow

Progress:
✓ Checkpoint 1: Refactoring goals understood
⧗ Checkpoint 2: Code analysis [CURRENT]

Analyzing WeeklyPlanScreen...

Current File Stats:
- File: lib/screens/weekly_plan_screen.dart
- Total lines: 1019
- State class lines: ~950
- Caching-related lines: ~130

Code to Extract (identified):

1. Cache Data Structure (lines 58-59):
```dart
final Map<String, List<Recipe>> _recommendationCache = {};
```

2. Cache Key Generation (lines ~200-203):
```dart
String _getRecommendationCacheKey(DateTime date, String mealType) {
  return '${date.toIso8601String()}-$mealType';
}
```

3. Cache Invalidation (lines ~205-215):
```dart
void _invalidateSlotCache(DateTime date, String mealType) {
  final cacheKey = _getRecommendationCacheKey(date, mealType);
  if (_recommendationCache.containsKey(cacheKey)) {
    _recommendationCache.remove(cacheKey);
  }
}

void _clearAllCache() {
  _recommendationCache.clear();
}
```

4. Context Building (lines ~220-280):
```dart
Future<Map<String, dynamic>> _buildRecommendationContext({
  required MealPlan? mealPlan,
  DateTime? forDate,
  String? mealType,
}) async {
  // ~60 lines of context building logic
}
```

5. Slot Recommendations (lines ~285-350):
```dart
Future<List<Recipe>> _getSlotRecommendations({...}) async {
  // Check cache
  // Build context
  // Get recommendations
  // Cache results
}
```

6. Detailed Recommendations (lines ~355-420):
```dart
Future<({List<RecipeRecommendation> recommendations, String historyId})>
    _getDetailedSlotRecommendations({...}) async {
  // Context building
  // Get detailed recommendations
  // Save to history
}
```

7. Refresh Method (lines ~425-440):
```dart
Future<...> _refreshDetailedRecommendations({...}) async {
  _invalidateSlotCache(date, mealType);
  return await _getDetailedSlotRecommendations(...);
}
```

Lines to Extract: ~130
Expected Screen Size After: ~890 lines (still too big, but progress)

Similar Service Patterns:

1. MealPlanAnalysisService
   Location: lib/core/services/meal_plan_analysis_service.dart
   Approach: Constructor DI, async methods, no state
   ```dart
   class MealPlanAnalysisService {
     final DatabaseHelper _dbHelper;

     MealPlanAnalysisService(this._dbHelper);

     Future<List<String>> getPlannedRecipeIds(...) async {...}
   }
   ```

2. MealActionService
   Location: lib/core/services/meal_action_service.dart
   Approach: Constructor DI, helper methods, stateless
   Recently extracted from WeeklyPlanScreen - good pattern

3. ServiceProvider Registration
   Location: lib/core/di/service_provider.dart
   Approach: Lazy instantiation in getter
   ```dart
   class _RecommendationServices {
     RecommendationService? _recommendationService;

     RecommendationService get recommendationService {
       _recommendationService ??= RecommendationService(...);
       return _recommendationService!;
     }
   }
   ```

Dependencies of Code to Extract:
- DatabaseHelper (for saving recommendation history)
- RecommendationService (for getting recommendations)
- MealPlanAnalysisService (for context building)

Exploration complete? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 3: Technical Design

```
═══════════════════════════════════════
CHECKPOINT 3/5: Technical Design
Goal: Design the extraction approach

Progress:
✓ Checkpoint 1: Goals understood
✓ Checkpoint 2: Code identified (~130 lines)
⧗ Checkpoint 3: Technical design [CURRENT]

For refactoring #230, the approach is straightforward:

══════════════════════════════════════
APPROACH: Extract to RecommendationCacheService
══════════════════════════════════════

Description:
Create new RecommendationCacheService containing all caching logic.
Service maintains cache state and provides methods for cache
management, context building, and recommendation retrieval.

Service Interface:
```dart
class RecommendationCacheService {
  // Constructor with DI
  RecommendationCacheService(
    DatabaseHelper dbHelper,
    RecommendationService recommendationService,
    MealPlanAnalysisService mealPlanAnalysis,
  );

  // Cache management
  void invalidateSlotCache(DateTime date, String mealType);
  void clearAllCache();

  // Context building
  Future<Map<String, dynamic>> buildRecommendationContext({
    required MealPlan? mealPlan,
    DateTime? forDate,
    String? mealType,
  });

  // Recommendation retrieval
  Future<List<Recipe>> getSlotRecommendations({
    required MealPlan? mealPlan,
    required DateTime date,
    required String mealType,
    int count = 5,
  });

  Future<({List<RecipeRecommendation> recommendations, String historyId})>
      getDetailedSlotRecommendations({
    required MealPlan? mealPlan,
    required DateTime date,
    required String mealType,
    int count = 5,
  });

  Future<...> refreshDetailedRecommendations({
    required MealPlan? mealPlan,
    required DateTime date,
    required String mealType,
  });
}
```

Extraction Strategy:

1. Create service file with empty class
2. Move cache data structure to service
3. Move cache management methods
4. Move context building method
5. Move recommendation methods
6. Update method signatures (remove underscore prefix)
7. Register in ServiceProvider
8. Update WeeklyPlanScreen to use service
9. Verify all tests pass

Technical Decisions:

1. Cache location: In service (not static)
   Rationale: Per-instance cache, testable, follows pattern

2. Method visibility: Public (no underscore)
   Rationale: Called from screen, may be reused

3. Constructor DI: Pass all dependencies
   Rationale: Testable, follows service pattern

4. State ownership: Service owns cache Map
   Rationale: Single source of truth for caching

5. Return types: Keep existing return types
   Rationale: Behavior preservation

Design Patterns Applied:
- Service pattern from MealActionService
- Constructor DI from MealPlanAnalysisService
- ServiceProvider registration pattern

Agree with extraction approach? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 4: Risk & Edge Case Analysis

```
═══════════════════════════════════════
CHECKPOINT 4/5: Risk & Edge Case Analysis
Goal: Ensure refactoring doesn't break anything

Progress:
✓ Checkpoint 1: Goals understood
✓ Checkpoint 2: Code identified
✓ Checkpoint 3: Approach designed
⧗ Checkpoint 4: Risk analysis [CURRENT]

Risk Assessment:

Technical Risks:
┌─────────────────────────────────────────────────────────────┐
│ Risk                    │ Level  │ Mitigation              │
├─────────────────────────────────────────────────────────────┤
│ Behavior change         │ 🟡 MED │ Keep exact method logic │
│                         │        │ Run all tests           │
│ Cache not shared        │ 🟢 LOW │ Same instance via DI    │
│ DI not working          │ 🟢 LOW │ Follow existing pattern │
│ Missing import          │ 🟢 LOW │ flutter analyze         │
│ Test failures           │ 🟡 MED │ May need test updates   │
└─────────────────────────────────────────────────────────────┘

Behavior Preservation Checklist:

1. Cache Key Generation
   Before: _getRecommendationCacheKey in screen
   After: _getRecommendationCacheKey in service (private)
   Verify: Same key format, same behavior

2. Cache Invalidation
   Before: _invalidateSlotCache called from screen
   After: invalidateSlotCache called on service
   Verify: Same slots invalidated

3. Cache Clearing
   Before: _clearAllCache in _loadData, _changeWeek, dispose
   After: clearAllCache on service from same places
   Verify: Cache cleared at same times

4. Context Building
   Before: _buildRecommendationContext in screen
   After: buildRecommendationContext in service
   Verify: Same context map returned

5. Recommendation Retrieval
   Before: _getSlotRecommendations in screen
   After: getSlotRecommendations in service
   Verify: Same recommendations, same caching

6. Detailed Recommendations
   Before: _getDetailedSlotRecommendations in screen
   After: getDetailedSlotRecommendations in service
   Verify: Same recommendations, same history saving

7. Refresh
   Before: _refreshDetailedRecommendations in screen
   After: refreshDetailedRecommendations in service
   Verify: Cache invalidated, fresh data returned

Edge Cases:

1. Service Instance Sharing
   Scenario: Multiple screens need same cache
   Current: Cache in screen (not shared)
   After: Cache in service (shared via ServiceProvider)
   Risk: None - actually improves sharing
   Note: Currently only WeeklyPlanScreen uses this

2. Service Initialization Order
   Scenario: Service depends on other services
   Risk: Circular dependency possible
   Mitigation: Pass dependencies in constructor, not via ServiceProvider

3. Test Mock Behavior
   Scenario: Tests may mock screen differently
   Risk: Tests may need updates
   Mitigation: Service can be injected via constructor in screen

4. Memory Lifecycle
   Scenario: Cache grows unbounded
   Current: Cache cleared on dispose
   After: Service persists (in ServiceProvider)
   Mitigation: Screen still calls clearAllCache on navigation

Testing Requirements:

Existing Tests to Verify:
- [ ] test/screens/weekly_plan_screen_test.dart (all pass)
- [ ] test/widgets/ related tests (all pass)
- [ ] Integration tests using weekly plan

New Tests to Add:
- [ ] RecommendationCacheService unit tests
  - Cache key generation
  - Cache invalidation
  - Context building
  - Recommendation retrieval
  - Cache hit/miss behavior

Refactoring Verification:
- [ ] flutter test (all existing tests pass)
- [ ] Manual testing of weekly plan caching
- [ ] No behavior changes observed

All risks identified? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Checkpoint 5: Implementation Preparation

```
═══════════════════════════════════════
CHECKPOINT 5/5: Implementation Preparation
Goal: Prepare step-by-step extraction plan

Progress:
✓ Checkpoint 1: Goals understood
✓ Checkpoint 2: Code identified
✓ Checkpoint 3: Approach designed
✓ Checkpoint 4: Risks assessed
⧗ Checkpoint 5: Implementation prep [CURRENT]

Implementation Plan:

══════════════════════════════════════
STEP 1: Create Service File
══════════════════════════════════════

File: lib/core/services/recommendation_cache_service.dart (NEW)

Create with imports and empty class:
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

class RecommendationCacheService {
  final DatabaseHelper _dbHelper;
  final RecommendationService _recommendationService;
  final MealPlanAnalysisService _mealPlanAnalysis;

  final Map<String, List<Recipe>> _recommendationCache = {};

  RecommendationCacheService(
    this._dbHelper,
    this._recommendationService,
    this._mealPlanAnalysis,
  );
}
```

Verification: flutter analyze

══════════════════════════════════════
STEP 2: Move Cache Management Methods
══════════════════════════════════════

Move from WeeklyPlanScreen to service:

```dart
String _getRecommendationCacheKey(DateTime date, String mealType) {
  return '${date.toIso8601String()}-$mealType';
}

void invalidateSlotCache(DateTime date, String mealType) {
  final cacheKey = _getRecommendationCacheKey(date, mealType);
  if (_recommendationCache.containsKey(cacheKey)) {
    _recommendationCache.remove(cacheKey);
  }
}

void clearAllCache() {
  _recommendationCache.clear();
}
```

Verification: flutter analyze

══════════════════════════════════════
STEP 3: Move Context Building
══════════════════════════════════════

Move buildRecommendationContext method to service.
Keep exact same logic, just change method visibility.

```dart
Future<Map<String, dynamic>> buildRecommendationContext({
  required MealPlan? mealPlan,
  DateTime? forDate,
  String? mealType,
}) async {
  // Copy exact code from screen
}
```

Verification: flutter analyze

══════════════════════════════════════
STEP 4: Move Recommendation Methods
══════════════════════════════════════

Move getSlotRecommendations and getDetailedSlotRecommendations.
Keep exact same logic.

```dart
Future<List<Recipe>> getSlotRecommendations({
  required MealPlan? mealPlan,
  required DateTime date,
  required String mealType,
  int count = 5,
}) async {
  // Copy exact code from screen
}

Future<({List<RecipeRecommendation> recommendations, String historyId})>
    getDetailedSlotRecommendations({...}) async {
  // Copy exact code from screen
}

Future<...> refreshDetailedRecommendations({...}) async {
  // Copy exact code from screen
}
```

Verification: flutter analyze

══════════════════════════════════════
STEP 5: Register in ServiceProvider
══════════════════════════════════════

File: lib/core/di/service_provider.dart

Add import and getter:
```dart
import '../services/recommendation_cache_service.dart';

// In _RecommendationServices class:
RecommendationCacheService? _cacheService;

RecommendationCacheService get cacheService {
  _cacheService ??= RecommendationCacheService(
    ServiceProvider.database.dbHelper,
    recommendationService,
    MealPlanAnalysisService(ServiceProvider.database.dbHelper),
  );
  return _cacheService!;
}
```

Verification: flutter analyze

══════════════════════════════════════
STEP 6: Update WeeklyPlanScreen
══════════════════════════════════════

File: lib/screens/weekly_plan_screen.dart

1. Add import:
```dart
import '../core/services/recommendation_cache_service.dart';
```

2. Add field:
```dart
late RecommendationCacheService _recommendationCache;
```

3. Initialize in initState:
```dart
_recommendationCache = RecommendationCacheService(
  _dbHelper,
  _recommendationService,
  _mealPlanAnalysis,
);
```

4. Remove extracted code (~130 lines)

5. Update calls:
- `_clearAllCache()` → `_recommendationCache.clearAllCache()`
- `_buildRecommendationContext(...)` → `_recommendationCache.buildRecommendationContext(...)`
- etc.

Verification:
- flutter analyze
- flutter test

══════════════════════════════════════
STEP 7: Add Service Tests
══════════════════════════════════════

File: test/core/services/recommendation_cache_service_test.dart (NEW)

```dart
void main() {
  group('RecommendationCacheService', () {
    late MockDatabaseHelper mockDb;
    late MockRecommendationService mockRecService;
    late MockMealPlanAnalysisService mockAnalysis;
    late RecommendationCacheService service;

    setUp(() {
      mockDb = MockDatabaseHelper();
      mockRecService = MockRecommendationService();
      mockAnalysis = MockMealPlanAnalysisService();
      service = RecommendationCacheService(
        mockDb, mockRecService, mockAnalysis);
    });

    test('cache key format is date-mealType', () {...});
    test('invalidateSlotCache removes specific key', () {...});
    test('clearAllCache removes all entries', () {...});
    test('getSlotRecommendations caches results', () {...});
    test('getSlotRecommendations returns cached on second call', () {...});
  });
}
```

══════════════════════════════════════
IMPLEMENTATION SUMMARY
══════════════════════════════════════

Total Steps: 7
Estimated Checkpoints for Phase 2: 6

Files to Create:
- lib/core/services/recommendation_cache_service.dart
- test/core/services/recommendation_cache_service_test.dart

Files to Modify:
- lib/core/di/service_provider.dart
- lib/screens/weekly_plan_screen.dart

Lines Moved: ~130
Expected Screen Reduction: ~130 lines

Behavior Changes: NONE (must preserve exactly)

Ready to update roadmap? (y/n)
═══════════════════════════════════════
```

**User Response**: y

---

## Phase 1 Completion

```
═══════════════════════════════════════
PHASE 1 ANALYSIS COMPLETE
═══════════════════════════════════════

Issue: #230 - Extract recommendation caching
Type: Refactor
Branch: feature/230-extract-recommendation-cache

Analysis Summary:
✓ Checkpoint 1: Refactoring goals understood
✓ Checkpoint 2: ~130 lines of code identified for extraction
✓ Checkpoint 3: Service interface designed
✓ Checkpoint 4: Behavior preservation verified
✓ Checkpoint 5: 7-step extraction plan prepared

Code to Extract:
- Cache data structure
- Cache key generation
- Cache invalidation methods
- Context building method
- Recommendation retrieval methods

Service Interface:
- invalidateSlotCache()
- clearAllCache()
- buildRecommendationContext()
- getSlotRecommendations()
- getDetailedSlotRecommendations()
- refreshDetailedRecommendations()

Key Principle:
BEHAVIOR MUST NOT CHANGE - this is a pure refactoring.

Files to Create: 2
Files to Modify: 2
Lines to Move: ~130

Verification Strategy:
1. All existing tests must pass
2. Manual testing of caching behavior
3. New unit tests for service

Roadmap Updated:
✓ docs/planning/0.1.6/ISSUE-230-ROADMAP.md
  └─ Phase 1 marked complete
  └─ Extraction plan documented
  └─ Service interface defined
  └─ Verification checklist

Next Steps:
1. → Execute Phase 2 with gastrobrain-senior-dev-implementation
2. → Follow 7-step extraction plan
3. → Run tests after each step
4. → Verify behavior unchanged

Ready for Phase 2? (y/n)
═══════════════════════════════════════
```

---

## Key Takeaways for Refactoring Analysis

1. **Identify Exact Code**: Know exactly what lines to move
2. **Preserve Behavior**: Refactoring = same behavior, better structure
3. **Follow Existing Patterns**: Use similar services as templates
4. **Plan Dependencies**: Know what the extracted code needs
5. **Update DI**: Register new service in ServiceProvider
6. **Verify at Each Step**: Run tests after each extraction step
7. **Document Interface**: Clear public API for new service
8. **Test Both Sides**: Existing tests + new service tests
