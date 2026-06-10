import 'package:flutter/material.dart';

/// Shows a bottom sheet with Gastrobrain defaults: `isScrollControlled: true`
/// and `useSafeArea: true`. Pass [useSafeArea] as false and
/// [backgroundColor] as `Colors.transparent` for sheets that manage their own
/// safe-area handling (e.g. DraggableScrollableSheet with transparent bg).
///
/// Callers must NOT call [showModalBottomSheet] directly — use this helper
/// so inset and scroll behaviour stays consistent project-wide.
Future<T?> showGastrobrainBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useSafeArea = true,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    shape: shape,
    builder: builder,
  );
}
