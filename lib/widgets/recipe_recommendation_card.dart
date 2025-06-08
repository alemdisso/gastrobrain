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
    final factorIcons = <Widget>[];

    // Process each factor in the recommendation
    recommendation.factorScores.forEach((factorId, score) {
      final icon = _getFactorIcon(factorId, score);
      if (icon != null) {
        // Determine badge properties based on factor type and score
        String label;
        Color backgroundColor;
        Color borderColor;
        Color textColor;
        if (factorId == 'randomization') {
          // Special case for randomization factor - show numeric score
          label = score.toStringAsFixed(0);
          backgroundColor = Colors.purple.withValues(alpha: 26);
          borderColor = Colors.purple;
          textColor = Colors.purple;
        } else {
          // Use factor-specific labels based on the factor ID
          if (factorId == 'frequency') {
            label = score >= 75 ? 'Due' : (score >= 50 ? 'Soon' : 'Recent');
          } else if (factorId == 'protein_rotation') {
            label = score >= 75 ? 'Varied' : (score >= 50 ? 'OK' : 'Recent');
          } else if (factorId == 'rating') {
            label = score >= 75 ? 'Top' : (score >= 50 ? 'Good' : 'Fair');
          } else if (factorId == 'variety_encouragement') {
            label = score >= 75 ? 'Rare' : (score >= 50 ? 'Often' : 'Regular');
          } else if (factorId == 'difficulty') {
            label = score >= 75 ? 'Easy' : (score >= 50 ? 'Medium' : 'Hard');
          } else {
            label = score >= 80
                ? 'Strong'
                : (score >= 60
                    ? 'Good'
                    : score >= 40
                        ? 'Fair'
                        : 'Weak');
          }

          backgroundColor = _getFactorColor(score);
          borderColor = _getFactorBorderColor(score);
          textColor = _getFactorTextColor(score);
        }
        // Create the factor badge with the determined properties
        factorIcons.add(
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: _getFactorTooltip(factorId, score),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    });

    // Add protein rotation warning if needed
    final proteinScore = recommendation.factorScores['protein_rotation'];
    if (proteinScore != null && proteinScore < 50) {
      // Determine severity based on score
      String warningText = proteinScore < 25 ? 'Same' : 'Repeat';

      factorIcons.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Tooltip(
            message:
                'Warning: This protein type was used recently in your meals.\nConsider choosing a different protein for better variety.',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 26),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    warningText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: factorIcons.isEmpty
          ? [Text('No factors', style: Theme.of(context).textTheme.bodySmall)]
          : factorIcons,
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

  Icon? _getFactorIcon(String factorId, double score) {
    switch (factorId) {
      case 'frequency':
        return const Icon(Icons.schedule, size: 16);
      case 'protein_rotation':
        return const Icon(Icons.rotate_right, size: 16);
      case 'rating':
        return const Icon(Icons.star, size: 16);
      case 'variety_encouragement':
        return const Icon(Icons.shuffle, size: 16);
      case 'difficulty':
        return const Icon(Icons.battery_full, size: 16);
      case 'randomization':
        return const Icon(Icons.casino, size: 16);
      default:
        return null;
    }
  }

  String _getFactorTooltip(String factorId, double score) {
    final scoreText = score.toStringAsFixed(1);
    switch (factorId) {
      case 'frequency':
        String statusText = score >= 75
            ? 'due now'
            : (score >= 50 ? 'due soon' : 'recently cooked');
        return 'Cooking frequency: $scoreText\nThis recipe is $statusText based on your frequency preferences';
      case 'protein_rotation':
        if (score < 50) {
          return 'Protein variety: $scoreText\nThis protein type was used recently. Consider a different protein for variety.';
        }
        return 'Protein variety: $scoreText\nGood variety - you haven\'t used this protein type recently';
      case 'rating':
        String ratingText = score >= 75
            ? 'top-rated'
            : (score >= 50 ? 'well-rated' : 'moderately rated');
        return 'Your rating: $scoreText\nThis recipe is $ratingText based on your preferences';
      case 'variety_encouragement':
        String frequencyText = score >= 75
            ? 'rarely cooked'
            : (score >= 50 ? 'rarely  cooked' : 'occasionally cooked');
        return 'Recipe variety: $scoreText\nThis recipe is $frequencyText in your meal rotation';
      case 'difficulty':
        String difficultyText =
            score >= 75 ? 'easy' : (score >= 50 ? 'medium' : 'more complex');
        String context = '';
        DateTime now = DateTime.now();
        bool isWeekend =
            now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
        context = isWeekend
            ? '\nWeekend meals can be more complex'
            : '\nWeekday meals are better when simpler';
        return 'Difficulty match: $scoreText\nThis recipe is $difficultyText to prepare (${recommendation.recipe.difficulty}/5)$context';
      case 'randomization':
        return 'Variety factor: $scoreText\nAdds a little randomness to keep suggestions fresh';
      default:
        return '$factorId: $scoreText';
    }
  }

  Color _getFactorColor(double score) {
    if (score >= 75) return Colors.green.withValues(alpha: 0.26);
    if (score >= 50) return Colors.amber.withValues(alpha: 0.26);
    return Colors.red.withValues(alpha: 0.26);
  }
}
