---
name: "Gastrobrain UX Design"
description: "User experience design specialist for Gastrobrain. Analyzes user goals, maps flows, designs information architecture, creates wireframes, and ensures accessibility before implementation. Reinforces 'Cultured & Flavorful' design identity. Use when: 'Design the UX for #XXX', 'Help me redesign [screen]', 'What should the user flow be?', 'I need wireframes for #XXX', 'Think through the information architecture'."
version: "1.0.0"
author: "Gastrobrain Development Team"
---

# Gastrobrain UX Design

A specialized skill for user experience design work in the Gastrobrain Flutter application. Acts as a UX specialist who thinks through user flows, information architecture, and interface semantics **before** implementation begins.

## When to Use This Skill

### Trigger Patterns

Use this skill when the user says:
- "Design the UX for #XXX"
- "Help me redesign [screen name]"
- "What should the user flow be for [feature]?"
- "I need wireframes for #XXX"
- "Help me think through the information architecture"
- "How should this feature work from a UX perspective?"
- "Plan the user experience for #XXX"

### Workflow Position

```
Issue Roadmap → UX Design → UI Component Implementation
```

This skill sits **between** planning and coding:
- **After Issue Roadmap**: You know WHAT to build
- **Before UI Component Implementation**: You design HOW users will experience it

### Automatic Actions

When triggered:
1. **Fetch issue details** if GitHub issue number provided
2. **Analyze user goals** and context
3. **Guide through 6 checkpoints** one at a time
4. **Generate design artifacts** at each checkpoint
5. **Wait for user confirmation** before proceeding

### Do NOT Use This Skill

- ❌ For writing actual Flutter widget code (use `gastrobrain-ui-component` instead)
- ❌ For applying styling/colors (use `gastrobrain-ui-polish` instead)
- ❌ For writing tests (use `gastrobrain-testing-implementation` instead)
- ✅ **Focus on conceptual design** before implementation

## Project Context

### Development Environment
- **Project**: Gastrobrain - Flutter meal planning & recipe management app
- **Platform**: Mobile-first (iOS, Android) with responsive layouts
- **Localization**: Bilingual (English, Portuguese-BR)
- **Users**: Home cooks who want organized, cultured meal planning
- **Design Identity**: "Cultured & Flavorful" (see Visual Identity section)

### Design Principles

#### "Cultured & Flavorful" Identity
Gastrobrain is **not** a generic meal planner - it's a sophisticated cooking companion.

**Core attributes**:
- **Warm & earthy**: Inspired by Brazilian ingredients (vibrant but grounded)
- **Generous whitespace**: Confident, not cramped (like a well-plated dish)
- **Clear hierarchy**: Cultured typography, intentional information design
- **Inviting but confident**: Welcoming to novices, respected by experienced cooks

**Visual language**:
- **Colors**: Warm terracotta, olive green, saffron yellow, cocoa brown
- **Spacing**: 16-24px standard gaps, 32-48px section breaks
- **Typography**: Clear hierarchy (24pt headers → 16pt body → 12pt labels)
- **Cards**: Elevated, rounded corners (8-12px radius), subtle shadows

#### Mobile-First Considerations
- **Touch targets**: Minimum 44x44px (iOS HIG standard)
- **Thumb zones**: Primary actions within bottom 2/3 of screen
- **One-handed use**: Critical paths accessible with thumb reach
- **Responsive**: Graceful layout shifts for tablets

#### Accessibility Standards
- **Screen reader support**: Semantic widgets, meaningful labels
- **Color contrast**: WCAG AA minimum (4.5:1 for text)
- **Touch targets**: No overlapping, clear spacing
- **Error states**: Visual + text feedback (not color alone)

## UX Design Process (6 Checkpoints)

Follow this systematic approach - **one checkpoint at a time, wait for user confirmation**.

---

### CHECKPOINT 1/6: Goal & Context Analysis

**Purpose**: Understand the user problem and define success criteria

**Tasks**:
- [ ] Fetch issue details (if GitHub issue provided)
- [ ] Identify user goals (what are they trying to accomplish?)
- [ ] Identify pain points (what's frustrating about current state?)
- [ ] Define success criteria (how do we know this works?)
- [ ] Clarify scope (is this a new feature or redesign?)

**Questions to answer**:
1. **Who** is the primary user for this feature?
2. **What** problem does this solve for them?
3. **Why** is this important (user value)?
4. **When/where** will they use this (context)?
5. **How** will we measure success?

**Artifact to produce**:
```markdown
## Goal & Context

**User Goal**: [2-3 sentence description of what users want to accomplish]

**Pain Point**: [What's frustrating about the current experience, or what's missing?]

**Success Criteria**:
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

**Scope**: [New feature / Redesign of [screen name] / Enhancement to [feature]]
```

**Verification**:
- User goals are specific and actionable (not vague)
- Success criteria are measurable
- Scope is clear and bounded

**Ready to proceed to Checkpoint 2? (y/n)**

---

### CHECKPOINT 2/6: Current State Assessment

**Purpose**: Understand what exists and what works/doesn't work

**When to run**:
- ✅ If redesigning existing screen/feature
- ❌ Skip if building net-new feature (proceed to Checkpoint 3)

**Tasks**:
- [ ] Review existing implementation (read current code if needed)
- [ ] Identify what works well (preserve these patterns)
- [ ] Identify what doesn't work (specific issues)
- [ ] Note design patterns to maintain for consistency
- [ ] Identify breaking changes vs. evolutionary improvements

**Questions to answer**:
1. What exists today in terms of UI/flow?
2. What do users currently like about it?
3. What specific problems need fixing?
4. What patterns should we preserve for consistency?
5. Is this evolutionary improvement or radical redesign?

**Artifact to produce**:
```markdown
## Current State Assessment

**What exists**: [Brief description of current implementation]

**What works** ✅:
- [Pattern/element to preserve]
- [Pattern/element to preserve]

**What doesn't work** ❌:
- [Specific problem 1]
- [Specific problem 2]
- [Specific problem 3]

**Design patterns to maintain**:
- [Pattern from elsewhere in app that should be consistent]
- [Interaction convention to follow]

**Approach**: [Evolutionary improvement / Radical redesign / Hybrid]
```

**Verification**:
- Specific problems identified (not vague complaints)
- Good patterns identified for preservation
- Clear sense of change magnitude

**Ready to proceed to Checkpoint 3? (y/n)**

---

### CHECKPOINT 3/6: User Flow Mapping

**Purpose**: Map the step-by-step user journey through the feature

**Tasks**:
- [ ] Map primary user flow (happy path)
- [ ] Identify decision points and branches
- [ ] Map error paths (what if something fails?)
- [ ] Map edge cases (empty states, first-time use, etc.)
- [ ] Identify entry points (how users reach this feature)
- [ ] Identify exit points (where users go after)

**Questions to answer**:
1. What's the step-by-step journey for the primary use case?
2. Where do users make decisions (branches)?
3. What happens if data is empty/missing?
4. What happens if actions fail?
5. How do users enter and exit this flow?

**Artifact to produce**:
```markdown
## User Flow Map

**Primary Flow** (Happy Path):
1. [Entry point] User navigates from [screen/action]
2. [Step 1] User sees [screen/state]
3. [Step 2] User interacts with [element]
4. [Step 3] System responds with [feedback]
5. [Exit point] User proceeds to [screen/action]

**Decision Points**:
- **At step [X]**: If [condition], then [branch A], else [branch B]
- **At step [Y]**: User chooses between [option 1] / [option 2] / [option 3]

**Error Paths**:
- **If [error type]**: Show [error message], allow [recovery action]
- **If [validation fails]**: Highlight [field], show [inline error]

**Edge Cases**:
- **Empty state**: [What user sees with no data]
- **First-time use**: [Any onboarding or guidance]
- **Loading state**: [What displays during data fetch]
- **Offline**: [Behavior if no network - if applicable]

**Navigation**:
- **Entry**: [How users reach this feature]
- **Exit**: [Where users go when done]
```

**Verification**:
- Primary flow is clear and logical
- All decision points identified
- Error handling considered
- Edge cases mapped

**Ready to proceed to Checkpoint 4? (y/n)**

---

### CHECKPOINT 4/6: Information Architecture

**Purpose**: Define content hierarchy and organization

**Tasks**:
- [ ] Identify all content elements needed on screen
- [ ] Establish hierarchy (primary/secondary/tertiary)
- [ ] Group related elements logically
- [ ] Decide what's visible vs. hidden (progressive disclosure)
- [ ] Check alignment with "Cultured & Flavorful" identity
- [ ] Ensure content supports user goals (remove unnecessary elements)

**Questions to answer**:
1. What information does the user need to see?
2. What's the most important element? (primary focus)
3. What's supporting context? (secondary elements)
4. What can be hidden until needed? (progressive disclosure)
5. Does this feel *cultured* or generic?

**Design identity check**:
- ❓ Is there **generous whitespace** or does it feel cramped?
- ❓ Is the **hierarchy clear** or does everything compete for attention?
- ❓ Does it feel **warm and inviting** or clinical?
- ❓ Would a sophisticated home cook **respect** this interface?

**Artifact to produce**:
```markdown
## Information Architecture

**Content Inventory** (all elements needed):
- [Element 1]
- [Element 2]
- [Element 3]
- ...

**Hierarchy**:

**Primary** (main focus, largest/boldest):
- [Primary element - what user came here for]

**Secondary** (supporting context, medium emphasis):
- [Supporting element 1]
- [Supporting element 2]

**Tertiary** (metadata, subtle):
- [Label/metadata 1]
- [Label/metadata 2]

**Progressive Disclosure**:
- **Hidden until needed**: [Collapsed sections, overflow menus, etc.]
- **Revealed on interaction**: [Expandable details, tooltips, etc.]

**Grouping**:
- **Group 1 - [Name]**: [Elements that belong together]
- **Group 2 - [Name]**: [Elements that belong together]

**Visual Identity Check** ✓:
- [X] Generous whitespace (not cramped)
- [X] Clear hierarchy (primary element stands out)
- [X] Warm & inviting (not clinical)
- [X] Cultured feel (sophisticated, intentional)
```

**Verification**:
- Clear hierarchy (not everything equal importance)
- Content supports user goals (no fluff)
- Logical grouping
- Feels "Cultured & Flavorful" (not generic)

**Ready to proceed to Checkpoint 5? (y/n)**

---

### CHECKPOINT 5/6: Wireframe & Interaction Design

**Purpose**: Define screen structure and interaction behavior

**Tasks**:
- [ ] Create wireframe representation (ASCII art or detailed text description)
- [ ] Specify component types (buttons, cards, lists, inputs, etc.)
- [ ] Define spacing and visual rhythm
- [ ] Map tap targets and gestures
- [ ] Specify transitions and feedback
- [ ] Define loading and error states visually

**Wireframe representation options**:
1. **ASCII art** - Quick visual sketch using text characters
2. **Detailed text description** - Layer-by-layer layout description
3. **Hybrid** - ASCII for structure + text for details

**Questions to answer**:
1. What's the overall layout structure?
2. What Flutter components are best for each element?
3. How does spacing create visual rhythm?
4. What happens when user taps/swipes/long-presses?
5. What visual feedback confirms actions?

**Artifact to produce**:
```markdown
## Wireframe & Interaction Design

**Layout Structure** (ASCII wireframe):

```
┌─────────────────────────────────────┐
│  [AppBar with title and actions]    │  ← 56px height
├─────────────────────────────────────┤
│                                     │  ← 16px padding
│  ┌───────────────────────────────┐  │
│  │  [Primary content card]       │  │  ← Elevated card
│  │  • Element 1 (24pt bold)      │  │
│  │  • Element 2 (16pt regular)   │  │  ← 12px internal padding
│  │  • Element 3 (12pt subtle)    │  │
│  └───────────────────────────────┘  │
│                                     │  ← 24px gap
│  ┌───────────────────────────────┐  │
│  │  [Secondary content]          │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Floating Action Button]           │  ← Bottom-right, 16px margin
└─────────────────────────────────────┘
```

**Component Specifications**:
- **AppBar**: Standard Material AppBar, title + actions
- **Primary card**: Card widget, 12px radius, elevation 2
- **List items**: ListTile widgets with InkWell (ripple effect)
- **FAB**: FloatingActionButton, 56x56px (standard)
- **Input fields**: TextFormField with validation

**Spacing & Rhythm**:
- **Screen padding**: 16px horizontal, 16px top
- **Card spacing**: 24px vertical gaps between cards
- **Internal padding**: 12-16px within cards
- **Section breaks**: 32px for major sections

**Interaction Patterns**:

**Tap targets**:
- **Primary button**: 48x48px minimum (Material standard)
- **List items**: Full-width, 56-72px height
- **Icon buttons**: 48x48px tap area
- **FAB**: 56x56px (standard)

**Gestures**:
- **Tap**: [Element] → [Action/navigation]
- **Long-press**: [Element] → [Context menu/details]
- **Swipe**: [If applicable - e.g., dismiss, delete]
- **Pull-to-refresh**: [If list/feed]

**Transitions**:
- **Navigation**: Material page route (slide-up on iOS, slide-left on Android)
- **Dialogs**: Fade-in with scale animation
- **Expanding sections**: Smooth height animation (200ms)
- **Loading**: Skeleton shimmer or circular progress indicator

**Feedback**:
- **Button press**: Ripple effect (InkWell)
- **Form validation**: Inline error text (red, below field)
- **Success**: SnackBar with checkmark icon
- **Error**: SnackBar with error icon + message
- **Loading**: CircularProgressIndicator or shimmer placeholder

**State Variations**:
- **Empty state**: [Illustration + message + action button]
- **Loading state**: [Skeleton shimmer / spinner]
- **Error state**: [Error icon + message + retry button]
- **Success state**: [Confirmation message + next action]
```

**Verification**:
- Layout structure is clear
- Component choices are appropriate for Flutter
- Spacing follows "generous whitespace" principle
- All interactions have clear feedback
- Touch targets meet 44x44px minimum

**Ready to proceed to Checkpoint 6? (y/n)**

---

### CHECKPOINT 6/6: Accessibility & Handoff

**Purpose**: Ensure accessibility and summarize all artifacts for implementation

**Tasks**:
- [ ] Verify screen reader compatibility (semantic widgets)
- [ ] Check color contrast (text readability)
- [ ] Verify touch target sizes (minimum 44x44px)
- [ ] Check semantic ordering (logical focus flow)
- [ ] Ensure error states use text + visual (not color alone)
- [ ] Summarize all design artifacts
- [ ] Create handoff checklist for implementation

**Accessibility checklist**:
- [ ] **Semantic widgets**: Use Text, Button, etc. (not just Containers)
- [ ] **Labels**: All interactive elements have semantic labels
- [ ] **Focus order**: Logical tab/focus flow
- [ ] **Color contrast**: 4.5:1 for text, 3:1 for large text/icons
- [ ] **Touch targets**: 44x44px minimum (iOS HIG standard)
- [ ] **Error feedback**: Text description + visual indicator
- [ ] **Loading states**: Announce to screen reader
- [ ] **Localization**: All strings in ARB files (not hardcoded)

**Artifact to produce**:
```markdown
## Accessibility Review

**Screen Reader Compatibility** ✓:
- [ ] All buttons use semantic widgets (ElevatedButton, TextButton, etc.)
- [ ] All images have Semantics labels
- [ ] Form fields have clear labels
- [ ] Error messages are announced
- [ ] Loading states are announced

**Color Contrast** ✓:
- [ ] Body text: [Color] on [Background] = [Ratio] (min 4.5:1)
- [ ] Headers: [Color] on [Background] = [Ratio] (min 4.5:1)
- [ ] Icons: [Color] on [Background] = [Ratio] (min 3:1)
- [ ] Error text: [Color] on [Background] = [Ratio] (min 4.5:1)

**Touch Targets** ✓:
- [ ] Primary button: [Size] (min 44x44px)
- [ ] Icon buttons: [Size] (min 44x44px)
- [ ] List items: [Height] (min 44px)
- [ ] No overlapping tap areas

**Semantic Ordering** ✓:
- [ ] Focus flows logically (top → bottom, left → right)
- [ ] TabIndex specified if needed for custom order
- [ ] No focus traps (user can navigate away)

**Error Handling** ✓:
- [ ] Errors use text + color (not color alone)
- [ ] Inline validation messages below fields
- [ ] SnackBar errors include icon + text
- [ ] Recovery actions clearly labeled

**Localization** ✓:
- [ ] No hardcoded strings in UI
- [ ] All strings in app_en.arb and app_pt.arb
- [ ] Layout tested with longer Portuguese strings
- [ ] Date/number formatting uses locale-aware helpers

---

## Design Artifacts Summary

All artifacts generated during UX design process:

1. **Goal & Context** (Checkpoint 1)
2. **Current State Assessment** (Checkpoint 2) - if applicable
3. **User Flow Map** (Checkpoint 3)
4. **Information Architecture** (Checkpoint 4)
5. **Wireframe & Interaction Design** (Checkpoint 5)
6. **Accessibility Review** (Checkpoint 6)

---

## Handoff Checklist for Implementation

Pass these to **UI Component Implementation** skill:

**Design decisions**:
- [ ] User goals and success criteria defined
- [ ] User flow mapped (happy path + errors + edge cases)
- [ ] Information hierarchy established
- [ ] Wireframe structure approved
- [ ] Interaction patterns specified
- [ ] Accessibility requirements documented

**Implementation guidance**:
- [ ] Flutter component types identified
- [ ] Spacing values specified
- [ ] Interaction behaviors defined
- [ ] State variations mapped (empty, loading, error, success)
- [ ] Localization needs identified

**Next steps**:
1. Implement UI components using wireframe structure
2. Apply "Cultured & Flavorful" styling (use `gastrobrain-ui-polish` if needed)
3. Implement tests (use `gastrobrain-testing-implementation`)
4. Validate with real users

---

**UX Design Complete** ✅
Ready to proceed to implementation? (y/n)
```

**Verification**:
- All accessibility criteria met
- All design artifacts complete
- Clear handoff to implementation

**UX Design skill complete** - ready for implementation phase.

---

## Visual Identity Reference

### "Cultured & Flavorful" Design Language

**NOT** a generic meal planner - Gastrobrain is a sophisticated cooking companion.

#### Color Palette (Warm & Earthy)
Inspired by Brazilian ingredients:
- **Terracotta**: #D4755F (warm clay, primary accent)
- **Olive Green**: #6B8E23 (fresh herbs, secondary accent)
- **Saffron Yellow**: #F4C430 (warm spice, highlights)
- **Cocoa Brown**: #3E2723 (rich earth, dark text)
- **Cream**: #FFF8DC (warm white, backgrounds)
- **Charcoal**: #2C2C2C (refined dark, headers)

#### Spacing System (Generous Whitespace)
Confident, not cramped - like a well-plated dish:
- **Micro**: 4px (icon-text gaps)
- **Small**: 8px (tight groupings)
- **Standard**: 16px (screen padding, card gaps)
- **Medium**: 24px (section breaks)
- **Large**: 32px (major section breaks)
- **XLarge**: 48px (hero sections)

#### Typography Hierarchy (Clear & Cultured)
- **Hero**: 32pt, bold (page titles, major headers)
- **Header**: 24pt, bold (section headers)
- **Subheader**: 18pt, medium (subsections)
- **Body**: 16pt, regular (primary content)
- **Label**: 12pt, medium (metadata, captions)
- **Caption**: 10pt, regular (footnotes, helper text)

#### Card Design (Elevated & Inviting)
- **Border radius**: 12px (friendly, approachable)
- **Elevation**: 2-4 (subtle shadow, not heavy)
- **Padding**: 16px (generous internal space)
- **Margins**: 16px horizontal, 12px vertical
- **Background**: Cream (#FFF8DC) or white

#### Interaction Feel (Responsive & Delightful)
- **Animations**: 200-300ms (smooth, not sluggish)
- **Ripple effects**: InkWell on all tappable elements
- **Transitions**: Material page routes (platform-appropriate)
- **Feedback**: Immediate visual response (no dead taps)

### Design Anti-Patterns to Avoid

**Don't**:
- ❌ Use cold blues/grays (feels clinical, not warm)
- ❌ Cram content (no breathing room = generic app)
- ❌ Use flat hierarchy (everything competing for attention)
- ❌ Use generic icons without context (lazy design)
- ❌ Ignore whitespace (cramped = cheap)
- ❌ Use harsh shadows (aggressive, not inviting)
- ❌ Use robotic copy (be warm and conversational)

**Do**:
- ✅ Embrace warm, earthy tones (Brazilian ingredient inspiration)
- ✅ Give content room to breathe (confident spacing)
- ✅ Establish clear hierarchy (guide the eye)
- ✅ Use context-aware labels (helpful, not cryptic)
- ✅ Respect whitespace (sophistication through restraint)
- ✅ Use subtle elevation (depth without aggression)
- ✅ Write friendly copy (cultured, not pretentious)

## Flutter-Specific Guidelines

### Recommended Widgets by Use Case

**Screens & Layout**:
- **Scaffold**: All full-screen layouts
- **AppBar**: Standard top navigation
- **SafeArea**: Respect device notches/insets
- **SingleChildScrollView**: Scrollable content
- **CustomScrollView**: Complex scrolling (slivers)

**Lists & Collections**:
- **ListView.builder**: Dynamic lists (performance)
- **GridView**: Grid layouts
- **Card**: Content containers
- **ExpansionTile**: Collapsible sections

**Forms & Input**:
- **Form**: Form validation wrapper
- **TextFormField**: Text inputs with validation
- **DropdownButton**: Select from options
- **Checkbox / Radio / Switch**: Boolean/choice inputs

**Actions**:
- **ElevatedButton**: Primary actions
- **TextButton**: Secondary actions
- **IconButton**: Icon-only actions
- **FloatingActionButton**: Primary screen action

**Feedback & State**:
- **SnackBar**: Transient messages
- **Dialog**: Blocking confirmations
- **CircularProgressIndicator**: Loading spinner
- **LinearProgressIndicator**: Progress bar

**Navigation**:
- **BottomNavigationBar**: Primary navigation (3-5 items)
- **Drawer**: Secondary navigation / settings
- **TabBar**: Sub-navigation within screen

### Responsive Design Patterns

**Mobile (< 600dp)**:
- Single column layout
- Full-width cards
- Bottom navigation
- FAB for primary action

**Tablet (600-900dp)**:
- Two-column layout (master-detail)
- Side navigation (drawer always visible)
- Larger touch targets (48x48 → 56x56)

**Desktop (> 900dp)** *(future consideration)*:
- Three-column layout
- Persistent side nav
- Hover states
- Keyboard shortcuts

### Platform-Specific Considerations

**iOS**:
- Cupertino widgets for native feel (if desired)
- Swipe-back navigation
- Haptic feedback (HapticFeedback.lightImpact)
- Modal sheets slide from bottom

**Android**:
- Material Design 3 components
- Ripple effects (InkWell)
- Floating Action Button convention
- Navigation drawer

**Both**:
- Platform-adaptive widgets (adaptive_components package)
- Respect platform conventions
- Test on both platforms

## Common UX Patterns in Gastrobrain

### Recipe Browsing
- **Card-based list**: Recipe cards with image, title, meta
- **Filters**: Dropdown/chip filters (meal type, difficulty)
- **Search**: Debounced search bar (300ms delay)
- **Empty state**: "No recipes found" with action to add

### Meal Planning
- **Calendar view**: Weekly grid with meal slots
- **Drag-and-drop**: Assign recipes to days/meals
- **Multi-select**: Add multiple side dishes
- **Quick actions**: Swipe gestures for common actions

### Forms & Dialogs
- **Validation**: Inline errors below fields
- **Progressive disclosure**: Show advanced options on toggle
- **Autosave**: Debounced save (500ms after typing stops)
- **Cancel confirmation**: Warn if unsaved changes

### Navigation Patterns
- **Hierarchical**: Home → List → Detail → Edit
- **Tab-based**: Main sections (Recipes, Meals, Shopping)
- **Modal**: Dialogs for focused tasks (add, edit, confirm)
- **Back navigation**: Preserve user context (return to filtered list)

## Edge Cases to Consider

Every UX design should address:

### Empty States
- **No data**: First-time user or empty collection
- **No results**: Search/filter returned nothing
- **Offline**: No network connection (if applicable)

### Boundary Conditions
- **Very long text**: Recipe names, ingredient lists
- **Very short text**: Single-word titles
- **Large numbers**: High serving counts, many ingredients
- **Zero values**: 0 servings, 0 ingredients (prevent if invalid)

### Error Scenarios
- **Network errors**: Failed API calls (if applicable)
- **Validation errors**: Invalid form inputs
- **Database errors**: Failed save/load operations
- **Permission errors**: Missing camera/storage access (if applicable)

### Interaction Patterns
- **Rapid tapping**: Prevent double-submit
- **Orientation change**: Preserve state on rotate
- **Background return**: Resume where user left off
- **Interruptions**: Phone call, notification

### Data Integrity
- **Concurrent edits**: Handle stale data
- **Orphaned records**: Delete cascades properly
- **Undo**: Allow reversal of destructive actions

## Usage Instructions

### Step 1: Invoke the Skill
```
User: "Design the UX for #285 - weekly meal planning screen"
```

### Step 2: Fetch Context
If GitHub issue provided, fetch details:
```bash
gh issue view 285
```

### Step 3: Execute Checkpoints
Run each checkpoint **one at a time**:
1. Generate artifact for checkpoint
2. Wait for user confirmation
3. Proceed to next checkpoint

**Never skip ahead** - each checkpoint builds on previous.

### Step 4: Produce Artifacts
At each checkpoint, generate complete markdown artifact (not just notes).

### Step 5: Handoff to Implementation
After Checkpoint 6, summarize all artifacts and provide implementation checklist.

## Examples

### Example 1: New Feature Design

**User**: "Design the UX for adding recipe tags and filtering by tags"

**Skill Response**:

```
CHECKPOINT 1/6: Goal & Context Analysis

I'll help you design the UX for recipe tags and filtering. Let me start by understanding the user goals.

## Goal & Context

**User Goal**: Users want to organize their recipes by custom categories (e.g., "quick weeknight", "fancy dinner", "kid-friendly") and quickly filter to find recipes matching those tags.

**Pain Point**: Currently, users can only filter by predefined meal type (breakfast/lunch/dinner) and difficulty. They have no way to create their own organizational system for recipes.

**Success Criteria**:
- [ ] Users can create custom tags (e.g., "vegetarian", "under 30 min")
- [ ] Users can assign multiple tags to a recipe
- [ ] Users can filter recipe list by one or more tags
- [ ] Tag filtering feels fast and intuitive (no slow searches)

**Scope**: New feature - tag management + filtering UI

Ready to proceed to Checkpoint 2? (y/n)
```

[User confirms]

```
CHECKPOINT 2/6: Current State Assessment

Since this is a new feature, I'll briefly assess the existing recipe browsing UI to maintain consistency.

## Current State Assessment

**What exists**: Recipe list screen with card-based layout, dropdown filters for meal type and difficulty, search bar.

**What works** ✅:
- Card-based recipe list is scannable and visual
- Dropdown filters are familiar and easy to use
- Search bar is prominent and discoverable

**What doesn't work** ❌:
- Limited filtering options (only 2 predefined filters)
- No way to save custom filter combinations
- Filter bar feels cluttered when both filters active

**Design patterns to maintain**:
- Card-based recipe list (Material Card widget)
- Filter chips above list (Chip widgets in Wrap)
- Pull-to-refresh on recipe list
- FloatingActionButton for "Add Recipe"

**Approach**: Evolutionary improvement - add tag filter alongside existing filters, reuse chip-based UI pattern

Ready to proceed to Checkpoint 3? (y/n)
```

[Continues through remaining checkpoints...]

### Example 2: Redesign Existing Screen

**User**: "Help me redesign the meal planning calendar - it feels cramped and hard to read"

**Skill Response**:

```
CHECKPOINT 1/6: Goal & Context Analysis

I'll help you redesign the meal planning calendar for better readability.

## Goal & Context

**User Goal**: Users want to see their weekly meal plan at a glance and quickly understand what's planned for each day without squinting or tapping to expand.

**Pain Point**: Current calendar feels cramped - recipe names are truncated, meal type labels compete for attention, and overall hierarchy is unclear. Users report it "feels generic" and "hard to scan quickly."

**Success Criteria**:
- [ ] Users can read recipe names without truncation (at least first 25 characters)
- [ ] Clear visual distinction between days and meal slots
- [ ] Meal type (breakfast/lunch/dinner) is obvious at a glance
- [ ] Empty meal slots are inviting (not just blank space)
- [ ] Overall feel is "cultured and organized" (not cramped and generic)

**Scope**: Redesign of weekly meal planning calendar screen

Ready to proceed to Checkpoint 2? (y/n)
```

[User confirms]

```
CHECKPOINT 2/6: Current State Assessment

Let me review the current calendar implementation to identify what to preserve and what to fix.

## Current State Assessment

**What exists**: Grid layout showing 7 days x 3 meals, recipe names in small text, dropdown icons to assign recipes.

**What works** ✅:
- Shows all 7 days at once (week-at-a-glance)
- Clear column headers for days of week
- Quick tap to assign recipe (dropdown)

**What doesn't work** ❌:
- Typography hierarchy unclear (day, meal type, recipe all similar size)
- Recipe names truncated after ~15 characters (...unable to read)
- No breathing room - 8px padding feels cramped
- Empty slots are just gray boxes (uninviting)
- Feels generic - could be any calendar app

**Design patterns to maintain**:
- Week-at-a-glance view (users like seeing full week)
- Tap-to-assign interaction (familiar)
- Day headers with date (context)

**Approach**: Evolutionary redesign - keep grid structure, improve typography hierarchy, add generous whitespace, make empty states inviting

Ready to proceed to Checkpoint 3? (y/n)
```

[Continues through remaining checkpoints with wireframes showing improved spacing, typography, and visual hierarchy...]

## Bundled Resources

This skill includes reference materials in `references/` directory:

### references/visual-identity.md
Complete "Cultured & Flavorful" design guidelines with:
- Color palette with hex values
- Spacing system with dp values
- Typography scale with font sizes
- Component examples (cards, buttons, etc.)
- Before/after comparisons

### references/accessibility-checklist.md
WCAG guidelines adapted for Flutter:
- Screen reader compatibility patterns
- Color contrast ratios with examples
- Touch target sizing for mobile
- Semantic widget usage
- Common accessibility mistakes to avoid

### references/common-patterns.md
Reusable UX patterns from Gastrobrain:
- Recipe browsing patterns
- Meal planning interactions
- Form design conventions
- Navigation patterns
- Empty state designs

### templates/wireframe-template.txt
ASCII art template for quick wireframing:
- Standard screen layouts
- Common component patterns
- Grid systems for alignment

## Success Metrics

How we know this skill is working:

- ✅ Fewer "wait, this screen doesn't make sense" moments during implementation
- ✅ Clear design direction before writing any Flutter widgets
- ✅ Screens feel intentional and cohesive (not haphazard)
- ✅ Consistent "Cultured & Flavorful" identity across features
- ✅ Accessibility considerations baked in from the start
- ✅ Smooth handoff to UI Component Implementation skill (no ambiguity)

## Continuous Improvement

After using this skill:
1. **Capture learnings**: What design patterns worked well?
2. **Update references**: Add new patterns to `common-patterns.md`
3. **Refine checkpoints**: Were any checkpoints too detailed or too shallow?
4. **Gather feedback**: Did implementation match design intent?
5. **Evolve identity**: Does "Cultured & Flavorful" need refinement?

**This skill should evolve** as design patterns mature.

---

## Version History

- **1.0.0** (2026-01-23): Initial skill creation with 6-checkpoint UX design process

