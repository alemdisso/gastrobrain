import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/servings_stepper.dart';

class RecipeMetadataDisplay extends StatelessWidget {
  final Recipe recipe;
  final bool isExpanded;
  final int servings;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onServingsChanged;

  const RecipeMetadataDisplay({
    super.key,
    required this.recipe,
    required this.isExpanded,
    required this.servings,
    required this.onToggleExpanded,
    required this.onServingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    tooltip: isExpanded ? 'Hide details' : 'Show details',
                    onPressed: onToggleExpanded,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.signal_cellular_alt, size: 18),
                        label: Text(
                            '${localizations.difficulty}: ${recipe.difficulty}/5'),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0.5),
                      ),
                      if (recipe.rating > 0)
                        Chip(
                          avatar: const Icon(Icons.star, size: 18),
                          label: Text(
                              '${localizations.rating}: ${recipe.rating}/5'),
                          backgroundColor:
                              Colors.amber.withValues(alpha: 0.3),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Prep: ${recipe.prepTimeMinutes}m  •  Cook: ${recipe.cookTimeMinutes}m',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ServingsStepper(
                    key: const Key('recipe_editor_servings_stepper'),
                    value: servings,
                    onChanged: onServingsChanged,
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Status: Incomplete recipe',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
