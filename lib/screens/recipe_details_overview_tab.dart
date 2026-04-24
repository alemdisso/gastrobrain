import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/recipe.dart';
import '../l10n/app_localizations.dart';

/// Overview tab for RecipeDetailsScreen.
///
/// Displays recipe metadata: category, rating, difficulty, servings,
/// prep/cook time, desired frequency, and notes.
class RecipeDetailsOverviewTab extends StatelessWidget {
  const RecipeDetailsOverviewTab({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Story — shown first, hidden when absent
          if (recipe.story.isNotEmpty) ...[
            _buildStoryCard(context),
            const SizedBox(height: 20),
          ],

          // Category
          _buildInfoRow(
            context,
            icon: Icons.category,
            label: AppLocalizations.of(context)!.category,
            value: recipe.category.getLocalizedDisplayName(context),
          ),
          const SizedBox(height: 12),

          // Rating
          if (recipe.rating > 0)
            _buildInfoRow(
              context,
              icon: Icons.star,
              label: AppLocalizations.of(context)!.rating,
              value: '${recipe.rating}/5',
            ),
          if (recipe.rating > 0) const SizedBox(height: 12),

          // Difficulty
          _buildInfoRow(
            context,
            icon: Icons.signal_cellular_alt,
            label: AppLocalizations.of(context)!.difficulty,
            value: '${recipe.difficulty}/5',
          ),
          const SizedBox(height: 12),

          // Servings
          _buildInfoRow(
            context,
            icon: Icons.people,
            label: AppLocalizations.of(context)!.servings,
            value: '${recipe.servings}',
          ),
          const SizedBox(height: 12),

          // Prep Time
          if (recipe.prepTimeMinutes > 0)
            _buildInfoRow(
              context,
              icon: Icons.kitchen,
              label: AppLocalizations.of(context)!.prepTimeLabel,
              value:
                  '${recipe.prepTimeMinutes} ${AppLocalizations.of(context)!.minuteAbbreviation}',
            ),
          if (recipe.prepTimeMinutes > 0) const SizedBox(height: 12),

          // Cook Time
          if (recipe.cookTimeMinutes > 0)
            _buildInfoRow(
              context,
              icon: Icons.whatshot,
              label: AppLocalizations.of(context)!.cookTimeLabel,
              value:
                  '${recipe.cookTimeMinutes} ${AppLocalizations.of(context)!.minuteAbbreviation}',
            ),
          if (recipe.cookTimeMinutes > 0) const SizedBox(height: 12),

          // Marinating Time
          if (recipe.marinatingTimeMinutes > 0)
            _buildInfoRow(
              context,
              icon: Icons.schedule,
              label: AppLocalizations.of(context)!.marinatingTimeLabel,
              value:
                  '${recipe.marinatingTimeMinutes} ${AppLocalizations.of(context)!.minuteAbbreviation}',
            ),
          if (recipe.marinatingTimeMinutes > 0) const SizedBox(height: 12),

          // Desired Frequency
          _buildInfoRow(
            context,
            icon: Icons.calendar_today,
            label: AppLocalizations.of(context)!.desiredFrequency,
            value: recipe.desiredFrequency.getLocalizedDisplayName(context),
          ),
          const SizedBox(height: 20),

          // Notes
          if (recipe.notes.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.notes,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recipe.notes,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 18,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.recipeStory,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MarkdownBody(
            data: recipe.story,
            shrinkWrap: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: TextStyle(
                fontSize: 15,
                height: 1.65,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
