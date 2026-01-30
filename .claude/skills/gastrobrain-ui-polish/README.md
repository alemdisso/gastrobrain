# Gastrobrain UI Styling & Visual Polish Skill

Transform functional but unpolished UI into cohesive, well-designed interfaces through a systematic 7-checkpoint process.

## Quick Start

**Trigger the skill with:**
- "Polish the UI for [screen/component]"
- "Help me style [feature]"
- "This screen feels unfinished visually"
- "Define visual design for the app"

**The skill will guide you through 7 checkpoints to systematically refine your UI.**

## What This Skill Does

✅ **Analyzes current visual state** and identifies specific gaps
✅ **Defines visual identity** for the app/feature
✅ **Creates design tokens** (colors, typography, spacing, components)
✅ **Plans systematic application** of visual improvements
✅ **Implements changes** with Flutter best practices
✅ **Refines through iteration** based on visual review
✅ **Documents patterns** for future reuse

## The 7-Checkpoint Process

```
1. Visual Analysis
   └─ Identify current state and visual gaps
   └─ WAIT for user confirmation

2. Identity Definition (if needed)
   └─ Define visual personality (3-5 adjectives)
   └─ WAIT for user approval

3. Design Tokens Definition
   └─ Create color, typography, spacing, component tokens
   └─ WAIT for user confirmation

4. Application Plan
   └─ Map UI elements to design tokens
   └─ Prioritize changes by visual impact
   └─ WAIT for user approval

5. Implementation
   └─ Apply visual improvements through code
   └─ Test across screen sizes
   └─ WAIT for user verification

6. Refinement Iteration
   └─ Polish based on visual review
   └─ Address edge cases
   └─ WAIT for user confirmation

7. Pattern Documentation
   └─ Document tokens and patterns
   └─ Capture insights for future use
   └─ WAIT for final approval
```

## When to Use This Skill

| Scenario | When | Example |
|----------|------|---------|
| **New Feature Polish** | After functionality works | Recipe screen works but looks generic |
| **Visual Consistency** | Multiple screens feel different | Each developer used different styles |
| **Brand Identity** | Need to establish personality | App uses Material defaults |
| **Pre-Release** | Preparing for production | Beta feedback: looks unfinished |
| **Component Styling** | Individual widget needs polish | Button styles inconsistent |
| **Design System** | Building reusable patterns | Want consistent visual language |

## Design Tokens Created

The skill helps you define:

### Color System
- Primary colors (brand identity)
- Secondary/accent colors (calls to action)
- Neutral palette (backgrounds, borders)
- Text colors (primary, secondary, disabled)
- Semantic colors (success, warning, error, info)

### Typography System
- Font family (with fallbacks)
- Size scale (display → caption)
- Weight scale (regular → bold)
- Line height standards

### Spacing System
- Base unit (4px or 8px)
- Spacing scale (xxs → xxl)
- Component padding standards

### Component Styling
- Border radius values
- Elevation/shadow system
- Border widths
- Icon sizing

## Example: Polishing Recipe Screen

### Before (Checkpoint 1: Analysis)
```
Issues Identified:
- Generic Material blue doesn't match food theme
- All text same size (no hierarchy)
- Inconsistent card styling
- Arbitrary spacing values
- No brand personality
```

### After (Checkpoint 7: Complete)
```
Improvements Applied:
- Warm orange primary color (food-appropriate)
- Clear typography hierarchy (24sp/18sp/16sp)
- Consistent card styling with subtle shadows
- 8px spacing system throughout
- Warm, organized, trustworthy personality
```

**Result:** Professional, cohesive UI that feels designed for meal planning.

## Flutter Implementation

The skill generates Flutter code following best practices:

### Theme Configuration
```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: DesignTokens.primaryColor,
    // ...
  ),
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontSize: DesignTokens.heading1Size,
      fontWeight: FontWeight.w600,
    ),
    // ...
  ),
)
```

### Design Tokens File
```dart
class DesignTokens {
  // Colors
  static const Color primaryColor = Color(0xFFE67E22);

  // Typography
  static const double heading1Size = 24.0;

  // Spacing
  static const double spacingMd = 16.0;

  // Components
  static const double borderRadiusMedium = 12.0;
}
```

### Component Usage
```dart
// Using design tokens
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(
      DesignTokens.borderRadiusMedium,
    ),
  ),
  padding: EdgeInsets.all(DesignTokens.spacingMd),
  child: Text(
    title,
    style: Theme.of(context).textTheme.headlineLarge,
  ),
)
```

## Integration with Gastrobrain

### Localization Considerations
- Tests with both EN and PT-BR text
- Portuguese text 20-30% longer
- Verifies wrapping works for both languages
- Considers cultural color meanings

### Testing Requirements
- Multiple screen sizes (320px → 414px+)
- Long text handling
- Touch targets ≥44px
- Contrast ratios (WCAG AA)
- No performance regressions

### Branch Workflow
```bash
# Create polish branch
git checkout -b ui/polish-recipe-screen

# After completing checkpoints
git commit -m "ui: polish recipe screen with consistent design tokens"

# Create PR
gh pr create --title "ui: polish recipe screen visual design"
```

## Common Polish Patterns

### Recipe Cards
- Warm surface color
- Subtle elevation (2-4px shadow)
- 12px border radius
- 16px padding
- Clear typography hierarchy

### Buttons
- Primary: Filled with primary color
- Secondary: Outlined with primary color
- Consistent padding (8px vertical, 16px horizontal)
- 8px border radius
- Medium font weight

### Screen Titles
- 24sp heading size
- Semibold weight
- Primary text color
- 16px padding around

### Spacing
- Base unit: 8px
- Card margins: 16px
- Section spacing: 24px
- Screen padding: 16px

## Quality Checklist

Before completing polish work:

**Visual:**
- [ ] Consistent colors across similar elements
- [ ] Clear typography hierarchy
- [ ] Systematic spacing (no arbitrary values)
- [ ] Unified component styling

**Usability:**
- [ ] Touch targets ≥44px
- [ ] Contrast ratios meet WCAG AA
- [ ] Visual hierarchy guides attention
- [ ] Interactive elements clearly identifiable

**Technical:**
- [ ] flutter analyze passes
- [ ] No performance regressions
- [ ] Theme properly used
- [ ] Patterns documented

**Localization:**
- [ ] Tested with EN and PT-BR
- [ ] Handles longer Portuguese strings
- [ ] Text wrapping works in both languages

## Outputs

After completing the 7 checkpoints:

1. **Polished UI** - Visually refined screens/components
2. **Design Tokens** - Documented color, typography, spacing system
3. **Theme Configuration** - Flutter theme properly configured
4. **Component Patterns** - Reusable styling patterns extracted
5. **Implementation Guide** - Documentation for applying patterns elsewhere
6. **Before/After Insights** - Lessons learned captured

## Success Metrics

Polish is successful when:
- ✅ Visual consistency across similar elements
- ✅ Clear hierarchy guides users
- ✅ App feels designed, not assembled
- ✅ Visual personality matches app purpose
- ✅ Patterns are documented and reusable
- ✅ User confirms improved polish
- ✅ No functional or performance regressions

## Common Pitfalls to Avoid

**Don't:**
- Mix too many visual styles
- Use arbitrary spacing values
- Make size differences too subtle
- Overuse bold/emphasis
- Skip responsive testing
- Forget about localization
- Make changes without user approval

**Do:**
- Use consistent design tokens
- Create clear visual hierarchy
- Test with real content
- Consider both languages
- Document patterns for reuse
- Follow checkpoint process

## Tips for Success

1. **Start with analysis** - Understand what's wrong before fixing
2. **Define personality first** - Visual choices should reflect identity
3. **Create tokens systematically** - Don't skip the token definition
4. **Prioritize impact** - Fix most visible issues first
5. **Test thoroughly** - Multiple sizes, languages, edge cases
6. **Document patterns** - Make polish work reusable

## Examples

See `examples/` directory for complete walkthroughs:
- `recipe_screen_polish.md` - Full polish process for recipe list
- `button_consistency.md` - Standardizing button styles
- `design_tokens_example.md` - Complete design tokens document

## Version History

**v1.0.0** (2026-01-13)
- Initial release
- 7-checkpoint systematic process
- Design tokens methodology
- Flutter implementation patterns
- Gastrobrain-specific guidelines

---

## Getting Help

**Documentation:**
- Read `SKILL.md` for complete details
- Check `examples/` for walkthroughs
- Review design tokens template

**Feedback:**
- Issues with skill: Create issue with `skill:ui-polish` label
- Suggestions: Add `enhancement` label

---

Transform your functional UI into polished, professional interfaces with systematic visual refinement! 🎨
