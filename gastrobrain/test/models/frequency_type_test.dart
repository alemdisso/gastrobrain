import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/frequency_type.dart';

void main() {
  group('FrequencyType', () {
    test('fromString converts valid strings correctly', () {
      expect(FrequencyType.fromString('daily'), FrequencyType.daily);
      expect(FrequencyType.fromString('weekly'), FrequencyType.weekly);
      expect(FrequencyType.fromString('biweekly'), FrequencyType.biweekly);
      expect(FrequencyType.fromString('bimonthly'), FrequencyType.bimonthly);
      expect(FrequencyType.fromString('monthly'), FrequencyType.monthly);
      expect(FrequencyType.fromString('rarely'), FrequencyType.rarely);
    });

    test('fromString handles invalid strings by defaulting to monthly', () {
      expect(FrequencyType.fromString('invalid'), FrequencyType.monthly);
      expect(FrequencyType.fromString(''), FrequencyType.monthly);
      expect(FrequencyType.fromString('DAILY'), FrequencyType.monthly);
    });

    test('value property returns correct string representation', () {
      expect(FrequencyType.daily.value, 'daily');
      expect(FrequencyType.weekly.value, 'weekly');
      expect(FrequencyType.biweekly.value, 'biweekly');
      expect(FrequencyType.bimonthly.value, 'bimonthly');
      expect(FrequencyType.monthly.value, 'monthly');
      expect(FrequencyType.rarely.value, 'rarely');
    });

    test('displayName returns correctly formatted string', () {
      expect(FrequencyType.daily.displayName, 'Daily');
      expect(FrequencyType.weekly.displayName, 'Weekly');
      expect(FrequencyType.biweekly.displayName, 'Biweekly');
      expect(FrequencyType.bimonthly.displayName, 'Bimonthly');
      expect(FrequencyType.monthly.displayName, 'Monthly');
      expect(FrequencyType.rarely.displayName, 'Rarely');
    });
  });
}
