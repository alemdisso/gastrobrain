import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Button Style Helpers for Gastrobrain
///
/// Provides standardized button styles for common use cases beyond the
/// default theme. Use these for special cases like destructive actions.
///
/// **Standard buttons** (use default theme):
/// - Primary actions: `ElevatedButton()` - uses theme automatically
/// - Secondary actions: `TextButton()` - uses theme automatically
/// - Alternative actions: `OutlinedButton()` - uses theme automatically
/// - Icon actions: `IconButton()` - uses theme automatically
///
/// **Special cases** (use helpers from this file):
/// - Destructive actions: `ElevatedButton(style: ButtonStyles.destructive)`
/// - Destructive text: `TextButton(style: ButtonStyles.destructiveText)`
///
/// Reference: docs/design/button_patterns.md
class ButtonStyles {
  // Private constructor to prevent instantiation
  ButtonStyles._();

  /// Destructive Button Style (Primary)
  ///
  /// Use for primary destructive actions (delete, remove, etc.)
  /// that require confirmation and visual emphasis.
  ///
  /// Example:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () => _confirmDelete(),
  ///   style: ButtonStyles.destructive,
  ///   child: Text('Delete Recipe'),
  /// )
  /// ```
  static final ButtonStyle destructive = ElevatedButton.styleFrom(
    backgroundColor: DesignTokens.error,
    foregroundColor: Colors.white,
    disabledBackgroundColor: DesignTokens.disabled,
    disabledForegroundColor: DesignTokens.textDisabled,
    elevation: DesignTokens.elevation1,
    padding: DesignTokens.buttonPadding,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
    ),
    textStyle: const TextStyle(
      fontSize: DesignTokens.bodySize,
      fontWeight: DesignTokens.weightMedium,
    ),
    // Ensure minimum 48x48dp touch target
    minimumSize: const Size(48, 48),
  );

  /// Destructive Text Button Style
  ///
  /// Use for secondary destructive actions (cancel, discard, etc.)
  /// that are less prominent but still indicate potential data loss.
  ///
  /// Example:
  /// ```dart
  /// TextButton(
  ///   onPressed: () => _discardChanges(),
  ///   style: ButtonStyles.destructiveText,
  ///   child: Text('Discard Changes'),
  /// )
  /// ```
  static final ButtonStyle destructiveText = TextButton.styleFrom(
    foregroundColor: DesignTokens.error,
    disabledForegroundColor: DesignTokens.textDisabled,
    padding: DesignTokens.buttonPadding,
    textStyle: const TextStyle(
      fontSize: DesignTokens.bodySize,
      fontWeight: DesignTokens.weightMedium,
    ),
    // Ensure minimum 48x48dp touch target
    minimumSize: const Size(48, 48),
  );

  /// Destructive Outlined Button Style
  ///
  /// Use for destructive actions that need more emphasis than text
  /// but less than a filled button.
  ///
  /// Example:
  /// ```dart
  /// OutlinedButton(
  ///   onPressed: () => _removeItem(),
  ///   style: ButtonStyles.destructiveOutlined,
  ///   child: Text('Remove'),
  /// )
  /// ```
  static final ButtonStyle destructiveOutlined = OutlinedButton.styleFrom(
    foregroundColor: DesignTokens.error,
    disabledForegroundColor: DesignTokens.textDisabled,
    side: const BorderSide(
      color: DesignTokens.error,
      width: DesignTokens.borderWidthThin,
    ),
    padding: DesignTokens.buttonPadding,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
    ),
    textStyle: const TextStyle(
      fontSize: DesignTokens.bodySize,
      fontWeight: DesignTokens.weightMedium,
    ),
    // Ensure minimum 48x48dp touch target
    minimumSize: const Size(48, 48),
  );
}

/// Button Pattern Extensions
///
/// Convenience methods for common button patterns.
extension ButtonPatternExtensions on BuildContext {
  /// Show a confirmation dialog before executing a destructive action
  ///
  /// Returns true if user confirmed, false if cancelled.
  ///
  /// Example:
  /// ```dart
  /// if (await context.confirmDestructiveAction(
  ///   title: 'Delete Recipe',
  ///   message: 'Are you sure you want to delete this recipe?',
  ///   confirmLabel: 'Delete',
  /// )) {
  ///   // Proceed with deletion
  /// }
  /// ```
  Future<bool> confirmDestructiveAction({
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ButtonStyles.destructive,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
