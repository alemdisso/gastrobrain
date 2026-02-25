# Gastrobrain Code Quality Watchdog — test/

Tests have different healthy patterns than production code. This file replaces
(does not inherit) the `lib/CLAUDE.md` rules. The silent, non-blocking, and
no-duplicate rules still apply.

---

## Test-Specific Thresholds

| Smell | Threshold | Severity | Notes |
|---|---|---|---|
| Test file length | > 500 lines | 🟡 High | Consider splitting by scenario group |
| Test file length | > 800 lines | 🔴 Critical | |
| Single test method length | > 60 lines | 🟡 High | Test is doing too much |

---

## Test-Specific Smells

| Smell | Trigger | Severity |
|---|---|---|
| Missing test file | New `lib/core/services/*.dart` created with no corresponding `test/` file | 🔴 Critical |
| Missing test file | New `lib/screens/*.dart` created with no corresponding `test/` file | 🟡 High |
| No assertions | Test method with no `expect()` call | 🔴 Critical |
| Real database in unit test | `DatabaseHelper.instance` used directly instead of `MockDatabaseHelper` | 🔴 Critical |
| Test without setUp | Test group with 3+ tests sharing repeated setup code and no `setUp()` | 🟡 High |
| Skipped tests | `skip:` or `markTestSkipped` present | 🟡 High |

---

## Proto-Issue Format (same as lib/)

```
- [ ] 🔴 `test/path/to/file_test.dart` — <smell> — flagged during: <brief context> — <YYYY-MM-DD>
```

Missing test file entries should reference the source file:

```
- [ ] 🔴 `test/core/services/meal_edit_service_test.dart` — missing test file for `lib/core/services/meal_edit_service.dart` — flagged during: <brief context> — <YYYY-MM-DD>
```

---

## Healthy Test Pattern (reference)

```dart
group('MyService', () {
  late MockDatabaseHelper mockDb;
  late MyService service;

  setUp(() {
    mockDb = TestSetup.setupMockDatabase();
    service = MyService(mockDb);
  });

  test('does X when Y', () async {
    // arrange
    when(mockDb.getData()).thenAnswer((_) async => testData);

    // act
    final result = await service.doSomething();

    // assert
    expect(result, isNotNull);
    verify(mockDb.getData()).called(1);
  });
});
```

---

## Integration

Backlog feeds the **Refactoring Skill** and **Testing Implementation Skill**.
Review `.github/refactoring-backlog.md` during Sprint Planning.