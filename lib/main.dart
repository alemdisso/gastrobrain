import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'screens/recipe_editor_screen.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/recipe_provider.dart';
import 'core/providers/meal_provider.dart';
import 'core/providers/meal_plan_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final dbHelper = DatabaseHelper();

  // Check if ingredients need to be seeded
  final ingredientsCount = await dbHelper.getIngredientsCount();
  if (ingredientsCount == 0) {
    // Only seed if there are no ingredients yet
    try {
      //print('Seeding ingredients database...');
      await dbHelper.importIngredientsFromJson('assets/ingredients.json');
      //print('Ingredients database seeded successfully');
    } catch (e) {
      //print('Error seeding ingredients: $e');
    }
  }

  // Check if recipes need to be seeded
  final recipesCount = await dbHelper.getRecipesCount();
  if (recipesCount == 0) {
    // Only seed if there are no recipes yet
    try {
      //print('Seeding ingredients database...');
      await dbHelper.importRecipesFromJson('assets/recipes.json');
      //print('Recipes database seeded successfully');
    } catch (e) {
      //print('Error seeding recipes: $e');
    }
  }

  runApp(const GastrobrainApp());
}

class GastrobrainApp extends StatelessWidget {
  const GastrobrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
      ],
      child: MaterialApp(
        title: 'Gastrobrain',
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'), // Set Portuguese Brazil as default
        home: const HomePage(),
        routes: {
          '/recipe-editor': (context) => const RecipeEditorScreen(),
        },
      ),
    );
  }
}
