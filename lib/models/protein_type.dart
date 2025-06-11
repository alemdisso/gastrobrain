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
}
