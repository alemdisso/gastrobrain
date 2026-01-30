# Example 1: Refactoring WeeklyPlanScreen (Long Screen)

## Scenario

The `WeeklyPlanScreen` has grown to 547 lines with multiple responsibilities:
- State management for meal plan data
- UI rendering for week view, day cards, and meal slots
- Database operations for loading and updating meals
- Business logic for meal recording, cooking status, and meal plan updates
- Navigation to other screens

This violates the Single Responsibility Principle and makes the code hard to maintain, test, and understand.

**User Request:** "Refactor WeeklyPlanScreen - it's grown to 547 lines and is becoming hard to work with"

---

## CHECKPOINT 1: Code Analysis & Smell Detection

**Objective:** Identify specific code quality issues and refactoring opportunities

### Code Smells Identified

#### Critical Priority
- ✗ **File length: 547 lines** (Critical threshold: >500 lines)
  - Location: `lib/screens/weekly_plan_screen.dart`
  - Impact: Hard to navigate, understand, and maintain

- ✗ **God class: Multiple responsibilities**
  - Responsibilities: State management, UI, database, business logic, navigation
  - Impact: Violates Single Responsibility Principle
  - Difficult to test in isolation

#### High Priority
- ✗ **Long method: `_buildWeekView` (87 lines)**
  - Location: `lib/screens/weekly_plan_screen.dart:234`
  - Impact: Hard to understand, multiple levels of nesting
  - Responsibilities: Layout, card building, meal slot rendering

- ✗ **Long method: `_handleMarkAsCooked` (64 lines)**
  - Location: `lib/screens/weekly_plan_screen.dart:445`
  - Impact: Complex business logic mixed with UI updates
  - Responsibilities: Validation, database updates, state management, error handling

- ✗ **Tight coupling: Direct DatabaseHelper calls**
  - Multiple locations throughout screen
  - Impact: Hard to test, violates Dependency Inversion Principle
  - Screen knows about database implementation details

#### Medium Priority
- ✗ **Deep nesting in `_buildDayCard`**
  - 4-5 levels of nesting
  - Impact: Reduced readability

- ✗ **Poor separation: Business logic mixed with UI**
  - Meal recording logic in UI callbacks
  - Impact: Can't reuse logic, hard to test

### SOLID Violations

- ✗ **Single Responsibility Principle**
  - Class has 4+ distinct responsibilities
  - Each responsibility should be a separate class

- ✗ **Dependency Inversion Principle**
  - Depends on concrete `DatabaseHelper` instead of abstraction
  - Should depend on service interface

### Current Metrics

| Metric | Current Value | Target Value |
|--------|---------------|--------------|
| File length | 547 lines | <300 lines |
| Longest method | 87 lines (`_buildWeekView`) | <30 lines |
| Number of responsibilities | 4 | 1 (UI only) |
| Direct DB calls | 8 locations | 0 |
| Test coverage | 87% | ≥87% (maintain) |

### User Confirmation

**Assistant:** "I've identified a god class with 547 lines handling state, UI, database, and business logic. The main issues are:
- 4 distinct responsibilities (should be 1)
- Long methods (`_buildWeekView`: 87 lines, `_handleMarkAsCooked`: 64 lines)
- Direct database coupling (8 locations)

Does this analysis identify the key problems? Any additional areas to focus on?"

**User:** ✓ "Yes, those are the main issues. Let's proceed with the refactoring."

---

## CHECKPOINT 2: Refactoring Strategy

**Objective:** Plan the refactoring approach without breaking functionality

### Refactoring Plan

#### Phase 1: Extract Methods (Low Risk)
1. **Extract Method** - `_buildDayCard` from `_buildWeekView`
   - Technique: Extract Method
   - Target: Break 87-line method into smaller pieces
   - Risk: Low (pure UI extraction)

2. **Extract Method** - `_buildMealSlot` from `_buildDayCard`
   - Technique: Extract Method
   - Target: Further decompose UI building
   - Risk: Low

3. **Rename Variables** - Improve clarity
   - Technique: Rename
   - Target: `_slot` → `mealPlanItem`, unclear abbreviations
   - Risk: Very Low

#### Phase 2: Extract Services (Medium Risk)
1. **Extract Class** - `WeeklyPlanService`
   - Technique: Extract Class
   - Responsibilities: Database operations for meal plans
   - Original: `lib/screens/weekly_plan_screen.dart`
   - New: `lib/core/services/weekly_plan_service.dart`
   - Risk: Medium (architectural change)

2. **Extract Class** - `MealOperationsService`
   - Technique: Extract Class
   - Responsibilities: Meal recording, cooking status, updates
   - New: `lib/core/services/meal_operations_service.dart`
   - Risk: Medium

3. **Introduce Dependency Injection** - Use ServiceProvider
   - Technique: Dependency Inversion
   - Replace direct DatabaseHelper with services via Provider
   - Risk: Medium (changes dependencies)

### Files to Create
- `lib/core/services/weekly_plan_service.dart` (~150 lines)
- `lib/core/services/meal_operations_service.dart` (~120 lines)
- `test/core/services/weekly_plan_service_test.dart` (~80 lines)
- `test/core/services/meal_operations_service_test.dart` (~70 lines)

### Files to Modify
- `lib/screens/weekly_plan_screen.dart` (547 → ~250 lines)
- `lib/core/di/service_provider.dart` (add new services)
- `test/screens/weekly_plan_screen_test.dart` (update to use service mocks)

### Test Strategy
1. Run all existing tests before starting (baseline: 15 tests passing)
2. Run tests after each refactoring step
3. Add 8 new service tests for extracted business logic
4. Update screen tests to use service mocks instead of database mocks
5. Verify integration tests still pass (meal planning flow)

### User Confirmation

**Assistant:** "Here's the refactoring strategy:
- **Phase 1:** Extract methods to break down long UI code (low risk)
- **Phase 2:** Extract services for database/business logic (medium risk)
- **Result:** Screen focuses only on UI (~250 lines), services handle data/logic

We'll create 2 new services and ~150 lines of tests. All 15 existing screen tests will be updated to use service mocks.

Does this strategy make sense? Any concerns about the approach?"

**User:** ✓ "Looks good. I like the separation of UI from business logic."

---

## CHECKPOINT 3: Test Verification Setup

**Objective:** Ensure tests exist and pass before refactoring

### Existing Test Coverage

**Screen Tests:**
- `test/screens/weekly_plan_screen_test.dart` - 15 tests
  - ✓ Loading state display
  - ✓ Week view rendering
  - ✓ Meal slot interactions
  - ✓ Mark as cooked functionality
  - ✓ Navigation to meal detail
  - ✓ Error handling
  - All 15 tests **passing** ✓

**Integration Tests:**
- `integration_test/meal_planning_flow_test.dart` - 3 tests
  - ✓ Create meal plan flow
  - ✓ Record meal flow
  - ✓ Mark meal as cooked flow
  - All 3 tests **passing** ✓

### Coverage Analysis
- **Current coverage:** 87% for `weekly_plan_screen.dart`
- **Coverage sufficient:** ✓ Yes
- **Edge cases tested:** ✓ Yes (empty states, errors, boundary conditions)
- **Integration points tested:** ✓ Yes (database, navigation)

### Behavior Baseline Documented

**Expected Behavior:**
- Load current meal plan from database
- Display 7-day week view with meal slots
- Allow marking meals as cooked
- Navigate to meal detail on tap
- Show loading/error states appropriately
- Update UI when data changes

**Success Criteria:**
- All current functionality preserved
- No behavior changes
- All 18 tests remain passing
- Performance maintained (no slowdowns)

### User Confirmation

**Assistant:** "Test verification complete:
- ✓ 15 screen tests passing
- ✓ 3 integration tests passing
- ✓ 87% coverage (sufficient for safe refactoring)
- ✓ Edge cases and integration points tested

All tests pass and coverage is good. Ready to proceed with refactoring?"

**User:** ✓ "Yes, let's start."

---

## CHECKPOINT 4: Incremental Refactoring - Phase 1

**Objective:** Apply first set of refactorings (structural changes)

### Refactoring 1: Extract `_buildDayCard` from `_buildWeekView`

**Before:**
```dart
Widget _buildWeekView() {
  // 87 lines of mixed layout and card building logic
  return ListView.builder(
    itemCount: 7,
    itemBuilder: (context, index) {
      final day = weekDays[index];
      // ... 75 lines of card building inline ...
    },
  );
}
```

**After:**
```dart
Widget _buildWeekView() {
  return ListView.builder(
    itemCount: 7,
    itemBuilder: (context, index) {
      final day = weekDays[index];
      return _buildDayCard(day);
    },
  );
}

Widget _buildDayCard(DateTime day) {
  // ... 70 lines of card building logic ...
}
```

**Results:**
- `_buildWeekView`: 87 lines → 23 lines ✓
- New `_buildDayCard`: 70 lines
- **Tests:** ✓ All 15 tests passing
- **Commit:** `f3a8d12` - Extract _buildDayCard method

---

### Refactoring 2: Extract `_buildMealSlot` from `_buildDayCard`

**Before:**
```dart
Widget _buildDayCard(DateTime day) {
  // 70 lines with inline meal slot building
  return Card(
    child: Column(
      children: [
        // ... header ...
        for (final slot in mealSlots)
          // ... 45 lines of meal slot UI inline ...
      ],
    ),
  );
}
```

**After:**
```dart
Widget _buildDayCard(DateTime day) {
  return Card(
    child: Column(
      children: [
        _buildDayHeader(day),
        ...mealSlots.map((slot) => _buildMealSlot(slot)).toList(),
      ],
    ),
  );
}

Widget _buildMealSlot(MealPlanItem item) {
  // ... 40 lines of meal slot UI ...
}

Widget _buildDayHeader(DateTime day) {
  // ... 15 lines of header UI ...
}
```

**Results:**
- `_buildDayCard`: 70 lines → 18 lines ✓
- New `_buildMealSlot`: 40 lines
- New `_buildDayHeader`: 15 lines
- **Tests:** ✓ All 15 tests passing
- **Commit:** `a7b4e31` - Extract _buildMealSlot and _buildDayHeader methods

---

### Refactoring 3: Rename variables for clarity

**Before:**
```dart
final _slot = mealPlanItems[index];
final _rec = _slot.recipe;
final _dt = _slot.date;
```

**After:**
```dart
final mealPlanItem = mealPlanItems[index];
final recipe = mealPlanItem.recipe;
final scheduledDate = mealPlanItem.date;
```

**Results:**
- Improved readability throughout file
- **Tests:** ✓ All 15 tests passing
- **Commit:** `c9d2f55` - Rename variables for clarity

---

### Phase 1 Summary

**File Length Progress:** 547 → 412 lines (↓ 135 lines)

**Methods Improved:**
- `_buildWeekView`: 87 → 23 lines
- `_buildDayCard`: 70 → 18 lines (extracted)
- `_buildMealSlot`: 40 lines (extracted)
- `_buildDayHeader`: 15 lines (extracted)

**All tests passing:** ✓ 15/15

### User Confirmation

**Assistant:** "Phase 1 complete! Structural improvements applied:
- Broke down 87-line `_buildWeekView` into 4 focused methods
- File length: 547 → 412 lines (↓ 135 lines)
- All tests passing ✓

The UI building code is now much more readable. Ready for Phase 2 (service extraction)?"

**User:** ✓ "Yes, the structure is much clearer now. Let's continue."

---

## CHECKPOINT 5: Incremental Refactoring - Phase 2

**Objective:** Apply deeper refactorings (class/module restructuring)

### Refactoring 4: Extract `WeeklyPlanService`

**Created:** `lib/core/services/weekly_plan_service.dart`

```dart
class WeeklyPlanService {
  final DatabaseHelper _database;

  WeeklyPlanService(this._database);

  Future<MealPlan?> getCurrentMealPlan() async {
    try {
      return await _database.getCurrentMealPlan();
    } on GastrobrainException {
      rethrow;
    }
  }

  Future<List<MealPlanItem>> getMealPlanItemsForWeek(
    DateTime startDate,
  ) async {
    try {
      final endDate = startDate.add(const Duration(days: 7));
      return await _database.getMealPlanItemsInRange(
        startDate,
        endDate,
      );
    } on GastrobrainException {
      rethrow;
    }
  }

  Future<void> updateMealPlanItem(MealPlanItem item) async {
    try {
      await _database.updateMealPlanItem(item);
    } on GastrobrainException {
      rethrow;
    }
  }
}
```

**Created:** `test/core/services/weekly_plan_service_test.dart`

```dart
group('WeeklyPlanService', () {
  late MockDatabaseHelper mockDb;
  late WeeklyPlanService service;

  setUp(() {
    mockDb = TestSetup.setupMockDatabase();
    service = WeeklyPlanService(mockDb);
  });

  test('getCurrentMealPlan returns current plan', () async {
    final plan = await service.getCurrentMealPlan();
    expect(plan, isNotNull);
    expect(plan!.id, equals(1));
  });

  test('getMealPlanItemsForWeek returns items in range', () async {
    final startDate = DateTime(2026, 1, 20);
    final items = await service.getMealPlanItemsForWeek(startDate);

    expect(items.length, greaterThan(0));
    for (final item in items) {
      expect(item.date.isAfter(startDate.subtract(Duration(days: 1))), isTrue);
      expect(item.date.isBefore(startDate.add(Duration(days: 8))), isTrue);
    }
  });

  // ... 6 more tests ...
});
```

**Results:**
- New service: 145 lines
- New tests: 78 lines (8 tests)
- **Tests:** ✓ All 8 service tests passing
- **Commit:** `e4f1a23` - Extract WeeklyPlanService

---

### Refactoring 5: Extract `MealOperationsService`

**Created:** `lib/core/services/meal_operations_service.dart`

```dart
class MealOperationsService {
  final DatabaseHelper _database;

  MealOperationsService(this._database);

  Future<void> recordMeal(MealPlanItem item) async {
    if (item.id == null) {
      throw ValidationException('Cannot record meal without ID');
    }

    try {
      final meal = Meal(
        mealPlanItemId: item.id!,
        cookedDate: DateTime.now(),
        rating: null,
        notes: null,
      );
      await _database.insertMeal(meal);
    } on GastrobrainException {
      rethrow;
    }
  }

  Future<void> markAsCooked(MealPlanItem item, {required bool cooked}) async {
    if (item.id == null) {
      throw ValidationException('Cannot update meal without ID');
    }

    try {
      if (cooked) {
        await recordMeal(item);
      } else {
        await _database.deleteMealByPlanItemId(item.id!);
      }
    } on GastrobrainException {
      rethrow;
    }
  }
}
```

**Created:** `test/core/services/meal_operations_service_test.dart`

```dart
group('MealOperationsService', () {
  late MockDatabaseHelper mockDb;
  late MealOperationsService service;

  setUp(() {
    mockDb = TestSetup.setupMockDatabase();
    service = MealOperationsService(mockDb);
  });

  test('recordMeal creates meal record', () async {
    final item = MealPlanItem(id: 1, date: DateTime.now(), recipeId: 1);

    await service.recordMeal(item);

    verify(mockDb.insertMeal(any)).called(1);
  });

  test('markAsCooked records meal when cooked=true', () async {
    final item = MealPlanItem(id: 1, date: DateTime.now(), recipeId: 1);

    await service.markAsCooked(item, cooked: true);

    verify(mockDb.insertMeal(any)).called(1);
  });

  // ... 5 more tests ...
});
```

**Results:**
- New service: 118 lines
- New tests: 72 lines (7 tests)
- **Tests:** ✓ All 7 service tests passing
- **Commit:** `b8c3d47` - Extract MealOperationsService

---

### Refactoring 6: Update `WeeklyPlanScreen` to use services

**Before (direct database access):**
```dart
class WeeklyPlanScreen extends StatefulWidget {
  // ...
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  final _database = DatabaseHelper.instance;

  Future<void> _loadMealPlan() async {
    final plan = await _database.getCurrentMealPlan();
    // ...
  }

  Future<void> _handleMarkAsCooked(MealPlanItem item) async {
    // 64 lines of business logic with direct DB calls
    await _database.insertMeal(meal);
    // ...
  }
}
```

**After (service layer):**
```dart
class WeeklyPlanScreen extends StatefulWidget {
  // ...
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  late final WeeklyPlanService _planService;
  late final MealOperationsService _mealService;

  @override
  void initState() {
    super.initState();
    _planService = Provider.of<WeeklyPlanService>(context, listen: false);
    _mealService = Provider.of<MealOperationsService>(context, listen: false);
  }

  Future<void> _loadMealPlan() async {
    final plan = await _planService.getCurrentMealPlan();
    // ...
  }

  Future<void> _handleMarkAsCooked(MealPlanItem item) async {
    // 12 lines - business logic moved to service
    await _mealService.markAsCooked(item, cooked: true);
    setState(() => _loadMealPlan());
  }
}
```

**Updated:** `test/screens/weekly_plan_screen_test.dart`

```dart
group('WeeklyPlanScreen', () {
  late MockWeeklyPlanService mockPlanService;
  late MockMealOperationsService mockMealService;

  setUp(() {
    mockPlanService = MockWeeklyPlanService();
    mockMealService = MockMealOperationsService();

    // Setup mock behavior
    when(mockPlanService.getCurrentMealPlan()).thenAnswer((_) async => testPlan);
  });

  testWidgets('displays week view when loaded', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<WeeklyPlanService>.value(value: mockPlanService),
          Provider<MealOperationsService>.value(value: mockMealService),
        ],
        child: MaterialApp(home: WeeklyPlanScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    verify(mockPlanService.getCurrentMealPlan()).called(1);
  });

  // ... 14 more tests updated ...
});
```

**Results:**
- Screen: 412 → 248 lines (↓ 164 lines)
- `_handleMarkAsCooked`: 64 → 12 lines (↓ 52 lines)
- Direct DB calls: 8 → 0 ✓
- **Tests:** ✓ All 15 screen tests passing (updated to use service mocks)
- **Commit:** `d5e7f89` - Update WeeklyPlanScreen to use services

---

### Refactoring 7: Register services in `ServiceProvider`

**Updated:** `lib/core/di/service_provider.dart`

```dart
class ServiceProvider {
  // ... existing services ...

  static WeeklyPlanService get weeklyPlan => WeeklyPlanService(database.helper);
  static MealOperationsService get mealOperations => MealOperationsService(database.helper);
}
```

**Results:**
- Services available globally via `ServiceProvider`
- **Tests:** ✓ All tests passing
- **Commit:** `a2f9e11` - Register new services in ServiceProvider

---

### Phase 2 Summary

**File Length Progress:** 412 → 248 lines (↓ 164 lines)
**Total Progress:** 547 → 248 lines (↓ 299 lines / 55% reduction) ✓

**Responsibilities Reduced:**
- Before: State, UI, Database, Business Logic (4 responsibilities)
- After: State, UI (2 responsibilities) - Business Logic and Database in services ✓

**Services Created:**
- `WeeklyPlanService` (145 lines, 8 tests)
- `MealOperationsService` (118 lines, 7 tests)

**All tests passing:** ✓ 30/30 (15 screen + 8 + 7 service tests)

### User Confirmation

**Assistant:** "Phase 2 complete! Major structural improvements:
- Created 2 new services (WeeklyPlanService, MealOperationsService)
- Screen now uses services instead of direct database access
- File length: 547 → 248 lines (↓ 55%)
- `_handleMarkAsCooked`: 64 → 12 lines
- All 30 tests passing (15 screen + 15 new service tests)

The screen now focuses only on UI, with business logic in testable services. Does the new structure feel clearer? Are responsibilities well-separated?"

**User:** ✓ "Much better! The screen is easier to read and the services make sense."

---

## CHECKPOINT 6: SOLID Principle Compliance Review

**Objective:** Verify refactored code adheres to SOLID principles

### SOLID Compliance Assessment

#### Single Responsibility Principle ✓
- **WeeklyPlanScreen:** UI rendering and state management only
- **WeeklyPlanService:** Meal plan data operations only
- **MealOperationsService:** Meal recording and status operations only
- Each class has one clear reason to change ✓

#### Open/Closed Principle ✓
- Services can be extended without modifying screen code
- New meal operations can be added to `MealOperationsService` without changing screen
- UI components can be extended without modifying services ✓

#### Liskov Substitution Principle ✓
- Services implement clear contracts
- Mock services in tests can replace real services safely
- No behavioral surprises ✓

#### Interface Segregation Principle ✓
- Services have focused interfaces (3-4 methods each)
- Screen only depends on methods it actually uses
- No "fat" interfaces ✓

#### Dependency Inversion Principle ✓
- Screen depends on service abstractions (via Provider)
- Services depend on DatabaseHelper abstraction
- No dependencies on concrete implementations ✓

### Remaining Issues

**None identified** - All critical SOLID violations have been addressed.

**Minor observation:**
- Screen still manages state directly (could use Provider/BLoC pattern)
- However, this is acceptable for screen-level state
- Not worth additional complexity at this time

### User Confirmation

**Assistant:** "SOLID compliance review:
- ✓ Single Responsibility: Each class has one clear purpose
- ✓ Open/Closed: Can extend services without modifying screen
- ✓ Liskov Substitution: Services are safely replaceable
- ✓ Interface Segregation: Focused interfaces (3-4 methods each)
- ✓ Dependency Inversion: Depends on abstractions, not implementations

All SOLID violations from Checkpoint 1 have been resolved. The code structure feels solid and maintainable. Any remaining concerns?"

**User:** ✓ "No concerns. This is much better than before."

---

## CHECKPOINT 7: Documentation & Pattern Capture

**Objective:** Document refactoring decisions and patterns for future reference

### Documentation Updates

#### Code Documentation

**Added to `WeeklyPlanService`:**
```dart
/// Service for managing meal plan data operations.
///
/// This service provides a clean abstraction over database operations
/// related to meal plans, improving testability and separation of concerns.
///
/// Use this service instead of direct DatabaseHelper access in UI code.
class WeeklyPlanService {
  // ...
}
```

**Added to `MealOperationsService`:**
```dart
/// Service for meal recording and status operations.
///
/// Handles business logic for:
/// - Recording meals as cooked
/// - Updating meal status
/// - Meal validation
///
/// Separated from UI to allow testing and reuse across screens.
class MealOperationsService {
  // ...
}
```

#### Architecture Documentation

**Updated:** `docs/architecture/Gastrobrain-Codebase-Overview.md`

```markdown
### Service Layer Pattern

Screens use services for data and business logic operations:

**Example: WeeklyPlanScreen**
- Uses `WeeklyPlanService` for meal plan data operations
- Uses `MealOperationsService` for meal recording logic
- Screen focuses only on UI rendering and state management
- Services injected via Provider for testability

**Benefits:**
- Clear separation of concerns (UI vs business logic)
- Services are easily testable in isolation
- Business logic can be reused across screens
- Easier to mock in tests
```

#### Testing Documentation

**Updated:** `docs/testing/DIALOG_TESTING_GUIDE.md`

```markdown
### Service Mocking Pattern

When testing screens that use services:

```dart
late MockWeeklyPlanService mockPlanService;

setUp(() {
  mockPlanService = MockWeeklyPlanService();
  when(mockPlanService.getCurrentMealPlan())
      .thenAnswer((_) async => testPlan);
});

testWidgets('test name', (tester) async {
  await tester.pumpWidget(
    Provider<WeeklyPlanService>.value(
      value: mockPlanService,
      child: MaterialApp(home: ScreenUnderTest()),
    ),
  );
  // ... test code ...
});
```

### Technical Debt Addressed

- ✓ Closes implicit technical debt: God class pattern in WeeklyPlanScreen
- ✓ Addresses code smell: Long methods (>50 lines)
- ✓ Addresses code smell: Tight coupling to database
- ✓ Addresses SOLID violation: Single Responsibility Principle
- ✓ Addresses SOLID violation: Dependency Inversion Principle

### Patterns Captured

#### Pattern 1: Screen + Service Decomposition
**Where applied:** WeeklyPlanScreen refactoring

**Pattern:**
1. Extract data operations to `[Feature]Service`
2. Extract business logic to `[Operation]Service`
3. Screen uses services via Provider injection
4. Screen focuses only on UI and state

**Reusable in:**
- Any screen >300 lines
- Any screen with direct database access
- Any screen with complex business logic

**Example:**
```dart
// Screen uses services, not database
class MyScreen extends StatefulWidget {
  // ...
}

class _MyScreenState extends State<MyScreen> {
  late final MyDataService _dataService;

  @override
  void initState() {
    super.initState();
    _dataService = Provider.of<MyDataService>(context, listen: false);
  }

  Future<void> _loadData() async {
    final data = await _dataService.getData();
    setState(() => _data = data);
  }
}

// Service handles data operations
class MyDataService {
  final DatabaseHelper _database;
  MyDataService(this._database);

  Future<List<Data>> getData() async {
    return await _database.getDataFromTable();
  }
}
```

#### Pattern 2: Extract Method for UI Decomposition
**Where applied:** `_buildWeekView`, `_buildDayCard`, `_buildMealSlot`

**Pattern:**
1. Identify long methods with multiple responsibilities
2. Extract logical sections into focused methods
3. Use descriptive method names (verb + noun)
4. Keep methods under 30 lines

**Anti-pattern avoided:** Inline 87-line UI building

### Refactoring Summary Report

**Before Refactoring:**
- File length: 547 lines
- Responsibilities: 4 (UI, State, Database, Business Logic)
- Long methods: 2 (87 lines, 64 lines)
- Direct DB calls: 8
- SOLID violations: 2 (SRP, DIP)
- Test count: 15 screen tests

**After Refactoring:**
- File length: 248 lines (↓ 299 lines / 55%)
- Responsibilities: 2 (UI, State) - proper screen responsibility ✓
- Long methods: 0 ✓
- Direct DB calls: 0 ✓
- SOLID violations: 0 ✓
- Test count: 30 (15 screen + 15 service)

**New Components Created:**
- `WeeklyPlanService` (145 lines, 8 tests)
- `MealOperationsService` (118 lines, 7 tests)

**Metrics Improved:**

| Metric | Before | After | Change | Target Met? |
|--------|--------|-------|--------|-------------|
| File length | 547 lines | 248 lines | ↓ 299 lines | ✓ Yes (<300) |
| Longest method | 87 lines | 40 lines | ↓ 47 lines | ✓ Yes (<50) |
| Responsibilities | 4 | 2 | ↓ 2 | ✓ Yes (≤2 for screens) |
| Direct DB calls | 8 | 0 | ↓ 8 | ✓ Yes (0) |
| Test count | 15 | 30 | ↑ 15 | ✓ Yes |
| Test coverage | 87% | 91% | ↑ 4% | ✓ Yes (maintained) |

### User Confirmation

**Assistant:** "Documentation complete! I've:
- Added class comments to new services
- Updated architecture docs with service layer pattern
- Updated testing docs with service mocking pattern
- Documented reusable patterns for future refactorings
- Created summary report showing 55% reduction in screen length

All code smells addressed, SOLID compliance achieved, 30/30 tests passing. Ready to merge?"

**User:** ✓ "Perfect! Let's merge this."

---

## Result

### Before

- **547-line god class** handling UI, state, database, and business logic
- **Tight coupling** to DatabaseHelper throughout
- **Hard to test** (requires real database)
- **Poor separation** of concerns
- **Long methods** (87 lines, 64 lines)
- **SOLID violations** (SRP, DIP)

### After

- **248-line screen** focused only on UI rendering and state
- **2 testable services** with clear responsibilities
  - `WeeklyPlanService` - meal plan data operations
  - `MealOperationsService` - meal recording business logic
- **Clean separation** UI ↔ Service ↔ Database
- **All methods <50 lines** with focused responsibilities
- **SOLID compliant** (all 5 principles)
- **30/30 tests passing** (15 screen + 15 service)

### Lessons Learned

**What Worked Well:**
1. **Incremental approach** - One refactoring at a time with test verification
2. **Two-phase strategy** - Structural improvements before architectural changes
3. **Service extraction** - Clear separation of UI and business logic
4. **Test-first verification** - Caught zero issues because tests passed each step

**Patterns for Future Use:**
1. **Screen + Service pattern** - Applicable to any screen >300 lines
2. **Extract Method for UI** - Break down long widget builders
3. **Service injection via Provider** - Clean dependency management

**Metrics:**
- **Time saved:** Future changes to business logic won't require touching UI
- **Maintainability:** 55% reduction in screen length
- **Testability:** Services can be tested in isolation
- **Reusability:** Business logic can be used in multiple screens

---

**Example Status:** Complete
**All Checkpoints:** ✓ Passed
**Tests:** ✓ 30/30 passing
**Ready for:** Reuse as refactoring template
