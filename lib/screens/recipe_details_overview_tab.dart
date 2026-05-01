import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/recipe.dart';
import '../models/tag.dart';
import '../l10n/app_localizations.dart';

/// Overview tab for RecipeDetailsScreen.
///
/// Displays recipe metadata: rating, difficulty, servings,
/// prep/cook time, desired frequency, notes, and tags.
class RecipeDetailsOverviewTab extends StatelessWidget {
  const RecipeDetailsOverviewTab({
    super.key,
    required this.recipe,
    this.tags = const [],
  });

  final Recipe recipe;
  final List<Tag> tags;

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

          // Rating
          if (recipe.rating > 0)
            _buildInfoRow(
              context,
              icon: Icons.star,
              label: AppLocalizations.of(context)!.rating,
              valueWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < recipe.rating ? Icons.star : Icons.star_border,
                    size: 18,
                    color: i < recipe.rating ? Colors.amber : Colors.grey,
                  ),
                ),
              ),
            ),
          if (recipe.rating > 0) const SizedBox(height: 12),

          // Difficulty
          _buildInfoRow(
            context,
            icon: Icons.signal_cellular_alt,
            label: AppLocalizations.of(context)!.difficulty,
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  i < recipe.difficulty
                      ? Icons.battery_full
                      : Icons.battery_0_bar,
                  size: 18,
                  color: i < recipe.difficulty ? Colors.green : Colors.grey,
                ),
              ),
            ),
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

          // Tags — grouped by type, meal_role and food_type first
          if (tags.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.tags,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildGroupedTags(context),
          ],

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

  static const _typeOrder = [
    'meal_role',
    'food_type',
    'cuisine',
    'occasion',
    'dietary',
  ];

  String _typeDisplayName(String typeId, AppLocalizations l10n) {
    switch (typeId) {
      case 'meal_role': return l10n.tagTypeMealRole;
      case 'food_type': return l10n.tagTypeFoodType;
      case 'cuisine': return l10n.tagTypeCuisine;
      case 'occasion': return l10n.tagTypeOccasion;
      case 'dietary': return l10n.tagTypeDietary;
      default: return typeId;
    }
  }

  List<Widget> _buildGroupedTags(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byType = <String, List<Tag>>{};
    for (final tag in tags) {
      (byType[tag.typeId] ??= []).add(tag);
    }
    final orderedIds = [
      ..._typeOrder.where(byType.containsKey),
      ...byType.keys.where((id) => !_typeOrder.contains(id)),
    ];
    final widgets = <Widget>[];
    for (final typeId in orderedIds) {
      final group = byType[typeId]!;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _typeDisplayName(typeId, l10n),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: group.map((t) => Chip(
                  label: Text(t.getLocalizedName(l10n)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
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
    String? value,
    Widget? valueWidget,
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
        if (valueWidget != null)
          valueWidget
        else
          Text(
            value ?? '',
            style: const TextStyle(fontSize: 16),
          ),
      ],
    );
  }
}
