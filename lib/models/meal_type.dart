import '../l10n/app_localizations.dart';

/// Enum representing the type/context of a cooked meal
enum MealType {
  lunch('lunch'),
  dinner('dinner'),
  prep('prep'); // Meal prep / undefined

  final String value;
  const MealType(this.value);

  /// Convert from database string value
  static MealType? fromString(String? value) {
    if (value == null) return null;
    return MealType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MealType.prep,
    );
  }

  /// Get localized display name
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case MealType.lunch:
        return l10n.mealTypeLunch;
      case MealType.dinner:
        return l10n.mealTypeDinner;
      case MealType.prep:
        return l10n.mealTypePrep;
    }
  }
}
