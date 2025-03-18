// test/core/services/recommendation_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/recipe.dart';

import '../../mocks/mock_database_helper.dart';

class TestRecommendationFactor implements RecommendationFactor {
  @override
  String get id => 'test_factor';

  @override
  int get weight => 10;

  @override
  Set<String> get requiredData => {'test_data'};

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    return 50.0; // Fixed test score
  }
}

void main() {
  late RecommendationService recommendationService;
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    recommendationService = RecommendationService(
        dbHelper: mockDbHelper, registerDefaultFactors: true);
  });

  tearDown(() {
    // Clean up after each test
    mockDbHelper.resetAllData();
  });

  group('RecommendationService - Factor Management', () {
    test('registers default factors correctly', () {
      // Verify the service has registered the correct factors
      expect(recommendationService.factors.length, 2);

      final factorIds = recommendationService.factors.map((f) => f.id).toList();
      expect(factorIds, contains('frequency'));
      expect(factorIds, contains('protein_rotation'));

      // Verify total weight adds up correctly (40% + 30%)
      expect(recommendationService.totalWeight, 70);
    });

    test('can register and unregister factors', () {
      // Initial factors count (frequency and protein_rotation)
      expect(recommendationService.factors.length, 2);

      // Unregister a factor
      recommendationService.unregisterFactor('frequency');
      expect(recommendationService.factors.length, 1);
      expect(recommendationService.factors.map((f) => f.id).toList(),
          ['protein_rotation']);

      // Unregister another factor
      recommendationService.unregisterFactor('protein_rotation');
      expect(recommendationService.factors.length, 0);

      // Create and register a test factor
      final testFactor = TestRecommendationFactor();
      recommendationService.registerFactor(testFactor);

      expect(recommendationService.factors.length, 1);
      expect(recommendationService.factors.first.id, 'test_factor');
      expect(recommendationService.totalWeight, 10);
    });
  });
}
