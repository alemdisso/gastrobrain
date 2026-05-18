import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import 'package:gastrobrain/models/meal_plan_summary.dart';
import 'package:gastrobrain/widgets/weekly_summary_widget.dart';

void main() {
  // Reference date fixed for all tests: a Wednesday
  final referenceDate = DateTime(2026, 5, 14); // Wednesday

  Widget buildWidget(MealPlanSummary summary) {
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
      home: Scaffold(
        body: WeeklySummaryWidget(
          summaryData: summary,
          onRetry: () {},
          referenceDate: referenceDate,
        ),
      ),
    );
  }

  MealPlanSummary summaryWithMeals(List<PlannedMealInfo> meals) {
    return MealPlanSummary(
      totalPlanned: meals.length,
      percentage: meals.length / 14.0,
      proteinsByDay: const {},
      plannedMeals: meals,
      uniqueRecipes: 0,
      repeatedRecipes: const [],
    );
  }

  group('WeeklySummaryWidget — temporal meal grouping', () {
    testWidgets('shows Cooked section for past meals marked as cooked',
        (tester) async {
      final summary = summaryWithMeals([
        PlannedMealInfo(
          day: 'Monday',
          date: DateTime(2026, 5, 11), // past
          mealType: 'dinner',
          recipes: const ['Pasta'],
          isCooked: true,
        ),
      ]);

      await tester.pumpWidget(buildWidget(summary));
      await tester.pumpAndSettle();

      expect(find.text('Cooked'), findsOneWidget);
      expect(find.text('Mon Dinner'), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);
    });

    testWidgets('shows Unconfirmed section for past meals not marked as cooked',
        (tester) async {
      final summary = summaryWithMeals([
        PlannedMealInfo(
          day: 'Tuesday',
          date: DateTime(2026, 5, 12), // past
          mealType: 'lunch',
          recipes: const ['Soup'],
          isCooked: false,
        ),
      ]);

      await tester.pumpWidget(buildWidget(summary));
      await tester.pumpAndSettle();

      expect(find.text('Unconfirmed'), findsOneWidget);
      expect(find.text('Tue Lunch'), findsOneWidget);
      expect(find.text('Soup'), findsOneWidget);
    });

    testWidgets('shows Upcoming section for today and future meals',
        (tester) async {
      final summary = summaryWithMeals([
        // today
        PlannedMealInfo(
          day: 'Wednesday',
          date: DateTime(2026, 5, 14),
          mealType: 'lunch',
          recipes: const ['Salad'],
          isCooked: false,
        ),
        // future
        PlannedMealInfo(
          day: 'Thursday',
          date: DateTime(2026, 5, 15),
          mealType: 'dinner',
          recipes: const ['Steak'],
          isCooked: false,
        ),
      ]);

      await tester.pumpWidget(buildWidget(summary));
      await tester.pumpAndSettle();

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Wed Lunch'), findsOneWidget);
      expect(find.text('Thu Dinner'), findsOneWidget);
      expect(find.text('Unconfirmed'), findsNothing);
      expect(find.text('Cooked'), findsNothing);
    });

    testWidgets('shows all three sections when mixed meals are present',
        (tester) async {
      final summary = summaryWithMeals([
        PlannedMealInfo(
          day: 'Monday',
          date: DateTime(2026, 5, 11),
          mealType: 'dinner',
          recipes: const ['Pasta'],
          isCooked: true,
        ),
        PlannedMealInfo(
          day: 'Tuesday',
          date: DateTime(2026, 5, 12),
          mealType: 'lunch',
          recipes: const ['Soup'],
          isCooked: false,
        ),
        PlannedMealInfo(
          day: 'Thursday',
          date: DateTime(2026, 5, 15),
          mealType: 'dinner',
          recipes: const ['Steak'],
          isCooked: false,
        ),
      ]);

      await tester.pumpWidget(buildWidget(summary));
      await tester.pumpAndSettle();

      expect(find.text('Cooked'), findsOneWidget);
      expect(find.text('Unconfirmed'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
    });

    testWidgets('shows no Unconfirmed section when all past meals are cooked',
        (tester) async {
      final summary = summaryWithMeals([
        PlannedMealInfo(
          day: 'Monday',
          date: DateTime(2026, 5, 11),
          mealType: 'dinner',
          recipes: const ['Pasta'],
          isCooked: true,
        ),
        PlannedMealInfo(
          day: 'Tuesday',
          date: DateTime(2026, 5, 12),
          mealType: 'lunch',
          recipes: const ['Rice'],
          isCooked: true,
        ),
      ]);

      await tester.pumpWidget(buildWidget(summary));
      await tester.pumpAndSettle();

      expect(find.text('Cooked'), findsOneWidget);
      expect(find.text('Unconfirmed'), findsNothing);
      expect(find.text('Upcoming'), findsNothing);
    });

    testWidgets('shows empty state when no meals are planned', (tester) async {
      final summary = summaryWithMeals([]);

      await tester.pumpWidget(buildWidget(summary));
      await tester.pumpAndSettle();

      expect(find.text('No meals planned yet'), findsOneWidget);
      expect(find.text('Cooked'), findsNothing);
      expect(find.text('Unconfirmed'), findsNothing);
      expect(find.text('Upcoming'), findsNothing);
    });
  });
}
