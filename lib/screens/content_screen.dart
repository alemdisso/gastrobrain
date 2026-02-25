import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'recipes_screen.dart';
import 'ingredients_screen.dart';

/// Container screen for content management (Recipes + Ingredients).
///
/// Uses a top TabBar to switch between the Recipes and Ingredients
/// sub-screens, keeping both accessible under a single bottom nav tab.
class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                tabs: [
                  Tab(text: l10n.recipes),
                  Tab(text: l10n.ingredients),
                ],
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                RecipesScreen(),
                IngredientsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
