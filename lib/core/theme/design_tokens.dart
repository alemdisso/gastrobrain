import 'package:flutter/material.dart';

/// Gastrobrain Design Tokens
///
/// Concrete, reusable visual values that implement the Gastrobrain Visual Identity.
/// These tokens should be used consistently across all UI implementation.
///
/// Reference: docs/design/design_tokens.md
/// Visual Identity: docs/design/visual_identity.md
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // ============================================================================
  // COLOR SYSTEM
  // ============================================================================

  /// Primary Colors (Warm, Food-Inspired)
  ///
  /// Warm amber/paprika color reflects Brazilian spices and earth tones.
  /// Inviting without being aggressive, food-focused without being literal.
  static const Color primary = Color(0xFFD97706); // Amber/Paprika
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primaryLight = Color(0xFFF59E0B);

  /// Secondary/Accent Colors
  ///
  /// Fresh herb green provides contrast to warm primary,
  /// suggests freshness and growth (exploration).
  static const Color accent = Color(0xFF059669); // Emerald/Herb Green
  static const Color accentDark = Color(0xFF047857);
  static const Color accentLight = Color(0xFF10B981);

  /// Neutral Palette
  ///
  /// Warm neutrals (stone palette) instead of cold grays.
  /// Creates warmth while maintaining clarity.
  static const Color background = Color(0xFFFAFAF9); // Warm White
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F4);
  static const Color border = Color(0xFFE7E5E4);
  static const Color borderStrong = Color(0xFFD6D3D1);
  static const Color disabled = Color(0xFFA8A29E);

  /// Text Colors
  ///
  /// Warm stone-based text colors maintain readability
  /// while avoiding harsh black-on-white.
  static const Color textPrimary = Color(0xFF1C1917); // Warm Black
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textTertiary = Color(0xFF78716C);
  static const Color textDisabled = Color(0xFFA8A29E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  /// Semantic Colors
  ///
  /// Semantic colors maintain warmth while being clearly distinguishable.
  static const Color success = Color(0xFF059669); // Emerald (matches accent)
  static const Color warning = Color(0xFFEA580C); // Warm Orange
  static const Color error = Color(0xFFDC2626); // Red
  static const Color info = Color(0xFF0284C7); // Sky Blue

  // ============================================================================
  // MEAL PLANNING COLORS
  // ============================================================================

  /// Meal Status Colors
  ///
  /// Status-based colors for meal planning slots. Colors communicate
  /// meal state (planned, cooked, empty) rather than meal type (lunch, dinner).
  /// Meal type is conveyed through icons (sun/moon), not color.

  /// Planned meal background - warm amber tint, inviting "ready to cook" feel
  static const Color mealPlanned = Color(0xFFFEF3C7); // Amber-50
  /// Planned meal border - stronger amber for definition
  static const Color mealPlannedBorder = Color(0xFFF59E0B); // Amber-400

  /// Cooked meal background - satisfying green tint, "done" feel
  static const Color mealCooked = Color(0xFFD1FAE5); // Emerald-100
  /// Cooked meal border - stronger green for definition
  static const Color mealCookedBorder = Color(0xFF059669); // Emerald-600
  /// Cooked meal checkmark icon
  static const Color mealCookedIcon = Color(0xFF059669); // Emerald-600

  /// Empty meal slot - neutral, inviting to add
  static const Color mealEmpty = Color(0xFFF5F5F4); // Stone-100 (surfaceVariant)
  /// Empty meal slot border
  static const Color mealEmptyBorder = Color(0xFFD6D3D1); // Stone-300

  /// Meal type badge background (subtle, type-agnostic)
  static const Color mealBadge = Color(0xFFF5F5F4); // Stone-100
  /// Meal type badge text/icon color
  static const Color mealBadgeContent = Color(0xFF57534E); // Stone-600

  /// Difficulty stars
  static const Color difficultyActive = Color(0xFFF59E0B); // Amber-400
  static const Color difficultyInactive = Color(0xFFA8A29E); // Stone-400

  // ============================================================================
  // TYPOGRAPHY SYSTEM
  // ============================================================================

  /// Font Sizes (Flutter sp units)
  ///
  /// Clear hierarchy with 2-4sp differences. 14sp body is readable on mobile
  /// while accommodating Portuguese text length.
  static const double displaySize = 32.0;
  static const double heading1Size = 24.0;
  static const double heading2Size = 20.0;
  static const double heading3Size = 18.0;
  static const double bodyLargeSize = 16.0;
  static const double bodySize = 14.0;
  static const double bodySmallSize = 12.0;
  static const double captionSize = 11.0;

  /// Font Weights
  ///
  /// Confident weights without being overwhelming.
  /// Semibold (600) for headings feels authoritative without being heavy.
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  /// Line Heights
  ///
  /// Generous line heights accommodate Portuguese text length
  /// and create comfortable reading experience.
  static const double tightLineHeight = 1.2;
  static const double normalLineHeight = 1.5;
  static const double relaxedLineHeight = 1.7;

  // ============================================================================
  // SPACING SYSTEM
  // ============================================================================

  /// Base Unit: 8px
  ///
  /// Industry standard, enables consistent rhythm, scales well across devices.

  /// Spacing Scale
  ///
  /// Proportional scale based on 8px unit. Provides generous spacing
  /// for warmth without feeling wasteful.
  static const double spacingXXs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXXl = 48.0;

  /// Component Padding Standards
  ///
  /// Generous padding creates warmth and comfort.
  /// Touch targets meet 44px minimum with padding.

  // Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    vertical: 12.0,
    horizontal: 24.0,
  );
  static const EdgeInsets buttonLargePadding = EdgeInsets.symmetric(
    vertical: 16.0,
    horizontal: 32.0,
  );

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardLargePadding = EdgeInsets.all(24.0);

  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    vertical: 12.0,
    horizontal: 16.0,
  );

  // Input field padding
  static const EdgeInsets inputFieldPadding = EdgeInsets.symmetric(
    vertical: 12.0,
    horizontal: 16.0,
  );

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
  );

  // ============================================================================
  // COMPONENT STYLING
  // ============================================================================

  /// Border Radius
  ///
  /// Moderate rounding (8-16px) feels friendly and warm
  /// without being overly playful.
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
  static const double borderRadiusCircular = 999.0;

  /// Elevation/Shadow
  ///
  /// Subtle shadows (low opacity) create warmth and depth without being heavy.
  /// Soft shadows feel inviting, not harsh.
  static const double elevation0 = 0.0;
  static const double elevation1 = 2.0;
  static const double elevation2 = 4.0;
  static const double elevation3 = 8.0;

  /// Shadow Definitions
  ///
  /// Custom shadow definitions for precise control over shadow appearance.
  static const List<BoxShadow> shadowLevel1 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowLevel2 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLevel3 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 15,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  /// Border Widths
  ///
  /// Thin borders maintain clarity without visual weight.
  /// Focus states use 2px for visibility.
  static const double borderWidthHairline = 1.0;
  static const double borderWidthThin = 2.0;
  static const double borderWidthMedium = 3.0;

  /// Icon Sizing
  ///
  /// Aligned with typography scale. 24px standard matches
  /// Material Design conventions.
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
}
