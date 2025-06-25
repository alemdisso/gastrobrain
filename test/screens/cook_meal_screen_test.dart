// test/screens/cook_meal_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/cook_meal_screen.dart';
import '../test_utils/test_app_wrapper.dart';

void main() {
  late Recipe testRecipe;
  late Recipe sideRecipe;

  setUp(() {
    testRecipe = Recipe(
      id: 'test-recipe-1',
      name: 'Grilled Chicken',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: 3,
      prepTimeMinutes: 15,
      cookTimeMinutes: 25,
    );

    sideRecipe = Recipe(
      id: 'side-recipe-1',
      name: 'Rice Pilaf',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: 2,
      prepTimeMinutes: 5,
      cookTimeMinutes: 20,
    );
  });

  group('CookMealScreen Widget Tests', () {
    testWidgets('renders with correct recipe name in title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Verify app bar title shows recipe name (Portuguese)
      expect(find.text('Cozinhar ${testRecipe.name}'), findsOneWidget);

      // Verify main content text (Portuguese)
      expect(find.text('Registrar detalhes de preparo para ${testRecipe.name}'),
          findsOneWidget);

      // Verify the "Registrar Detalhes da Refeição" button exists
      expect(find.text('Registrar Detalhes da Refeição'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('tapping button shows meal recording dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Tap the "Registrar Detalhes da Refeição" button
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Verify that the MealRecordingDialog appeared
      // We can check for the dialog title which should show the recipe name
      expect(find.text('Cozinhar ${testRecipe.name}'),
          findsNWidgets(2)); // One in app bar, one in dialog

      // Or check for dialog-specific elements (Portuguese)
      expect(find.text('Número de Porções'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('handles dialog cancellation correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Tap the button to open dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Cancel the dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Should return to the main screen (dialog closed)
      expect(find.text('Registrar detalhes de preparo para ${testRecipe.name}'),
          findsOneWidget);
      expect(find.text('Registrar Detalhes da Refeição'), findsOneWidget);

      // Dialog should be gone
      expect(find.text('Número de Porções'), findsNothing);
    });

    testWidgets('renders with additional recipes when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(
          recipe: testRecipe,
          additionalRecipes: [sideRecipe],
        )),
      );

      await tester.pumpAndSettle();

      // Should still show the primary recipe name in title
      expect(find.text('Cozinhar ${testRecipe.name}'), findsOneWidget);

      // Should show the same UI regardless of additional recipes
      expect(find.text('Registrar detalhes de preparo para ${testRecipe.name}'),
          findsOneWidget);
      expect(find.text('Registrar Detalhes da Refeição'), findsOneWidget);
    });

    testWidgets('passes additional recipes to dialog when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(
          recipe: testRecipe,
          additionalRecipes: [sideRecipe],
        )),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Should show both primary and additional recipes in the dialog
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.text(sideRecipe.name), findsOneWidget);

      // Should show proper indicators for main vs side dish (Portuguese)
      expect(find.text('Prato principal'), findsOneWidget);
      expect(find.text('Acompanhamento'), findsOneWidget);
    });
    testWidgets('handles empty additional recipes list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(
          recipe: testRecipe,
          additionalRecipes: const [],
        )),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Should only show primary recipe
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.text('Prato principal'), findsOneWidget);

      // Should not show any side dishes
      expect(find.text('Acompanhamento'), findsNothing);

      // Should still show "Adicionar Receita" button for adding sides
      expect(find.text('Adicionar Receita'), findsOneWidget);
    });

    testWidgets('shows correct app bar title with long recipe names',
        (WidgetTester tester) async {
      final longNameRecipe = Recipe(
        id: 'long-name-recipe',
        name: 'Super Long Recipe Name That Might Cause Layout Issues',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: longNameRecipe)),
      );

      await tester.pumpAndSettle();

      // Should handle long names gracefully in app bar
      expect(find.text('Cozinhar ${longNameRecipe.name}'), findsOneWidget);

      // Should also show in main content
      expect(find.text('Registrar detalhes de preparo para ${longNameRecipe.name}'),
          findsOneWidget);
    });
  });
}
