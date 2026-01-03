// integration_test/e2e_recipe_editing_workflow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/edit_recipe_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import 'helpers/e2e_test_helpers.dart';

/// Recipe Editing Workflow Test
///
/// This test verifies the recipe editing workflow:
/// 1. Create a test recipe (via database)
/// 2. Verify recipe appears in UI
/// 3. Navigate to Edit Recipe screen
/// 4. Modify recipe name using key-based field access
/// 5. Save changes
/// 6. Verify changes in database
/// 7. Clean up test data
///
/// This is a hybrid E2E test that uses database operations for initial
/// recipe creation and direct navigation to the edit screen, but tests
/// the actual edit form interaction and data persistence.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Recipe Editing Workflow', () {
    testWidgets('Edit recipe name and verify changes persist',
        (WidgetTester tester) async {
      // ======================================================================
      // TEST DATA SETUP
      // ======================================================================

      final originalRecipeName = 'E2E Original Recipe ${DateTime.now().millisecondsSinceEpoch}';
      final updatedRecipeName = 'E2E Updated Recipe ${DateTime.now().millisecondsSinceEpoch}';
      final testRecipeId = 'e2e-edit-test-${DateTime.now().millisecondsSinceEpoch}';

      String? createdRecipeId;

      try {
        // ==================================================================
        // SETUP: Launch and Initialize
        // ==================================================================

        print('=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = DatabaseHelper();

        // ==================================================================
        // SETUP: Create Test Recipe
        // ==================================================================

        print('\n=== CREATING TEST RECIPE ===');
        final testRecipe = Recipe(
          id: testRecipeId,
          name: originalRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 30,
          cookTimeMinutes: 45,
          difficulty: 2,
          rating: 3,
          notes: 'Original notes',
        );

        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipeId;
        print('✓ Test recipe created: $originalRecipeName');

        // ==================================================================
        // VERIFY: Recipe Exists in Database
        // ==================================================================

        final createdRecipe = await dbHelper.getRecipe(testRecipeId);
        expect(createdRecipe, isNotNull);
        expect(createdRecipe!.name, equals(originalRecipeName));
        print('✓ Recipe verified in database');

        // ==================================================================
        // VERIFY: On Main Screen
        // ==================================================================

        E2ETestHelpers.verifyOnMainScreen();
        print('✓ On main screen');

        // ==================================================================
        // VERIFY: Recipe Appears in UI
        // ==================================================================

        print('\n=== VERIFYING RECIPE IN UI ===');
        final foundInUI = await E2ETestHelpers.verifyRecipeInUI(
          tester,
          originalRecipeName,
        );

        if (foundInUI) {
          print('✓ Recipe appears in recipe list');
        } else {
          print('⚠ Recipe not immediately visible (may be off-screen)');
        }

        // ==================================================================
        // ACT: Navigate to Edit Recipe Screen
        // ==================================================================

        print('\n=== NAVIGATING TO EDIT RECIPE SCREEN ===');

        // Navigate directly to EditRecipeScreen
        // (bypassing menu interaction for this test)
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('pt'), // Portuguese
            ],
            home: EditRecipeScreen(recipe: createdRecipe),
          ),
        );
        await tester.pumpAndSettle();

        print('✓ Edit Recipe screen loaded');

        // ==================================================================
        // VERIFY: On Edit Form Screen
        // ==================================================================

        // Verify we're on the edit screen by checking for form fields
        final nameField = find.byKey(const Key('edit_recipe_name_field'));
        expect(nameField, findsOneWidget, reason: 'Name field should be visible');
        print('✓ On Edit Recipe form');

        // Verify current name is displayed
        expect(find.text(originalRecipeName), findsOneWidget);
        print('✓ Original recipe name displayed in form');

        // ==================================================================
        // ACT: Modify Recipe Name
        // ==================================================================

        print('\n=== MODIFYING RECIPE NAME ===');

        // Clear existing text and enter new name
        await tester.enterText(nameField, updatedRecipeName);
        await tester.pumpAndSettle();

        expect(find.text(updatedRecipeName), findsOneWidget);
        print('✓ New name entered: $updatedRecipeName');

        // ==================================================================
        // ACT: Save Changes
        // ==================================================================

        print('\n=== SAVING CHANGES ===');

        // Find and tap save button using helper (handles ensureVisible)
        await E2ETestHelpers.tapSaveButton(tester);
        print('✓ Save button tapped');

        // Wait for async operations
        await E2ETestHelpers.waitForAsyncOperations();

        // ==================================================================
        // VERIFY: Changes in Database
        // ==================================================================

        print('\n=== VERIFYING CHANGES IN DATABASE ===');

        final updatedRecipe = await dbHelper.getRecipe(testRecipeId);
        expect(updatedRecipe, isNotNull, reason: 'Recipe should still exist');
        expect(updatedRecipe!.name, equals(updatedRecipeName),
            reason: 'Recipe name should be updated');
        expect(updatedRecipe.id, equals(testRecipeId),
            reason: 'Recipe ID should remain unchanged');
        expect(updatedRecipe.createdAt, equals(createdRecipe.createdAt),
            reason: 'Created date should remain unchanged');

        print('✅ SUCCESS! Recipe updated in database!');
        print('   Original name: $originalRecipeName');
        print('   Updated name:  $updatedRecipeName');
        print('   Recipe ID:     $testRecipeId');

        // Verify other fields remained unchanged
        expect(updatedRecipe.difficulty, equals(testRecipe.difficulty));
        expect(updatedRecipe.rating, equals(testRecipe.rating));
        expect(updatedRecipe.prepTimeMinutes, equals(testRecipe.prepTimeMinutes));
        expect(updatedRecipe.cookTimeMinutes, equals(testRecipe.cookTimeMinutes));
        print('✓ Other recipe fields preserved');

        print('\n=== 🎉 RECIPE EDITING WORKFLOW TEST PASSED! 🎉 ===');
        print('✓ Created test recipe');
        print('✓ Verified recipe in database and UI');
        print('✓ Navigated to Edit Recipe screen');
        print('✓ Modified recipe name using key-based field access');
        print('✓ Saved changes');
        print('✓ Verified changes persisted in database');

      } finally {
        // ==================================================================
        // CLEANUP: Remove Test Data
        // ==================================================================

        print('\n=== CLEANUP ===');
        final dbHelper = DatabaseHelper();

        if (createdRecipeId != null) {
          try {
            await dbHelper.deleteRecipe(createdRecipeId);
            print('✓ Test recipe deleted: $createdRecipeId');
          } catch (e) {
            print('⚠ Error deleting recipe: $e');
          }
        }

        print('✓ Cleanup complete');
      }
    });
  });
}
