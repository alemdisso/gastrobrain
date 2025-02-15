import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../database/database_helper.dart';
import 'cook_meal_screen.dart';

class MealHistoryScreen extends StatefulWidget {
  final Recipe recipe;

  const MealHistoryScreen({super.key, required this.recipe});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Meal> meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    final loadedMeals = await _dbHelper.getMealsForRecipe(widget.recipe.id);
    setState(() {
      meals = loadedMeals;
      _isLoading = false;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History: ${widget.recipe.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : meals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No meals recorded yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  meal.wasSuccessful
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: meal.wasSuccessful
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDateTime(meal.cookedAt),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.people, size: 16),
                                const SizedBox(width: 4),
                                Text('${meal.servings}'),
                              ],
                            ),
                            if (meal.actualPrepTime > 0 ||
                                meal.actualCookTime > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.timer, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Actual times - Prep: ${meal.actualPrepTime}min, Cook: ${meal.actualCookTime}min',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                            if (meal.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                meal.notes,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => CookMealScreen(recipe: widget.recipe),
            ),
          ).then((value) {
            if (value == true) {
              _loadMeals();
            }
          });
        },
        tooltip: 'Cook Now',
        child: const Icon(Icons.add),
      ),
    );
  }
}
