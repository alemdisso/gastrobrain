// test/database/meal_ordering_test.dart
//
// Integration tests for recent-meals ordering against a real in-memory SQLite
// database. The mock sorts only by cookedAt with no CASE clause, so these
// tests are the only reliable check that the actual SQL ORDER BY is correct.
//
// Context: users plan ahead and confirm meals from past slots — sometimes days
// later, sometimes all at once, in any order. Ordering must reflect slot date,
// not recording timestamp. See issues #341, #351, #352 for history.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';

Future<Database> _openDb() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await InitialSchemaMigration().up(DatabaseWrapper(db));
  return db;
}

Future<void> _insertMeal(
  Database db, {
  required String id,
  required DateTime cookedAt,
  required String mealType,
}) async {
  await db.rawInsert(
    'INSERT INTO meals (id, cooked_at, servings, meal_type) VALUES (?, ?, ?, ?)',
    [id, cookedAt.toIso8601String(), 2, mealType],
  );
}

/// The exact ORDER BY used in DatabaseHelper.getRecentMeals / getAllMeals.
Future<List<String>> _queryOrder(Database db) async {
  final rows = await db.rawQuery(
    "SELECT meal_type FROM meals "
    "ORDER BY cooked_at DESC, "
    "CASE meal_type WHEN 'dinner' THEN 0 WHEN 'lunch' THEN 1 ELSE 2 END ASC",
  );
  return rows.map((r) => r['meal_type'] as String).toList();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Weekly plan path — cooked_at = slot midnight', () {
    // MealRecordingDialog sets cooked_at = plannedDate = DateTime(y, m, d),
    // which is midnight with no time component. Same-day meals always tie on
    // the primary sort, so the CASE clause is what determines order.

    test('same-day: dinner appears before lunch when confirmed in natural order',
        () async {
      final db = await _openDb();
      final slot = DateTime(2026, 4, 15); // midnight — the slot date

      await _insertMeal(db, id: 'm1', cookedAt: slot, mealType: 'lunch');
      await _insertMeal(db, id: 'm2', cookedAt: slot, mealType: 'dinner');

      expect(await _queryOrder(db), ['dinner', 'lunch']);
      await db.close();
    });

    test('same-day: dinner appears before lunch when confirmed in reverse order',
        () async {
      // User confirms dinner first, then lunch — insertion order must not
      // affect the result since both share the same cooked_at.
      final db = await _openDb();
      final slot = DateTime(2026, 4, 15);

      await _insertMeal(db, id: 'm1', cookedAt: slot, mealType: 'dinner');
      await _insertMeal(db, id: 'm2', cookedAt: slot, mealType: 'lunch');

      expect(await _queryOrder(db), ['dinner', 'lunch']);
      await db.close();
    });

    test('same-day: full type ordering is dinner, lunch, prep', () async {
      final db = await _openDb();
      final slot = DateTime(2026, 4, 15);

      // Insert in worst-case order
      await _insertMeal(db, id: 'm1', cookedAt: slot, mealType: 'prep');
      await _insertMeal(db, id: 'm2', cookedAt: slot, mealType: 'dinner');
      await _insertMeal(db, id: 'm3', cookedAt: slot, mealType: 'lunch');

      expect(await _queryOrder(db), ['dinner', 'lunch', 'prep']);
      await db.close();
    });

    test('multi-day batch: newer slot dates appear before older, type order preserved',
        () async {
      // Simulates user confirming Thu and Fri meals in a single session
      // in completely arbitrary order.
      final db = await _openDb();
      final thu = DateTime(2026, 4, 10);
      final fri = DateTime(2026, 4, 11);

      await _insertMeal(db, id: 'thu-lunch',  cookedAt: thu, mealType: 'lunch');
      await _insertMeal(db, id: 'fri-dinner', cookedAt: fri, mealType: 'dinner');
      await _insertMeal(db, id: 'fri-lunch',  cookedAt: fri, mealType: 'lunch');
      await _insertMeal(db, id: 'thu-dinner', cookedAt: thu, mealType: 'dinner');

      // Friday meals first (newer), each day in dinner→lunch order
      expect(await _queryOrder(db), ['dinner', 'lunch', 'dinner', 'lunch']);
      await db.close();
    });
  });

  group('cook_meal_screen path — cooked_at = recording timestamp', () {
    // When confirming via cook_meal_screen there is no plannedDate, so
    // cooked_at = DateTime.now() at the moment of confirmation.
    // Same-day meals differ by recording time; the CASE clause only fires
    // if they happen to share the exact same second (practically never).

    test('same-day meals confirmed in wrong order sort by recording time — known limitation',
        () async {
      // Documents the failure: dinner confirmed at 10:00, lunch confirmed at 11:00.
      // Lunch has a later timestamp so it wins the primary sort — incorrect order.
      final db = await _openDb();
      final dinnerConfirmedAt = DateTime(2026, 4, 15, 10, 0, 0);
      final lunchConfirmedAt  = DateTime(2026, 4, 15, 11, 0, 0);

      await _insertMeal(db, id: 'm1', cookedAt: dinnerConfirmedAt, mealType: 'dinner');
      await _insertMeal(db, id: 'm2', cookedAt: lunchConfirmedAt,  mealType: 'lunch');

      // Current query: lunch (11:00) wins — this is the known limitation.
      expect(await _queryOrder(db), ['lunch', 'dinner']);
      await db.close();
    });

    test('#351 fix: date(cooked_at) restores correct order for recording-time meals',
        () async {
      // date(cooked_at) truncates to date-only, causing same-day meals to tie
      // on the primary sort and the CASE clause to determine order correctly.
      final db = await _openDb();
      final dinnerConfirmedAt = DateTime(2026, 4, 15, 10, 0, 0);
      final lunchConfirmedAt  = DateTime(2026, 4, 15, 11, 0, 0);

      await _insertMeal(db, id: 'm1', cookedAt: dinnerConfirmedAt, mealType: 'dinner');
      await _insertMeal(db, id: 'm2', cookedAt: lunchConfirmedAt,  mealType: 'lunch');

      final rows = await db.rawQuery(
        "SELECT meal_type FROM meals "
        "ORDER BY date(cooked_at) DESC, "
        "CASE meal_type WHEN 'dinner' THEN 0 WHEN 'lunch' THEN 1 ELSE 2 END ASC",
      );
      final order = rows.map((r) => r['meal_type'] as String).toList();

      expect(order, ['dinner', 'lunch']);
      await db.close();
    });
  });
}
