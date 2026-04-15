import 'package:flutter/material.dart';

/// Holds developer-facing toggle states for the current session.
///
/// Settings are not persisted across app restarts — they are intended
/// for active development and algorithm inspection only.
class DebugSettingsProvider extends ChangeNotifier {
  bool _debugScoringMode = false;

  bool get debugScoringMode => _debugScoringMode;

  void toggleDebugScoringMode() {
    _debugScoringMode = !_debugScoringMode;
    notifyListeners();
  }
}
