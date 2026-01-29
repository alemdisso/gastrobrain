import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_category.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/recipe_card.dart';
import 'package:gastrobrain/screens/recipe_details_screen.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

void main() {
  group('RecipeCard Layout Tests', () {
    late Recipe testRecipe;
    late MockRecipeProvider mockRecipeProvider;

    Widget createTestableWidget(Widget child,
        {Locale locale = const Locale('en', '')}) {
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
        home: ChangeNotifierProvider<RecipeProvider>.value(
          value: mockRecipeProvider,
          child: Scaffold(body: child),
        ),
      );
    }

    setUp(() {
      testRecipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe with a Very Long Name That Might Cause Issues',
        category: RecipeCategory.mainDishes,
        desiredFrequency: FrequencyType.weekly,
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 4,
        createdAt: DateTime.now(),
      );
      mockRecipeProvider = MockRecipeProvider();
    });

    testWidgets('recipe card displays localized category - English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: DateTime(2023, 12, 25),
          ),
        ),
      );

      // Should display English category name
      expect(find.text('Main dishes'), findsOneWidget);
    });

    testWidgets('recipe card displays localized category - Portuguese',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: DateTime(2023, 12, 25),
          ),
          locale: const Locale('pt', ''),
        ),
      );

      // Should display Portuguese category name
      expect(find.text('Pratos principais'), findsOneWidget);
    });

    testWidgets('recipe card displays recipe name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: DateTime(2023, 12, 25),
          ),
        ),
      );

      // Should display recipe name
      expect(
          find.text('Test Recipe with a Very Long Name That Might Cause Issues'),
          findsOneWidget);
    });

    testWidgets('recipe card displays rating stars and total time',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: DateTime(2023, 12, 25),
          ),
        ),
      );

      // Should display total time (30 + 45 = 75 min)
      expect(find.text('75 min'), findsOneWidget);

      // Should display 4 filled stars and 1 empty star (rating = 4)
      expect(find.byIcon(Icons.star), findsNWidgets(4));
      expect(find.byIcon(Icons.star_border), findsNWidgets(1));

      // Should display timer icon (difficulty = 3, which is < 4)
      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('tapping recipe card navigates to RecipeDetailsScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: DateTime(2023, 12, 25),
          ),
        ),
      );

      // Find and tap the card
      final cardFinder = find.byType(InkWell);
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Should navigate to RecipeDetailsScreen
      expect(find.byType(RecipeDetailsScreen), findsOneWidget);
    });

    testWidgets('recipe card with InkWell has ripple effect',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: DateTime(2023, 12, 25),
          ),
        ),
      );

      // Verify InkWell exists with border radius
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, equals(BorderRadius.circular(12)));
    });
  });
}

/// Mock RecipeProvider for testing
class MockRecipeProvider extends ChangeNotifier implements RecipeProvider {
  @override
  List<Recipe> get recipes => [];

  @override
  bool get isLoading => false;

  @override
  GastrobrainException? get error => null;

  @override
  bool get hasError => false;

  @override
  bool get hasData => false;

  @override
  String? get currentSortBy => 'name';

  @override
  String? get currentSortOrder => 'asc';

  @override
  Map<String, dynamic> get filters => {};

  @override
  bool get hasActiveFilters => false;

  @override
  int get totalRecipeCount => 0;

  @override
  int get filteredRecipeCount => 0;

  @override
  Future<void> loadRecipes({bool forceRefresh = false}) async {}

  @override
  Future<bool> createRecipe(Recipe recipe) async => true;

  @override
  Future<bool> updateRecipe(Recipe recipe) async => true;

  @override
  Future<bool> deleteRecipe(String id) async => true;

  @override
  Future<void> setSorting({String? sortBy, String? sortOrder}) async {}

  @override
  Future<void> setFilters(Map<String, dynamic> filters) async {}

  @override
  Future<void> clearFilters() async {}

  @override
  void clearError() {}

  @override
  Future<void> refreshMealStats() async {}

  @override
  Future<void> refresh() async {}

  @override
  int getMealCount(String recipeId) => 0;

  @override
  DateTime? getLastCookedDate(String recipeId) => null;

  @override
  Future<Recipe?> getRecipe(String id) async => null;

  @override
  void updateMealStats(String recipeId, int mealCount, DateTime? lastCooked) {}
}
