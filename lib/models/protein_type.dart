import '../l10n/app_localizations.dart';

enum ProteinType {
  // Main proteins (for rotation)
  beef(isMainProtein: true),
  chicken(isMainProtein: true),
  pork(isMainProtein: true),
  fish(isMainProtein: true),
  seafood(isMainProtein: true),
  lamb(isMainProtein: true),

  // Special categories (not for rotation)
  charcuterie(isMainProtein: false),
  offal(isMainProtein: false),
  plantBased(isMainProtein: false),
  other(isMainProtein: false);

  final bool isMainProtein;

  const ProteinType({required this.isMainProtein});

  String get displayName {
    switch (this) {
      case ProteinType.beef:
        return 'Beef';
      case ProteinType.chicken:
        return 'Chicken';
      case ProteinType.pork:
        return 'Pork';
      case ProteinType.lamb:
        return 'Lamb';
      case ProteinType.fish:
        return 'Fish';
      case ProteinType.seafood:
        return 'Seafood';
      case ProteinType.charcuterie:
        return 'Charcuterie';
      case ProteinType.offal:
        return 'Offal';
      case ProteinType.plantBased:
        return 'Plant Based';
      case ProteinType.other:
        return 'Other';
    }
  }

  String getLocalizedDisplayName(context) {
    final localizations = context != null ? AppLocalizations.of(context)! : null;
    
    if (localizations == null) {
      return displayName; // Fallback to English
    }
    
    switch (this) {
      case ProteinType.beef:
        return localizations.proteinBeef;
      case ProteinType.chicken:
        return localizations.proteinChicken;
      case ProteinType.pork:
        return localizations.proteinPork;
      case ProteinType.lamb:
        return localizations.proteinLamb;
      case ProteinType.fish:
        return localizations.proteinFish;
      case ProteinType.seafood:
        return localizations.proteinSeafood;
      case ProteinType.charcuterie:
        return localizations.proteinCharcuterie;
      case ProteinType.offal:
        return localizations.proteinOffal;
      case ProteinType.plantBased:
        return localizations.proteinPlantBased;
      case ProteinType.other:
        return localizations.proteinOther;
    }
  }
}
