import '../migration.dart';

/// Add quantity and unit columns to simple sides tables
///
/// Simple sides added to planned and recorded meals now carry an explicit
/// quantity (default 1.0) and an optional unit string. These values are used
/// by the shopping list generator when including simple sides in the list.
///
/// Existing rows receive quantity = 1.0 and unit = NULL.
class AddSimpleSidesQuantityMigration extends Migration {
  @override
  int get version => 11;

  @override
  String get description =>
      'Add quantity (default 1.0) and unit columns to simple sides tables';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    // meal_plan_item_ingredients
    final planCols = await db
        .rawQuery('PRAGMA table_info(meal_plan_item_ingredients)');
    if (!planCols.any((c) => c['name'] == 'quantity')) {
      await db.execute('''
        ALTER TABLE meal_plan_item_ingredients
        ADD COLUMN quantity REAL NOT NULL DEFAULT 1.0
      ''');
    }
    if (!planCols.any((c) => c['name'] == 'unit')) {
      await db.execute('''
        ALTER TABLE meal_plan_item_ingredients
        ADD COLUMN unit TEXT
      ''');
    }

    // meal_ingredients
    final mealCols =
        await db.rawQuery('PRAGMA table_info(meal_ingredients)');
    if (!mealCols.any((c) => c['name'] == 'quantity')) {
      await db.execute('''
        ALTER TABLE meal_ingredients
        ADD COLUMN quantity REAL NOT NULL DEFAULT 1.0
      ''');
    }
    if (!mealCols.any((c) => c['name'] == 'unit')) {
      await db.execute('''
        ALTER TABLE meal_ingredients
        ADD COLUMN unit TEXT
      ''');
    }
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // SQLite < 3.35 does not support DROP COLUMN — recreate tables.
    await db.execute('''
      CREATE TABLE meal_plan_item_ingredients_new(
        id TEXT PRIMARY KEY,
        meal_plan_item_id TEXT NOT NULL,
        ingredient_id TEXT,
        custom_name TEXT,
        notes TEXT,
        FOREIGN KEY (meal_plan_item_id)
          REFERENCES meal_plan_items(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id)
          REFERENCES ingredients(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      INSERT INTO meal_plan_item_ingredients_new
        (id, meal_plan_item_id, ingredient_id, custom_name, notes)
      SELECT id, meal_plan_item_id, ingredient_id, custom_name, notes
      FROM meal_plan_item_ingredients
    ''');
    await db.execute('DROP TABLE meal_plan_item_ingredients');
    await db.execute(
        'ALTER TABLE meal_plan_item_ingredients_new '
        'RENAME TO meal_plan_item_ingredients');

    await db.execute('''
      CREATE TABLE meal_ingredients_new(
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        ingredient_id TEXT,
        custom_name TEXT,
        notes TEXT,
        FOREIGN KEY (meal_id)
          REFERENCES meals(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id)
          REFERENCES ingredients(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      INSERT INTO meal_ingredients_new
        (id, meal_id, ingredient_id, custom_name, notes)
      SELECT id, meal_id, ingredient_id, custom_name, notes
      FROM meal_ingredients
    ''');
    await db.execute('DROP TABLE meal_ingredients');
    await db.execute(
        'ALTER TABLE meal_ingredients_new RENAME TO meal_ingredients');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final planCols = await db
        .rawQuery('PRAGMA table_info(meal_plan_item_ingredients)');
    final names1 = planCols.map((c) => c['name'] as String).toSet();
    if (!names1.containsAll({'quantity', 'unit'})) return false;

    final mealCols =
        await db.rawQuery('PRAGMA table_info(meal_ingredients)');
    final names2 = mealCols.map((c) => c['name'] as String).toSet();
    return names2.containsAll({'quantity', 'unit'});
  }
}
