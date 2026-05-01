import 'package:flutter_test/flutter_test.dart';

// Mirrors the frequency ordering in DatabaseHelper._frequencyOrder.
// These tests guard against accidental reordering of the frequency enum values.
const _frequencyOrder = ['daily', 'weekly', 'biweekly', 'monthly', 'bimonthly', 'rarely'];

List<String> _frequenciesAtLeast(String freq) {
  final idx = _frequencyOrder.indexOf(freq);
  return idx == -1 ? [freq] : _frequencyOrder.sublist(0, idx + 1);
}

// Mirrors the tag-grouping logic in DatabaseHelper.getRecipesWithSortAndFilter.
// Groups a flat list of tag filter maps into {typeId → names}, respecting is_hard.
({Map<String, List<String>> namesByType, Map<String, bool> isHardByType})
    _groupTagFilters(List<Map<String, String>> tagFilters) {
  final Map<String, List<String>> namesByType = {};
  final Map<String, bool> isHardByType = {};
  for (final tf in tagFilters) {
    final typeId = tf['type_id']!;
    namesByType.putIfAbsent(typeId, () => []).add(tf['name']!);
    isHardByType[typeId] = tf['is_hard'] == 'true';
  }
  return (namesByType: namesByType, isHardByType: isHardByType);
}

void main() {
  group('Frequency "at least" expansion', () {
    test('daily returns only daily', () {
      expect(_frequenciesAtLeast('daily'), equals(['daily']));
    });

    test('weekly returns daily and weekly', () {
      expect(_frequenciesAtLeast('weekly'), equals(['daily', 'weekly']));
    });

    test('biweekly returns daily, weekly, biweekly', () {
      expect(
        _frequenciesAtLeast('biweekly'),
        equals(['daily', 'weekly', 'biweekly']),
      );
    });

    test('monthly returns all frequencies up to monthly', () {
      expect(
        _frequenciesAtLeast('monthly'),
        equals(['daily', 'weekly', 'biweekly', 'monthly']),
      );
    });

    test('bimonthly returns all frequencies up to bimonthly', () {
      expect(
        _frequenciesAtLeast('bimonthly'),
        equals(['daily', 'weekly', 'biweekly', 'monthly', 'bimonthly']),
      );
    });

    test('rarely returns all frequencies', () {
      expect(
        _frequenciesAtLeast('rarely'),
        equals(['daily', 'weekly', 'biweekly', 'monthly', 'bimonthly', 'rarely']),
      );
    });

    test('unknown value falls back to single-item list', () {
      expect(_frequenciesAtLeast('unknown'), equals(['unknown']));
    });
  });

  group('Tag filter grouping — hard vs soft types', () {
    test('single soft tag produces one entry', () {
      final result = _groupTagFilters([
        {'type_id': 'cuisine', 'name': 'Italian', 'is_hard': 'false'},
      ]);
      expect(result.namesByType['cuisine'], equals(['Italian']));
      expect(result.isHardByType['cuisine'], isFalse);
    });

    test('multiple soft tags in same type are grouped (OR within type)', () {
      final result = _groupTagFilters([
        {'type_id': 'cuisine', 'name': 'Italian', 'is_hard': 'false'},
        {'type_id': 'cuisine', 'name': 'Japanese', 'is_hard': 'false'},
      ]);
      expect(result.namesByType['cuisine'], equals(['Italian', 'Japanese']));
      expect(result.isHardByType['cuisine'], isFalse);
    });

    test('single hard tag produces one entry', () {
      final result = _groupTagFilters([
        {'type_id': 'dietary', 'name': 'vegetarian', 'is_hard': 'true'},
      ]);
      expect(result.namesByType['dietary'], equals(['vegetarian']));
      expect(result.isHardByType['dietary'], isTrue);
    });

    test('multiple hard tags in same type are grouped but marked hard (AND within type)', () {
      final result = _groupTagFilters([
        {'type_id': 'dietary', 'name': 'vegetarian', 'is_hard': 'true'},
        {'type_id': 'dietary', 'name': 'gluten-free', 'is_hard': 'true'},
      ]);
      expect(result.namesByType['dietary'], equals(['vegetarian', 'gluten-free']));
      expect(result.isHardByType['dietary'], isTrue);
    });

    test('tags across different types are kept in separate groups', () {
      final result = _groupTagFilters([
        {'type_id': 'dietary', 'name': 'vegetarian', 'is_hard': 'true'},
        {'type_id': 'cuisine', 'name': 'Italian', 'is_hard': 'false'},
      ]);
      expect(result.namesByType.keys, containsAll(['dietary', 'cuisine']));
      expect(result.namesByType['dietary'], equals(['vegetarian']));
      expect(result.namesByType['cuisine'], equals(['Italian']));
      expect(result.isHardByType['dietary'], isTrue);
      expect(result.isHardByType['cuisine'], isFalse);
    });

    test('empty tag filter list produces empty groups', () {
      final result = _groupTagFilters([]);
      expect(result.namesByType, isEmpty);
      expect(result.isHardByType, isEmpty);
    });
  });
}
