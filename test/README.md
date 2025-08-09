# Testing Guide

This document provides guidelines for testing in the Gastrobrain Flutter application.

## Database Mocking in Widget Tests

### Overview

To ensure widget tests can run in parallel without database locking issues, all widgets that access the database should use **dependency injection** rather than directly instantiating `DatabaseHelper`.

### The Problem

Previously, some widgets were directly creating `DatabaseHelper` instances:

```dart
// ❌ BAD: Direct instantiation causes database locking in parallel tests
final DatabaseHelper _dbHelper = DatabaseHelper();
```

This approach caused database locking when tests ran in parallel, requiring the use of `--concurrency=1` as a workaround.

### The Solution

**1. Widget Design Pattern**

Widgets should accept an optional `DatabaseHelper` parameter and fall back to `ServiceProvider`:

```dart
class MyWidget extends StatefulWidget {
  final DatabaseHelper? databaseHelper;  // 👈 Add this parameter
  
  const MyWidget({
    super.key,
    this.databaseHelper,  // 👈 Optional parameter
  });
}

class _MyWidgetState extends State<MyWidget> {
  late final DatabaseHelper _dbHelper;
  
  @override
  void initState() {
    super.initState();
    // 👈 Use dependency injection
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
  }
}
```

**2. Test Setup Pattern**

Widget tests should follow this standard pattern:

```dart
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  
  setUp(() {
    // Create fresh mock for each test
    mockDbHelper = MockDatabaseHelper();
    mockDbHelper.resetAllData();
    
    // Set up test data if needed
    await mockDbHelper.insertRecipe(testRecipe);
  });
  
  tearDown(() {
    // Clean up to prevent test pollution
    mockDbHelper.resetAllData();
  });
  
  testWidgets('test description', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapWithLocalizations(
        MyWidget(
          databaseHelper: mockDbHelper,  // 👈 Inject mock
        ),
      ),
    );
    
    // Test assertions...
  });
}
```

### Examples

**Good Widget Implementation:**
- `WeeklyCalendarWidget` - Accepts `DatabaseHelper? databaseHelper` parameter
- `EditMealRecordingDialog` - Uses dependency injection pattern

**Good Test Implementation:**
- `test/widgets/weekly_calendar_widget_test.dart` - Proper mock setup
- `test/widgets/edit_meal_recording_dialog_test.dart` - Clean test patterns

### Benefits

1. **Parallel Test Execution**: Tests can run concurrently without database locking
2. **Test Isolation**: Each test uses its own mock database instance
3. **No Global State**: Avoids shared database state between tests
4. **Fast Test Execution**: No need for `--concurrency=1` flag

### Key Points

- ✅ **DO**: Use dependency injection with optional `DatabaseHelper?` parameter
- ✅ **DO**: Inject `MockDatabaseHelper` in tests
- ✅ **DO**: Reset mock data in `setUp()` and `tearDown()`
- ❌ **DON'T**: Create `DatabaseHelper()` instances directly in widgets
- ❌ **DON'T**: Rely on `ServiceProvider` without allowing test injection
- ❌ **DON'T**: Share mock instances between tests

This approach ensures robust, fast, and reliable widget tests that can run in parallel.