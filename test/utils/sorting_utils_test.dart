import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/utils/sorting_utils.dart';

void main() {
  group('SortingUtils', () {
    group('normalizeForSorting', () {
      test('converts to lowercase', () {
        expect(
          SortingUtils.normalizeForSorting('PIMENTA'),
          equals('pimenta'),
        );
      });

      test('replaces hyphens with spaces', () {
        expect(
          SortingUtils.normalizeForSorting('pimenta-do-reino'),
          equals('pimenta do reino'),
        );
      });

      test('removes Portuguese diacritics', () {
        expect(
          SortingUtils.normalizeForSorting('feijão'),
          equals('feijao'),
        );
        expect(
          SortingUtils.normalizeForSorting('açúcar'),
          equals('acucar'),
        );
        expect(
          SortingUtils.normalizeForSorting('coração'),
          equals('coracao'),
        );
      });

      test('removes accents from other languages', () {
        expect(
          SortingUtils.normalizeForSorting('jalapeño'),
          equals('jalapeno'),
        );
        expect(
          SortingUtils.normalizeForSorting('café'),
          equals('cafe'),
        );
      });

      test('handles combined transformations', () {
        expect(
          SortingUtils.normalizeForSorting('Feijão-Fradinho'),
          equals('feijao fradinho'),
        );
        expect(
          SortingUtils.normalizeForSorting('COUVE-FLOR'),
          equals('couve flor'),
        );
        expect(
          SortingUtils.normalizeForSorting('Castanha-do-Pará'),
          equals('castanha do para'),
        );
      });

      test('trims whitespace', () {
        expect(
          SortingUtils.normalizeForSorting('  pimenta  '),
          equals('pimenta'),
        );
      });

      test('handles empty string', () {
        expect(
          SortingUtils.normalizeForSorting(''),
          equals(''),
        );
      });
    });

    group('sortStrings', () {
      test('sorts hyphenated words before space-separated variants', () {
        final input = [
          'feijão vermelho',
          'feijão-fradinho',
        ];
        final result = SortingUtils.sortStrings(input);
        expect(result, equals([
          'feijão-fradinho',
          'feijão vermelho',
        ]));
      });

      test('sorts pimenta variants correctly', () {
        final input = [
          'pimenta malagueta',
          'pimenta jalapeño',
          'pimenta-do-reino',
        ];
        final result = SortingUtils.sortStrings(input);
        expect(result, equals([
          'pimenta-do-reino',
          'pimenta jalapeño',
          'pimenta malagueta',
        ]));
      });

      test('handles multiple hyphenated compounds', () {
        final input = [
          'couve manteiga',
          'couve-flor',
          'couve-de-bruxelas',
          'couve roxa',
        ];
        final result = SortingUtils.sortStrings(input);
        expect(result, equals([
          'couve-de-bruxelas',
          'couve-flor',
          'couve manteiga',
          'couve roxa',
        ]));
      });

      test('is case-insensitive', () {
        final input = [
          'PIMENTA',
          'abacate',
          'Zebra',
        ];
        final result = SortingUtils.sortStrings(input);
        expect(result, equals([
          'abacate',
          'PIMENTA',
          'Zebra',
        ]));
      });

      test('handles accented characters correctly', () {
        final input = [
          'açúcar',
          'abacate',
          'água',
        ];
        final result = SortingUtils.sortStrings(input);
        expect(result, equals([
          'abacate',
          'açúcar',
          'água',
        ]));
      });

      test('sorts comprehensive Portuguese ingredient list', () {
        final input = [
          'feijão preto',
          'feijão vermelho',
          'feijão-fradinho',
          'pimenta jalapeño',
          'pimenta malagueta',
          'pimenta-do-reino',
          'castanha-de-caju',
          'castanha-do-pará',
          'cebolinha',
          'coentro',
          'couve-flor',
          'couve manteiga',
        ];
        final result = SortingUtils.sortStrings(input);
        expect(result, equals([
          'castanha-de-caju',
          'castanha-do-pará',
          'cebolinha',
          'coentro',
          'couve-flor',
          'couve manteiga',
          'feijão-fradinho',
          'feijão preto',
          'feijão vermelho',
          'pimenta-do-reino',
          'pimenta jalapeño',
          'pimenta malagueta',
        ]));
      });

      test('handles empty list', () {
        final result = SortingUtils.sortStrings([]);
        expect(result, isEmpty);
      });

      test('handles single-item list', () {
        final result = SortingUtils.sortStrings(['pimenta']);
        expect(result, equals(['pimenta']));
      });
    });

    group('sortByName', () {
      test('sorts objects by name property', () {
        final items = [
          TestItem('feijão vermelho'),
          TestItem('feijão-fradinho'),
        ];
        final result = SortingUtils.sortByName(items, (i) => i.name);
        expect(result.map((i) => i.name).toList(), equals([
          'feijão-fradinho',
          'feijão vermelho',
        ]));
      });

      test('sorts complex objects correctly', () {
        final items = [
          TestItem('pimenta malagueta'),
          TestItem('pimenta jalapeño'),
          TestItem('pimenta-do-reino'),
        ];
        final result = SortingUtils.sortByName(items, (i) => i.name);
        expect(result.map((i) => i.name).toList(), equals([
          'pimenta-do-reino',
          'pimenta jalapeño',
          'pimenta malagueta',
        ]));
      });

      test('handles empty list', () {
        final result = SortingUtils.sortByName<TestItem>([], (i) => i.name);
        expect(result, isEmpty);
      });

      test('does not modify original list', () {
        final original = [
          TestItem('zebra'),
          TestItem('abacate'),
        ];
        final originalCopy = List<TestItem>.from(original);

        SortingUtils.sortByName(original, (i) => i.name);

        expect(original, equals(originalCopy));
      });
    });
  });
}

/// Test helper class
class TestItem {
  final String name;
  TestItem(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestItem && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
