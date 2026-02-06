---
name: gastrobrain-ui-polish
description: Guide systematic visual refinement of Flutter/Dart UI through checkpoint-driven iterations, defining and applying consistent visual identity
version: 1.0.0
author: Gastrobrain Development Team
tags: [ui, styling, visual-design, polish, flutter, material-design]
---

# UI Styling & Visual Polish Skill

## Overview

This skill guides systematic visual refinement of Flutter/Dart UI through a **7-checkpoint interactive process**, helping you define and apply a consistent visual identity across the app. It transforms functional but unpolished UI into cohesive, well-designed interfaces with clear personality.

## When to Use This Skill

**Trigger phrases:**
- "Polish the UI for [screen/component]"
- "This screen feels unfinished visually"
- "Help me style [component]"
- "Define visual design for the app"
- "Make this look more professional"

**Use cases:**
1. **New Feature Polish** - Feature works but needs visual refinement
2. **Visual Consistency** - Multiple screens feel inconsistent
3. **Brand Identity Definition** - Need to establish app's visual personality
4. **Pre-Release Polish** - Preparing for production/beta release
5. **Component Styling** - Individual component needs visual improvement
6. **Design System Creation** - Building reusable visual patterns

## Visual Polish Philosophy

**Why systematic visual refinement matters:**
- Creates professional, trustworthy appearance
- Improves user experience through clear hierarchy
- Establishes brand personality and recognition
- Makes the app feel cohesive rather than assembled
- Reduces decision fatigue with reusable patterns
- Communicates quality and attention to detail

**Gastrobrain-specific considerations:**
- Flutter Material Design best practices
- Mobile-first responsive design
- Bilingual UI (EN/PT-BR) considerations
- Information density for meal planning app
- Accessibility and readability
- Performance impact of visual effects

## Checkpoint-Based Polish Process

**CRITICAL:** Never make sweeping visual changes without user confirmation. Always use the 7-checkpoint interactive process.

### Checkpoint Flow Overview

```
User Input (screenshots/code) → Visual Analysis
    ↓
Checkpoint 1: Visual Analysis (WAIT)
    ↓
Checkpoint 2: Identity Definition [if needed] (WAIT)
    ↓
Checkpoint 3: Design Tokens Definition (WAIT)
    ↓
Checkpoint 4: Application Plan (WAIT)
    ↓
Checkpoint 5: Implementation (WAIT)
    ↓
Checkpoint 6: Refinement Iteration (WAIT)
    ↓
Checkpoint 7: Pattern Documentation (WAIT)
    ↓
Complete: Polished UI + Documented Patterns
```

---

## Checkpoint 1: Visual Analysis

**Purpose:** Understand current state and identify specific visual gaps

**Output format:**
```
UI Styling & Visual Polish

CHECKPOINT 1: Visual Analysis
─────────────────────────────────────────

Current State Analysis:

Component/Screen: [Name]
Current visual elements:
- Colors: [Describe current color usage]
- Typography: [Font choices, sizes, hierarchy]
- Spacing: [Padding/margin patterns]
- Component styling: [Borders, shadows, shapes]
- Overall coherence: [Assessment]

Specific Visual Gaps Identified:

1. **Inconsistency:** [What feels inconsistent?]
   - Example: Different button styles across screens
   - Impact: Confusing, unprofessional

2. **Lack of Personality:** [What lacks character?]
   - Example: Generic Material defaults, no brand identity
   - Impact: App feels generic, forgettable

3. **Unfinished Elements:** [What looks incomplete?]
   - Example: Placeholder spacing, default colors
   - Impact: Prototype-like appearance

4. **Visual Hierarchy Issues:** [What's competing for attention?]
   - Example: Everything same size/weight
   - Impact: Hard to scan, unclear focus

5. **Other Issues:** [Additional concerns]

Does this analysis match your perception of the visual gaps?
Any additional concerns I should note? (y/n/more)
```

**Analysis guidelines:**

**Color assessment:**
- Are colors used consistently?
- Is there a clear primary/secondary color scheme?
- Do colors have semantic meaning (success, error, etc.)?
- Are there too many different colors?

**Typography assessment:**
- Is there a clear hierarchy (headings vs. body)?
- Are font sizes appropriate for mobile?
- Is text readable (contrast, line height)?
- Are weights used effectively?

**Spacing assessment:**
- Is spacing consistent (same padding in similar contexts)?
- Does spacing create visual grouping?
- Is spacing proportional (not cramped or too loose)?

**Component styling assessment:**
- Are interactive elements clearly clickable?
- Is visual feedback consistent (hover, pressed, disabled)?
- Do components have appropriate visual weight?
- Are borders/shadows used consistently?

**Wait for user response before proceeding.**

---

## Checkpoint 2: Identity Definition

**Purpose:** Define the visual personality for the feature/app

**When to use:**
- Visual identity is not yet established
- App uses generic Material defaults
- Multiple developers have created different visual styles
- Preparing for brand consistency

**When to skip:**
- Visual identity already documented
- Working within established design system
- Minor component polish only

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 2: Identity Definition

Visual Personality Definition:

App Purpose: [Describe what the app does]
Target Users: [Who uses this app]

Desired Visual Personality (3-5 adjectives):
1. [Adjective 1] - [Why this matters for users]
2. [Adjective 2] - [How this reflects app purpose]
3. [Adjective 3] - [What this communicates]

What This App Is NOT:
- Not [quality/style to avoid] - [Why]
- Not [quality/style to avoid] - [Why]

Visual Influences:
- [Reference or theme] - [Why relevant]
- [Cultural considerations] - [For PT-BR audience]

Long-term Vision:
[How should this app evolve visually over time?]

Example Personality:
For Gastrobrain (meal planning app):
- **Warm and approachable** - Food is personal and emotional
- **Clear and organized** - Planning requires clarity
- **Confident and trustworthy** - Users rely on recommendations
- **Not overly playful** - Respect user's time
- **Not minimalist cold** - Food deserves warmth

Does this visual identity feel right for your vision?
Any adjustments needed? (y/n/adjust)
```

**Identity definition guidelines:**

**Choose personality adjectives carefully:**
- Specific over generic ("warm" vs. "good")
- Actionable in visual terms (can translate to color, typography)
- Reflect user needs and app purpose
- Avoid contradictions (can't be both "minimal" and "rich")

**Define what the app is NOT:**
- Prevents clichés and overused patterns
- Clarifies boundaries
- Guides against inappropriate choices

**Consider cultural context:**
- Brazilian users may have different aesthetic preferences
- Color meanings vary by culture
- Typography should support both languages

**Wait for user response before proceeding.**

---

## Checkpoint 3: Design Tokens Definition

**Purpose:** Create concrete, reusable visual values

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 3: Design Tokens Definition

COLOR SYSTEM:

Primary Colors:
- Primary: #[hex] - [Usage: main actions, key elements]
- Primary Dark: #[hex] - [Usage: pressed states]
- Primary Light: #[hex] - [Usage: hover states, tints]

Secondary/Accent Colors:
- Accent: #[hex] - [Usage: calls to action, highlights]
- Accent Dark/Light: [variants]

Neutral Palette:
- Background: #[hex] - [Usage: main background]
- Surface: #[hex] - [Usage: cards, elevated elements]
- Border: #[hex] - [Usage: dividers, borders]
- Disabled: #[hex] - [Usage: inactive elements]

Text Colors:
- Text Primary: #[hex] - [Usage: main content]
- Text Secondary: #[hex] - [Usage: supporting text]
- Text Disabled: #[hex] - [Usage: inactive text]

Semantic Colors:
- Success: #[hex] - [Usage: confirmations, success states]
- Warning: #[hex] - [Usage: warnings, cautions]
- Error: #[hex] - [Usage: errors, destructive actions]
- Info: #[hex] - [Usage: informational messages]

─────────────────────────────────────────

TYPOGRAPHY SYSTEM:

Font Family:
- Primary: [Font name] - [Usage: all UI text]
- Fallback: [System fallback]

Size Scale:
- Display: [size]sp - [Usage: hero headings]
- Heading 1: [size]sp - [Usage: screen titles]
- Heading 2: [size]sp - [Usage: section titles]
- Heading 3: [size]sp - [Usage: subsection titles]
- Body Large: [size]sp - [Usage: emphasized body text]
- Body: [size]sp - [Usage: main content]
- Body Small: [size]sp - [Usage: supporting text]
- Caption: [size]sp - [Usage: labels, hints]

Weight Scale:
- Regular: 400 - [Usage: body text]
- Medium: 500 - [Usage: emphasis, buttons]
- Semibold: 600 - [Usage: headings]
- Bold: 700 - [Usage: strong emphasis]

Line Height:
- Tight: 1.2 - [Usage: headings]
- Normal: 1.5 - [Usage: body text]
- Relaxed: 1.8 - [Usage: long-form content]

─────────────────────────────────────────

SPACING SYSTEM:

Base Unit: [4px or 8px]

Spacing Scale:
- xxs: [X]px - [Usage: icon padding, tight spaces]
- xs: [X]px - [Usage: compact spacing]
- sm: [X]px - [Usage: small gaps]
- md: [X]px - [Usage: standard spacing]
- lg: [X]px - [Usage: section spacing]
- xl: [X]px - [Usage: major sections]
- xxl: [X]px - [Usage: screen padding]

Component Padding Standards:
- Button: [vertical]px [horizontal]px
- Card: [X]px all sides
- List Item: [vertical]px [horizontal]px
- Input Field: [vertical]px [horizontal]px

─────────────────────────────────────────

COMPONENT STYLING:

Border Radius:
- Small: [X]px - [Usage: buttons, chips]
- Medium: [X]px - [Usage: cards, inputs]
- Large: [X]px - [Usage: dialogs, large cards]
- Circular: 999px - [Usage: avatars, round buttons]

Elevation/Shadow:
- Level 0: none - [Usage: flat elements]
- Level 1: [shadow def] - [Usage: cards]
- Level 2: [shadow def] - [Usage: floating buttons]
- Level 3: [shadow def] - [Usage: dialogs, menus]

Border Widths:
- Hairline: 1px - [Usage: subtle dividers]
- Thin: 2px - [Usage: borders, focus states]
- Medium: 3px - [Usage: emphasized borders]

Icon Sizing:
- Small: [X]px - [Usage: inline icons]
- Medium: [X]px - [Usage: standard icons]
- Large: [X]px - [Usage: feature icons]

─────────────────────────────────────────

Do these design tokens feel appropriate for the visual identity?
Any values need adjustment? (y/n/adjust)
```

**Design token guidelines:**

**Color system:**
- Primary color: Brand color, used for key actions
- Keep palette manageable (5-7 main colors + semantic)
- Ensure sufficient contrast for accessibility (WCAG AA minimum)
- Test colors in both light and dark backgrounds
- Consider color blindness (don't rely solely on color)

**Typography system:**
- Use Flutter sp units for scalability
- Mobile sizes typically smaller than web (16sp body is common)
- Clear hierarchy: at least 2-3sp difference between levels
- Limit weights (3-4 maximum)
- Test with both EN and PT-BR text (some fonts render differently)

**Spacing system:**
- Base unit of 4px or 8px enables consistent rhythm
- Scale should be proportional (not random values)
- Use scale consistently (don't create one-off spacing)
- Component padding should feel balanced
- Consider touch targets (44px minimum for buttons)

**Component styling:**
- Border radius affects personality (sharp=technical, rounded=friendly)
- Shadows create depth and hierarchy
- Consistent border widths reinforce unity
- Icon sizes should align with text sizes

**Wait for user response before proceeding.**

---

## Checkpoint 4: Application Plan

**Purpose:** Plan how to apply design tokens to current UI

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 4: Application Plan

Mapping Current UI to Design Tokens:

Current Element → Design Token Application

1. **Screen Title**
   - Current: Default Text, 20sp, black
   - New: Heading 1 (24sp), Semibold, Text Primary
   - Change: Increase size, add weight, use token color

2. **Primary Button**
   - Current: Material default blue
   - New: Primary color, Medium weight, Border Radius Small
   - Change: Replace color, adjust padding, add radius

3. **Card Background**
   - Current: White with no elevation
   - New: Surface color, Elevation Level 1, Border Radius Medium
   - Change: Add subtle shadow, round corners

[Continue for all elements...]

─────────────────────────────────────────

Prioritized Changes (Highest Visual Impact First):

Priority 1 (Critical - Most Visible):
- [ ] Update primary color throughout (buttons, links)
- [ ] Fix heading hierarchy (too similar sizes)
- [ ] Standardize card styling

Priority 2 (Important - Visual Consistency):
- [ ] Apply consistent spacing
- [ ] Update typography weights
- [ ] Standardize border radius

Priority 3 (Polish - Final Touches):
- [ ] Refine shadows
- [ ] Adjust subtle colors (borders, backgrounds)
- [ ] Polish edge cases

─────────────────────────────────────────

Flutter Implementation Approach:

Theme Configuration:
- Update ThemeData in MaterialApp
  - primaryColor: [token]
  - colorScheme: [define from tokens]
  - textTheme: [define from tokens]
  - elevations, shapes, etc.

Custom Widgets Needed:
- [Widget name] - [Why needed]
- [If creating reusable components]

Files to Modify:
- lib/main.dart (theme)
- lib/screens/[screen].dart
- lib/widgets/[widgets].dart
- [Other files]

Testing Considerations:
- Test on different screen sizes
- Test with long text (Portuguese tends longer)
- Test dark mode if supported
- Verify touch targets are adequate

─────────────────────────────────────────

Does this plan address the key visual gaps identified?
Ready to proceed with implementation? (y/n/adjust)
```

**Application planning guidelines:**

**Map systematically:**
- Go through UI element by element
- Document current state and desired state
- Be specific (don't say "make it better", say exact changes)

**Prioritize wisely:**
- Priority 1: Changes visible on every screen or most used features
- Priority 2: Consistency improvements across similar elements
- Priority 3: Subtle refinements users may not consciously notice

**Flutter implementation:**
- Theme configuration is most efficient (applies everywhere)
- Custom widgets for repeatable patterns
- Consider Material Design 3 if applicable
- Responsive design for different screen sizes

**Wait for user response before proceeding.**

---

## Checkpoint 5: Implementation

**Purpose:** Apply visual improvements through code changes

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 5: Implementation

Implementing Priority 1 Changes:

Change 1: Update Primary Color
[Shows code changes]

File: lib/main.dart
```dart
ThemeData(
  primaryColor: Color(0xFF[hex]),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF[hex]),
  ),
  // ...
)
```

Change 2: Fix Heading Hierarchy
[Shows code changes]

File: lib/screens/home_screen.dart
```dart
Text(
  AppLocalizations.of(context)!.recipeListTitle,
  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
    fontWeight: FontWeight.w600,
  ),
)
```

[Continue for each priority 1 change...]

─────────────────────────────────────────

Testing Results:

✓ Tested on small screen (320px width)
✓ Tested on standard screen (375px width)
✓ Tested on large screen (414px width)
✓ Tested with long Portuguese text
✓ All touch targets ≥44px
✓ flutter analyze passes
✓ No visual regressions on other screens

─────────────────────────────────────────

Do the changes work as expected? Any issues or adjustments needed?
(y/n/issues)
```

**Implementation guidelines:**

**Code quality:**
- Use Theme.of(context) for themeable values
- Create const constructors where possible
- Extract reusable styles to theme or constants
- Follow Flutter best practices (Key usage, etc.)

**Testing approach:**
- Visual inspection on multiple screen sizes
- Test with real content (not just placeholder)
- Check both languages if bilingual
- Verify no performance degradation
- Ensure accessibility maintained

**Common Flutter patterns:**
```dart
// Using theme colors
color: Theme.of(context).colorScheme.primary

// Using text theme
style: Theme.of(context).textTheme.bodyLarge

// Custom theme extension
extension CustomColors on ColorScheme {
  Color get customColor => Color(0xFF...);
}

// Spacing constants
class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  // ...
}
```

**Wait for user response before proceeding.**

---

## Checkpoint 6: Refinement Iteration

**Purpose:** Polish based on visual review

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 6: Refinement Iteration

Visual Review Results:

✓ Visual Balance & Harmony:
  - Colors work well together
  - Spacing feels proportional
  - Elements don't compete

⚠ Consistency Check:
  - Issue: Button padding inconsistent in dialogs vs. screens
  - Fix: Standardize to 12px vertical, 24px horizontal

✓ Design Token Compliance:
  - All colors from defined palette
  - Typography follows scale
  - Spacing uses system values

⚠ Unintended Issues:
  - Issue: Recipe card title wraps awkwardly on small screens
  - Fix: Adjust line height from 1.2 to 1.4

✓ Edge Cases Verified:
  - Long text handling: ✓ Ellipsis added
  - Empty states: ✓ Styled consistently
  - Loading states: ✓ Skeleton screens match design

─────────────────────────────────────────

Refinement Changes:

Change 1: Standardize button padding
[Code changes]

Change 2: Improve recipe card title line height
[Code changes]

Change 3: [Other refinements]

─────────────────────────────────────────

Does this feel polished and ready? Any final adjustments?
(y/n/adjust)
```

**Refinement guidelines:**

**Visual balance:**
- Step back and look at the whole screen
- Is any element too dominant or too subtle?
- Does spacing create natural grouping?
- Is there a clear focal point?

**Consistency check:**
- Compare similar elements across screens
- Verify same patterns used everywhere
- Check that exceptions are intentional

**Edge cases to test:**
- Very long text (recipe names, ingredient lists)
- Very short text (single word buttons)
- Empty states (no data)
- Loading states
- Error states
- Disabled states
- Pressed/active states

**Common refinements:**
- Adjust spacing by 4-8px for better balance
- Tweak font size by 1-2sp for readability
- Lighten/darken colors slightly for contrast
- Add subtle shadows for depth
- Adjust line height for text wrapping

**Wait for user response before proceeding.**

---

## Checkpoint 7: Pattern Documentation

**Purpose:** Capture reusable patterns for future use

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 7: Pattern Documentation

Design Tokens Documentation:

File: docs/design/design-tokens.md

# Gastrobrain Design Tokens

## Color System
[Document colors with usage guidelines]

## Typography System
[Document type scale with examples]

## Spacing System
[Document spacing scale with common uses]

## Component Styling
[Document border radius, shadows, etc.]

─────────────────────────────────────────

Component Patterns Created:

1. **Styled Card Pattern**
   - Usage: Recipe cards, meal cards
   - Code:
   ```dart
   Container(
     decoration: BoxDecoration(
       color: Theme.of(context).colorScheme.surface,
       borderRadius: BorderRadius.circular(12),
       boxShadow: [/* elevation level 1 */],
     ),
     padding: EdgeInsets.all(16),
     child: child,
   )
   ```

2. **Primary Button Pattern**
   - Usage: Main actions
   - Code: [Pattern]

[Continue for each pattern...]

─────────────────────────────────────────

Before/After Insights:

What Changed:
- Primary color changed from default blue to warm orange
- Typography hierarchy clarified (larger headings)
- Consistent card styling across app
- Spacing standardized to 8px base unit

Visual Impact:
- App feels warmer and more food-focused
- Information hierarchy clearer
- More professional and cohesive
- Better reflects meal planning purpose

Lessons Learned:
- Consistent spacing has huge impact on polish
- Typography hierarchy requires more contrast than expected
- Shadow elevation needs to be subtle for food app
- [Other insights]

─────────────────────────────────────────

Patterns Applicable to Other Screens:

1. Recipe List Screen - Apply same card pattern
2. Meal History Screen - Use same typography hierarchy
3. Ingredient Selection - Match button styling
[Continue...]

─────────────────────────────────────────

Is this documented clearly for future use?
(y/n/adjust)
```

**Documentation guidelines:**

**Design tokens:**
- Document in markdown for easy reference
- Include visual examples if possible
- Explain usage guidelines (when to use each color)
- Update as tokens evolve

**Component patterns:**
- Extract reusable patterns into widgets
- Document props/parameters
- Show code examples
- Explain when to use vs. alternatives

**Insights capture:**
- Document what worked well
- Note what didn't work and why
- Record lessons for future polish work
- Identify patterns to propagate

**Wait for user response. Once confirmed, polish work is complete.**

---

## Integration with Gastrobrain Workflow

### Related Skills

**Works well with:**
- **UI Component Implementation Skill** - Polish after creating new components
- **Feature Implementation** - Add polish checkpoint after functionality complete
- **Code Review Skill** - Include visual review in pre-merge checks

**Timing in workflow:**
- **Early:** Define visual identity for new features before implementation
- **Mid:** Polish functional screens that lack visual refinement
- **Late:** Systematic polish pass before milestone releases

### Branch Workflow

```bash
# Create polish branch
git checkout develop
git pull origin develop
git checkout -b ui/polish-recipe-screen

# After completing checkpoints
git add .
git commit -m "ui: polish recipe screen with consistent design tokens

- Define color system with warm primary palette
- Establish typography hierarchy (24sp/18sp/16sp)
- Apply 8px spacing system throughout
- Add subtle elevation to cards
- Improve visual consistency"

# Merge when complete
gh pr create --title "ui: polish recipe screen visual design"
```

### Localization Considerations

When polishing UI:
- Test with both EN and PT-BR text
- Portuguese text often 20-30% longer
- Ensure wrapping works for both languages
- Verify translated text fits in designed spaces
- Consider cultural color meanings (white=mourning in some cultures)

### Testing After Polish

```bash
# Visual regression testing (if tools available)
flutter test --update-goldens  # Update golden image tests

# Manual verification checklist
- [ ] Test on smallest target screen (320px)
- [ ] Test on largest target screen (414px+)
- [ ] Test with longest translated strings
- [ ] Verify touch targets ≥44px
- [ ] Check contrast ratios (WCAG AA)
- [ ] Verify no performance impact

# Automated checks
flutter analyze  # No new warnings
flutter test     # All tests pass
```

---

## Design Token Implementation in Flutter

### Theme Configuration Example

```dart
// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // Color Scheme from Design Tokens
    colorScheme: ColorScheme.light(
      primary: DesignTokens.primaryColor,
      secondary: DesignTokens.accentColor,
      surface: DesignTokens.surfaceColor,
      error: DesignTokens.errorColor,
      // ...
    ),

    // Typography from Design Tokens
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: DesignTokens.displaySize,
        fontWeight: FontWeight.w600,
        height: DesignTokens.tightLineHeight,
      ),
      headlineLarge: TextStyle(
        fontSize: DesignTokens.heading1Size,
        fontWeight: FontWeight.w600,
        height: DesignTokens.tightLineHeight,
      ),
      bodyLarge: TextStyle(
        fontSize: DesignTokens.bodySize,
        fontWeight: FontWeight.normal,
        height: DesignTokens.normalLineHeight,
      ),
      // ...
    ),

    // Card Theme from Design Tokens
    cardTheme: CardTheme(
      elevation: DesignTokens.elevation1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
      ),
    ),

    // Button Theme from Design Tokens
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: DesignTokens.spacingSm,
          horizontal: DesignTokens.spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
        ),
      ),
    ),
  );
}
```

### Design Tokens File Example

```dart
// lib/theme/design_tokens.dart
import 'package:flutter/material.dart';

class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // COLOR SYSTEM
  static const Color primaryColor = Color(0xFFE67E22); // Warm orange
  static const Color primaryDark = Color(0xFFD35400);
  static const Color primaryLight = Color(0xFFF39C12);

  static const Color accentColor = Color(0xFF27AE60); // Fresh green

  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFDEE2E6);

  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled = Color(0xFFADB5BD);

  static const Color successColor = Color(0xFF28A745);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFDC3545);
  static const Color infoColor = Color(0xFF17A2B8);

  // TYPOGRAPHY SYSTEM
  static const double displaySize = 32.0;
  static const double heading1Size = 24.0;
  static const double heading2Size = 20.0;
  static const double heading3Size = 18.0;
  static const double bodyLargeSize = 16.0;
  static const double bodySize = 14.0;
  static const double bodySmallSize = 12.0;
  static const double captionSize = 10.0;

  static const double tightLineHeight = 1.2;
  static const double normalLineHeight = 1.5;
  static const double relaxedLineHeight = 1.8;

  // SPACING SYSTEM (8px base unit)
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
}
```

---

## Common UI Polish Patterns for Gastrobrain

### Recipe Card Styling

```dart
// Well-styled recipe card with design tokens
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  padding: EdgeInsets.all(DesignTokens.spacingMd),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Recipe image if available
      // Recipe title with proper typography
      Text(
        recipe.name,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(height: DesignTokens.spacingSm),
      // Metadata row with icons
      Row(
        children: [
          Icon(Icons.schedule, size: DesignTokens.iconSizeSmall),
          SizedBox(width: DesignTokens.spacingXs),
          Text(
            '${recipe.prepTime} min',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ],
  ),
)
```

### Button Styling Consistency

```dart
// Primary action button
ElevatedButton(
  onPressed: onPressed,
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    padding: EdgeInsets.symmetric(
      vertical: DesignTokens.spacingSm,
      horizontal: DesignTokens.spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
    ),
  ),
  child: Text(AppLocalizations.of(context)!.save),
)

// Secondary action button
OutlinedButton(
  onPressed: onPressed,
  style: OutlinedButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.primary,
    side: BorderSide(
      color: Theme.of(context).colorScheme.primary,
      width: DesignTokens.borderWidthThin,
    ),
    padding: EdgeInsets.symmetric(
      vertical: DesignTokens.spacingSm,
      horizontal: DesignTokens.spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
    ),
  ),
  child: Text(AppLocalizations.of(context)!.cancel),
)
```

### Screen Title Typography

```dart
// Consistent screen title styling
Padding(
  padding: EdgeInsets.all(DesignTokens.spacingMd),
  child: Text(
    AppLocalizations.of(context)!.recipesTitle,
    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onBackground,
    ),
  ),
)
```

---

## Skill Guardrails

### What This Skill DOES

✅ Provide systematic visual refinement process
✅ Define concrete design tokens
✅ Apply consistent styling patterns
✅ Document reusable visual patterns
✅ Balance visual personality with usability
✅ Consider cultural and language factors
✅ Test across screen sizes and contexts

### What This Skill DOES NOT Do

❌ Make changes without user confirmation
❌ Apply arbitrary styling without rationale
❌ Ignore Material Design guidelines
❌ Create visual designs from scratch (not a design tool)
❌ Override functional requirements for aesthetics
❌ Skip accessibility considerations
❌ Ignore localization impacts

---

## Quality Checklist

Before completing polish work, verify:

**Visual Consistency:**
- [ ] Colors used consistently across similar elements
- [ ] Typography hierarchy clear and consistent
- [ ] Spacing follows defined system
- [ ] Component styling patterns applied uniformly

**Design Tokens:**
- [ ] All colors from defined palette
- [ ] All font sizes from type scale
- [ ] All spacing values from spacing system
- [ ] All border radius/shadows from system

**Usability:**
- [ ] Touch targets ≥44px for interactive elements
- [ ] Contrast ratios meet WCAG AA (4.5:1 for text)
- [ ] Visual hierarchy guides user attention appropriately
- [ ] Interactive elements clearly identifiable

**Localization:**
- [ ] Tested with both EN and PT-BR text
- [ ] Layout handles longer Portuguese strings
- [ ] Text wrapping works in both languages
- [ ] Cultural color considerations addressed

**Technical:**
- [ ] flutter analyze passes with no warnings
- [ ] No performance regressions
- [ ] Theme configuration properly used
- [ ] Patterns documented for reuse

**Documentation:**
- [ ] Design tokens documented
- [ ] Component patterns extracted and documented
- [ ] Before/after insights captured
- [ ] Future polish patterns identified

---

## Success Metrics

**The UI polish is successful when:**

- ✅ Visual consistency across similar elements
- ✅ Clear visual hierarchy that guides users
- ✅ App feels designed, not assembled
- ✅ Visual personality aligns with app purpose
- ✅ Design tokens are documented and reusable
- ✅ User confirms improved polish
- ✅ No regressions in functionality or performance
- ✅ Patterns applicable to other screens identified

---

## Common Pitfalls to Avoid

**Visual Design:**
- Mixing too many different styles (pick one personality)
- Arbitrary spacing (use consistent scale)
- Poor typography hierarchy (size differences too subtle)
- Colors without semantic meaning (why this color here?)
- Overusing emphasis (everything bold = nothing bold)

**Technical Implementation:**
- Hardcoding values instead of using theme
- Creating one-off spacing values
- Ignoring responsive design
- Not testing with real content
- Skipping edge cases (long text, empty states)

**Process:**
- Making sweeping changes without checkpoint approval
- Ignoring user feedback on visual preferences
- Copying references exactly without adapting
- Neglecting documentation of patterns
- Not considering localization impact

---

## Version History

**v1.0.0** (2026-01-13)
- Initial skill creation
- 7-checkpoint interactive process
- Design tokens definition methodology
- Flutter implementation patterns
- Gastrobrain-specific guidelines
- Complete examples and documentation

---

## Next Steps After Polish

1. **Apply patterns** to other screens using documented tokens
2. **Update style guide** with new patterns
3. **Extract common components** into reusable widgets
4. **Schedule polish reviews** for each milestone
5. **Gather user feedback** on visual improvements
