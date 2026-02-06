import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'recipes_screen.dart';
import 'weekly_plan_screen.dart';
import 'ingredients_screen.dart';
import 'tools_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const RecipesScreen(),
      const WeeklyPlanScreen(),
      const IngredientsScreen(),
      const ToolsScreen(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? null // RecipesScreen has its own AppBar
          : AppBar(
              title: Text(AppLocalizations.of(context)!.appTitle),
            ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book, key: Key('recipes_tab_icon')),
            label: AppLocalizations.of(context)!.recipes,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today,
                key: Key('meal_plan_tab_icon')),
            label: AppLocalizations.of(context)!.mealPlan,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu,
                key: Key('ingredients_tab_icon')),
            label: AppLocalizations.of(context)!.ingredients,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.build, key: Key('tools_tab_icon')),
            label: 'Tools',
          ),
        ],
      ),
    );
  }
}
