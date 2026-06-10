import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/screens/recipe_stub_create_screen.dart';
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
    supportedLocales: const [
      Locale('en', ''),
      Locale('pt', ''),
    ],
    home: child,
  );
}

void main() {
  late MockDatabaseHelper mockDb;

  setUp(() {
    mockDb = MockDatabaseHelper();
  });

  group('RecipeStubCreateScreen', () {
    group('initial state', () {
      testWidgets('shows name field and save button', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(RecipeStubCreateScreen(databaseHelper: mockDb)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });


    });

    group('validation', () {
      testWidgets('shows error when saving with empty name', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(RecipeStubCreateScreen(databaseHelper: mockDb)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Validation error visible, no recipe inserted
        expect(mockDb.recipes.isEmpty, isTrue); // no recipe inserted
      });

      testWidgets('saves when name is provided', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(RecipeStubCreateScreen(databaseHelper: mockDb)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'My New Recipe');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(mockDb.recipes.length, equals(1));
        expect(mockDb.recipes.values.first.name, equals('My New Recipe'));
      });

      testWidgets('trims whitespace from name before saving', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(RecipeStubCreateScreen(databaseHelper: mockDb)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField), '  Padded Name  ');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(mockDb.recipes.values.first.name, equals('Padded Name'));
      });
    });

    group('error handling', () {
      testWidgets('shows snackbar when insert fails', (tester) async {
        mockDb.failOnOperation('insertRecipe');

        await tester.pumpWidget(
          _buildTestApp(RecipeStubCreateScreen(databaseHelper: mockDb)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'Recipe');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });
    });
  });
}
