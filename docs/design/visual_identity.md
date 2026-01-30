# Gastrobrain Visual Identity and Design Principles

> **Document Purpose:** This document defines the visual personality and core design principles that guide all UI decisions for Gastrobrain. This is the foundational document for the 0.1.7 milestone and all subsequent visual/UI work should reference this visual identity.

**Status:** Draft - Initial Definition
**Created:** 2026-01-30
**Issue:** [#255 - Define Gastrobrain Visual Identity and Design Principles](https://github.com/rodrigo-omena/gastrobrain/issues/255)

---

## App Purpose

Gastrobrain is a meal planning and recipe management application that helps users organize their cooking with intelligent recipe recommendations. Unlike generic meal planning tools, Gastrobrain embraces a **Brazilian perspective on food culture** - treating food as culture, not just fuel - with a focus on regional cuisines and the concept of "seasoning palette."

## Target Users

- Home cooks who value authenticity and cultural connection to food
- Users exploring Brazilian and regional cuisines
- People seeking curated, intelligent recipe recommendations (not just database search)
- Bilingual users (Portuguese-first, with English support)

---

## Core Visual Personality Attributes

Gastrobrain's visual design is guided by five core personality attributes:

### 1. Warm and Inviting

**Why this matters:** Food is personal, emotional, and cultural. The app should feel like a welcoming kitchen, not a sterile database.

**Visual translation:**
- Warm color palette inspired by food and Brazilian culture
- Comfortable, generous spacing that doesn't feel cramped
- Friendly rounded shapes over sharp, technical edges
- Soft shadows and gentle gradients over harsh contrasts

### 2. Confident and Trustworthy

**Why this matters:** Users rely on the recommendation engine for meal decisions. The app must feel authoritative without being intimidating.

**Visual translation:**
- Clear visual hierarchy that guides attention
- Purposeful, consistent use of color with semantic meaning
- Professional typography with confident weights
- Consistent patterns that build user trust through predictability

### 3. Cultured and Exploratory

**Why this matters:** Reflects the Brazilian food culture perspective and encourages users to discover new recipes and regional cuisines.

**Visual translation:**
- Sophisticated color combinations that avoid clichés
- Thoughtful use of white space to create breathing room
- Cultural visual cues that feel authentic, not stereotypical
- Design that invites exploration without overwhelming

### 4. Clear and Organized

**Why this matters:** Meal planning requires practical clarity - users need to quickly understand their week, find recipes, and manage ingredients.

**Visual translation:**
- Strong information hierarchy (heading sizes, weights, colors)
- Effective use of white space for visual grouping
- Scannable layouts with clear sections
- Functional design that serves user goals first

### 5. Regionally Rooted

**Why this matters:** The app's Brazilian perspective should be present but not overwhelming - subtle cultural authenticity.

**Visual translation:**
- Color choices inspired by Brazilian culture and ingredients
- Design accommodates Portuguese text length (20-30% longer than English)
- Warmth and richness over minimalist coldness
- Cultural authenticity without tourist-guide aesthetics

---

## What Gastrobrain IS NOT

To avoid generic patterns and maintain authentic identity:

### Not Generic/Corporate
This isn't another blue SaaS app or sterile productivity tool. Food deserves personality and warmth. Avoid default Material Design colors and corporate tech aesthetics.

### Not Overly Playful/Gamified
While friendly, Gastrobrain respects users' time and serious intent. No cartoonish elements, excessive animation, or gamification badges. Food culture deserves maturity.

### Not Minimalist-Cold
Scandinavian minimalism works for some apps, but food culture needs warmth and richness. Minimal doesn't mean sterile - we choose purposeful richness over stark emptiness.

### Not Instagram-First
This is a practical tool, not a photo showcase. Visual appeal serves function, not the reverse. We prioritize usability over aesthetic trends.

### Not Americanized
The Brazilian perspective is intentional - avoid defaulting to US food culture visual tropes, ingredient assumptions, or cultural references.

---

## Visual Influences

### Brazilian Color Palette
Drawing from Brazil's vibrant culture without resorting to clichés (avoiding literal green/yellow flag colors). Think: warm earth tones, rich food colors (paprika red, cilantro green, coffee brown), natural warmth of Brazilian markets and kitchens.

### Market Aesthetic (Feira)
The organized abundance of a Brazilian market - colorful yet well-organized, inviting yet clear, with distinct categories but rich variety within each. This balance of structure and richness guides our information architecture.

### Portuguese Language Considerations
Portuguese text runs 20-30% longer than English. Visual design must accommodate longer strings gracefully without cramping, maintain hierarchy with longer headings, and provide flexible layouts that don't break with translation.

### Food as Craft
Visual respect for cooking as a cultural practice, not just sustenance. Typography and spacing that gives recipes room to breathe, component design that honors the importance of meal planning, information density that respects the complexity of cooking.

---

## Long-term Vision

As Gastrobrain evolves into a "food exploration platform," the visual identity should:

- **Support discovery** of regional Brazilian cuisines without feeling like a tourist guide
- **Scale gracefully** to accommodate rich content (techniques, seasonings, cultural context) without feeling cluttered
- **Evolve sophistication** as features expand, while maintaining warmth and approachability
- **Establish patterns** that can extend to future features (community sharing, technique libraries, seasoning profiles)
- **Maintain authenticity** as the user base grows, staying true to Brazilian food culture perspective

---

## Visual Identity Statement

**Gastrobrain's visual design reflects the Brazilian understanding that food is culture, not fuel.**

The interface balances warmth and confidence - inviting users into their personal culinary journey while projecting the authority of a trusted recommendation system. Colors draw from the rich, earthy palette of Brazilian ingredients rather than tech conventions. Typography and spacing create breathing room that respects cooking as a cultural practice.

The design is organized and clear (meal planning demands it) but never cold or sterile (food culture deserves better). Every visual choice reinforces that Gastrobrain is a cultured companion for food exploration, rooted in Brazilian perspective, built with intention.

---

## Application to Design Decisions

This visual identity should guide all future UI decisions:

### Color Palette
- **Primary colors:** Warm, food-inspired (not default blue)
- **Accent colors:** Drawn from Brazilian ingredients and culture
- **Semantic colors:** Clear meaning (success, warning, error) with appropriate warmth
- **Avoid:** Tech-industry defaults, cold grays, sterile whites

### Typography
- **Hierarchy:** Clear contrast between heading levels (2-3sp minimum difference)
- **Weights:** Confident weights for headings (semibold/bold), regular for body
- **Line height:** Generous for Portuguese text (1.5-1.8 for body text)
- **Avoid:** Thin/light weights that feel fragile, cramped line heights

### Spacing
- **System:** Consistent scale (8px base unit recommended)
- **Philosophy:** Generous without being wasteful, organized without cramping
- **Touch targets:** Minimum 44px for interactive elements
- **Avoid:** Random one-off values, cramped component padding

### Component Styling
- **Shapes:** Rounded corners (friendly) over sharp edges (technical)
- **Elevation:** Subtle shadows for depth, not aggressive 3D effects
- **Borders:** Purposeful use for grouping, not decoration
- **Avoid:** Overly flat (lacks warmth) or overly shadowed (dated skeuomorphism)

---

## Success Criteria

The visual identity is successfully applied when:

- ✅ App feels distinctly "Gastrobrain" - not generic Material Design
- ✅ Users sense warmth and cultural awareness, not cold functionality
- ✅ Visual hierarchy guides users naturally through their tasks
- ✅ Brazilian perspective is present but not heavy-handed
- ✅ Portuguese text displays gracefully without cramping
- ✅ Design feels cohesive across all screens
- ✅ Newcomers to the codebase can reference this document for UI decisions

---

## Next Steps

With this visual identity defined, the next phase is to:

1. **Define Design Tokens** (Checkpoint 3) - Translate personality into concrete values (colors, typography scale, spacing system)
2. **Create Theme Configuration** - Implement tokens in Flutter ThemeData
3. **Document Component Patterns** - Build reusable styled components
4. **Apply Systematically** - Polish existing screens following these principles

**Related Documentation:**
- Design tokens (to be created): `docs/design/design-tokens.md`
- Component patterns (to be created): `docs/design/component-patterns.md`

---

**Document Changelog:**
- 2026-01-30: Initial visual identity definition (Checkpoint 2 of UI polish process)
