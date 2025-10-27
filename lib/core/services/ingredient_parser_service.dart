import '../../l10n/app_localizations.dart';
import '../../models/measurement_unit.dart';
import '../../models/ingredient.dart';
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
  
  /// Parse a single ingredient line into structured data
  /// 
  /// Returns a parsed ingredient with quantity, unit, name, and notes
  /// Uses context-aware "de" stripping and fuzzy ingredient matching
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
    final quantityPattern = RegExp(r'^(\d+(?:[.,]\d+)?)\s*');
    final quantityMatch = quantityPattern.firstMatch(trimmedLine);
    
    double quantity = 1.0;
    String remaining = trimmedLine;
    
    if (quantityMatch != null) {
      final quantityStr = quantityMatch.group(1)!.replaceAll(',', '.');
      quantity = double.tryParse(quantityStr) ?? 1.0;
      remaining = trimmedLine.substring(quantityMatch.end).trim();
    }
    
    // Step 2: Try to match unit at the start of remaining text
    String? unit;
    final unitMatch = matchUnitAtStart(remaining);
    
    if (unitMatch != null) {
      unit = unitMatch.unit;
      remaining = unitMatch.remaining;
      
      // Step 3: Strip "de" ONLY if it immediately follows the matched unit
      if (remaining.toLowerCase().startsWith('de ')) {
        remaining = remaining.substring(3).trim();
      }
    } else if (quantityMatch != null) {
      // Quantity but no unit → default to "piece"
      unit = 'piece';
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
        
        // Accept if high confidence (≥90%) or only match
        if (testMatches.isNotEmpty) {
          final bestMatch = testMatches.first;
          if (bestMatch.confidence >= 0.90 || testMatches.length == 1) {
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
