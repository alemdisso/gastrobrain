import 'package:flutter/material.dart';
import '../models/time_context.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/design_tokens.dart';

/// A reusable widget for navigating between weeks in a meal planning interface.
///
/// Displays the current week range with visual indicators for past/current/future context,
/// and provides navigation buttons to move between weeks.
class WeekNavigationWidget extends StatelessWidget {
  /// The start date of the current week (typically Friday)
  final DateTime weekStartDate;

  /// The temporal context of the current week (past, current, or future)
  final TimeContext timeContext;

  /// Callback when the previous week button is pressed
  final VoidCallback onPreviousWeek;

  /// Callback when the next week button is pressed
  final VoidCallback onNextWeek;

  /// Callback when tapping to jump to the current week (null if already on current week)
  final VoidCallback? onJumpToCurrentWeek;

  const WeekNavigationWidget({
    super.key,
    required this.weekStartDate,
    required this.timeContext,
    required this.onPreviousWeek,
    required this.onNextWeek,
    this.onJumpToCurrentWeek,
  });

  /// Calculates the relative week distance from the current week
  int _getWeekDistanceFromCurrent() {
    final now = DateTime.now();
    final currentWeekFriday = _getFriday(now);
    final differenceInDays = weekStartDate.difference(currentWeekFriday).inDays;
    return (differenceInDays / 7).round();
  }

  /// Returns a formatted string showing relative time distance
  String _getRelativeTimeDistance(BuildContext context) {
    final distance = _getWeekDistanceFromCurrent();
    if (distance == 0) {
      return AppLocalizations.of(context)!.thisWeekRelative;
    } else if (distance == 1) {
      return AppLocalizations.of(context)!.nextWeekRelative;
    } else if (distance == -1) {
      return AppLocalizations.of(context)!.previousWeekRelative;
    } else if (distance > 0) {
      return AppLocalizations.of(context)!.futureWeeksRelative(distance);
    } else {
      return AppLocalizations.of(context)!.pastWeeksRelative(distance);
    }
  }

  /// Helper method to get the Friday of a given week
  static DateTime _getFriday(DateTime date) {
    final int weekday = date.weekday;
    final daysToSubtract = weekday < 5
        ? weekday + 2 // Go back to previous Friday
        : weekday - 5; // Friday is day 5

    return date.subtract(Duration(days: daysToSubtract));
  }

  /// Gets the context indicator color (for background)
  Color _getContextColor(BuildContext context) {
    switch (timeContext) {
      case TimeContext.past:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case TimeContext.current:
        return Theme.of(context).colorScheme.primaryContainer;
      case TimeContext.future:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Gets the context text color
  Color _getContextTextColor(BuildContext context) {
    switch (timeContext) {
      case TimeContext.past:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case TimeContext.current:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case TimeContext.future:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Gets the context icon
  IconData _getContextIcon() {
    switch (timeContext) {
      case TimeContext.past:
        return Icons.history;
      case TimeContext.current:
        return Icons.today;
      case TimeContext.future:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPreviousWeek,
            tooltip: AppLocalizations.of(context)!.previousWeek,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Context badge with combined message
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getContextColor(context).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.spacingXs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getContextIcon(),
                        size: 16,
                        color: _getContextTextColor(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getRelativeTimeDistance(context),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: _getContextTextColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Today button - always visible, disabled when on current week
                IconButton(
                  icon: Icon(
                    Icons.today,
                    size: 20,
                    color: timeContext == TimeContext.current
                        ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                        : null,
                  ),
                  onPressed: timeContext == TimeContext.current ? null : onJumpToCurrentWeek,
                  tooltip: timeContext == TimeContext.current
                      ? null
                      : AppLocalizations.of(context)!.tapToJumpToCurrentWeek,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextWeek,
            tooltip: AppLocalizations.of(context)!.nextWeek,
          ),
        ],
      ),
    );
  }
}
