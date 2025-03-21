import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'screens/home_screen.dart';

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
    return MaterialApp(
      title: 'Gastrobrain',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
