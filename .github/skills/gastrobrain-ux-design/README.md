# Gastrobrain UX Design - Quick Reference

User experience design specialist that thinks through user flows, information architecture, and wireframes **before** coding begins.

## Quick Start

**Trigger**: `"Design the UX for #XXX"` or `"Help me redesign [screen]"`

**Output**: 6 checkpoint-driven design process producing complete UX artifacts

**Duration**: ~30-60 minutes depending on complexity

## Workflow Position

```
Issue Roadmap → UX Design → UI Component Implementation
```

## 6 Checkpoints

1. **Goal & Context** - User goals, pain points, success criteria
2. **Current State** - What exists, what works/doesn't (skip for new features)
3. **User Flow** - Step-by-step journey, decision points, edge cases
4. **Information Architecture** - Content hierarchy, visual identity check
5. **Wireframe & Interaction** - Layout structure, components, behaviors
6. **Accessibility & Handoff** - A11y check, artifact summary, implementation checklist

## Design Identity

**"Cultured & Flavorful"** - Not a generic meal planner

✅ Warm earthy colors (terracotta, olive, saffron)
✅ Generous whitespace (16-24px standard, 32-48px sections)
✅ Clear typography hierarchy (24pt headers → 16pt body)
✅ Inviting but confident

❌ Cold blues/grays
❌ Cramped layouts
❌ Flat hierarchy

## Key Outputs

- **Problem statement** (2-3 sentences)
- **User flow map** (text-based diagram)
- **Information hierarchy** (primary/secondary/tertiary)
- **Wireframe** (ASCII art or detailed text description)
- **Interaction specification** (taps, gestures, transitions, feedback)
- **Accessibility checklist** (screen reader, contrast, touch targets)

## When to Use

✅ Before implementing new UI features
✅ When redesigning existing screens
✅ When user flow is unclear
✅ When information architecture needs thought

❌ For writing actual Flutter code (use `gastrobrain-ui-component`)
❌ For styling/colors (use `gastrobrain-ui-polish`)
❌ For writing tests (use `gastrobrain-testing-implementation`)

## Example Usage

```
User: "Design the UX for #285 - weekly meal planning redesign"

Skill:
CHECKPOINT 1/6: Goal & Context
[Analyzes issue, defines user goals]
Ready to proceed? (y/n)

[After confirmation...]

CHECKPOINT 2/6: Current State Assessment
[Reviews existing calendar, identifies problems]
Ready to proceed? (y/n)

[Continues through all 6 checkpoints...]

CHECKPOINT 6/6: Accessibility & Handoff
[A11y review + complete artifact summary]
Ready for implementation? (y/n)
```

## Success Metrics

- ✅ Clear design direction before coding
- ✅ Screens feel intentional (not haphazard)
- ✅ Consistent "Cultured & Flavorful" identity
- ✅ Accessibility baked in from start
- ✅ Smooth handoff to implementation

## Bundled Resources

- `references/visual-identity.md` - "Cultured & Flavorful" guidelines
- `references/accessibility-checklist.md` - WCAG/Flutter a11y patterns
- `references/common-patterns.md` - Reusable Gastrobrain UX patterns
- `templates/wireframe-template.txt` - ASCII wireframe templates

## Full Documentation

See `SKILL.md` for complete checkpoint details, examples, and design guidelines.

---

**Version**: 1.0.0
**Created**: January 2026
