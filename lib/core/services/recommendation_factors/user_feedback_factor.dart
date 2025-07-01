// lib/core/services/recommendation_factors/user_feedback_factor.dart

import 'dart:math';
import '../../../models/recipe.dart';
import '../../../models/recipe_recommendation.dart';
import '../recommendation_service.dart';
import '../../../database/database_helper.dart';

/// A scoring factor that adjusts recommendations based on user feedback history.
///
/// This factor analyzes past user responses to recipe recommendations and applies
/// scoring adjustments to influence future recommendations:
/// - `lessOften`: -15% penalty to discourage frequent recommendations
/// - `moreOften`: +20% boost to encourage frequent recommendations  
/// - `neverAgain`: -40% penalty to significantly reduce recommendation likelihood
/// - `notToday`: No impact (session-only dismissal)
/// - `accepted`: +25% boost for recipes that were selected
/// - `rejected`: -20% penalty for hard rejections
///
/// Feedback influence decays over time (6-12 months) to allow taste evolution.
class UserFeedbackFactor implements RecommendationFactor {

  @override
  String get id => 'user_feedback';

  @override
  int get defaultWeight => 15; // 15% default weight

  @override
  Set<String> get requiredData => {'feedbackHistory'};

  // Scoring adjustments for each feedback type
  static const Map<UserResponse, double> _feedbackAdjustments = {
    UserResponse.lessOften: -0.15,    // -15% penalty
    UserResponse.moreOften: 0.20,     // +20% boost
    UserResponse.neverAgain: -0.40,   // -40% penalty
    UserResponse.accepted: 0.25,      // +25% boost
    UserResponse.rejected: -0.20,     // -20% penalty
    UserResponse.saved: 0.10,         // +10% mild positive
    UserResponse.ignored: 0.0,        // No adjustment
    UserResponse.notToday: 0.0,       // No adjustment (session-only)
  };

  // Temporal decay parameters
  static const int _fullInfluenceDays = 30;  // Full influence for 30 days
  static const int _maxInfluenceDays = 365;  // Complete decay after 365 days

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    // Get feedback history from context (may be null in tests or if not loaded)
    final Map<String, List<Map<String, dynamic>>>? feedbackHistory =
        context['feedbackHistory'] as Map<String, List<Map<String, dynamic>>>?;

    // If no feedback history available, return neutral score
    if (feedbackHistory == null) {
      return 70.0; // Neutral score when feedback data is unavailable
    }

    // Get feedback for this specific recipe
    final recipeFeedback = feedbackHistory[recipe.id] ?? [];

    // If no feedback history, return neutral score
    if (recipeFeedback.isEmpty) {
      return 70.0; // Neutral score for recipes with no feedback
    }

    // Calculate cumulative feedback impact
    double totalAdjustment = 0.0;
    int feedbackCount = 0;

    final now = DateTime.now();

    for (final feedback in recipeFeedback) {
      try {
        final userResponse = UserResponse.values.byName(feedback['user_response']);
        final respondedAt = DateTime.parse(feedback['responded_at']);
        
        // Calculate temporal decay factor
        final daysSinceFeedback = now.difference(respondedAt).inDays;
        final decayFactor = _calculateDecayFactor(daysSinceFeedback);
        
        // Skip feedback that has completely decayed
        if (decayFactor <= 0.0) continue;

        // Get base adjustment for this feedback type
        final baseAdjustment = _feedbackAdjustments[userResponse] ?? 0.0;
        
        // Apply temporal decay
        final adjustedFeedback = baseAdjustment * decayFactor;
        
        totalAdjustment += adjustedFeedback;
        feedbackCount++;
      } catch (e) {
        // Skip malformed feedback entries
        continue;
      }
    }

    // Calculate average adjustment if we have feedback
    final averageAdjustment = feedbackCount > 0 ? totalAdjustment / feedbackCount : 0.0;

    // Convert adjustment to score (0-100 scale)
    // Start with neutral score of 70, then apply adjustment
    double score = 70.0 + (averageAdjustment * 100.0);

    // Apply dampening for extreme adjustments to prevent overfitting
    if (feedbackCount > 0) {
      final dampening = _calculateDampening(feedbackCount);
      score = 70.0 + ((score - 70.0) * dampening);
    }

    // Ensure score stays within valid range
    return max(0.0, min(100.0, score));
  }

  /// Calculate temporal decay factor for feedback based on age
  /// Returns 1.0 for recent feedback, declining to 0.0 for old feedback
  double _calculateDecayFactor(int daysSinceFeedback) {
    if (daysSinceFeedback <= _fullInfluenceDays) {
      return 1.0; // Full influence for recent feedback
    }
    
    if (daysSinceFeedback >= _maxInfluenceDays) {
      return 0.0; // No influence for very old feedback
    }

    // Linear decay between full influence and no influence
    final decayPeriod = _maxInfluenceDays - _fullInfluenceDays;
    final decayProgress = (daysSinceFeedback - _fullInfluenceDays) / decayPeriod;
    
    return 1.0 - decayProgress;
  }

  /// Calculate dampening factor to prevent overfitting with limited feedback
  /// Returns lower values for small sample sizes
  double _calculateDampening(int feedbackCount) {
    // Use logarithmic dampening to reduce extreme adjustments with limited data
    // 1 feedback: ~63% dampening
    // 3 feedback: ~85% dampening  
    // 5+ feedback: ~95% dampening
    return min(1.0, log(feedbackCount + 1) / log(6));
  }

  /// Get feedback history for recipes from the database
  /// This method will be called by the recommendation service during context building
  static Future<Map<String, List<Map<String, dynamic>>>> getFeedbackHistory(
    DatabaseHelper dbHelper, {
    List<String>? recipeIds,
    int lookbackDays = 365,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: lookbackDays));

    // Get recommendation history with user responses
    final historyEntries = await dbHelper.getRecommendationHistory(
      startDate: startDate,
      endDate: endDate,
      limit: 1000, // Large limit to get comprehensive history
    );

    final Map<String, List<Map<String, dynamic>>> feedbackMap = {};

    // Process each history entry
    for (final entry in historyEntries) {
      try {
        // Deserialize the recommendation results
        final results = await dbHelper.getRecommendationById(entry['id']);
        if (results == null) continue;

        // Extract feedback from each recommendation
        for (final recommendation in results.recommendations) {
          // Skip if no user response
          if (recommendation.userResponse == null || 
              recommendation.respondedAt == null) continue;

          final recipeId = recommendation.recipe.id;
          
          // Filter by recipe IDs if specified
          if (recipeIds != null && !recipeIds.contains(recipeId)) continue;

          // Initialize list for this recipe if needed
          feedbackMap[recipeId] ??= [];

          // Add feedback entry
          feedbackMap[recipeId]!.add({
            'user_response': recommendation.userResponse!.name,
            'responded_at': recommendation.respondedAt!.toIso8601String(),
            'total_score': recommendation.totalScore,
            'created_at': entry['created_at'],
          });
        }
      } catch (e) {
        // Skip malformed entries
        continue;
      }
    }

    // Sort feedback by date (newest first) for each recipe
    for (final recipeId in feedbackMap.keys) {
      feedbackMap[recipeId]!.sort((a, b) {
        final dateA = DateTime.parse(a['responded_at']);
        final dateB = DateTime.parse(b['responded_at']);
        return dateB.compareTo(dateA);
      });
    }

    return feedbackMap;
  }
}