import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/di/service_provider.dart';
import 'package:gastrobrain/services/shopping_list_service.dart';

void main() {
  group('ServiceProvider', () {
    test('provides access to ShoppingListService', () {
      final service = ServiceProvider.shoppingList;

      expect(service, isNotNull);
      expect(service, isA<ShoppingListService>());
    });
  });
}
