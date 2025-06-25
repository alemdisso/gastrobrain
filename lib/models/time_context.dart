import '../l10n/app_localizations.dart';

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

  String getLocalizedDisplayName(context) {
    final localizations = context != null ? AppLocalizations.of(context)! : null;
    
    if (localizations == null) {
      return displayName; // Fallback to English
    }
    
    switch (this) {
      case TimeContext.past:
        return localizations.timeContextPast;
      case TimeContext.current:
        return localizations.timeContextCurrent;
      case TimeContext.future:
        return localizations.timeContextFuture;
    }
  }

  String getLocalizedDescription(context) {
    final localizations = context != null ? AppLocalizations.of(context)! : null;
    
    if (localizations == null) {
      return description; // Fallback to English
    }
    
    switch (this) {
      case TimeContext.past:
        return localizations.timeContextPastDescription;
      case TimeContext.current:
        return localizations.timeContextCurrentDescription;
      case TimeContext.future:
        return localizations.timeContextFutureDescription;
    }
  }
}
