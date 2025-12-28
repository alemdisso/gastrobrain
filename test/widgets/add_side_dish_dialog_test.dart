// test/widgets/add_side_dish_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/widgets/add_side_dish_dialog.dart';
import 'package:gastrobrain/models/recipe.dart';
import '../test_utils/test_app_wrapper.dart';
import '../test_utils/test_setup.dart';
import '../test_utils/dialog_fixtures.dart';
import '../helpers/dialog_test_helpers.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late Recipe primaryRecipe;
  late Recipe sideRecipe1;
  late Recipe sideRecipe2;
  late Recipe sideRecipe3;
  late List<Recipe> availableRecipes;

  setUp(() {
    mockDbHelper = TestSetup.setupMockDatabase();

    // Create test recipes
    primaryRecipe = DialogFixtures.createPrimaryRecipe();
    sideRecipe1 = DialogFixtures.createSideRecipe();
    sideRecipe2 = DialogFixtures.createTestRecipe(
      id: 'side-recipe-2',
      name: 'Roasted Vegetables',
      difficulty: 2,
    );
    sideRecipe3 = DialogFixtures.createTestRecipe(
      id: 'side-recipe-3',
      name: 'Mashed Potatoes',
      difficulty: 1,
    );

    availableRecipes = [primaryRecipe, sideRecipe1, sideRecipe2, sideRecipe3];
  });

  tearDown(() {
    TestSetup.cleanupMockDatabase(mockDbHelper);
  });

  group('AddSideDishDialog - Multi-Recipe Mode', () {
    testWidgets('dialog opens with available recipes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe], // Exclude primary from selectable list
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog opened
      expect(DialogTestHelpers.findDialogByType<AddSideDishDialog>(),
          findsOneWidget);

      // Verify dialog title (multi-recipe mode shows "Gerenciar Acompanhamentos")
      expect(find.text('Gerenciar Acompanhamentos'), findsOneWidget);

      // Verify primary recipe shown in primary section (as combined text)
      expect(find.textContaining(primaryRecipe.name), findsOneWidget);
      expect(find.textContaining('Prato principal'), findsOneWidget);

      // Verify available side dishes are shown
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);
      expect(find.text(sideRecipe3.name), findsOneWidget);

      // Verify action buttons (multi-recipe mode)
      expect(find.text('Voltar'), findsOneWidget);
      expect(find.text('Salvar Refeição'), findsOneWidget);
    });

    testWidgets('returns selected recipes on save',
        (WidgetTester tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Map>(
        tester,
        dialogBuilder: (context) => AddSideDishDialog(
          availableRecipes: availableRecipes,
          primaryRecipe: primaryRecipe,
          excludeRecipes: [primaryRecipe],
        ),
      );

      // Select a side dish
      await tester.tap(find.text(sideRecipe1.name));
      await tester.pumpAndSettle();

      // Save
      await DialogTestHelpers.tapDialogButton(tester, 'Salvar Refeição');
      await tester.pumpAndSettle();

      // Verify return value
      expect(result.hasValue, isTrue);
      expect(result.value, isNotNull);
      expect(result.value!['primaryRecipe'], equals(primaryRecipe));
      expect(result.value!['additionalRecipes'], isA<List<Recipe>>());
      expect((result.value!['additionalRecipes'] as List<Recipe>).length,
          equals(1));
      expect((result.value!['additionalRecipes'] as List<Recipe>)[0].id,
          equals(sideRecipe1.id));
    });

    testWidgets('excludes already selected recipes from list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    currentSideDishes: [sideRecipe1],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify already selected recipe is NOT in available list
      // sideRecipe1 should appear in "current side dishes" section, not in selectable list
      final sideRecipe1Finders = find.text(sideRecipe1.name);
      expect(sideRecipe1Finders, findsOneWidget); // Shows in current side dishes

      // Verify other recipes are still available
      expect(find.text(sideRecipe2.name), findsOneWidget);
      expect(find.text(sideRecipe3.name), findsOneWidget);
    });

    testWidgets('excludes primary recipe from selectable list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Primary recipe should show in the primary section only (as combined text)
      expect(find.textContaining(primaryRecipe.name), findsOneWidget);
      expect(find.textContaining('Prato principal'), findsOneWidget);

      // Verify side dishes are shown but not primary in the list
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);
    });

    testWidgets('search functionality filters recipes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                    enableSearch: true,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify all recipes initially visible
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);
      expect(find.text(sideRecipe3.name), findsOneWidget);

      // Enter search query
      final searchField = find.byKey(const Key('add_side_dish_search_field'));
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Rice');
      await tester.pumpAndSettle();

      // Verify filtered results (only Rice Pilaf should match)
      expect(find.text(sideRecipe1.name), findsOneWidget); // Rice Pilaf
      expect(find.text(sideRecipe2.name), findsNothing); // Roasted Vegetables
      expect(find.text(sideRecipe3.name), findsNothing); // Mashed Potatoes
    });

    testWidgets('can add multiple side dishes', (WidgetTester tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Map>(
        tester,
        dialogBuilder: (context) => AddSideDishDialog(
          availableRecipes: availableRecipes,
          primaryRecipe: primaryRecipe,
          excludeRecipes: [primaryRecipe],
        ),
      );

      // Add first side dish
      await tester.tap(find.text(sideRecipe1.name));
      await tester.pumpAndSettle();

      // Verify it appears in selected section
      expect(find.text('Acompanhamentos:'), findsOneWidget);

      // Add second side dish
      await tester.tap(find.text(sideRecipe2.name));
      await tester.pumpAndSettle();

      // Save
      await DialogTestHelpers.tapDialogButton(tester, 'Salvar Refeição');
      await tester.pumpAndSettle();

      // Verify both recipes in return value
      expect(result.hasValue, isTrue);
      final additionalRecipes =
          result.value!['additionalRecipes'] as List<Recipe>;
      expect(additionalRecipes.length, equals(2));
      expect(additionalRecipes.any((r) => r.id == sideRecipe1.id), isTrue);
      expect(additionalRecipes.any((r) => r.id == sideRecipe2.id), isTrue);
    });

    testWidgets('can remove selected side dishes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    currentSideDishes: [sideRecipe1],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify side dish is shown
      expect(find.text('Acompanhamentos:'), findsOneWidget);
      expect(find.text(sideRecipe1.name), findsOneWidget);

      // Find and tap remove button
      final removeButton = find.byIcon(Icons.remove_circle_outline);
      expect(removeButton, findsOneWidget);
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      // Verify side dish section is hidden (no side dishes left)
      expect(find.text('Acompanhamentos:'), findsNothing);

      // Verify recipe is back in available list
      expect(find.text(sideRecipe1.name), findsOneWidget);
    });

    testWidgets('returns null when cancelled', (WidgetTester tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Map>(
        tester,
        dialogBuilder: (context) => AddSideDishDialog(
          availableRecipes: availableRecipes,
          primaryRecipe: primaryRecipe,
          excludeRecipes: [primaryRecipe],
        ),
      );

      // Cancel
      await DialogTestHelpers.tapDialogButton(tester, 'Voltar');
      await tester.pumpAndSettle();

      // Verify null return
      DialogTestHelpers.verifyDialogCancelled(result);
      DialogTestHelpers.verifyDialogClosed<AddSideDishDialog>();
    });

    testWidgets('shows current side dishes correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    currentSideDishes: [sideRecipe1, sideRecipe2],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify side dishes section is shown
      expect(find.text('Acompanhamentos:'), findsOneWidget);

      // Verify both side dishes are listed
      final sideDish1Finder = find.descendant(
        of: find.byType(ListTile),
        matching: find.text(sideRecipe1.name),
      );
      final sideDish2Finder = find.descendant(
        of: find.byType(ListTile),
        matching: find.text(sideRecipe2.name),
      );

      expect(sideDish1Finder, findsOneWidget);
      expect(sideDish2Finder, findsOneWidget);

      // Verify each has a remove button
      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(2));
    });

    testWidgets('onSideDishesChanged callback fires correctly',
        (WidgetTester tester) async {
      List<Recipe>? callbackRecipes;

      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                    onSideDishesChanged: (recipes) {
                      callbackRecipes = recipes;
                    },
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Add a side dish
      await tester.tap(find.text(sideRecipe1.name));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(callbackRecipes, isNotNull);
      expect(callbackRecipes!.length, equals(1));
      expect(callbackRecipes![0].id, equals(sideRecipe1.id));

      // Add another side dish
      await tester.tap(find.text(sideRecipe2.name));
      await tester.pumpAndSettle();

      // Verify callback was called again with updated list
      expect(callbackRecipes!.length, equals(2));
      expect(callbackRecipes!.any((r) => r.id == sideRecipe1.id), isTrue);
      expect(callbackRecipes!.any((r) => r.id == sideRecipe2.id), isTrue);
    });
  });

  group('AddSideDishDialog - Single Selection Mode', () {
    testWidgets('dialog opens with correct title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    // No primaryRecipe = single selection mode
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog title (single mode shows "Adicionar Acompanhamento")
      // Note: This text appears twice - once as title and once as section header
      expect(find.text('Adicionar Acompanhamento'), findsNWidgets(2));

      // Verify only Cancel button (no Save button in single mode)
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Salvar Refeição'), findsNothing);
    });

    testWidgets('returns recipe immediately on selection',
        (WidgetTester tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Recipe>(
        tester,
        dialogBuilder: (context) => AddSideDishDialog(
          availableRecipes: availableRecipes,
        ),
      );

      // Tap a recipe
      await tester.tap(find.text(sideRecipe1.name));
      await tester.pumpAndSettle();

      // Verify recipe returned immediately (dialog closed)
      expect(result.hasValue, isTrue);
      expect(result.value, isNotNull);
      expect(result.value!.id, equals(sideRecipe1.id));
      DialogTestHelpers.verifyDialogClosed<AddSideDishDialog>();
    });

    testWidgets('excludes recipes from excludeRecipes parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    excludeRecipes: [sideRecipe1],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify excluded recipe is not shown
      expect(find.text(sideRecipe1.name), findsNothing);

      // Verify other recipes are shown
      expect(find.text(primaryRecipe.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);
      expect(find.text(sideRecipe3.name), findsOneWidget);
    });

    testWidgets('returns null when cancelled', (WidgetTester tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Recipe>(
        tester,
        dialogBuilder: (context) => AddSideDishDialog(
          availableRecipes: availableRecipes,
        ),
      );

      // Cancel
      await DialogTestHelpers.tapDialogButton(tester, 'Cancelar');
      await tester.pumpAndSettle();

      // Verify null return
      DialogTestHelpers.verifyDialogCancelled(result);
      DialogTestHelpers.verifyDialogClosed<AddSideDishDialog>();
    });
  });

  group('AddSideDishDialog - Search Features', () {
    testWidgets('search can be disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                    enableSearch: false,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify search field is not present
      expect(find.byKey(const Key('add_side_dish_search_field')), findsNothing);
    });

    testWidgets('search clears when clear button tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                    enableSearch: true,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byKey(const Key('add_side_dish_search_field'));
      await tester.enterText(searchField, 'Rice');
      await tester.pumpAndSettle();

      // Verify clear button appears
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Verify all recipes are visible again
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);
      expect(find.text(sideRecipe3.name), findsOneWidget);
    });

    testWidgets('shows no results message when search has no matches',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                    enableSearch: true,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter search query with no matches
      final searchField = find.byKey(const Key('add_side_dish_search_field'));
      await tester.enterText(searchField, 'Nonexistent Recipe');
      await tester.pumpAndSettle();

      // Verify no results message with search query
      expect(find.textContaining('Nenhuma receita encontrada'), findsOneWidget);
      expect(find.textContaining('Nonexistent Recipe'), findsAtLeastNWidgets(1));
    });

    testWidgets('custom search hint is used when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                    enableSearch: true,
                    searchHint: 'Custom search hint',
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify custom hint is used
      final searchField = find.byKey(const Key('add_side_dish_search_field'));
      final textField = tester.widget<TextField>(searchField);
      expect(textField.decoration!.hintText, equals('Custom search hint'));
    });
  });

  group('AddSideDishDialog - Edge Cases', () {
    testWidgets('handles empty available recipes list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: [primaryRecipe],
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe], // Only primary, so list is empty
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify empty state message is shown
      expect(find.text('Nenhum acompanhamento disponível'), findsOneWidget);
    });

    testWidgets('recipes are sorted by name', (WidgetTester tester) async {
      // Create recipes with specific names for sorting test
      final recipeA = DialogFixtures.createTestRecipe(
          id: 'a', name: 'Zebra Recipe');
      final recipeB = DialogFixtures.createTestRecipe(
          id: 'b', name: 'Apple Recipe');
      final recipeC = DialogFixtures.createTestRecipe(
          id: 'c', name: 'Mango Recipe');
      final unsortedRecipes = [recipeA, recipeB, recipeC];

      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: unsortedRecipes,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find all recipe ListTiles
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(3));

      // Get the order of recipes in the list
      final listTileWidgets = tester.widgetList<ListTile>(listTiles).toList();

      // Verify they're sorted alphabetically
      expect((listTileWidgets[0].title as Text).data, equals('Apple Recipe'));
      expect((listTileWidgets[1].title as Text).data, equals('Mango Recipe'));
      expect((listTileWidgets[2].title as Text).data, equals('Zebra Recipe'));
    });

    testWidgets('search clears after adding a side dish',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                    enableSearch: true,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byKey(const Key('add_side_dish_search_field'));
      await tester.enterText(searchField, 'Rice');
      await tester.pumpAndSettle();

      // Verify only Rice Pilaf is shown
      expect(find.text(sideRecipe1.name), findsOneWidget);

      // Tap to add it
      await tester.tap(find.text(sideRecipe1.name));
      await tester.pumpAndSettle();

      // Verify search was cleared (all remaining recipes visible)
      expect(find.text(sideRecipe2.name), findsOneWidget);
      expect(find.text(sideRecipe3.name), findsOneWidget);
    });
  });

  group('AddSideDishDialog - Controller Disposal', () {
    testWidgets('safely disposes controller on cancel',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Cancel
      await DialogTestHelpers.tapDialogButton(tester, 'Voltar');
      await tester.pumpAndSettle();

      // Verify dialog closed without errors
      DialogTestHelpers.verifyDialogClosed<AddSideDishDialog>();

      // Pump a few more frames to ensure no disposal errors
      await tester.pump();
      await tester.pump();
    });

    testWidgets('safely disposes controller on back button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Press back button
      await DialogTestHelpers.pressBackButton(tester);
      await tester.pumpAndSettle();

      // Verify dialog closed without errors
      DialogTestHelpers.verifyDialogClosed<AddSideDishDialog>();

      // Pump a few more frames to ensure no disposal errors
      await tester.pump();
      await tester.pump();
    });

    testWidgets('safely disposes controller on save',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddSideDishDialog(
                    availableRecipes: availableRecipes,
                    primaryRecipe: primaryRecipe,
                    excludeRecipes: [primaryRecipe],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Save
      await DialogTestHelpers.tapDialogButton(tester, 'Salvar Refeição');
      await tester.pumpAndSettle();

      // Verify dialog closed without errors
      DialogTestHelpers.verifyDialogClosed<AddSideDishDialog>();

      // Pump a few more frames to ensure no disposal errors
      await tester.pump();
      await tester.pump();
    });

    group('Alternative Dismissal Methods', () {
      testWidgets('tapping outside dialog dismisses and returns null',
          (WidgetTester tester) async {
        final primaryRecipe = DialogFixtures.createPrimaryRecipe();
        final availableRecipes = DialogFixtures.createMultipleRecipes(5);

        final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
          tester,
          dialogBuilder: (context) => AddSideDishDialog(
            availableRecipes: availableRecipes,
            primaryRecipe: primaryRecipe,
            excludeRecipes: [primaryRecipe],
          ),
        );

        // Tap outside dialog to dismiss
        await DialogTestHelpers.tapOutsideDialog(tester);
        await tester.pumpAndSettle();

        // Verify dialog was dismissed and returned null
        DialogTestHelpers.verifyDialogCancelled(result);
        DialogTestHelpers.verifyDialogClosed<AddSideDishDialog>();
      });

      testWidgets('back button dismisses and returns null',
          (WidgetTester tester) async {
        final primaryRecipe = DialogFixtures.createPrimaryRecipe();
        final availableRecipes = DialogFixtures.createMultipleRecipes(5);

        final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
          tester,
          dialogBuilder: (context) => AddSideDishDialog(
            availableRecipes: availableRecipes,
            primaryRecipe: primaryRecipe,
            excludeRecipes: [primaryRecipe],
          ),
        );

        // Press back button to dismiss
        await DialogTestHelpers.pressBackButton(tester);
        await tester.pumpAndSettle();

        // Verify dialog was dismissed and returned null
        DialogTestHelpers.verifyDialogCancelled(result);
        DialogTestHelpers.verifyDialogClosed<AddSideDishDialog>();
      });
    });
  });
}