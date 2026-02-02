import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../screens/recipe_details_screen.dart';
import '../core/providers/recipe_provider.dart';
import '../core/theme/design_tokens.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final Function() onEdit;
  final Function() onDelete;
  final Function() onCooked;
  final int mealCount; // New parameter
  final DateTime? lastCooked; // New parameter

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onEdit,
    required this.onDelete,
    required this.onCooked,
    required this.mealCount,
    required this.lastCooked,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSm,
        vertical: DesignTokens.spacingXs,
      ),
      child: InkWell(
        onTap: _handleCardTap,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Row
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.spacingMd,
              DesignTokens.spacingMd,
              DesignTokens.spacingMd,
              DesignTokens.spacingSm,
            ),
            child: Text(
              widget.recipe.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.weightBold,
              ),
            ),
          ),
          // Info and Actions Row
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.spacingMd,
              0,
              DesignTokens.spacingSm,
              DesignTokens.spacingMd,
            ),
            child: Row(
              children: [
                // Left side - Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category row
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: DesignTokens.spacingXs),
                          Flexible(
                            child: Text(
                              widget.recipe.category
                                  .getLocalizedDisplayName(context),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: DesignTokens.weightMedium,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: DesignTokens.spacingSm),
                      // Time and rating row
                      Row(
                        children: [
                          Icon(
                            widget.recipe.difficulty >= 4
                                ? Icons.warning
                                : Icons.timer,
                            size: 16,
                            color: widget.recipe.difficulty >= 4
                                ? DesignTokens.warning
                                : null,
                          ),
                          SizedBox(width: DesignTokens.spacingXs),
                          Text(
                            '${widget.recipe.prepTimeMinutes + widget.recipe.cookTimeMinutes} min',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: widget.recipe.difficulty >= 4
                                  ? DesignTokens.warning
                                  : null,
                            ),
                          ),
                          SizedBox(width: DesignTokens.spacingMd),
                          // Rating stars (5-star scale)
                          ...List.generate(5, (index) {
                            return Icon(
                              index < widget.recipe.rating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: index < widget.recipe.rating
                                  ? Colors.amber // Keep standard rating color
                                  : DesignTokens.textSecondary,
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _handleCardTap() async {
    final hasChanges = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(recipe: widget.recipe),
      ),
    );

    // If changes were made to the recipe, refresh the recipe list
    if (hasChanges == true && mounted) {
      context.read<RecipeProvider>().loadRecipes(forceRefresh: true);
    }
  }
}
