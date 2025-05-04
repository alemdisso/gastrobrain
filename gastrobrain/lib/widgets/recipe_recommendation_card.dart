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

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
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
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    return Colors.red;
  }

  Widget _buildFactorIndicators(BuildContext context) {
    return Row(
      children: [
        // We'll add factor icons here in the next step
        Text('Factor icons to be added',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
