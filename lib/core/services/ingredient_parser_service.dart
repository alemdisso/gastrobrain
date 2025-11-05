import '../../l10n/app_localizations.dart';
import '../../models/measurement_unit.dart';
import '../../models/ingredient_match.dart';
import 'ingredient_matching_service.dart';

/// Service for parsing ingredient text lines into structured data
///
/// Provides context-aware parsing that handles Portuguese ingredient syntax,
/// particularly the multiple uses of "de" (meaning "of"):
/// 1. Inside compound units: "colheres de sopa" → keep as single unit
/// 2. After unit: "2 kg de mangas" → strip to extract ingredient name
/// 3. Inside ingredient names: "pasta de tamarindo" → preserve
/// 4. Inside descriptors: "em ponto de bala" → preserve in notes
///
/// The service uses the MeasurementUnit model as the single source of truth
/// for valid units and supports localized unit names via AppLocalizations.
class IngredientParserService {
  /// Map of all recognized unit strings to their standard MeasurementUnit values
  /// Built from MeasurementUnit enum and localized strings
  final Map<String, String> _unitStringMap = {};
  
  /// Sorted list of unit strings (longest first) for matching
  List<String> _sortedUnitStrings = [];
  
  /// Reference to ingredient matching service for fuzzy matching
  IngredientMatchingService? _matchingService;
  
  /// Whether the service has been initialized
  bool _isInitialized = false;
  
  /// Initialize the service with localized strings
  /// Must be called before using the service
  void initialize(AppLocalizations localizations, {IngredientMatchingService? matchingService}) {
    // Guard against double initialization
    if (_isInitialized) {
      return;
    }
    
    _matchingService = matchingService;
    _unitStringMap.clear();
    
    // Build unit map from MeasurementUnit enum
    for (final unit in MeasurementUnit.values) {
      final standardValue = unit.value;
      
      // Add the standard value (e.g., 'g', 'kg', 'tbsp')
      _unitStringMap[standardValue] = standardValue;
      
      // Add English display name
      _unitStringMap[unit.displayName.toLowerCase()] = standardValue;
      
      // Add localized display name (Portuguese)
      final localizedName = unit.getLocalizedDisplayName(null); // Uses fallback
      if (localizedName != unit.displayName) {
        _unitStringMap[localizedName.toLowerCase()] = standardValue;
      }
      
      // Get Portuguese localized name using the localizations object
      // Map each unit to its Portuguese equivalent
      String? portugueseName;
      switch (unit) {
        case MeasurementUnit.cup:
          portugueseName = localizations.measurementUnitCup.toLowerCase();
          break;
        case MeasurementUnit.tablespoon:
          portugueseName = localizations.measurementUnitTablespoon.toLowerCase();
          break;
        case MeasurementUnit.teaspoon:
          portugueseName = localizations.measurementUnitTeaspoon.toLowerCase();
          break;
        case MeasurementUnit.piece:
          portugueseName = localizations.measurementUnitPiece.toLowerCase();
          break;
        case MeasurementUnit.slice:
          portugueseName = localizations.measurementUnitSlice.toLowerCase();
          break;
        case MeasurementUnit.bunch:
          portugueseName = localizations.measurementUnitBunch.toLowerCase();
          break;
        case MeasurementUnit.leaves:
          portugueseName = localizations.measurementUnitLeaves.toLowerCase();
          break;
        case MeasurementUnit.pinch:
          portugueseName = localizations.measurementUnitPinch.toLowerCase();
          break;
        case MeasurementUnit.clove:
          portugueseName = localizations.measurementUnitClove.toLowerCase();
          break;
        case MeasurementUnit.head:
          portugueseName = localizations.measurementUnitHead.toLowerCase();
          break;
        case MeasurementUnit.can:
          portugueseName = localizations.measurementUnitCan.toLowerCase();
          break;
        case MeasurementUnit.box:
          portugueseName = localizations.measurementUnitBox.toLowerCase();
          break;
        case MeasurementUnit.stem:
          portugueseName = localizations.measurementUnitStem.toLowerCase();
          break;
        case MeasurementUnit.sprig:
          portugueseName = localizations.measurementUnitSprig.toLowerCase();
          break;
        case MeasurementUnit.seed:
          portugueseName = localizations.measurementUnitSeed.toLowerCase();
          break;
        case MeasurementUnit.grain:
          portugueseName = localizations.measurementUnitGrain.toLowerCase();
          break;
        case MeasurementUnit.centimeter:
          portugueseName = localizations.measurementUnitCm.toLowerCase();
          break;
        default:
          portugueseName = null;
      }
      
      if (portugueseName != null && portugueseName.isNotEmpty) {
        _unitStringMap[portugueseName] = standardValue;
      }
    }
    
    // Add common abbreviations and variants (PT/EN)
    _addUnitVariants();
    
    // Sort unit strings by length (longest first) for matching
    _sortedUnitStrings = _unitStringMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    _isInitialized = true;
  }
  
  /// Add common abbreviations and variants for units
  void _addUnitVariants() {
    // Weight variants
    _unitStringMap['gram'] = 'g';
    _unitStringMap['grama'] = 'g';
    _unitStringMap['gramas'] = 'g';
    _unitStringMap['quilograma'] = 'kg';
    _unitStringMap['quilogramas'] = 'kg';
    _unitStringMap['kilogram'] = 'kg';
    _unitStringMap['kilograms'] = 'kg';
    
    // Volume variants
    _unitStringMap['litro'] = 'l';
    _unitStringMap['litros'] = 'l';
    _unitStringMap['liter'] = 'l';
    _unitStringMap['liters'] = 'l';
    
    // Cup variants
    _unitStringMap['xícara'] = 'cup';
    _unitStringMap['xicara'] = 'cup';
    _unitStringMap['xícaras'] = 'cup';
    _unitStringMap['xicaras'] = 'cup';
    _unitStringMap['cups'] = 'cup';
    _unitStringMap['c'] = 'cup';
    
    // Tablespoon variants (including compound forms)
    _unitStringMap['tablespoon'] = 'tbsp';
    _unitStringMap['tablespoons'] = 'tbsp';
    _unitStringMap['colher'] = 'tbsp';
    _unitStringMap['colheres'] = 'tbsp';
    _unitStringMap['col'] = 'tbsp';
    _unitStringMap['cs'] = 'tbsp';
    _unitStringMap['csp'] = 'tbsp';
    // Compound forms (primary Portuguese forms)
    _unitStringMap['colher de sopa'] = 'tbsp';
    _unitStringMap['colheres de sopa'] = 'tbsp';
    _unitStringMap['colher de sobremesa'] = 'tbsp'; // dessert spoon (≈ tbsp)
    _unitStringMap['colheres de sobremesa'] = 'tbsp';
    
    // Teaspoon variants (including compound forms)
    _unitStringMap['teaspoon'] = 'tsp';
    _unitStringMap['teaspoons'] = 'tsp';
    // Compound forms with accent (primary Portuguese forms)
    _unitStringMap['colher de chá'] = 'tsp';
    _unitStringMap['colheres de chá'] = 'tsp';
    // Compound forms without accent (variant)
    _unitStringMap['colher de cha'] = 'tsp';
    _unitStringMap['colheres de cha'] = 'tsp';
    // Simple forms
    _unitStringMap['chá'] = 'tsp';
    _unitStringMap['cha'] = 'tsp';
    _unitStringMap['cc'] = 'tsp';
    
    // Count variants
    _unitStringMap['unidade'] = 'piece';
    _unitStringMap['unidades'] = 'piece';
    _unitStringMap['piece'] = 'piece';
    _unitStringMap['pieces'] = 'piece';
    _unitStringMap['pç'] = 'piece';
    _unitStringMap['pc'] = 'piece';
    _unitStringMap['un'] = 'piece';
    
    // Slice variants
    _unitStringMap['fatias'] = 'slice';
    _unitStringMap['slice'] = 'slice';
    _unitStringMap['slices'] = 'slice';
    
    // Bunch variants
    _unitStringMap['maço'] = 'bunch';
    _unitStringMap['macos'] = 'bunch';
    _unitStringMap['bunch'] = 'bunch';
    _unitStringMap['bunches'] = 'bunch';
    
    // Leaves variants
    _unitStringMap['folha'] = 'leaves';
    _unitStringMap['folhas'] = 'leaves';
    _unitStringMap['leaf'] = 'leaves';
    
    // Pinch variants
    _unitStringMap['pitada'] = 'pinch';
    _unitStringMap['pitadas'] = 'pinch';
    
    // Clove variants
    _unitStringMap['dente'] = 'clove';
    _unitStringMap['dentes'] = 'clove';
    _unitStringMap['cloves'] = 'clove';
    
    // Head variants
    _unitStringMap['cabeça'] = 'head';
    _unitStringMap['cabeca'] = 'head';
    _unitStringMap['cabeças'] = 'head';
    _unitStringMap['cabecas'] = 'head';
    _unitStringMap['heads'] = 'head';
    
    // Can variants
    _unitStringMap['lata'] = 'can';
    _unitStringMap['latas'] = 'can';
    _unitStringMap['can'] = 'can';
    _unitStringMap['cans'] = 'can';
    
    // Box variants
    _unitStringMap['caixa'] = 'box';
    _unitStringMap['caixas'] = 'box';
    _unitStringMap['box'] = 'box';
    _unitStringMap['boxes'] = 'box';
    
    // Stem variants
    _unitStringMap['talo'] = 'stem';
    _unitStringMap['talos'] = 'stem';
    _unitStringMap['stem'] = 'stem';
    _unitStringMap['stems'] = 'stem';
    
    // Sprig variants
    _unitStringMap['ramo'] = 'sprig';
    _unitStringMap['ramos'] = 'sprig';
    _unitStringMap['sprig'] = 'sprig';
    _unitStringMap['sprigs'] = 'sprig';
    
    // Seed variants
    _unitStringMap['semente'] = 'seed';
    _unitStringMap['sementes'] = 'seed';
    _unitStringMap['seed'] = 'seed';
    _unitStringMap['seeds'] = 'seed';
    
    // Grain variants (for peppercorns, cardamom, etc.)
    _unitStringMap['grão'] = 'grain';
    _unitStringMap['grao'] = 'grain'; // without tilde
    _unitStringMap['grãos'] = 'grain';
    _unitStringMap['graos'] = 'grain'; // without tilde
    _unitStringMap['grain'] = 'grain';
    _unitStringMap['grains'] = 'grain';
    
    // Centimeter variants
    _unitStringMap['cm'] = 'cm';
    _unitStringMap['centímetro'] = 'cm';
    _unitStringMap['centimetro'] = 'cm'; // without accent
    _unitStringMap['centímetros'] = 'cm';
    _unitStringMap['centimetros'] = 'cm'; // without accent
    _unitStringMap['centimeter'] = 'cm';
    _unitStringMap['centimeters'] = 'cm';
  }
  
  /// Match a unit string at the start of the text
  /// Returns matched unit and remaining text, or null if no match
  _UnitMatch? matchUnitAtStart(String text) {
    if (!_isInitialized) {
      throw StateError('IngredientParserService must be initialized before use');
    }
    
    final lowerText = text.toLowerCase().trim();
    
    // Try to match unit strings from longest to shortest
    // This ensures "colheres de sopa" matches before "colheres"
    for (final unitString in _sortedUnitStrings) {
      if (lowerText.startsWith(unitString)) {
        // Check word boundary (space or end of string)
        final endIndex = unitString.length;
        if (endIndex >= lowerText.length || lowerText[endIndex] == ' ') {
          final standardUnit = _unitStringMap[unitString]!;
          final remaining = text.substring(endIndex).trim();
          
          return _UnitMatch(
            unit: standardUnit,
            matchedString: text.substring(0, endIndex).trim(),
            remaining: remaining,
          );
        }
      }
    }
    
    return null;
  }
  
  /// Parse a quantity string that may include mixed numbers
  /// 
  /// Handles mixed numbers where a whole number is followed by a fraction,
  /// separated by a space (e.g., "2 1/2" or "1 ½").
  /// 
  /// Supports:
  /// - Mixed numbers with slash fractions: 1 1/2 → 1.5, 2 3/4 → 2.75
  /// - Mixed numbers with unicode fractions: 1 ½ → 1.5, 2 ¾ → 2.75
  /// - Single fractions: 1/2 → 0.5, ½ → 0.5
  /// - Decimals: 1.5, 2,5
  /// - Integers: 1, 2, 3
  /// 
  /// For mixed numbers, the whole and fractional parts are added together.
  /// If the string is not a mixed number, delegates to [_parseFraction].
  double _parseQuantity(String quantityStr) {
    // Check for mixed number pattern: "2 1/2" or "1 ½"
    // Captures: (whole number) (space) (fraction part)
    final mixedPattern = RegExp(r'^(\d+)\s+(.+)$');
    final mixedMatch = mixedPattern.firstMatch(quantityStr);
    
    if (mixedMatch != null) {
      final wholePart = mixedMatch.group(1)!;
      final fractionPart = mixedMatch.group(2)!;
      
      // Check if the second part is a fraction (unicode or slash)
      // Only treat as mixed number if second part is actually a fraction
      if (fractionPart.contains('/') || 
          RegExp(r'^[½⅓¼⅔¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]$').hasMatch(fractionPart)) {
        final whole = double.tryParse(wholePart) ?? 0;
        final fraction = _parseFraction(fractionPart);
        return whole + fraction;
      }
    }
    
    // Not a mixed number, parse as single fraction/number
    return _parseFraction(quantityStr);
  }
  
  /// Parse a fraction string to decimal
  /// 
  /// Converts various fraction formats to their decimal equivalents.
  /// Handles unicode fractions, slash fractions, decimals, and integers.
  /// 
  /// Supports:
  /// - Unicode fractions: ½ → 0.5, ¼ → 0.25, etc.
  /// - Slash fractions: 1/2 → 0.5, 3/4 → 0.75, 5/3 → 1.667, etc.
  /// - Regular decimals: 1.5, 2,5 (both . and , as decimal separator)
  /// - Integers: 1, 2, 3
  /// 
  /// Invalid fractions (e.g., divide by zero) return 1.0 as a safe default.
  double _parseFraction(String fractionStr) {
    // Unicode fraction map - maps common fraction characters to decimal values
    // Values are approximations for repeating decimals (e.g., 1/3 ≈ 0.333)
    const unicodeFractions = {
      '½': 0.5,      // 1/2
      '⅓': 0.333,    // 1/3 (approximation)
      '¼': 0.25,     // 1/4
      '⅔': 0.667,    // 2/3 (approximation)
      '¾': 0.75,     // 3/4
      '⅕': 0.2,      // 1/5
      '⅖': 0.4,      // 2/5
      '⅗': 0.6,      // 3/5
      '⅘': 0.8,      // 4/5
      '⅙': 0.167,    // 1/6 (approximation)
      '⅚': 0.833,    // 5/6 (approximation)
      '⅛': 0.125,    // 1/8
      '⅜': 0.375,    // 3/8
      '⅝': 0.625,    // 5/8
      '⅞': 0.875,    // 7/8
    };
    
    // Check if it's a unicode fraction
    if (unicodeFractions.containsKey(fractionStr)) {
      return unicodeFractions[fractionStr]!;
    }
    
    // Check if it's a slash fraction (e.g., "1/2", "3/4", "5/3")
    if (fractionStr.contains('/')) {
      final parts = fractionStr.split('/');
      if (parts.length == 2) {
        final numerator = int.tryParse(parts[0]);
        final denominator = int.tryParse(parts[1]);
        
        // Handle invalid fractions gracefully (divide by zero, invalid numbers)
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
      // Invalid fraction format (e.g., "1/0", "a/b"), return safe default
      return 1.0;
    }
    
    // Regular decimal/integer (handle both . and , as decimal separator)
    // Portuguese uses comma as decimal separator, so we normalize to period
    return double.tryParse(fractionStr.replaceAll(',', '.')) ?? 1.0;
  }
  
  /// Parse a single ingredient line into structured data
  /// 
  /// Returns a parsed ingredient with quantity, unit, name, and notes
  /// Uses context-aware "de" stripping and fuzzy ingredient matching
  /// 
  /// Supports various quantity formats:
  /// - Integers: 1, 2, 3
  /// - Decimals: 1.5, 2,5 (both . and , as decimal separator)
  /// - Unicode fractions: ½, ¼, ¾, ⅓, ⅔, ⅛, ⅜, ⅝, ⅞, ⅕, ⅖, ⅗, ⅘, ⅙, ⅚
  /// - Slash fractions: 1/2, 3/4, 1/3, 2/3, 5/4 (any valid fraction)
  /// - Mixed numbers: 1 1/2, 2 3/4, 1 ½, 10 ¼ (with slash or unicode fractions)
  /// 
  /// Portuguese "de" pattern handling:
  /// - Strips "de" between quantity and unit: "1/4 de xícara" → 0.25 cup
  /// - Strips "de" after unit: "2 kg de mangas" → 2 kg, mangas
  /// - Preserves "de" in compound units: "colher de sopa" → tbsp
  /// - Preserves "de" in ingredient names: "pasta de tamarindo"
  /// 
  /// Examples:
  /// ```dart
  /// parseIngredientLine('½ xícara de farinha')
  ///   → quantity: 0.5, unit: "cup", name: "farinha"
  /// 
  /// parseIngredientLine('2 1/2 kg de mangas')
  ///   → quantity: 2.5, unit: "kg", name: "mangas"
  /// 
  /// parseIngredientLine('1/4 de xícara de açúcar')
  ///   → quantity: 0.25, unit: "cup", name: "açúcar"
  /// ```
  ParsedIngredientResult parseIngredientLine(String line) {
    if (!_isInitialized) {
      throw StateError('IngredientParserService must be initialized before use');
    }
    
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      return ParsedIngredientResult(
        quantity: 0,
        unit: null,
        ingredientName: '',
        notes: null,
        matches: [],
      );
    }
    
    // Step 1: Extract quantity from beginning
    // Match: mixed number, slash fraction, unicode fraction, decimal, or integer
    // Pattern explanation:
    // - (\d+\s+)?(\d+/\d+|[½⅓¼⅔¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]) : optional whole number + space + fraction
    // - |\d+(?:[.,]\d+)? : OR decimal/integer
    final quantityPattern = RegExp(r'^((?:\d+\s+)?(?:\d+/\d+|[½⅓¼⅔¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞])|\d+(?:[.,]\d+)?)\s*');
    final quantityMatch = quantityPattern.firstMatch(trimmedLine);
    
    double quantity = 1.0;
    String remaining = trimmedLine;
    
    if (quantityMatch != null) {
      final quantityStr = quantityMatch.group(1)!;
      quantity = _parseQuantity(quantityStr);
      remaining = trimmedLine.substring(quantityMatch.end).trim();
    }
    
    // Step 2: Try to match unit at the start of remaining text
    String? unit;

    // Handle Portuguese "de" between quantity and unit (e.g., "1/4 de xícara")
    // Also handles "de" without unit (e.g., "1/4 de pimenta")
    String unitSearchText = remaining;
    bool strippedDe = false;
    if (remaining.toLowerCase().startsWith('de ')) {
      unitSearchText = remaining.substring(3).trim();
      strippedDe = true;
    }

    final unitMatch = matchUnitAtStart(unitSearchText);

    if (unitMatch != null) {
      unit = unitMatch.unit;
      remaining = unitMatch.remaining;

      // Step 3: Strip "de" ONLY if it immediately follows the matched unit
      // This handles patterns like "2 kg de mangas" or "2 colheres de sopa de azeite"
      if (remaining.toLowerCase().startsWith('de ')) {
        remaining = remaining.substring(3).trim();
      }
    } else {
      // No unit found - but if we stripped "de", use the stripped version
      // This handles: "1/4 de pimenta" → quantity=0.25, ingredient="pimenta"
      if (strippedDe) {
        remaining = unitSearchText;
      }
      if (quantityMatch != null) {
        // Quantity but no unit → default to "piece"
        unit = 'piece';
      }
    }
    
    // Step 4: Extract ingredient name + descriptors from remaining text
    String ingredientName = remaining;
    String? notes;
    List<IngredientMatch> matches = [];
    
    if (remaining.isNotEmpty && _matchingService != null) {
      // Try progressively shorter prefixes to find ingredient name
      final nameParts = remaining.split(' ');
      bool foundMatch = false;
      
      for (int i = nameParts.length; i >= 1 && !foundMatch; i--) {
        final testName = nameParts.sublist(0, i).join(' ');
        final testMatches = _matchingService!.findMatches(testName);
        
        // Accept if high confidence (≥90%)
        // For single-word matches (i==1), also accept if it's the only match
        if (testMatches.isNotEmpty) {
          final bestMatch = testMatches.first;
          if (bestMatch.confidence >= 0.90 || (i == 1 && testMatches.length == 1)) {
            ingredientName = bestMatch.ingredient.name;
            matches = testMatches;
            foundMatch = true;
            
            // Everything after matched ingredient → notes
            if (i < nameParts.length) {
              notes = nameParts.sublist(i).join(' ');
            }
          }
        }
      }
      
      // If no match found, keep original remaining text as name
      if (!foundMatch) {
        ingredientName = remaining;
        matches = _matchingService!.findMatches(remaining);
      }
    }
    
    // Handle "to taste" pattern (no quantity)
    if (quantityMatch == null && unit == null) {
      // Check if it's a "to taste" pattern
      if (trimmedLine.toLowerCase().contains('a gosto') ||
          trimmedLine.toLowerCase().contains('to taste')) {
        quantity = 0;
        // Extract just the ingredient name without "a gosto" / "to taste"
        ingredientName = ingredientName
            .replaceAll(RegExp(r'\s*a\s+gosto\s*', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*to\s+taste\s*', caseSensitive: false), '')
            .trim();
        notes = 'a gosto';
      }
    }
    
    return ParsedIngredientResult(
      quantity: quantity,
      unit: unit,
      ingredientName: ingredientName,
      notes: notes,
      matches: matches,
    );
  }
}

/// Result of matching a unit at the start of text
class _UnitMatch {
  final String unit;
  final String matchedString;
  final String remaining;
  
  _UnitMatch({
    required this.unit,
    required this.matchedString,
    required this.remaining,
  });
}

/// Result of parsing an ingredient line
class ParsedIngredientResult {
  final double quantity;
  final String? unit;
  final String ingredientName;
  final String? notes;
  final List<IngredientMatch> matches;
  
  ParsedIngredientResult({
    required this.quantity,
    required this.unit,
    required this.ingredientName,
    required this.notes,
    required this.matches,
  });
}
