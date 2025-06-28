import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_category.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/recipe_card.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

void main() {
  group('RecipeCard Rating Display Tests', () {
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
        home: Scaffold(body: child),
      );
    }

    testWidgets('displays 5 stars for 0-star recipe (all unfilled)',
        (WidgetTester tester) async {
      final zeroRatedRecipe = Recipe(
        id: 'test-recipe-0',
        name: 'Test Recipe',
        category: RecipeCategory.mainDishes,
        desiredFrequency: FrequencyType.weekly,
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 0,
        createdAt: DateTime.now(),
      );
      
      await tester.pumpWidget(
        createTestableWidget(
          SizedBox(
            width: 350,
            child: RecipeCard(
              recipe: zeroRatedRecipe,
              onEdit: () {},
              onDelete: () {},
              onCooked: () {},
              mealCount: 0,
              lastCooked: null,
            ),
          ),
        ),
      );

      // Should find exactly 5 star icons
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('displays 5 stars for 3-star recipe (3 filled, 2 unfilled)',
        (WidgetTester tester) async {
      final threeStarRecipe = Recipe(
        id: 'test-recipe-3',
        name: 'Test Recipe',
        category: RecipeCategory.mainDishes,
        desiredFrequency: FrequencyType.weekly,
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 3,
        createdAt: DateTime.now(),
      );
      
      await tester.pumpWidget(
        createTestableWidget(
          SizedBox(
            width: 350,
            child: RecipeCard(
              recipe: threeStarRecipe,
              onEdit: () {},
              onDelete: () {},
              onCooked: () {},
              mealCount: 5,
              lastCooked: DateTime(2023, 12, 25),
            ),
          ),
        ),
      );

      // Should find exactly 3 filled stars and 2 unfilled stars
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('displays 5 stars for 5-star recipe (all filled)',
        (WidgetTester tester) async {
      final fiveStarRecipe = Recipe(
        id: 'test-recipe-5',
        name: 'Test Recipe',
        category: RecipeCategory.mainDishes,
        desiredFrequency: FrequencyType.weekly,
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 5,
        createdAt: DateTime.now(),
      );
      
      await tester.pumpWidget(
        createTestableWidget(
          SizedBox(
            width: 350,
            child: RecipeCard(
              recipe: fiveStarRecipe,
              onEdit: () {},
              onDelete: () {},
              onCooked: () {},
              mealCount: 10,
              lastCooked: DateTime(2023, 12, 25),
            ),
          ),
        ),
      );

      // Should find exactly 5 filled stars
      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('displays 5 stars for 1-star recipe (1 filled, 4 unfilled)',
        (WidgetTester tester) async {
      final oneStarRecipe = Recipe(
        id: 'test-recipe-1',
        name: 'Test Recipe',
        category: RecipeCategory.mainDishes,
        desiredFrequency: FrequencyType.weekly,
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 1,
        createdAt: DateTime.now(),
      );
      
      await tester.pumpWidget(
        createTestableWidget(
          SizedBox(
            width: 350,
            child: RecipeCard(
              recipe: oneStarRecipe,
              onEdit: () {},
              onDelete: () {},
              onCooked: () {},
              mealCount: 1,
              lastCooked: DateTime(2023, 12, 25),
            ),
          ),
        ),
      );

      // Should find exactly 1 filled star and 4 unfilled stars
      expect(find.byIcon(Icons.star), findsNWidgets(1));
      expect(find.byIcon(Icons.star_border), findsNWidgets(4));
    });

    testWidgets('displays 5 stars for 4-star recipe (4 filled, 1 unfilled)',
        (WidgetTester tester) async {
      final fourStarRecipe = Recipe(
        id: 'test-recipe-4',
        name: 'Test Recipe',
        category: RecipeCategory.mainDishes,
        desiredFrequency: FrequencyType.weekly,
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 4,
        createdAt: DateTime.now(),
      );
      
      await tester.pumpWidget(
        createTestableWidget(
          SizedBox(
            width: 350,
            child: RecipeCard(
              recipe: fourStarRecipe,
              onEdit: () {},
              onDelete: () {},
              onCooked: () {},
              mealCount: 8,
              lastCooked: DateTime(2023, 12, 25),
            ),
          ),
        ),
      );

      // Should find exactly 4 filled stars and 1 unfilled star
      expect(find.byIcon(Icons.star), findsNWidgets(4));
      expect(find.byIcon(Icons.star_border), findsNWidgets(1));
    });
  });
}