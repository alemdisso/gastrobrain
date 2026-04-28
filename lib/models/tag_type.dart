import '../l10n/app_localizations.dart';

class TagType {
  final String id;
  final String name;
  final bool isHard;
  final bool isOpen;

  const TagType({
    required this.id,
    required this.name,
    required this.isHard,
    required this.isOpen,
  });

  factory TagType.fromMap(Map<String, dynamic> map) {
    return TagType(
      id: map['id'] as String,
      name: map['name'] as String,
      isHard: (map['is_hard'] as int) == 1,
      isOpen: (map['is_open'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_hard': isHard ? 1 : 0,
      'is_open': isOpen ? 1 : 0,
    };
  }

  String getLocalizedName(AppLocalizations l10n) {
    switch (id) {
      case 'cuisine':
        return l10n.tagTypeCuisine;
      case 'occasion':
        return l10n.tagTypeOccasion;
      case 'dietary':
        return l10n.tagTypeDietary;
      case 'meal_role':
        return l10n.tagTypeMealRole;
      case 'food_type':
        return l10n.tagTypeFoodType;
      default:
        return name;
    }
  }

  TagType copyWith({
    String? id,
    String? name,
    bool? isHard,
    bool? isOpen,
  }) {
    return TagType(
      id: id ?? this.id,
      name: name ?? this.name,
      isHard: isHard ?? this.isHard,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagType && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TagType($id, isHard: $isHard, isOpen: $isOpen)';
}
