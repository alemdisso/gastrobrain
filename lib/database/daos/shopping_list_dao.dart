// lib/database/daos/shopping_list_dao.dart

import 'package:sqflite/sqflite.dart';
import '../../models/shopping_list.dart';
import '../../models/shopping_list_item.dart';

class ShoppingListDao {
  final Future<Database> Function() _getDb;

  ShoppingListDao(this._getDb);

  Future<int> insertShoppingList(ShoppingList shoppingList) async {
    final db = await _getDb();
    return await db.insert('shopping_lists', shoppingList.toMap());
  }

  Future<ShoppingList?> getShoppingList(int id) async {
    final db = await _getDb();
    final results = await db.query('shopping_lists', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return ShoppingList.fromMap(results.first);
  }

  Future<ShoppingList?> getShoppingListForDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _getDb();
    final results = await db.query(
      'shopping_lists',
      where: 'start_date = ? AND end_date = ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: 'date_created DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ShoppingList.fromMap(results.first);
  }

  Future<void> deleteShoppingList(int id) async {
    final db = await _getDb();
    await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertShoppingListItem(ShoppingListItem item) async {
    final db = await _getDb();
    return await db.insert('shopping_list_items', item.toMap());
  }

  Future<ShoppingListItem?> getShoppingListItem(int id) async {
    final db = await _getDb();
    final results = await db.query('shopping_list_items', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return ShoppingListItem.fromMap(results.first);
  }

  Future<List<ShoppingListItem>> getShoppingListItems(int shoppingListId) async {
    final db = await _getDb();
    final results = await db.query('shopping_list_items', where: 'shopping_list_id = ?', whereArgs: [shoppingListId]);
    return results.map((map) => ShoppingListItem.fromMap(map)).toList();
  }

  Future<void> updateShoppingListItem(ShoppingListItem item) async {
    final db = await _getDb();
    await db.update('shopping_list_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteShoppingListItem(int id) async {
    final db = await _getDb();
    await db.delete('shopping_list_items', where: 'id = ?', whereArgs: [id]);
  }
}
