import 'package:flutter/material.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';

class RecipeRecommendationCard extends StatelessWidget {
  final RecipeRecommendation recommendation;
  final VoidCallback? onTap;

  const RecipeRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe name
              Text(
                recommendation.recipe.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Recipe details row
              Row(
                children: [
                  // Difficulty stars
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < recommendation.recipe.difficulty
                          ? Icons.battery_full
                          : Icons.battery_0_bar,
                      size: 14,
                      color: i < recommendation.recipe.difficulty
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Cooking time
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${recommendation.recipe.prepTimeMinutes + recommendation.recipe.cookTimeMinutes} min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Factor indicators
              _buildFactorIndicators(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactorIndicators(BuildContext context) {
    final badges = <Widget>[];

    // Combine relevant scores for timing/variety badge
    final frequencyScore = recommendation.factorScores['frequency'] ?? 0.0;
    final proteinScore = recommendation.factorScores['protein_rotation'] ?? 0.0;
    final varietyScore =
        recommendation.factorScores['variety_encouragement'] ?? 0.0;

    // Calculate averages for the three main aspects
    final timingVarietyScore =
        (frequencyScore + proteinScore + varietyScore) / 3;
    final qualityScore = recommendation.factorScores['rating'] ?? 50.0;
    final effortScore = recommendation.factorScores['difficulty'] ?? 50.0;

    // Create the three main badges
    final scores = [
      (score: timingVarietyScore, label: 'Timing'),
      (score: qualityScore, label: 'Quality'),
      (score: effortScore, label: 'Effort'),
    ];

    // Add the three badges
    for (final badgeData in scores) {
      final backgroundColor = _getFactorColor(badgeData.score);
      final borderColor = _getFactorBorderColor(badgeData.score);
      final textColor = _getFactorTextColor(badgeData.score);

      badges.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Text(
              badgeData.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: badges.isEmpty
          ? [Text('No badges', style: Theme.of(context).textTheme.bodySmall)]
          : badges,
    );
  }

  Color _getFactorBorderColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.amber;
    return Colors.red;
  }

  Color _getFactorTextColor(double score) {
    if (score >= 75) return Colors.green.shade800;
    if (score >= 50) return Colors.amber.shade800;
    return Colors.red.shade800;
  }

  Color _getFactorColor(double score) {
    if (score >= 75) return Colors.green.withValues(alpha: 0.26);
    if (score >= 50) return Colors.amber.withValues(alpha: 0.26);
    return Colors.red.withValues(alpha: 0.26);
  }
}
