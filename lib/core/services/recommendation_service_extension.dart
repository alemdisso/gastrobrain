// lib/core/services/recommendation_service_extension.dart

import '../../database/database_helper.dart';
import '../../models/recipe.dart';
import 'recommendation_service.dart';
import 'meal_plan_analysis_service.dart';

/// Extension methods for DatabaseHelper to easily create recommendation services
extension RecommendationServiceExtension on DatabaseHelper {
  /// Create a recommendation service with standard factors registered
  RecommendationService createRecommendationService({
    bool registerDefaultFactors = true,
  }) {
    return RecommendationService(
      dbHelper: this,
      mealPlanAnalysis: MealPlanAnalysisService(this),
      registerDefaultFactors: registerDefaultFactors,
    );
  }

  /// Get recipe recommendations using the default configuration
  Future<List<Recipe>> getRecommendations({
    int count = 5,
    List<String> excludeIds = const [],
  }) async {
    final service = createRecommendationService();
    return await service.getRecommendations(
      count: count,
      excludeIds: excludeIds,
    );
  }
}
