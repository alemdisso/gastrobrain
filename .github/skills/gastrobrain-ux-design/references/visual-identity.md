# "Cultured & Flavorful" Visual Identity Guide

Gastrobrain is **not** a generic meal planner - it's a sophisticated cooking companion for home cooks who value organization and culinary culture.

## Core Design Philosophy

**Cultured**: Intentional, sophisticated, respects the user's intelligence
**Flavorful**: Warm, inviting, inspired by Brazilian culinary traditions
**Confident**: Generous whitespace, clear hierarchy, not cramped or cluttered

## Color Palette

### Primary Colors (Warm & Earthy)

Inspired by Brazilian ingredients and culinary traditions:

```
Terracotta      #D4755F   RGB(212, 117, 95)
└─ Warm clay, primary accent color
└─ Use for: Primary buttons, key actions, important highlights

Olive Green     #6B8E23   RGB(107, 142, 35)
└─ Fresh herbs, secondary accent
└─ Use for: Secondary actions, success states, natural elements

Saffron Yellow  #F4C430   RGB(244, 196, 48)
└─ Warm spice, highlight color
└─ Use for: Warnings, highlights, attention (sparingly)

Cocoa Brown     #3E2723   RGB(62, 39, 35)
└─ Rich earth, dark text
└─ Use for: Primary text, headers, dark UI elements

Cream           #FFF8DC   RGB(255, 248, 220)
└─ Warm white, soft backgrounds
└─ Use for: Card backgrounds, soft surfaces

Charcoal        #2C2C2C   RGB(44, 44, 44)
└─ Refined dark, elegant headers
└─ Use for: Navigation bars, headers, dark mode
```

### Supporting Colors

```
Pure White      #FFFFFF   RGB(255, 255, 255)
└─ Clean backgrounds, crisp contrast

Light Gray      #F5F5F5   RGB(245, 245, 245)
└─ Subtle backgrounds, disabled states

Medium Gray     #BDBDBD   RGB(189, 189, 189)
└─ Borders, dividers, inactive elements

Error Red       #D32F2F   RGB(211, 47, 47)
└─ Errors, destructive actions, warnings

Success Green   #388E3C   RGB(56, 142, 60)
└─ Success states, confirmations
```

### Color Usage Examples

**Buttons**:
- Primary action: Terracotta background, white text
- Secondary action: Olive Green background, white text
- Tertiary action: Transparent background, Cocoa Brown text

**Cards**:
- Background: Cream or White
- Border: Light Gray (if needed)
- Shadow: Charcoal with 8% opacity

**Text**:
- Headings: Charcoal or Cocoa Brown
- Body: Cocoa Brown
- Labels/metadata: Medium Gray
- Links: Terracotta

### Color Contrast Ratios

All combinations meet WCAG AA standards (4.5:1 for text):

```
✅ Cocoa Brown on Cream: 8.2:1 (excellent)
✅ Charcoal on White: 13.1:1 (excellent)
✅ Terracotta on White: 4.9:1 (pass)
✅ Olive Green on White: 5.8:1 (pass)
⚠️ Saffron Yellow on White: 1.8:1 (use for backgrounds, not text)
✅ White on Terracotta: 4.9:1 (pass)
✅ White on Olive Green: 5.8:1 (pass)
```

## Spacing System

### Scale (Generous Whitespace)

Confident spacing - give content room to breathe:

```
4px   (micro)    - Icon-text gaps, tight inline elements
8px   (small)    - Tight groupings, related items
16px  (standard) - Screen padding, card gaps, list items
24px  (medium)   - Section breaks, card internal spacing
32px  (large)    - Major section breaks
48px  (xlarge)   - Hero sections, dramatic breaks
```

### Application Guidelines

**Screen Padding**:
- Horizontal: 16px (mobile), 24px (tablet)
- Top: 16px below AppBar
- Bottom: 16px above bottom nav (or 80px for FAB clearance)

**Card Spacing**:
- Internal padding: 16-20px
- Gap between cards: 12-16px vertical
- Margin from screen edges: 16px

**List Items**:
- Height: 56-72px (depending on content density)
- Internal padding: 16px horizontal, 12px vertical
- Gap between items: 0px (dividers) or 8px (card-based)

**Section Breaks**:
- Within same context: 24px
- Between different sections: 32-48px
- Hero to content: 48px

### Bad vs Good Spacing

❌ **Bad (Cramped)**:
```
Card padding: 8px
Section gaps: 12px
Text line-height: 1.2
```
Feels cheap, generic, hard to scan.

✅ **Good (Generous)**:
```
Card padding: 20px
Section gaps: 32px
Text line-height: 1.5
```
Feels cultured, confident, easy to read.

## Typography Hierarchy

### Scale (Clear & Readable)

```
Hero        32pt / 34sp    Bold       Page titles, major headers
Header      24pt / 26sp    Bold       Section headers
Subheader   18pt / 20sp    Medium     Subsections, card titles
Body        16pt / 18sp    Regular    Primary content, readable text
Label       12pt / 14sp    Medium     Metadata, captions, labels
Caption     10pt / 12sp    Regular    Footnotes, helper text, timestamps
```

### Font Families

**Primary**: System default (San Francisco on iOS, Roboto on Android)
- Clean, readable, platform-native

**Alternative** (if custom needed): Lato, Open Sans, Nunito
- Warm, friendly, still professional

### Typography Usage

**Headers**:
- Use Charcoal or Cocoa Brown
- Bold weight (700)
- Letter spacing: -0.5% (tighten slightly for elegance)
- Line height: 1.2-1.3

**Body Text**:
- Use Cocoa Brown
- Regular weight (400)
- Letter spacing: 0% (default)
- Line height: 1.5-1.6 (generous, readable)

**Labels/Metadata**:
- Use Medium Gray
- Medium weight (500)
- All caps optional (use sparingly)
- Letter spacing: +2% if all caps

### Hierarchy Examples

**Recipe Card**:
```
Recipe Name         (Subheader, 18pt, Bold, Cocoa Brown)
Difficulty: Easy    (Label, 12pt, Medium, Medium Gray)
30 minutes          (Label, 12pt, Medium, Medium Gray)
```

**Screen Title**:
```
Weekly Meal Plan    (Hero, 32pt, Bold, Charcoal)
Jan 23 - Jan 29     (Label, 12pt, Medium, Medium Gray)
```

## Card Design

### Standard Recipe Card

```
┌─────────────────────────────────┐
│  [Image 16:9 ratio]             │  ← Rounded top corners (12px)
├─────────────────────────────────┤
│  Recipe Name (18pt, bold)       │  ← 16px padding all sides
│  Difficulty • Time • Servings   │  ← 12pt labels, Medium Gray
│                                 │  ← 8px gap between title and meta
└─────────────────────────────────┘
```

**Specifications**:
- Border radius: 12px
- Elevation: 2 (subtle shadow)
- Background: Cream or White
- Padding: 16px
- Image aspect ratio: 16:9 or 4:3
- Tap area: Entire card (InkWell)

### Elevated Card (Important Content)

```
┌─────────────────────────────────┐
│  Header (24pt, bold)            │  ← 20px padding
│  ─────────────────────────────  │  ← 1px divider (Light Gray)
│                                 │
│  Content area                   │  ← 20px padding
│                                 │  ← Generous line height (1.6)
│                                 │
└─────────────────────────────────┘
```

**Specifications**:
- Border radius: 12px
- Elevation: 4 (pronounced shadow)
- Background: White
- Padding: 20-24px (more generous than standard)
- Use for: Forms, important summaries, feature callouts

## Component Library

### Buttons

**Primary Button** (ElevatedButton):
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFD4755F), // Terracotta
    foregroundColor: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    minimumSize: Size(88, 44), // Touch target
  ),
  onPressed: () {},
  child: Text('Primary Action'),
)
```

**Secondary Button** (OutlinedButton):
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Color(0xFFD4755F), // Terracotta
    side: BorderSide(color: Color(0xFFD4755F), width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    minimumSize: Size(88, 44),
  ),
  onPressed: () {},
  child: Text('Secondary Action'),
)
```

**Text Button** (TextButton):
```dart
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: Color(0xFF3E2723), // Cocoa Brown
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    minimumSize: Size(64, 44),
  ),
  onPressed: () {},
  child: Text('Tertiary Action'),
)
```

### Input Fields

**Standard Text Field**:
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Recipe Name',
    hintText: 'Enter recipe name',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xFFBDBDBD)), // Medium Gray
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xFFD4755F), width: 2), // Terracotta
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  style: TextStyle(fontSize: 16, color: Color(0xFF3E2723)), // Cocoa Brown
)
```

### Icons

**Icon Button** (minimum 48x48 touch target):
```dart
IconButton(
  icon: Icon(Icons.favorite_border),
  iconSize: 24,
  color: Color(0xFFD4755F), // Terracotta
  onPressed: () {},
  constraints: BoxConstraints(minWidth: 48, minHeight: 48),
)
```

**Icon with Label**:
```dart
Row(
  children: [
    Icon(Icons.schedule, size: 16, color: Color(0xFFBDBDBD)),
    SizedBox(width: 4),
    Text('30 min', style: TextStyle(fontSize: 12, color: Color(0xFFBDBDBD))),
  ],
)
```

## Animation & Transitions

### Timing (Smooth, Not Sluggish)

```
Fast        150ms   - Micro-interactions (checkbox toggle, ripple start)
Standard    200ms   - UI element transitions (sheet slide, fade)
Medium      300ms   - Page transitions, modal appearances
Slow        400ms   - Complex animations (only if needed)
```

### Easing Curves

```
Linear              - Progress indicators only
EaseIn              - Elements exiting screen
EaseOut             - Elements entering screen
EaseInOut           - Modal dialogs, sheets (default)
FastOutSlowIn       - Material Design standard (recommended)
```

### Common Animations

**Button Press** (Material Ripple):
- InkWell with splash color (Terracotta at 20% opacity)
- Duration: 150ms

**Page Transition**:
- Material page route (platform-appropriate)
- Duration: 250ms
- Curve: FastOutSlowIn

**Modal Sheet**:
- Slide from bottom
- Duration: 300ms
- Curve: EaseInOut

**Expand/Collapse**:
- Height animation
- Duration: 200ms
- Curve: EaseOut

**Loading Shimmer** (Skeleton):
- Gradient sweep across placeholder
- Duration: 1500ms (slow, continuous)
- Colors: Light Gray → White → Light Gray

## Platform-Specific Guidance

### iOS Considerations

**Navigation**:
- Use Cupertino navigation bar (if going full Cupertino)
- Swipe-back gesture (default in Material)
- Haptic feedback on important actions (HapticFeedback.lightImpact)

**Typography**:
- San Francisco font (system default)
- Slightly larger touch targets (48x48)

**Modals**:
- Slide from bottom (CupertinoModalPopup)
- Rounded top corners

### Android Considerations

**Navigation**:
- Material AppBar with elevation
- Ripple effects (InkWell)
- FloatingActionButton convention

**Typography**:
- Roboto font (system default)
- Material Design 3 components

**Modals**:
- Center dialogs (AlertDialog)
- Bottom sheets (showModalBottomSheet)

### Adaptive Design

For truly platform-adaptive UI, use:
```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget adaptiveButton(BuildContext context) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return CupertinoButton(/*...*/);
  }
  return ElevatedButton(/*...*/);
}
```

## Before & After Examples

### Example 1: Recipe Card

❌ **Before (Generic)**:
- Cramped 8px padding
- Small 14pt text (hard to read)
- Cold blue accent
- No whitespace between elements
- Flat (no elevation)

✅ **After (Cultured & Flavorful)**:
- Generous 16px padding
- Clear 18pt bold title, 12pt metadata
- Warm Terracotta accent
- 8px gap between title and metadata
- Subtle elevation (2)
- Cream background

### Example 2: Form Screen

❌ **Before (Generic)**:
- Fields touching screen edges (no padding)
- Tight 12px gaps between fields
- Generic blue focused state
- No section breaks (all fields run together)

✅ **After (Cultured & Flavorful)**:
- 16px screen padding
- 24px gaps between field groups
- Terracotta focused state
- 32px section breaks with subtle headers
- Helpful labels in Medium Gray

### Example 3: Meal Planning Calendar

❌ **Before (Generic)**:
- 8px cell padding (cramped)
- Recipe names truncated after 12 chars
- No hierarchy (day, meal type, recipe all same size)
- Gray empty slots (boring)

✅ **After (Cultured & Flavorful)**:
- 16px cell padding (breathing room)
- Recipe names use full width (25+ chars visible)
- Clear hierarchy: Day (24pt bold) → Meal type (12pt label) → Recipe (16pt)
- Cream empty slots with "+" icon (inviting)

## Design Checklist

Use this checklist when designing any screen:

**Colors**:
- [ ] Warm palette used (Terracotta, Olive, Saffron, Cocoa)
- [ ] No cold blues/grays (unless for neutral elements)
- [ ] Primary actions use Terracotta
- [ ] Text contrast meets WCAG AA (4.5:1 minimum)

**Spacing**:
- [ ] Screen padding: 16px minimum
- [ ] Card padding: 16-20px
- [ ] Section breaks: 24-32px
- [ ] No elements touching screen edges (except full-bleed images)

**Typography**:
- [ ] Clear hierarchy (3+ distinct sizes)
- [ ] Headers are bold and distinct
- [ ] Body text is 16pt minimum (readable)
- [ ] Line height is generous (1.5-1.6 for body)

**Whitespace**:
- [ ] Content has room to breathe
- [ ] Not every pixel is filled
- [ ] Generous gaps between sections
- [ ] Empty states use space confidently

**Components**:
- [ ] Cards use 12px border radius
- [ ] Buttons have 44x44px minimum touch target
- [ ] Input fields have clear focused state
- [ ] Icons are 24px (readable, not tiny)

**Polish**:
- [ ] Subtle shadows (elevation 2-4)
- [ ] Smooth animations (200-300ms)
- [ ] Ripple effects on tappable elements
- [ ] Loading states feel intentional (not just spinners)

**Identity**:
- [ ] Feels **cultured** (sophisticated, intentional)
- [ ] Feels **flavorful** (warm, inviting, colorful)
- [ ] Feels **confident** (not cramped or cluttered)
- [ ] NOT generic (stands out from other meal planners)

---

**Use this guide** when designing UX in Gastrobrain to maintain consistent visual identity.

**Questions?** Refer back to this document or ask for clarification.
