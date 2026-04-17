import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:gastrobrain/screens/ingredient_detail_screen.dart';
import 'package:gastrobrain/screens/recipe_details_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../mocks/mock_database_helper.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: child,
  );
}

Ingredient _makeIngredient({String id = 'ing-1', String name = 'Salt'}) {
  return Ingredient(
    id: id,
    name: name,
    category: IngredientCategory.seasoning,
  );
}

Recipe _makeRecipe({
  String id = 'recipe-1',
  String name = 'Test Recipe',
  int difficulty = 2,
  int rating = 3,
}) {
  return Recipe(
    id: id,
    name: name,
    createdAt: DateTime(2024, 1, 1),
    difficulty: difficulty,
    rating: rating,
    notes: '',
  );
}

RecipeIngredient _makeRecipeIngredient({
  required String recipeId,
  required String ingredientId,
  double quantity = 1.5,
  String id = 'ri-1',
}) {
  return RecipeIngredient(
    id: id,
    recipeId: recipeId,
    ingredientId: ingredientId,
    quantity: quantity,
  );
}

void main() {
  late MockDatabaseHelper mockDb;
  late Ingredient ingredient;

  setUp(() {
    mockDb = MockDatabaseHelper();
    ingredient = _makeIngredient();
  });

  tearDown(() {
    mockDb.resetAllData();
  });

  group('IngredientDetailScreen — Used In tab', () {
    testWidgets('recipe card shows name, category, difficulty, rating, quantity',
        (tester) async {
      final recipe = _makeRecipe(difficulty: 3, rating: 4);
      mockDb.recipes[recipe.id!] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id!, ingredientId: ingredient.id, quantity: 2.5),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Recipe'), findsOneWidget);
      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.text('★★★☆☆'), findsOneWidget); // difficulty 3
      expect(find.text('★★★★☆'), findsOneWidget); // rating 4
      expect(find.textContaining('2.5'), findsOneWidget); // quantity
    });

    testWidgets('tapping recipe card navigates to RecipeDetailsScreen',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id!] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id!, ingredientId: ingredient.id),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Recipe'));
      await tester.pump(); // start navigation
      await tester.pump(); // settle navigation frame

      expect(find.byType(RecipeDetailsScreen), findsOneWidget);
    });

    testWidgets('shows empty state when no recipes use the ingredient',
        (tester) async {
      // No recipes or recipe ingredients added → empty result

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(
            "This ingredient hasn't been added to any recipes yet."),
        findsOneWidget,
      );
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('no Incomplete chip when recipe has 3 or more ingredients',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id!] = recipe;
      // Add 3 ingredients → ingredient_count = 3 → not incomplete
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            id: 'ri-1', recipeId: recipe.id!, ingredientId: ingredient.id),
      );
      await mockDb.addIngredientToRecipe(
        RecipeIngredient(
            id: 'ri-2',
            recipeId: recipe.id!,
            ingredientId: 'other-ing',
            quantity: 1.0),
      );
      await mockDb.addIngredientToRecipe(
        RecipeIngredient(
            id: 'ri-3',
            recipeId: recipe.id!,
            ingredientId: 'another-ing',
            quantity: 2.0),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Incomplete'), findsNothing);
    });

    testWidgets('shows Incomplete chip when recipe has fewer than 3 ingredients',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id!] = recipe;
      // Only 1 ingredient → ingredient_count = 1 → incomplete
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id!, ingredientId: ingredient.id),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Incomplete'), findsOneWidget);
    });

    testWidgets('renders recipe list when recipes use the ingredient',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id!] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id!, ingredientId: ingredient.id),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Recipe'), findsOneWidget);
    });
  });
}
