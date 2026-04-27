import '../../database/database_helper.dart';
import '../../models/tag.dart';
import '../../models/tag_type.dart';
import '../../utils/id_generator.dart';
import '../errors/gastrobrain_exceptions.dart';

class TagRepository {
  final DatabaseHelper _dbHelper;

  TagRepository(this._dbHelper);

  Future<List<TagType>> getAllTagTypes() async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query('tag_types', orderBy: 'name ASC');
      return rows.map(TagType.fromMap).toList();
    } catch (e) {
      throw GastrobrainException('Failed to load tag types: $e');
    }
  }

  Future<List<Tag>> getTagsByType(String typeId) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'tags',
        where: 'type_id = ?',
        whereArgs: [typeId],
        orderBy: 'name ASC',
      );
      return rows.map(Tag.fromMap).toList();
    } catch (e) {
      throw GastrobrainException('Failed to load tags for type $typeId: $e');
    }
  }

  Future<List<Tag>> getTagsForRecipe(String recipeId) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery('''
        SELECT t.id, t.name, t.type_id
        FROM tags t
        JOIN recipe_tags rt ON rt.tag_id = t.id
        WHERE rt.recipe_id = ?
        ORDER BY t.type_id ASC, t.name ASC
      ''', [recipeId]);
      return rows.map(Tag.fromMap).toList();
    } catch (e) {
      throw GastrobrainException('Failed to load tags for recipe $recipeId: $e');
    }
  }

  Future<void> addTagToRecipe(String recipeId, String tagId) async {
    try {
      final db = await _dbHelper.database;
      await db.rawInsert(
        'INSERT OR IGNORE INTO recipe_tags (recipe_id, tag_id) VALUES (?, ?)',
        [recipeId, tagId],
      );
    } catch (e) {
      throw GastrobrainException('Failed to add tag to recipe: $e');
    }
  }

  Future<void> removeTagFromRecipe(String recipeId, String tagId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'recipe_tags',
        where: 'recipe_id = ? AND tag_id = ?',
        whereArgs: [recipeId, tagId],
      );
    } catch (e) {
      throw GastrobrainException('Failed to remove tag from recipe: $e');
    }
  }

  Future<Tag> createTag(String name, String typeId) async {
    try {
      final db = await _dbHelper.database;
      final tag = Tag(
        id: IdGenerator.generateId(),
        name: name.trim(),
        typeId: typeId,
      );
      await db.insert('tags', tag.toMap());
      return tag;
    } catch (e) {
      throw GastrobrainException('Failed to create tag: $e');
    }
  }

  /// Returns an existing tag with the same name+typeId (case-insensitive),
  /// or creates a new one if none exists.
  Future<Tag> getOrCreateTag(String name, String typeId) async {
    try {
      final db = await _dbHelper.database;
      final existing = await db.rawQuery(
        'SELECT id, name, type_id FROM tags WHERE type_id = ? AND LOWER(name) = LOWER(?)',
        [typeId, name.trim()],
      );
      if (existing.isNotEmpty) {
        return Tag.fromMap(existing.first);
      }
      return createTag(name, typeId);
    } catch (e) {
      if (e is GastrobrainException) rethrow;
      throw GastrobrainException('Failed to get or create tag: $e');
    }
  }

  Future<void> setTagsForRecipe(String recipeId, List<String> tagIds) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'recipe_tags',
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
      );
      for (final tagId in tagIds) {
        await db.rawInsert(
          'INSERT OR IGNORE INTO recipe_tags (recipe_id, tag_id) VALUES (?, ?)',
          [recipeId, tagId],
        );
      }
    } catch (e) {
      throw GastrobrainException('Failed to set tags for recipe: $e');
    }
  }
}
