enum FrequencyType {
  daily('daily'),
  weekly('weekly'),
  biweekly('biweekly'),
  monthly('monthly'),
  bimonthly('bimonthly'),
  rarely('rarely');

  final String value;
  const FrequencyType(this.value);

  static FrequencyType fromString(String value) {
    return FrequencyType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FrequencyType.monthly,
    );
  }

  String get displayName => value[0].toUpperCase() + value.substring(1);

  String get compactDisplayName {
    switch (this) {
      case FrequencyType.daily:
        return '1d';
      case FrequencyType.weekly:
        return '1w';
      case FrequencyType.biweekly:
        return '2w';
      case FrequencyType.monthly:
        return '1m';
      case FrequencyType.bimonthly:
        return '2m';
      case FrequencyType.rarely:
        return 'rare';
    }
  }
}
