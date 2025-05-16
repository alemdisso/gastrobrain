import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/core/services/recommendation_service_extension.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';

/// Provides recommendation services throughout the application
class RecommendationProvider {
  // Singleton instance
  static final RecommendationProvider _instance =
      RecommendationProvider._internal();

  factory RecommendationProvider() => _instance;

  RecommendationProvider._internal();

  // Lazy initialization of the recommendation service
  RecommendationService? _recommendationService;

  RecommendationService get recommendationService {
    _recommendationService ??=
        DatabaseProvider().dbHelper.createRecommendationService();
    return _recommendationService!;
  }

  // For testing: allows injection of a mock recommendation service
  void setRecommendationService(RecommendationService service) {
    _recommendationService = service;
  }
}
