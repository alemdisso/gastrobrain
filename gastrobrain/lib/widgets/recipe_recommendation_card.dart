import 'package:flutter/material.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';

class RecipeRecommendationCard extends StatelessWidget {
  final RecipeRecommendation recommendation;
  final VoidCallback? onTap;

  const RecipeRecommendationCard({
    Key? key,
    required this.recommendation,
    this.onTap,
  }) : super(key: key);

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
              // Recipe name and basic info
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recommendation.recipe.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Score indicator
                  _buildScoreIndicator(context),
                ],
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
                          ? Icons.star
                          : Icons.star_border,
                      size: 14,
                      color: i < recommendation.recipe.difficulty
                          ? Colors.amber
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

  Widget _buildScoreIndicator(BuildContext context) {
    final score = recommendation.totalScore;
    final color = _getScoreColor(score);

    // Determine strength label based on score
    String strengthLabel = 'Fair';
    if (score >= 80) {
      strengthLabel = 'Strong';
    } else if (score >= 60) {
      strengthLabel = 'Good';
    } else if (score < 40) {
      strengthLabel = 'Weak';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            // Add a subtle background color matching the score
            color: color.withValues(alpha: 26), // 0.1 * 255 ≈ 26
          ),
          child: Center(
            child: Text(
              '${score.toInt()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          strengthLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    return Colors.red;
  }

  Widget _buildFactorIndicators(BuildContext context) {
    final factorIcons = <Widget>[];

    // Process each factor in the recommendation
    recommendation.factorScores.forEach((factorId, score) {
      final icon = _getFactorIcon(factorId, score);
      if (icon != null) {
        // Determine factor strength label
        String strengthLabel = '';
        if (score >= 80) {
          strengthLabel = 'Strong';
        } else if (score >= 60) {
          strengthLabel = 'Good';
        } else if (score >= 40) {
          strengthLabel = 'Fair';
        } else {
          strengthLabel = 'Weak';
        }

        factorIcons.add(
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: _getFactorTooltip(factorId, score),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getFactorColor(score),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getFactorBorderColor(score),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 4),
                    Text(
                      strengthLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getFactorTextColor(score),
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
      factorIcons.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Tooltip(
            message: 'Warning: Protein type recently used',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 26),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning,
                    size: 16,
                    color: Colors.red,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Recent',
                    style: TextStyle(
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

// Add helper methods for colors
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
        return const Icon(Icons.fitness_center, size: 16);
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
        return 'Cooking frequency score: $scoreText';
      case 'protein_rotation':
        return 'Protein variety score: $scoreText';
      case 'rating':
        return 'Recipe rating score: $scoreText';
      case 'variety_encouragement':
        return 'Variety encouragement score: $scoreText';
      case 'difficulty':
        return 'Difficulty appropriateness: $scoreText';
      case 'randomization':
        return 'Randomization factor: $scoreText';
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
