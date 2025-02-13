import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'models/meal.dart';
import 'database/database_helper.dart';
import 'screens/add_recipe_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Recipe> recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final loadedRecipes = await _dbHelper.getAllRecipes();
    setState(() {
      recipes = loadedRecipes;
    });
  }

  Future<void> _addRecipe() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );

    if (result == true) {
      _loadRecipes(); // Reload the list if a recipe was added
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastrobrain'),
      ),
      body: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return ListTile(
            title: Text(recipe.name),
            subtitle: Text('Created: ${recipe.createdAt.toString()}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecipe,
        tooltip: 'Add Recipe',
        child: const Icon(Icons.add),
      ),
    );
  }
}
