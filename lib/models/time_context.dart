enum TimeContext {
  past,
  current,
  future;

  String get displayName {
    switch (this) {
      case TimeContext.past:
        return 'Past';
      case TimeContext.current:
        return 'Current';
      case TimeContext.future:
        return 'Future';
    }
  }

  String get description {
    switch (this) {
      case TimeContext.past:
        return 'Previous week';
      case TimeContext.current:
        return 'This week';
      case TimeContext.future:
        return 'Upcoming week';
    }
  }
}
