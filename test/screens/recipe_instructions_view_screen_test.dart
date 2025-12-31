import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/recipe_instructions_view_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

void main() {
  group('RecipeInstructionsViewScreen', () {
    Widget createTestableWidget(Widget child, {Locale locale = const Locale('en', '')}) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('pt', ''),
        ],
        home: child,
      );
    }

    Recipe createTestRecipeWithInstructions({
      String name = 'Test Recipe',
      String? instructions,
    }) {
      return Recipe(
        id: 'test-recipe-1',
        name: name,
        createdAt: DateTime(2024, 1, 1),
        desiredFrequency: FrequencyType.weekly,
        instructions: instructions ?? '',
      );
    }

    testWidgets('displays recipe name in app bar', (WidgetTester tester) async {
      final recipe = createTestRecipeWithInstructions(
        name: 'Pasta Carbonara',
        instructions: 'Cook pasta and make sauce',
      );

      await tester.pumpWidget(
        createTestableWidget(
          RecipeInstructionsViewScreen(recipe: recipe),
        ),
      );

      expect(find.text('Pasta Carbonara'), findsOneWidget);
    });

    testWidgets('displays instructions when available', (WidgetTester tester) async {
      final recipe = createTestRecipeWithInstructions(
        name: 'Pasta Recipe',
        instructions: '1. Boil water\n2. Cook pasta',
      );

      await tester.pumpWidget(
        createTestableWidget(
          RecipeInstructionsViewScreen(recipe: recipe),
        ),
      );

      expect(find.text('1. Boil water\n2. Cook pasta'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows placeholder when instructions are empty', (WidgetTester tester) async {
      final recipe = createTestRecipeWithInstructions(
        name: 'Empty Recipe',
        instructions: '',
      );

      await tester.pumpWidget(
        createTestableWidget(
          RecipeInstructionsViewScreen(recipe: recipe),
        ),
      );

      expect(find.text('No instructions available for this recipe.'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('long instructions are scrollable', (WidgetTester tester) async {
      final longInstructions = List.generate(50, (i) => '${i + 1}. Step ${i + 1}').join('\n');
      final recipe = createTestRecipeWithInstructions(
        name: 'Complex Recipe',
        instructions: longInstructions,
      );

      await tester.pumpWidget(
        createTestableWidget(
          RecipeInstructionsViewScreen(recipe: recipe),
        ),
      );

      // Verify SingleChildScrollView exists for scrollable content
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify the full text content is displayed (all steps from 1 to 50)
      expect(find.text(longInstructions), findsOneWidget);
    });
  });
}