import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Gastrobrain App Theme Configuration
///
/// Centralized theme configuration implementing design tokens.
/// Provides consistent styling across all widgets following
/// Gastrobrain's visual identity (warm, confident, cultured, clear, rooted).
///
/// Reference: docs/design/visual_identity.md
/// Design Tokens: docs/design/design_tokens.md
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light Theme
  ///
  /// Primary theme for Gastrobrain app implementing warm, food-inspired
  /// color palette and generous spacing.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // ========================================================================
      // COLOR SCHEME
      // ========================================================================
      colorScheme: ColorScheme.light(
        // Primary colors (warm amber/paprika)
        primary: DesignTokens.primary,
        onPrimary: DesignTokens.textOnPrimary,
        primaryContainer: DesignTokens.primaryLight,
        onPrimaryContainer: DesignTokens.textPrimary,

        // Secondary/Accent colors (fresh herb green)
        secondary: DesignTokens.accent,
        onSecondary: DesignTokens.textOnAccent,
        secondaryContainer: DesignTokens.accentLight,
        onSecondaryContainer: DesignTokens.textPrimary,

        // Surfaces
        surface: DesignTokens.surface,
        onSurface: DesignTokens.textPrimary,
        surfaceContainerHighest: DesignTokens.surfaceVariant,

        // Background (using surface as background is deprecated)
        surfaceContainerLowest: DesignTokens.background,

        // Semantic colors
        error: DesignTokens.error,
        onError: Colors.white,

        // Outline/borders
        outline: DesignTokens.border,
        outlineVariant: DesignTokens.borderStrong,
      ),

      // ========================================================================
      // TYPOGRAPHY
      // ========================================================================
      textTheme: TextTheme(
        // Display
        displayLarge: TextStyle(
          fontSize: DesignTokens.displaySize,
          fontWeight: DesignTokens.weightSemibold,
          height: DesignTokens.tightLineHeight,
          color: DesignTokens.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: DesignTokens.heading1Size,
          fontWeight: DesignTokens.weightSemibold,
          height: DesignTokens.tightLineHeight,
          color: DesignTokens.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: DesignTokens.heading2Size,
          fontWeight: DesignTokens.weightSemibold,
          height: DesignTokens.tightLineHeight,
          color: DesignTokens.textPrimary,
        ),

        // Headings
        headlineLarge: TextStyle(
          fontSize: DesignTokens.heading1Size,
          fontWeight: DesignTokens.weightSemibold,
          height: DesignTokens.tightLineHeight,
          color: DesignTokens.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: DesignTokens.heading2Size,
          fontWeight: DesignTokens.weightSemibold,
          height: DesignTokens.tightLineHeight,
          color: DesignTokens.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: DesignTokens.heading3Size,
          fontWeight: DesignTokens.weightSemibold,
          height: DesignTokens.tightLineHeight,
          color: DesignTokens.textPrimary,
        ),

        // Titles
        titleLarge: TextStyle(
          fontSize: DesignTokens.heading2Size,
          fontWeight: DesignTokens.weightMedium,
          height: DesignTokens.normalLineHeight,
          color: DesignTokens.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: DesignTokens.heading3Size,
          fontWeight: DesignTokens.weightMedium,
          height: DesignTokens.normalLineHeight,
          color: DesignTokens.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: DesignTokens.bodyLargeSize,
          fontWeight: DesignTokens.weightMedium,
          height: DesignTokens.normalLineHeight,
          color: DesignTokens.textPrimary,
        ),

        // Body
        bodyLarge: TextStyle(
          fontSize: DesignTokens.bodyLargeSize,
          fontWeight: DesignTokens.weightRegular,
          height: DesignTokens.normalLineHeight,
          color: DesignTokens.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: DesignTokens.bodySize,
          fontWeight: DesignTokens.weightRegular,
          height: DesignTokens.normalLineHeight,
          color: DesignTokens.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: DesignTokens.bodySmallSize,
          fontWeight: DesignTokens.weightRegular,
          height: DesignTokens.normalLineHeight,
          color: DesignTokens.textSecondary,
        ),

        // Labels
        labelLarge: TextStyle(
          fontSize: DesignTokens.bodySize,
          fontWeight: DesignTokens.weightMedium,
          height: DesignTokens.normalLineHeight,
          color: DesignTokens.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: DesignTokens.bodySmallSize,
          fontWeight: DesignTokens.weightMedium,
          height: DesignTokens.normalLineHeight,
          color: DesignTokens.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: DesignTokens.captionSize,
          fontWeight: DesignTokens.weightRegular,
          height: DesignTokens.normalLineHeight,
          color: DesignTokens.textTertiary,
        ),
      ),

      // ========================================================================
      // COMPONENT THEMES
      // ========================================================================

      /// AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.surface,
        foregroundColor: DesignTokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: DesignTokens.heading2Size,
          fontWeight: DesignTokens.weightSemibold,
          height: DesignTokens.tightLineHeight,
          color: DesignTokens.textPrimary,
        ),
      ),

      /// Card Theme
      cardTheme: CardThemeData(
        color: DesignTokens.surface,
        elevation: DesignTokens.elevation1,
        shadowColor: Color.fromRGBO(0, 0, 0, 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSm,
          vertical: DesignTokens.spacingXs,
        ),
      ),

      /// Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primary,
          foregroundColor: DesignTokens.textOnPrimary,
          disabledBackgroundColor: DesignTokens.disabled,
          disabledForegroundColor: DesignTokens.textDisabled,
          elevation: DesignTokens.elevation1,
          padding: DesignTokens.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
          ),
          textStyle: TextStyle(
            fontSize: DesignTokens.bodySize,
            fontWeight: DesignTokens.weightMedium,
          ),
        ),
      ),

      /// Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.primary,
          disabledForegroundColor: DesignTokens.textDisabled,
          side: const BorderSide(
            color: DesignTokens.primary,
            width: DesignTokens.borderWidthThin,
          ),
          padding: DesignTokens.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
          ),
          textStyle: TextStyle(
            fontSize: DesignTokens.bodySize,
            fontWeight: DesignTokens.weightMedium,
          ),
        ),
      ),

      /// Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.primary,
          disabledForegroundColor: DesignTokens.textDisabled,
          padding: DesignTokens.buttonPadding,
          textStyle: TextStyle(
            fontSize: DesignTokens.bodySize,
            fontWeight: DesignTokens.weightMedium,
          ),
        ),
      ),

      /// Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: DesignTokens.textSecondary,
          disabledForegroundColor: DesignTokens.textDisabled,
          iconSize: DesignTokens.iconSizeMedium,
        ),
      ),

      /// Input Decoration Theme (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.surface,
        contentPadding: DesignTokens.inputFieldPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
          borderSide: const BorderSide(
            color: DesignTokens.border,
            width: DesignTokens.borderWidthHairline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
          borderSide: const BorderSide(
            color: DesignTokens.border,
            width: DesignTokens.borderWidthHairline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
          borderSide: const BorderSide(
            color: DesignTokens.primary,
            width: DesignTokens.borderWidthThin,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
          borderSide: const BorderSide(
            color: DesignTokens.error,
            width: DesignTokens.borderWidthHairline,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
          borderSide: const BorderSide(
            color: DesignTokens.error,
            width: DesignTokens.borderWidthThin,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
          borderSide: const BorderSide(
            color: DesignTokens.border,
            width: DesignTokens.borderWidthHairline,
          ),
        ),
        labelStyle: TextStyle(
          fontSize: DesignTokens.bodySize,
          color: DesignTokens.textSecondary,
        ),
        hintStyle: TextStyle(
          fontSize: DesignTokens.bodySize,
          color: DesignTokens.textTertiary,
        ),
        errorStyle: TextStyle(
          fontSize: DesignTokens.bodySmallSize,
          color: DesignTokens.error,
        ),
      ),

      /// Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: DesignTokens.surface,
        elevation: DesignTokens.elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLarge),
        ),
        titleTextStyle: TextStyle(
          fontSize: DesignTokens.heading2Size,
          fontWeight: DesignTokens.weightSemibold,
          color: DesignTokens.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: DesignTokens.bodySize,
          color: DesignTokens.textPrimary,
          height: DesignTokens.normalLineHeight,
        ),
      ),

      /// Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DesignTokens.surface,
        selectedItemColor: DesignTokens.primary,
        unselectedItemColor: DesignTokens.textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: DesignTokens.captionSize,
          fontWeight: DesignTokens.weightMedium,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: DesignTokens.captionSize,
          fontWeight: DesignTokens.weightRegular,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: DesignTokens.elevation2,
      ),

      /// Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DesignTokens.textPrimary,
        contentTextStyle: TextStyle(
          fontSize: DesignTokens.bodySize,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      /// Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.surfaceVariant,
        disabledColor: DesignTokens.disabled,
        selectedColor: DesignTokens.primaryLight,
        secondarySelectedColor: DesignTokens.accentLight,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSm,
          vertical: DesignTokens.spacingXs,
        ),
        labelStyle: TextStyle(
          fontSize: DesignTokens.bodySmallSize,
          color: DesignTokens.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: DesignTokens.bodySmallSize,
          color: DesignTokens.textOnPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
        ),
      ),

      /// Divider Theme
      dividerTheme: const DividerThemeData(
        color: DesignTokens.border,
        thickness: DesignTokens.borderWidthHairline,
        space: DesignTokens.spacingMd,
      ),

      /// List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: DesignTokens.listItemPadding,
        titleTextStyle: TextStyle(
          fontSize: DesignTokens.bodySize,
          fontWeight: DesignTokens.weightMedium,
          color: DesignTokens.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: DesignTokens.bodySmallSize,
          color: DesignTokens.textSecondary,
        ),
      ),
    );
  }

  /// Dark Theme (Foundation)
  ///
  /// Dark theme foundation structure for future implementation.
  /// Currently returns a basic dark theme based on design tokens.
  /// To be fully implemented when dark mode is prioritized.
  static ThemeData get darkTheme {
    // TODO: Implement comprehensive dark theme
    // For now, return a basic dark theme structure
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: DesignTokens.primary,
        onPrimary: DesignTokens.textOnPrimary,
        secondary: DesignTokens.accent,
        onSecondary: DesignTokens.textOnAccent,
      ),
    );
  }
}
