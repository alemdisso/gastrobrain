// lib/models/shopping_list.dart

class ShoppingList {
  final int? id;
  final String name;
  final DateTime dateCreated;
  final DateTime startDate;
  final DateTime endDate;

  ShoppingList({
    this.id,
    required this.name,
    required this.dateCreated,
    required this.startDate,
    required this.endDate,
  });

  /// Convert a ShoppingList to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date_created': dateCreated.millisecondsSinceEpoch,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate.millisecondsSinceEpoch,
    };
  }

  /// Create a ShoppingList from a Map retrieved from database
  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'] as int?,
      name: map['name'] as String,
      dateCreated: DateTime.fromMillisecondsSinceEpoch(map['date_created'] as int),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int),
    );
  }

  /// Create a copy of this ShoppingList with optional field updates
  ShoppingList copyWith({
    int? id,
    String? name,
    DateTime? dateCreated,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      dateCreated: dateCreated ?? this.dateCreated,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingList &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, dateCreated: $dateCreated, startDate: $startDate, endDate: $endDate)';
  }
}
