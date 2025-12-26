import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/edit_recipe_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

void main() {
  group('EditRecipeScreen', () {
    late Recipe testRecipe;

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

    setUp(() {
      testRecipe = Recipe(
        id: 'test_id',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 4,
        instructions: '',
      );
    });

    testWidgets('loads recipe frequency correctly - English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe)),
      );

      // Find dropdown
      final dropdownFinder =
          find.byType(DropdownButtonFormField<FrequencyType>);
      expect(dropdownFinder, findsOneWidget);

      // Find the dropdown button's text
      final dropdownButton =
          find.byType(DropdownButtonFormField<FrequencyType>);
      expect(dropdownButton, findsOneWidget);

      // Verify the selected value text is visible within the button
      final buttonText = find.descendant(
        of: dropdownButton,
        matching: find.text('Weekly'),
      );
      expect(buttonText, findsOneWidget);
    });

    testWidgets('loads recipe frequency correctly - Portuguese',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe), locale: const Locale('pt', '')),
      );

      // Find dropdown
      final dropdownFinder =
          find.byType(DropdownButtonFormField<FrequencyType>);
      expect(dropdownFinder, findsOneWidget);

      // Find the dropdown button's text
      final dropdownButton =
          find.byType(DropdownButtonFormField<FrequencyType>);
      expect(dropdownButton, findsOneWidget);

      // Verify the selected value text is visible within the button
      final buttonText = find.descendant(
        of: dropdownButton,
        matching: find.text('Semanal'),
      );
      expect(buttonText, findsOneWidget);
    });

    testWidgets('shows all frequency options - English', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe)),
      );

      // Find and tap the dropdown button to open the menu
      await tester.tap(find.byType(DropdownButtonFormField<FrequencyType>));
      await tester.pumpAndSettle();

      // Verify each frequency appears in the menu with English text
      final expectedTexts = ['Daily', 'Weekly', 'Biweekly', 'Monthly', 'Bimonthly', 'Rarely'];
      for (final text in expectedTexts) {
        final menuItemFinder = find
            .ancestor(
              of: find.text(text),
              matching: find.byType(DropdownMenuItem<FrequencyType>),
            )
            .last; // Use last to get the one in the overlay

        expect(menuItemFinder, findsOneWidget,
            reason: 'Should find menu item for $text');
      }
    });

    testWidgets('shows all frequency options - Portuguese', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe), locale: const Locale('pt', '')),
      );

      // Find and tap the dropdown button to open the menu
      await tester.tap(find.byType(DropdownButtonFormField<FrequencyType>));
      await tester.pumpAndSettle();

      // Verify each frequency appears in the menu with Portuguese text
      final expectedTexts = ['Diário', 'Semanal', 'Quinzenal', 'Mensal', 'Bimestral', 'Raramente'];
      for (final text in expectedTexts) {
        final menuItemFinder = find
            .ancestor(
              of: find.text(text),
              matching: find.byType(DropdownMenuItem<FrequencyType>),
            )
            .last; // Use last to get the one in the overlay

        expect(menuItemFinder, findsOneWidget,
            reason: 'Should find menu item for $text');
      }
    });

    testWidgets('can change frequency - English', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe)),
      );

      // Open dropdown and select monthly
      await tester.tap(find.byType(DropdownButtonFormField<FrequencyType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly').last);
      await tester.pumpAndSettle();

      // Find the dropdown button
      final dropdownButton =
          find.byType(DropdownButtonFormField<FrequencyType>);

      // Verify the selected value text is visible within the button
      final monthlyText = find.descendant(
        of: dropdownButton,
        matching: find.text('Monthly'),
      );
      final weeklyText = find.descendant(
        of: dropdownButton,
        matching: find.text('Weekly'),
      );

      expect(monthlyText, findsOneWidget);
      expect(weeklyText, findsNothing);
    });

    testWidgets('can change frequency - Portuguese', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe), locale: const Locale('pt', '')),
      );

      // Open dropdown and select monthly
      await tester.tap(find.byType(DropdownButtonFormField<FrequencyType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mensal').last);
      await tester.pumpAndSettle();

      // Find the dropdown button
      final dropdownButton =
          find.byType(DropdownButtonFormField<FrequencyType>);

      // Verify the selected value text is visible within the button
      final monthlyText = find.descendant(
        of: dropdownButton,
        matching: find.text('Mensal'),
      );
      final weeklyText = find.descendant(
        of: dropdownButton,
        matching: find.text('Semanal'),
      );

      expect(monthlyText, findsOneWidget);
      expect(weeklyText, findsNothing);
    });

    testWidgets('preserves frequency when other fields change - English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe)),
      );

      // Change recipe name
      await tester.enterText(
          find.byType(TextFormField).first, 'Updated Recipe');
      await tester.pump();

      // Verify frequency is still weekly
      expect(find.text('Weekly'), findsOneWidget);
    });

    testWidgets('preserves frequency when other fields change - Portuguese',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe), locale: const Locale('pt', '')),
      );

      // Change recipe name
      await tester.enterText(
          find.byType(TextFormField).first, 'Updated Recipe');
      await tester.pump();

      // Verify frequency is still weekly
      expect(find.text('Semanal'), findsOneWidget);
    });

    testWidgets('instructions field initializes with recipe instructions - English',
        (WidgetTester tester) async {
      final recipeWithInstructions = Recipe(
        id: 'test_id',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 4,
        instructions: 'Preheat oven to 180°C\nBake for 30 minutes',
      );

      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: recipeWithInstructions)),
      );

      final instructionsField = find.byKey(const Key('edit_recipe_instructions_field'));
      expect(instructionsField, findsOneWidget);

      // Verify the field contains the instructions text
      expect(find.text('Preheat oven to 180°C\nBake for 30 minutes'), findsOneWidget);
    });

    testWidgets('instructions field initializes with recipe instructions - Portuguese',
        (WidgetTester tester) async {
      final recipeWithInstructions = Recipe(
        id: 'test_id',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 4,
        instructions: 'Preaqueça o forno a 180°C\nAsse por 30 minutos',
      );

      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: recipeWithInstructions), locale: const Locale('pt', '')),
      );

      final instructionsField = find.byKey(const Key('edit_recipe_instructions_field'));
      expect(instructionsField, findsOneWidget);

      // Verify the field contains the instructions text
      expect(find.text('Preaqueça o forno a 180°C\nAsse por 30 minutos'), findsOneWidget);
    });

    testWidgets('instructions field accepts multi-line input - English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe)),
      );

      final instructionsField = find.byKey(const Key('edit_recipe_instructions_field'));
      expect(instructionsField, findsOneWidget);

      // Enter multi-line text
      await tester.enterText(
        instructionsField,
        'Line 1\nLine 2\nLine 3',
      );
      await tester.pump();

      // Verify the multi-line text is displayed
      expect(find.text('Line 1\nLine 2\nLine 3'), findsOneWidget);
    });

    testWidgets('instructions field accepts multi-line input - Portuguese',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe), locale: const Locale('pt', '')),
      );

      final instructionsField = find.byKey(const Key('edit_recipe_instructions_field'));
      expect(instructionsField, findsOneWidget);

      // Enter multi-line text
      await tester.enterText(
        instructionsField,
        'Linha 1\nLinha 2\nLinha 3',
      );
      await tester.pump();

      // Verify the multi-line text is displayed
      expect(find.text('Linha 1\nLinha 2\nLinha 3'), findsOneWidget);
    });

    testWidgets('instructions field handles empty input - English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe)),
      );

      final instructionsField = find.byKey(const Key('edit_recipe_instructions_field'));
      expect(instructionsField, findsOneWidget);

      // Enter and then clear text
      await tester.enterText(instructionsField, 'Some instructions');
      await tester.pump();
      expect(find.text('Some instructions'), findsOneWidget);

      await tester.enterText(instructionsField, '');
      await tester.pump();

      // Field should be empty
      expect(find.text('Some instructions'), findsNothing);
    });

    testWidgets('instructions field handles empty input - Portuguese',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe), locale: const Locale('pt', '')),
      );

      final instructionsField = find.byKey(const Key('edit_recipe_instructions_field'));
      expect(instructionsField, findsOneWidget);

      // Enter and then clear text
      await tester.enterText(instructionsField, 'Algumas instruções');
      await tester.pump();
      expect(find.text('Algumas instruções'), findsOneWidget);

      await tester.enterText(instructionsField, '');
      await tester.pump();

      // Field should be empty
      expect(find.text('Algumas instruções'), findsNothing);
    });

    testWidgets('instructions field is visible and accessible - English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe)),
      );

      final instructionsField = find.byKey(const Key('edit_recipe_instructions_field'));
      expect(instructionsField, findsOneWidget);

      // Verify the field is a TextFormField
      expect(tester.widget(instructionsField), isA<TextFormField>());
    });

    testWidgets('instructions field is visible and accessible - Portuguese',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(EditRecipeScreen(recipe: testRecipe), locale: const Locale('pt', '')),
      );

      final instructionsField = find.byKey(const Key('edit_recipe_instructions_field'));
      expect(instructionsField, findsOneWidget);

      // Verify the field is a TextFormField
      expect(tester.widget(instructionsField), isA<TextFormField>());
    });
  });
}
