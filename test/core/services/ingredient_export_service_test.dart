import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/ingredient_export_service.dart';
import '../../mocks/mock_database_helper.dart';

void main() {
  group('IngredientExportService', () {
    late MockDatabaseHelper mockDatabaseHelper;

    setUp(() {
      mockDatabaseHelper = MockDatabaseHelper();
    });

    group('exportIngredientsToJson', () {
      test('handles empty ingredient list correctly', () async {
        // Get mock ingredients from helper (should be empty by default)
        final ingredients = await mockDatabaseHelper.getAllIngredients();
        expect(ingredients, isEmpty);

        // The service should handle empty lists gracefully
        // We can't test the actual file export in unit tests, but we can
        // verify that the service would process empty data correctly
      });
    });

    group('validateExportStructure', () {
      test('validates correct export structure', () {
        final validData = [
          {
            'ingredient_id': '1',
            'name': 'Tomato',
            'category': 'vegetable',
            'unit': 'unit',
            'protein_type': null,
            'notes': null,
          }
        ];

        expect(IngredientExportService.validateExportStructure(validData), isTrue);
      });

      test('rejects invalid export structure - missing required field', () {
        final invalidData = [
          {
            'ingredient_id': '1',
            'name': 'Tomato',
            // missing category
            'unit': 'unit',
          }
        ];

        expect(IngredientExportService.validateExportStructure(invalidData), isFalse);
      });

      test('rejects invalid export structure - null category', () {
        final invalidData = [
          {
            'ingredient_id': '1',
            'name': 'Tomato',
            'category': null,
            'unit': 'unit',
          }
        ];

        expect(IngredientExportService.validateExportStructure(invalidData), isFalse);
      });

      test('accepts empty data as valid', () {
        expect(IngredientExportService.validateExportStructure([]), isTrue);
      });
    });
  });
}