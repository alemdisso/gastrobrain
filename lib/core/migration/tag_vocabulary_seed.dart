import 'migration.dart';

/// Built-in tag_types seeded by migrations 005 (AddTagsMigration), 006
/// (AddMealRoleFoodTypeMigration), and 008 (AddSauceFoodTypeMigration).
/// Tuple shape: (id, name, isHard, isOpen)
const builtInTagTypes = <(String, String, int, int)>[
  ('cuisine', 'Cuisine', 0, 1),
  ('occasion', 'Occasion', 0, 1),
  ('dietary', 'Dietary', 1, 0),
  ('meal_role', 'Meal Role', 0, 0),
  ('food_type', 'Food Type', 0, 0),
];

/// Built-in tags seeded by migrations 005, 006, and 008.
/// Tuple shape: (id, name, typeId)
const builtInTags = <(String, String, String)>[
  // dietary
  ('dietary-vegetarian', 'vegetarian', 'dietary'),
  ('dietary-vegan', 'vegan', 'dietary'),
  ('dietary-gluten-free', 'gluten-free', 'dietary'),
  ('dietary-dairy-free', 'dairy-free', 'dietary'),
  // meal_role
  ('meal-role-main-dish', 'main dish', 'meal_role'),
  ('meal-role-side-dish', 'side dish', 'meal_role'),
  ('meal-role-complete-meal', 'complete meal', 'meal_role'),
  ('meal-role-appetizer', 'appetizer', 'meal_role'),
  ('meal-role-accompaniment', 'accompaniment', 'meal_role'),
  ('meal-role-dessert', 'dessert', 'meal_role'),
  ('meal-role-snack', 'snack', 'meal_role'),
  // food_type
  ('food-type-soup', 'soup', 'food_type'),
  ('food-type-stew', 'stew', 'food_type'),
  ('food-type-salad', 'salad', 'food_type'),
  ('food-type-stock', 'stock', 'food_type'),
  ('food-type-sandwich', 'sandwich', 'food_type'),
  ('food-type-pasta', 'pasta', 'food_type'),
  ('food-type-rice', 'rice', 'food_type'),
  ('food-type-grilled', 'grilled', 'food_type'),
  ('food-type-baked', 'baked', 'food_type'),
  ('food-type-raw', 'raw', 'food_type'),
  ('food-type-sauce', 'sauce', 'food_type'),
];

/// Built-in tag vocabulary seed data, sourced verbatim from migrations 005
/// (AddTagsMigration), 006 (AddMealRoleFoodTypeMigration), and 008
/// (AddSauceFoodTypeMigration).
///
/// Idempotent via INSERT OR IGNORE — safe on a fresh, partially-seeded, or
/// fully-seeded database. Used by migration 013 (self-heal), by
/// DatabaseBackupService._restoreFromJson (post-restore reseed, #399), and
/// by TagRepository's startup health-check/repair (#401).
Future<void> seedBuiltInTagVocabulary(DatabaseExecutor db) async {
  for (final (id, name, isHard, isOpen) in builtInTagTypes) {
    await db.execute(
      'INSERT OR IGNORE INTO tag_types (id, name, is_hard, is_open) VALUES (?, ?, ?, ?)',
      [id, name, isHard, isOpen],
    );
  }

  for (final (id, name, typeId) in builtInTags) {
    await db.execute(
      'INSERT OR IGNORE INTO tags (id, name, type_id) VALUES (?, ?, ?)',
      [id, name, typeId],
    );
  }
}
