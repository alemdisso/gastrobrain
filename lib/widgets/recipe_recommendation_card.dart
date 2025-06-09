import 'package:flutter/material.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';

class _BadgeInfo {
  final double score;
  final String label;

  const _BadgeInfo({required this.score, required this.label});
}

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
              // Recipe name and category
              Text(
                recommendation.recipe.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                recommendation.recipe.category.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 204), // 0.8 * 255 = 204
                    ),
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

  double _calculateEffortScore() {
    final totalTime = recommendation.recipe.prepTimeMinutes +
        recommendation.recipe.cookTimeMinutes;
    final difficulty = recommendation.recipe.difficulty;

    // Base score from difficulty (0-100)
    double score = (6 - difficulty) * 20; // 5=0, 4=20, 3=40, 2=60, 1=80

    // Adjust score based on time
    if (totalTime <= 30) {
      score += 20; // Bonus for quick recipes
    } else if (totalTime >= 90) {
      score -= 20; // Penalty for very long recipes
    } else if (totalTime > 60) {
      score -= 10; // Small penalty for longer recipes
    }

    // Clamp final score to 0-100 range
    return score.clamp(0.0, 100.0);
  }

  String _getTooltip(_BadgeInfo badge, String type) {
    switch (type) {
      case 'timing':
        final statusText = badge.score >= 75
            ? 'ready to explore'
            : badge.score >= 60
                ? 'good variety'
                : badge.score >= 40
                    ? 'recently used'
                    : 'very recently used';
        return 'Timing & Variety: ${badge.score.toStringAsFixed(0)}/100\n'
            'This recipe is $statusText based on:\n'
            '• When you last cooked it\n'
            '• Protein type variety\n'
            '• Recipe rotation';

      case 'quality':
        final ratingText = badge.score >= 85
            ? 'one of your favorites'
            : badge.score >= 70
                ? 'highly rated by you'
                : badge.score >= 50
                    ? 'rated above average'
                    : badge.score > 0
                        ? 'rated below average'
                        : 'not yet rated';
        return 'Recipe Quality: ${badge.score.toStringAsFixed(0)}/100\n'
            'This recipe is $ratingText';

      case 'effort':
        final timeText = recommendation.recipe.prepTimeMinutes +
            recommendation.recipe.cookTimeMinutes;
        final difficultyText = recommendation.recipe.difficulty;
        return 'Recipe Effort: ${badge.score.toStringAsFixed(0)}/100\n'
            'Total time: $timeText minutes\n'
            'Difficulty level: $difficultyText/5';

      default:
        return badge.label;
    }
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
    final effortScore = _calculateEffortScore();

    // Create badge data with scores and labels
    final badgeData = [
      (
        info: _BadgeInfo(
          score: timingVarietyScore,
          label: _getTimingVarietyLabel(timingVarietyScore),
        ),
        type: 'timing'
      ),
      (
        info: _BadgeInfo(
          score: qualityScore,
          label: _getQualityLabel(qualityScore),
        ),
        type: 'quality'
      ),
      (
        info: _BadgeInfo(
          score: effortScore,
          label: _getEffortLabel(),
        ),
        type: 'effort'
      ),
    ];

    // Add the three badges
    for (final badge in badgeData) {
      final backgroundColor = _getFactorColor(badge.info.score);
      final borderColor = _getFactorBorderColor(badge.info.score);
      final textColor = _getFactorTextColor(badge.info.score);

      badges.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Tooltip(
            message: _getTooltip(badge.info, badge.type),
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
                badge.info.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
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

  String _getTimingVarietyLabel(double score) {
    // Maps frequency, protein_rotation, and variety scores
    if (score >= 75) return 'Explore'; // High variety, good timing
    if (score >= 60) return 'Varied'; // Good variety, decent timing
    if (score >= 40) return 'Recent'; // Recently used proteins/recipes
    return 'Repeat'; // Very recently used
  }

  String _getQualityLabel(double score) {
    // Maps rating score to user preference labels
    if (score >= 85) return 'Loved'; // Consistently high rated
    if (score >= 70) return 'Great'; // Well rated
    if (score >= 50) return 'Good'; // Average rating
    if (score > 0) return 'Fair'; // Below average rating
    return 'New'; // No rating yet
  }

  String _getEffortLabel() {
    // Combines difficulty score with cooking time
    final totalTime = recommendation.recipe.prepTimeMinutes +
        recommendation.recipe.cookTimeMinutes;
    final difficulty = recommendation.recipe.difficulty;

    // Quick: Easy and under 30 minutes
    if (difficulty <= 2 && totalTime <= 30) return 'Quick';

    // Easy: Low difficulty, any time
    if (difficulty <= 2) return 'Easy';

    // Complex: High difficulty, over 60 minutes
    if (difficulty >= 4 && totalTime > 60) return 'Project';

    // Complex: High difficulty
    if (difficulty >= 4) return 'Complex';

    // Moderate: Everything else
    return 'Moderate';
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
