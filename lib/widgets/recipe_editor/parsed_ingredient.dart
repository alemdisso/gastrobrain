import '../../models/ingredient.dart';
import '../../models/ingredient_category.dart';
import '../../models/ingredient_match.dart';

class ParsedIngredient {
  double quantity;
  double? quantityMax;
  String? unit;
  String name;
  String originalName;
  IngredientCategory category;
  String? notes;
  String? qtyError;

  List<IngredientMatch> matches;
  IngredientMatch? selectedMatch;

  Ingredient? newIngredientToCreate;
  bool get isNewIngredient => newIngredientToCreate != null;

  bool isManual;

  ParsedIngredient({
    required this.quantity,
    this.quantityMax,
    this.unit,
    required this.name,
    String? originalName,
    required this.category,
    this.notes,
    this.matches = const [],
    this.selectedMatch,
    this.newIngredientToCreate,
    this.qtyError,
    this.isManual = false,
  }) : originalName = originalName ?? name;
}
