import '../migration.dart';

/// Adds meal_role and food_type closed tag types with initial vocabulary.
///
/// Both types are soft (is_hard=0) and closed (is_open=0).
/// is_hard will be revisited when the recommendation engine integrates tags (#127).
///
/// UI exposure is deferred to the recipe creation redesign (#370).
/// These types are filtered out of the recipe editor until then.
class AddMealRoleFoodTypeMigration extends Migration {
  @override
  int get version => 106;

  @override
  String get description => 'Add meal_role and food_type closed tag types with vocabulary';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    // Tag types
    await db.execute(
      "INSERT OR IGNORE INTO tag_types (id, name, is_hard, is_open) VALUES ('meal_role', 'Meal Role', 0, 0)",
    );
    await db.execute(
      "INSERT OR IGNORE INTO tag_types (id, name, is_hard, is_open) VALUES ('food_type', 'Food Type', 0, 0)",
    );

    // meal_role vocabulary
    const mealRoleTags = [
      ('meal-role-main-dish', 'main dish'),
      ('meal-role-side-dish', 'side dish'),
      ('meal-role-complete-meal', 'complete meal'),
      ('meal-role-appetizer', 'appetizer'),
      ('meal-role-accompaniment', 'accompaniment'),
      ('meal-role-dessert', 'dessert'),
      ('meal-role-snack', 'snack'),
    ];
    for (final (id, name) in mealRoleTags) {
      await db.execute(
        "INSERT OR IGNORE INTO tags (id, name, type_id) VALUES ('$id', '$name', 'meal_role')",
      );
    }

    // food_type vocabulary
    const foodTypeTags = [
      ('food-type-soup', 'soup'),
      ('food-type-stew', 'stew'),
      ('food-type-salad', 'salad'),
      ('food-type-stock', 'stock'),
      ('food-type-sandwich', 'sandwich'),
      ('food-type-pasta', 'pasta'),
      ('food-type-rice', 'rice'),
      ('food-type-grilled', 'grilled'),
      ('food-type-baked', 'baked'),
      ('food-type-raw', 'raw'),
    ];
    for (final (id, name) in foodTypeTags) {
      await db.execute(
        "INSERT OR IGNORE INTO tags (id, name, type_id) VALUES ('$id', '$name', 'food_type')",
      );
    }
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    await db.execute("DELETE FROM tags WHERE type_id IN ('meal_role', 'food_type')");
    await db.execute("DELETE FROM tag_types WHERE id IN ('meal_role', 'food_type')");
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      "SELECT id FROM tag_types WHERE id IN ('meal_role', 'food_type')",
    );
    return result.length == 2;
  }
}
