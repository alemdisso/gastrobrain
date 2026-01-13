# 0.1.7 - Visual Foundations & Polish - Issue Creation Prompts

This document contains all prompts for creating the 0.1.7 milestone issues on GitHub.

## Overview

**Milestone:** 0.1.7 - Visual Foundations & Polish  
**Theme:** Establish visual identity and polish core screens before beta  
**Position:** Final 0.1.x milestone, preparing for 0.2.0 multi-user phase  
**Total Issues:** 10

---

## Issue Creation Order

Issues should be created and worked on in this order due to dependencies:

### Phase 1: Foundation (Issues 1-3)
1. Define Visual Identity
2. Create Design Tokens System  
3. Implement ThemeData Configuration

### Phase 2: Core Screens (Issues 4-6)
4. Polish Weekly Meal Planning Screen
5. Polish Recipe List Screen
6. Create/Polish Landing Page

### Phase 3: Components (Issues 7-9)
7. Standardize Button Styles
8. Standardize Form Input Styles
9. Standardize Navigation Elements

### Phase 4: Documentation (Issue 10)
10. Create UI Component Library Documentation

---

## Individual Issue Prompts

Each issue has its own detailed prompt file:

- `issue_01_visual_identity.md` - Define Gastrobrain Visual Identity
- `issue_02_design_tokens.md` - Create Design Tokens System
- `issue_03_themedata_implementation.md` - Implement ThemeData Configuration
- `issue_04_polish_weekly_planning.md` - Polish Weekly Meal Planning Screen
- `issue_05_polish_recipe_list.md` - Polish Recipe List Screen
- `issue_06_landing_page.md` - Create/Polish Landing Page
- `issue_07_standardize_buttons.md` - Standardize Button Styles
- `issue_08_standardize_form_inputs.md` - Standardize Form Input Styles
- `issue_09_standardize_navigation.md` - Standardize Navigation Elements
- `issue_10_component_library_docs.md` - Create UI Component Library Documentation

---

## How to Use These Prompts

1. **Create milestone first**: Create the `0.1.7 - Visual Foundations & Polish` milestone on GitHub

2. **Create issues in order**: Follow the phase order above for dependencies

3. **For each issue**:
   - Read the corresponding `.md` file
   - Use the "Prompt for Agent" section to ask Claude to create the GitHub issue
   - Claude will generate the complete issue content
   - Copy and paste into GitHub's issue creation form
   - Add specified labels and milestone

4. **Working on issues**: Use the UI Styling Skill (from `ui_styling_skill.md`) when implementing visual work

---

## Key Integration Points

**UI Styling Skill**: Issues 1-2 use Checkpoints 1-3 of the skill, Issues 4-9 use Checkpoints 4-7

**Design Tokens**: Defined in Issue 2, implemented in Issue 3, used in all subsequent issues

**Visual Identity**: Defined in Issue 1, guides all visual decisions throughout 0.1.7

**Component Library**: Issue 10 captures all patterns created during Issues 7-9

---

## Success Criteria for 0.1.7

- [ ] Visual identity clearly defined and documented
- [ ] Design tokens system established and implemented
- [ ] Core screens (weekly planning, recipe list, landing page) polished
- [ ] Component patterns standardized (buttons, inputs, navigation)
- [ ] UI component library documented
- [ ] App feels "designed" not "assembled"
- [ ] Consistent visual language across all screens
- [ ] Foundation ready for 0.2.0 beta phase

---

## Notes

- Issues 1-3 are foundational and high priority (P1-High)
- Issues 4-6 are core screen polish (P1-High for weekly planning, P2-Medium for others)
- Issues 7-9 are component standardization (P2-Medium to P3-Low)
- Issue 10 is documentation (P3-Low)
- All issues include testing requirements
- All issues reference the UI Styling Skill for implementation guidance
