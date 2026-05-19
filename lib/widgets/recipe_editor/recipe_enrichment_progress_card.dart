import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

const int kEnrichedRecipesMilestoneTarget = 50;
const int kEnrichedRecipesWarningThreshold = 25;

class RecipeEnrichmentProgressCard extends StatelessWidget {
  final Map<String, int>? enrichmentStats;
  final bool isLoading;

  const RecipeEnrichmentProgressCard({
    super.key,
    required this.enrichmentStats,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (isLoading || enrichmentStats == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.recipeDatabaseStatus,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    final stats = enrichmentStats!;
    final enrichedCount = stats['enriched'] ?? 0;
    final incompleteCount = stats['incomplete'] ?? 0;
    final totalCount = stats['total'] ?? 0;
    final progressPercent =
        totalCount > 0 ? ((enrichedCount / totalCount) * 100).round() : 0;
    final isTargetReached = enrichedCount >= kEnrichedRecipesMilestoneTarget;
    final recipesNeeded =
        isTargetReached ? 0 : kEnrichedRecipesMilestoneTarget - enrichedCount;

    Color? cardColor;
    if (isTargetReached) {
      cardColor = Colors.green.withValues(alpha: 0.1);
    } else if (enrichedCount >= kEnrichedRecipesWarningThreshold) {
      cardColor = Colors.orange.withValues(alpha: 0.1);
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isTargetReached ? Icons.check_circle : Icons.bar_chart,
                  color: isTargetReached
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizations.recipeDatabaseStatus,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildStatColumn(
                    context,
                    localizations.enrichedRecipes,
                    enrichedCount.toString(),
                    Colors.green,
                    Icons.check_circle_outline,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    context,
                    localizations.needEnrichment,
                    incompleteCount.toString(),
                    Colors.orange,
                    Icons.warning_amber_outlined,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    context,
                    localizations.totalRecipes,
                    totalCount.toString(),
                    Theme.of(context).colorScheme.primary,
                    Icons.restaurant_menu,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? enrichedCount / totalCount : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isTargetReached ? Colors.green : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.progressPercent(progressPercent),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '$enrichedCount / $totalCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTargetReached
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isTargetReached
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isTargetReached ? Icons.emoji_events : Icons.flag,
                    size: 20,
                    color: isTargetReached ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.milestoneTarget,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          localizations.enrichedRecipesTarget,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTargetReached
                              ? localizations.milestoneAchieved
                              : localizations
                                  .recipesNeededForMilestone(recipesNeeded),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isTargetReached
                                        ? Colors.green
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                  ),
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

  Widget _buildStatColumn(BuildContext context, String label, String value,
      Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}
