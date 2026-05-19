<!-- markdownlint-disable -->
# Gastrobrain Development Roadmap & Status

**Last Updated:** May 2026
**Current Version:** 0.2.11 (shipped) / 0.2.12 complete in develop
**Current Branch:** `develop`

## 📊 **Quick Status Overview**

| Milestone | Status | Issues | Theme |
|-----------|--------|--------|-------|
| **0.1.0** | ✅ Complete | 53 closed | Personal meal planning excellence |
| **0.1.1** | ✅ Complete | 9 closed | Stability & polish |
| **0.1.2** | ✅ Complete | 12 closed | Polish & data safety |
| **0.1.3** | ✅ Complete | 8 closed | User features & critical foundation |
| **0.1.4** | ✅ Complete | 5 closed | Architecture & critical bug fixes |
| **0.1.5** | ✅ Complete | 7 closed | Test coverage & polish |
| **0.1.6** | ✅ Complete | 7 closed | Shopping list & polish |
| **0.1.7a** | ✅ Complete | 3 closed | Visual foundation |
| **0.1.7b** | ✅ Complete | 8 closed | Screen & component polish |
| **0.1.8** | ✅ Complete | 12 closed | UX quick fixes & bug fixes |
| **0.1.9** | ✅ Complete | 5 closed | Meal planning UX redesign |
| **0.1.10** | ✅ Complete | 4 closed | Landing page & polish |
| **0.1.11** | ✅ Complete | 6 closed | Shopping list corrections |
| **0.1.12** | ✅ Complete | 7 closed | Servings & quantity tracking |
| **0.1.13** | ✅ Complete | 5 closed | Meal planning & shopping enhancements |
| **0.1.14** | ✅ Complete | 5 closed | DB housekeeping & documentation |
| **0.1.15** | ✅ Complete | 2 closed | Patch: import bug fixes |
| **0.2.0** | ✅ Complete | 11 closed | Beta-ready phase |
| **0.2.1** | ✅ Complete | 4 closed | Data seeding & recipe content |
| **0.2.2** | ✅ Complete | 11 closed | Algorithm & stability |
| **0.2.3** | ✅ Complete | 11 closed | UX polish |
| **0.2.4** | ✅ Complete | 12 closed | Recipe enhancement |
| **0.2.5** | ✅ Complete | 7 closed | Tagging & filtering |
| **0.2.6** | ✅ Complete | 1 closed | Patch |
| **0.2.7** | ✅ Complete | 9 closed | Code health |
| **0.2.9** | ✅ Complete | — | Migration hotfix |
| **0.2.10** | ✅ Complete | 1 closed | Patch |
| **0.2.11** | ✅ Complete | 6 closed | DB safety foundation + UX polish |
| **0.2.12** | ✅ Complete | 4 closed | Architecture & editor |
| **0.2.13** | 🎯 **Current** | 2 open | Recipe redesign |
| **0.3.0** | 📋 **Next** | 25 open | Multi-user foundation |
| **1.0.0** | ⭐ **Vision** | 13 open | Community platform |

**Total issues resolved:** 235+ across 29 completed milestones

---

## ✅ **Completed: 0.1.0 — Personal Meal Planning Excellence**

### Major Achievements
- Modern state management with Provider pattern
- Database migration system with versioned migrations
- Full bilingual support (English/Portuguese) with ARB-based localization
- 6-factor recommendation engine with temporal intelligence and dual-context analysis
- Multi-recipe meal support (main dish + side dishes) with proper protein tracking
- Bulk recipe management with intelligent ingredient parsing
- CI/CD pipeline with automated testing
- Complete UI polish and all P0-Critical bug fixes

**53 closed issues**

---

## ✅ **Completed: 0.1.1 — Stability & Polish**

- Comprehensive testing infrastructure (unit, widget, integration, e2e)
- Form field keys for testability across all forms
- Recipe search/filter by name
- Improved meal history screen layout
- Proper date localization

**9 closed issues**

---

## ✅ **Completed: 0.1.2 through 0.1.15 — Foundation Hardening**

These sprints systematically addressed data safety, UX polish, testing coverage, and feature completeness:

- **0.1.2** — Database backup/restore, active filter indicators, Portuguese sorting, fraction display, parser improvements
- **0.1.3** — Shopping list generation, meal type selection, "to taste" ingredient handling, testing completion
- **0.1.4** — Architecture improvements, critical bug fixes
- **0.1.5** — Test coverage expansion and polish
- **0.1.6** — Shopping list refinement and UX polish
- **0.1.7a/b** — Visual identity system, design tokens, comprehensive screen/component polish
- **0.1.8** — UX quick fixes and bug fixes
- **0.1.9** — Meal planning UX redesign
- **0.1.10** — Dashboard/landing page, onboarding improvements
- **0.1.11** — Shopping list corrections and edge case handling
- **0.1.12** — Servings tracking and quantity improvements
- **0.1.13** — Meal planning and shopping enhancements
- **0.1.14** — Database housekeeping, documentation, migration cleanup
- **0.1.15** — Import bug fixes (patch release)

**65 combined issues closed**

---

## ✅ **Completed: 0.2.0 — Beta-Ready Phase**

Full transition to a production-ready app suitable for 5-6 trusted beta users:
- Recipe photo support and advanced filtering
- Proximity-based recommendation avoidance logic
- Meal type-specific recommendation profiles
- Enhanced protein tracking and weekly protein distribution
- Smart metric conversion and unit formatting improvements
- Ingredient aliases and import tools

**11 closed issues**

---

## ✅ **Completed: 0.2.1 through 0.2.12 — Beta Refinement Cycle**

Iterative improvements driven by real-world beta usage:

- **0.2.1** — Data seeding and recipe content improvements
- **0.2.2** — Recommendation algorithm improvements and stability
- **0.2.3** — UX polish across multiple screens
- **0.2.4** — Recipe enhancement features
- **0.2.5** — Tagging system and advanced filtering
- **0.2.6/0.2.10** — Patches
- **0.2.7** — Code health: CI green, schema cleanup, parser confidence fix, navigation bug fix
- **0.2.9** — Migration hotfix (critical schema repair)
- **0.2.11** — Database safety: migration failures recorded persistently and surfaced as visible warning; meal options dialog, week plan temporal status, ingredient dialog, recipe scroll
- **0.2.12** — Architecture: DAO extraction from DatabaseHelper god class; RecipeEditorScreen split into focused components; IngredientParserService extracted; migration auto-rollback

**62 combined issues closed**

---

## 🎯 **Current Milestone: 0.2.13 — Recipe Redesign**

**Theme:** First-class, guided recipe entry experiences
**Sprint character:** Discovery-heavy — mandatory UX design phase before implementation
**Target velocity:** ~5 pts/day (discovery mode)

### Open Issues (2 total)

- **#370** — Redesign recipe creation as a phased, progressive disclosure flow
- **#371** — Redesign ingredient parser UX/UI as a first-class entry method

### Dependencies
- Requires 0.2.12 complete: `IngredientParserService` (#283) standalone and `RecipeEditorScreen` (#336) split — both done
- Day 1 is mandatory design — no code until UX is mapped

---

## 📋 **Next: 0.3.0 — Multi-User Foundation**

**Goal:** Server-client architecture for broader user base
**Issues:** 25 open, 0 closed

**Key Features:**
- Backend infrastructure and RESTful API
- Authentication and authorization system
- End-to-end data encryption and GDPR compliance
- Cross-device synchronization
- Performance optimizations and profiling
- Developer mode for recommendation debugging
- Advanced pagination for recommendation results

---

## ⭐ **Vision: 1.0.0 — Community Platform Launch**

**Goal:** Complete realization of the Gastrobrain vision
**Issues:** 13 open, 1 closed

**Key Features:**
- Public recipe sharing and discovery
- AI-enhanced recommendations and meal planning
- Mobile app store deployment (iOS/Android)
- Developer ecosystem and API
- Comprehensive recommendation engine test suite
- Track out-of-home meals
- Frequency-based filtering in recommendations

---

## 🎯 **Strategic Position**

### Strengths
- **29 milestones completed** across a year of development — consistent delivery cadence
- **235+ issues resolved** with systematic tracking and velocity data
- **Solid architecture:** DAO layer extracted, DatabaseHelper no longer a god class, IngredientParserService standalone, RecipeEditorScreen componentized
- **Database safety:** Migration failures auto-roll back and surface as visible warnings — never silent failures
- **2047+ unit/widget tests + 73 E2E tests** — comprehensive coverage preventing regressions
- **Beta-driven:** All feature priorities driven by real-world usage feedback
- **Cruising velocity:** ~30 pts/week (6.5 pts/day) with documented sprint history

### Current Focus (0.2.13 — Recipe Redesign)
- **#370** — Recipe creation as phased, progressive disclosure flow
- **#371** — Ingredient parser as first-class guided entry method
- Builds on the clean architectural foundation laid in 0.2.12

### Milestone Strategy
1. **0.2.13** (~1 week): Recipe redesign → complete the recipe entry experience
2. **0.3.0** (TBD): Multi-user foundation → server-client architecture, the major architectural leap
3. **1.0.0** (TBD): Community platform → app store deployment and public launch

---

## 📈 **Development Velocity**

- **Cruising velocity:** 30 pts/week (6.5 pts/day)
- **Execution mode:** ~36 pts/week on well-scoped architecture work
- **Discovery mode:** ~20 pts/week on UX-heavy or complex features
- **Sprint history:** `docs/archive/Sprint-Estimation-Diary.md`

---

## 📝 **Planning Notes**

### Milestone Versioning History
- **0.0.x** — Early prototypes (pre-public tracking)
- **0.1.x** — Foundation phase: 16 milestones, systematic quality and feature completion
- **0.2.x** — Beta phase: iterative refinement driven by real usage, 14 milestones (including hotfixes)
- **0.3.x** — Multi-user phase: architectural transformation (upcoming)
- **1.0.0** — Public launch (vision)

### Related Documents
- **[Sprint Estimation Diary](Sprint-Estimation-Diary.md)**: Sprint-by-sprint velocity data and retrospectives
- **[Sprint Planning](../planning/sprints/)**: Individual sprint plans for recent milestones
