# Gastrobrain Design Tokens

> **Document Purpose:** Concrete, reusable visual values that implement the [Gastrobrain Visual Identity](visual_identity.md). These tokens should be used consistently across all UI implementation.

**Status:** Approved - Ready for Implementation
**Created:** 2026-01-30
**Related:** [Issue #255 - Define Gastrobrain Visual Identity and Design Principles](https://github.com/rodrigo-omena/gastrobrain/issues/255)

---

## COLOR SYSTEM

### Primary Colors (Warm, Food-Inspired)

| Token | Hex Value | Usage |
|-------|-----------|-------|
| **Primary** | `#D97706` | Main actions, key elements, navigation highlights |
| **Primary Dark** | `#B45309` | Pressed states, hover emphasis |
| **Primary Light** | `#F59E0B` | Hover states, subtle backgrounds, tints |

**Rationale:** Warm amber/paprika color reflects Brazilian spices and earth tones. Inviting without being aggressive, food-focused without being literal.

### Secondary/Accent Colors

| Token | Hex Value | Usage |
|-------|-----------|-------|
| **Accent** | `#059669` | Success states, fresh elements, secondary actions |
| **Accent Dark** | `#047857` | Pressed states |
| **Accent Light** | `#10B981` | Subtle highlights |

**Rationale:** Fresh herb green provides contrast to warm primary, suggests freshness and growth (exploration).

### Neutral Palette

| Token | Hex Value | Usage |
|-------|-----------|-------|
| **Background** | `#FAFAF9` | Main background (slightly warm, not stark white) |
| **Surface** | `#FFFFFF` | Cards, elevated elements |
| **Surface Variant** | `#F5F5F4` | Subtle backgrounds, sections |
| **Border** | `#E7E5E4` | Dividers, borders (warm gray, not cold) |
| **Border Strong** | `#D6D3D1` | Emphasized borders |
| **Disabled** | `#A8A29E` | Inactive elements |

**Rationale:** Warm neutrals (stone palette) instead of cold grays. Creates warmth while maintaining clarity.

### Text Colors

| Token | Hex Value | Usage |
|-------|-----------|-------|
| **Text Primary** | `#1C1917` | Main content, headings |
| **Text Secondary** | `#57534E` | Supporting text, metadata |
| **Text Tertiary** | `#78716C` | Hints, captions |
| **Text Disabled** | `#A8A29E` | Inactive text |
| **Text On Primary** | `#FFFFFF` | Text on primary color buttons |
| **Text On Accent** | `#FFFFFF` | Text on accent color elements |

**Rationale:** Warm stone-based text colors maintain readability while avoiding harsh black-on-white.

### Semantic Colors

| Token | Hex Value | Usage |
|-------|-----------|-------|
| **Success** | `#059669` | Confirmations, success states, completed items |
| **Warning** | `#EA580C` | Warnings, cautions, attention needed |
| **Error** | `#DC2626` | Errors, destructive actions, validation failures |
| **Info** | `#0284C7` | Informational messages, tips |

**Rationale:** Semantic colors maintain warmth (success uses accent green, warning uses warm orange) while being clearly distinguishable.

---

## TYPOGRAPHY SYSTEM

### Font Family

```dart
Primary: System Default (San Francisco on iOS, Roboto on Android)
Fallback: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
```

**Rationale:** System fonts ensure performance and native feel. Professional without requiring custom font loading.

### Size Scale (Flutter sp units)

| Token | Size | Usage |
|-------|------|-------|
| **Display** | `32sp` | Hero headings, special emphasis (rare) |
| **Heading 1** | `24sp` | Screen titles, main headings |
| **Heading 2** | `20sp` | Section titles, card headings |
| **Heading 3** | `18sp` | Subsection titles, emphasized text |
| **Body Large** | `16sp` | Emphasized body text, important information |
| **Body** | `14sp` | Main content, standard text |
| **Body Small** | `12sp` | Supporting text, metadata |
| **Caption** | `11sp` | Labels, hints, very small text |

**Rationale:** Clear hierarchy with 2-4sp differences. 14sp body is readable on mobile while accommodating Portuguese length.

### Weight Scale

| Token | Value | Usage |
|-------|-------|-------|
| **Regular** | `400` | Body text, standard content |
| **Medium** | `500` | Emphasis, button text, subtle headings |
| **Semibold** | `600` | Headings, important labels, strong emphasis |
| **Bold** | `700` | Strong emphasis, screen titles (use sparingly) |

**Rationale:** Confident weights without being overwhelming. Semibold (600) for headings feels authoritative without being heavy.

### Line Height

| Token | Value | Usage |
|-------|-------|-------|
| **Tight** | `1.2` | Headings, titles (compact) |
| **Normal** | `1.5` | Standard body text (Portuguese-friendly) |
| **Relaxed** | `1.7` | Long-form content, reading-heavy screens |

**Rationale:** Generous line heights accommodate Portuguese text length and create comfortable reading experience.

---

## SPACING SYSTEM

### Base Unit: `8px`

**Rationale:** Industry standard, enables consistent rhythm, scales well across devices.

### Spacing Scale

| Token | Size | Usage |
|-------|------|-------|
| **xxs** | `2px` | Icon padding, very tight spaces (rare) |
| **xs** | `4px` | Compact spacing, icon gaps |
| **sm** | `8px` | Small gaps, list item spacing |
| **md** | `16px` | Standard spacing, component padding |
| **lg** | `24px` | Section spacing, card padding |
| **xl** | `32px` | Major sections, screen margins |
| **xxl** | `48px` | Screen padding, major separations |

**Rationale:** Proportional scale based on 8px unit. Provides generous spacing for warmth without feeling wasteful.

### Component Padding Standards

| Component | Padding | Usage |
|-----------|---------|-------|
| **Button** | `12px vertical, 24px horizontal` | Standard buttons |
| **Button Large** | `16px vertical, 32px horizontal` | Primary actions |
| **Card** | `16px all sides` | Standard cards |
| **Card Large** | `24px all sides` | Emphasized cards |
| **List Item** | `12px vertical, 16px horizontal` | List items, menu items |
| **Input Field** | `12px vertical, 16px horizontal` | Text inputs, form fields |
| **Screen Padding** | `16px horizontal` | Main screen content areas |

**Rationale:** Generous padding creates warmth and comfort. Touch targets meet 44px minimum with padding.

---

## COMPONENT STYLING

### Border Radius

| Token | Size | Usage |
|-------|------|-------|
| **Small** | `8px` | Buttons, chips, small elements |
| **Medium** | `12px` | Cards, inputs, standard components |
| **Large** | `16px` | Dialogs, large cards, modals |
| **XLarge** | `20px` | Special features, hero elements |
| **Circular** | `999px` | Avatars, round buttons, badges |

**Rationale:** Moderate rounding (8-16px) feels friendly and warm without being overly playful.

### Elevation/Shadow

| Level | Shadow Definition | Usage |
|-------|------------------|-------|
| **Level 0** | `none` | Flat elements, no elevation needed |
| **Level 1** | `0px 1px 3px rgba(0, 0, 0, 0.08), 0px 1px 2px rgba(0, 0, 0, 0.06)` | Cards, subtle elevation |
| **Level 2** | `0px 4px 6px rgba(0, 0, 0, 0.08), 0px 2px 4px rgba(0, 0, 0, 0.06)` | Floating buttons, dropdowns |
| **Level 3** | `0px 10px 15px rgba(0, 0, 0, 0.08), 0px 4px 6px rgba(0, 0, 0, 0.06)` | Dialogs, menus, modals |

**Rationale:** Subtle shadows (low opacity) create warmth and depth without being heavy. Soft shadows feel inviting, not harsh.

### Border Widths

| Token | Size | Usage |
|-------|------|-------|
| **Hairline** | `1px` | Subtle dividers, card borders |
| **Thin** | `2px` | Standard borders, focus states |
| **Medium** | `3px` | Emphasized borders, selected states |

**Rationale:** Thin borders maintain clarity without visual weight. Focus states use 2px for visibility.

### Icon Sizing

| Token | Size | Usage |
|-------|------|-------|
| **Small** | `16px` | Inline icons, metadata icons |
| **Medium** | `24px` | Standard icons, navigation |
| **Large** | `32px` | Feature icons, empty states |
| **XLarge** | `48px` | Hero icons, illustrations |

**Rationale:** Aligned with typography scale. 24px standard matches Material Design conventions.

---

## Implementation Guide

### Flutter Theme Configuration

These tokens should be implemented in `lib/theme/design_tokens.dart` and applied through `ThemeData`:

```dart
// lib/theme/design_tokens.dart
import 'package:flutter/material.dart';

class DesignTokens {
  DesignTokens._(); // Private constructor

  // COLOR SYSTEM
  static const Color primary = Color(0xFFD97706);
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primaryLight = Color(0xFFF59E0B);

  static const Color accent = Color(0xFF059669);
  static const Color accentDark = Color(0xFF047857);
  static const Color accentLight = Color(0xFF10B981);

  static const Color background = Color(0xFFFAFAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F4);
  static const Color border = Color(0xFFE7E5E4);
  static const Color borderStrong = Color(0xFFD6D3D1);
  static const Color disabled = Color(0xFFA8A29E);

  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textTertiary = Color(0xFF78716C);
  static const Color textDisabled = Color(0xFFA8A29E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFEA580C);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  // TYPOGRAPHY SYSTEM
  static const double displaySize = 32.0;
  static const double heading1Size = 24.0;
  static const double heading2Size = 20.0;
  static const double heading3Size = 18.0;
  static const double bodyLargeSize = 16.0;
  static const double bodySize = 14.0;
  static const double bodySmallSize = 12.0;
  static const double captionSize = 11.0;

  static const double tightLineHeight = 1.2;
  static const double normalLineHeight = 1.5;
  static const double relaxedLineHeight = 1.7;

  // SPACING SYSTEM
  static const double spacingXXs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXXl = 48.0;

  // COMPONENT STYLING
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
  static const double borderRadiusCircular = 999.0;

  static const double elevation0 = 0.0;
  static const double elevation1 = 2.0;
  static const double elevation2 = 4.0;
  static const double elevation3 = 8.0;

  static const double borderWidthHairline = 1.0;
  static const double borderWidthThin = 2.0;
  static const double borderWidthMedium = 3.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
}
```

### Usage Examples

```dart
// Using color tokens
Container(
  color: DesignTokens.primary,
  child: Text(
    'Button Text',
    style: TextStyle(color: DesignTokens.textOnPrimary),
  ),
)

// Using typography tokens
Text(
  'Screen Title',
  style: TextStyle(
    fontSize: DesignTokens.heading1Size,
    fontWeight: FontWeight.w600,
    height: DesignTokens.tightLineHeight,
    color: DesignTokens.textPrimary,
  ),
)

// Using spacing tokens
Padding(
  padding: EdgeInsets.all(DesignTokens.spacingMd),
  child: child,
)

// Using component styling tokens
Container(
  decoration: BoxDecoration(
    color: DesignTokens.surface,
    borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
    border: Border.all(
      color: DesignTokens.border,
      width: DesignTokens.borderWidthHairline,
    ),
  ),
)
```

---

## Design Philosophy Summary

These tokens translate our visual identity attributes:

- **Warm & Inviting:** Warm color palette (amber/paprika), generous spacing, rounded corners, soft shadows
- **Confident & Trustworthy:** Clear typography hierarchy, consistent scale, professional weights
- **Cultured & Exploratory:** Sophisticated color choices (avoiding tech defaults), balanced spacing
- **Clear & Organized:** Strong size/weight hierarchy, systematic spacing scale
- **Regionally Rooted:** Brazilian-inspired colors, Portuguese-friendly line heights, warmth over minimalism

---

## Maintenance

### When to Update Tokens

- **Add new tokens:** When introducing new UI patterns that need consistency
- **Adjust values:** When user testing reveals issues or when visual identity evolves
- **Never:** Don't create one-off values outside this system - extend the system instead

### Token Governance

- All token changes must be documented in this file with rationale
- Breaking changes (removing tokens) require codebase-wide review
- New tokens should follow established naming conventions
- Consult [visual_identity.md](visual_identity.md) when making token decisions

---

**Document Changelog:**
- 2026-01-30: Initial design tokens definition (Checkpoint 3 of UI polish process)
