import '../l10n/app_localizations.dart';

enum MeasurementUnit {
  gram('g'),
  kilogram('kg'),
  milliliter('ml'),
  liter('l'),
  cup('cup'),
  tablespoon('tbsp'),
  teaspoon('tsp'),
  piece('piece'),
  slice('slice'),
  bunch('bunch'),
  leaves('leaves'),
  pinch('pinch');

  final String value;
  const MeasurementUnit(this.value);

  static MeasurementUnit? fromString(String? value) {
    if (value == null) return null;
    
    try {
      return MeasurementUnit.values.firstWhere(
        (unit) => unit.value == value.toLowerCase(),
      );
    } catch (e) {
      return null; // Return null for unknown units
    }
  }

  String get displayName {
    switch (this) {
      case MeasurementUnit.gram:
        return 'g';
      case MeasurementUnit.kilogram:
        return 'kg';
      case MeasurementUnit.milliliter:
        return 'ml';
      case MeasurementUnit.liter:
        return 'l';
      case MeasurementUnit.cup:
        return 'Cup';
      case MeasurementUnit.tablespoon:
        return 'Tbsp';
      case MeasurementUnit.teaspoon:
        return 'Tsp';
      case MeasurementUnit.piece:
        return 'Piece';
      case MeasurementUnit.slice:
        return 'Slice';
      case MeasurementUnit.bunch:
        return 'Bunch';
      case MeasurementUnit.leaves:
        return 'Leaves';
      case MeasurementUnit.pinch:
        return 'Pinch';
    }
  }

  String getLocalizedDisplayName(context) {
    final localizations = context != null ? AppLocalizations.of(context)! : null;
    
    if (localizations == null) {
      return displayName; // Fallback to English
    }
    
    switch (this) {
      case MeasurementUnit.gram:
        return 'g'; // Keep abbreviations as-is
      case MeasurementUnit.kilogram:
        return 'kg';
      case MeasurementUnit.milliliter:
        return 'ml';
      case MeasurementUnit.liter:
        return 'l';
      case MeasurementUnit.cup:
        return localizations.measurementUnitCup;
      case MeasurementUnit.tablespoon:
        return localizations.measurementUnitTablespoon;
      case MeasurementUnit.teaspoon:
        return localizations.measurementUnitTeaspoon;
      case MeasurementUnit.piece:
        return localizations.measurementUnitPiece;
      case MeasurementUnit.slice:
        return localizations.measurementUnitSlice;
      case MeasurementUnit.bunch:
        return localizations.measurementUnitBunch;
      case MeasurementUnit.leaves:
        return localizations.measurementUnitLeaves;
      case MeasurementUnit.pinch:
        return localizations.measurementUnitPinch;
    }
  }
}