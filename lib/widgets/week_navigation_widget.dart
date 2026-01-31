import 'package:flutter/material.dart';
import '../models/time_context.dart';
import '../l10n/app_localizations.dart';

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

  /// Gets the context indicator color
  Color _getContextColor(BuildContext context) {
    switch (timeContext) {
      case TimeContext.past:
        return Colors.grey.withAlpha(51);
      case TimeContext.current:
        return Theme.of(context).colorScheme.primaryContainer.withAlpha(128);
      case TimeContext.future:
        return Theme.of(context).colorScheme.primary.withAlpha(76);
    }
  }

  /// Gets the context border color
  Color _getContextBorderColor(BuildContext context) {
    switch (timeContext) {
      case TimeContext.past:
        return Colors.grey.withAlpha(128);
      case TimeContext.current:
        return Theme.of(context).colorScheme.primary.withAlpha(128);
      case TimeContext.future:
        return Theme.of(context).colorScheme.primary.withAlpha(128);
    }
  }

  /// Gets the context text color
  Color _getContextTextColor(BuildContext context) {
    switch (timeContext) {
      case TimeContext.past:
        return Colors.grey[700] ?? Colors.grey;
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
    final formattedDate =
        '${weekStartDate.day}/${weekStartDate.month}/${weekStartDate.year}';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: onPreviousWeek,
            tooltip: AppLocalizations.of(context)!.previousWeek,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onJumpToCurrentWeek,
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.weekOf(formattedDate),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Time context indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getContextColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getContextBorderColor(context),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getContextIcon(),
                              size: 14,
                              color: _getContextTextColor(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeContext.getLocalizedDisplayName(context),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getContextTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Relative time distance with tap hint
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getRelativeTimeDistance(context),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          // Show subtle jump hint for non-current weeks
                          if (timeContext != TimeContext.current) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.my_location,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(128),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  // Add subtle hint text for non-current weeks
                  if (timeContext != TimeContext.current)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        AppLocalizations.of(context)!.tapToJumpToCurrentWeek,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(153),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: onNextWeek,
            tooltip: AppLocalizations.of(context)!.nextWeek,
          ),
        ],
      ),
    );
  }
}
