// =============================================================================
// Model Pattern Template
// =============================================================================
// Reference: lib/models/meal_type.dart, lib/models/recipe.dart
//
// This file demonstrates the standard patterns for:
// 1. Enum definitions with database value mapping
// 2. Model classes with serialization
// =============================================================================

import '../l10n/app_localizations.dart';

// -----------------------------------------------------------------------------
// ENUM PATTERN
// -----------------------------------------------------------------------------
// Use when: Creating a new enum that maps to database values
// Reference: lib/models/meal_type.dart
// -----------------------------------------------------------------------------

/// Enum with string value mapping and localization
enum MyType {
  option1('option1'),
  option2('option2'),
  option3('option3');

  /// The database/storage value
  final String value;

  const MyType(this.value);

  /// Convert from database string value
  /// Returns null if value is null, default if not found
  static MyType? fromString(String? value) {
    if (value == null) return null;
    return MyType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MyType.option1, // Default fallback
    );
  }

  /// Get localized display name for UI
  /// Always use l10n strings, never hardcode
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case MyType.option1:
        return l10n.myTypeOption1;
      case MyType.option2:
        return l10n.myTypeOption2;
      case MyType.option3:
        return l10n.myTypeOption3;
    }
  }
}

// -----------------------------------------------------------------------------
// MODEL PATTERN
// -----------------------------------------------------------------------------
// Use when: Creating a new data model for database entities
// Reference: lib/models/recipe.dart, lib/models/meal.dart
// -----------------------------------------------------------------------------

/// Model class with complete serialization support
class MyModel {
  /// Unique identifier (use String for UUIDs)
  final String id;

  /// Required field
  final String name;

  /// Optional field with type enum
  final MyType? type;

  /// Nullable optional field
  final String? description;

  /// Non-null with default value
  final bool isActive;

  /// DateTime field
  final DateTime createdAt;

  MyModel({
    required this.id,
    required this.name,
    this.type,
    this.description,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to map for database storage
  /// Keys must match database column names (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type?.value, // Use .value for enums
      'description': description,
      'is_active': isActive ? 1 : 0, // SQLite uses 0/1 for bools
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from database map
  /// Handle null values and type conversions
  factory MyModel.fromMap(Map<String, dynamic> map) {
    return MyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: MyType.fromString(map['type'] as String?),
      description: map['description'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Copy with modified fields
  /// All parameters are optional
  MyModel copyWith({
    String? id,
    String? name,
    MyType? type,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Equality based on ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MyModel(id: $id, name: $name, type: $type)';
}
