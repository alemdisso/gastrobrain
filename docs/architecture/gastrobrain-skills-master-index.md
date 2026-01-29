# Gastrobrain Agent Skills - Master Index

## Overview

This document provides a complete map of the Agent Skills ecosystem for Gastrobrain development, showing how skills work together throughout the development workflow and the recommended implementation order.

---

## Skills Ecosystem Architecture

### Tier 1: Planning & Strategy
High-level planning and issue preparation

### Tier 2: Implementation & Execution
Phase-by-phase implementation with checkpoints

### Tier 3: Quality & Finalization
Review, validation, and merge

---

## Complete Skill Catalog

### **Tier 1: Planning Skills** ✅ (Prompts Ready)

#### 0. Issue Creation Skill ⭐
**Status:** ✅ Prompt ready
**Location:** `.github/skills/gastrobrain-issue-creator/`
**Triggers:** "Create an issue for...", "I found a bug...", "Feature request...", user reports problem

**Purpose:**
- Transform informal reports into structured GitHub issues
- Interactive 6-checkpoint process for accuracy
- Support bug reports, feature requests, technical debt
- Provide technical context and implementation guidance
- Estimate story points with reasoning
- Detect and reference related issues
- Generate exact GitHub CLI commands

**Checkpoint Flow:**
1. Understanding the Problem (clarify type, scope, priority)
2. Issue Details (title, context, current/expected behavior)
3. Implementation Guidance (solution, tasks, technical notes)
4. Acceptance & Testing (criteria, test cases)
5. Labels & Priority (with reasoning, story point estimate)
6. Final Review (complete markdown + CLI commands)

**Key Features:**
- Never creates issues without user confirmation
- Detects active work context (current branch, related issues)
- Handles multiple issue types with appropriate templates
- Provides reasoning for all recommendations
- Allows revision at any checkpoint

**Outputs:**
- Complete, well-structured GitHub issue
- Proper labels and priority
- Story point estimate with justification
- Related issue references
- Ready-to-execute gh CLI commands

---

#### 1. Sprint Planning Skill
**Status:** ✅ Prompt ready  
**Location:** `sprint-planning-skill-prompt.md` (from earlier conversation)  
**Triggers:** "Help me plan sprint 0.1.X", "plan next sprint"

**Purpose:**
- Analyze GitHub issues from Project #3
- Apply sprint history insights (0.1.2-0.1.5 velocity data)
- Group issues by type and dependencies
- Generate realistic capacity planning (10-15 points per 5 days)
- Risk assessment and sequencing strategy
- Day-by-day breakdown

**Outputs:**
- Sprint goal summary
- Grouped issues by theme
- Daily implementation sequence
- Risk assessment with mitigations
- Testing strategy
- Success criteria checklist

---

#### 2. Issue Roadmap Skill
**Status:** ✅ Prompt ready  
**Location:** `issue-roadmap-skill-prompt.md` (from earlier conversation)

**Triggers:** "I want to deal with #XXX", "create roadmap for #XXX", "plan issue #XXX"

**Purpose:**
- Fetch issue details from GitHub
- Generate 4-phase roadmap (Analysis → Implementation → Testing → Documentation)
- Identify files to modify
- Apply Gastrobrain-specific conventions
- Testing requirements by issue type
- Localization and database change checklists

**Outputs:**
- Comprehensive markdown roadmap
- Phase-by-phase checklists
- Files to modify list
- Testing strategy
- Acceptance criteria
- Risk assessment
- Clarifying questions (if needed)

---

### **Tier 2: Implementation Skills** (Top 3 Ready)

#### 3. Testing Implementation Skill ⭐
**Status:** ✅ Prompt ready  
**Location:** `testing-implementation-skill-prompt.md`

**Triggers:** "Implement Phase 3 for #XXX", "add tests for #XXX", "implement testing"

**Purpose:**
- ONE test at a time (prevents pattern error propagation)
- Reads roadmap Phase 3 (Testing)
- Generates test plan with count
- Creates tests iteratively with verification
- Learns from each test before next
- Progress tracking (TEST X/Y)

**Checkpoint Flow:**
1. Test plan generation (count: N tests)
2. TEST 1/N → verify → learn
3. TEST 2/N → verify → learn
4. Continue until N/N complete
5. Full suite verification

**Key Feature:** Avoids creating 8 tests with same error by testing each one before proceeding

---

#### 4. Database Migration Skill ⭐
**Status:** ✅ Prompt ready  
**Location:** `database-migration-skill-prompt.md`

**Triggers:** "Create migration for #XXX", "implement database changes", "Phase 2 - database"

**Purpose:**
- Checkpoint-based migration implementation
- Reads roadmap Phase 2 (Database section)
- Determines migration version number
- Implements schema changes safely
- Verifies rollback capability
- Updates models and seed data

**Checkpoint Flow:**
1. Migration file creation (skeleton)
2. Schema changes (up method)
3. Rollback implementation (down method) - CRITICAL
4. Model class updates
5. Seed data updates (if needed)
6. Migration tests

**Key Feature:** Database state verified at each checkpoint, rollback tested before proceeding

---

#### 5. Code Review Skill ⭐
**Status:** ✅ Prompt ready  
**Location:** `code-review-skill-prompt.md`

**Triggers:** "Review #XXX", "pre-merge check for #XXX", "ready to merge #XXX"

**Purpose:**
- Systematic pre-merge quality verification
- Verifies roadmap completion
- Checks acceptance criteria
- Runs automated checks (analyze, tests)
- Manual quality verification
- Localization verification
- Generates merge instructions

**Checkpoint Flow:**
1. Git status and branch verification
2. Roadmap completion check
3. Acceptance criteria verification
4. Technical standards (analyze, tests)
5. Code quality checks
6. Localization verification
7. Merge readiness assessment

**Key Feature:** Clear pass/warning/fail status, provides remediation guidance, generates merge instructions

---

#### 6. Localization Update Skill
**Status:** 📋 Prompt needed  
**Priority:** Medium (Phase 3)

**Triggers:** "Add localization for #XXX", "update ARB files", "translate UI strings"

**Purpose:**
- Reads existing ARB files (app_en.arb, app_pt.arb)
- Identifies new UI strings from code
- Generates bilingual entries
- Follows naming conventions
- Suggests AppLocalizations usage

**Checkpoint Flow:**
1. Scan code for new UI strings
2. Generate EN entries with context
3. Generate PT-BR translations
4. Update ARB files
5. Show usage examples in code
6. Verify no hardcoded strings remain

---

#### 7. UI Styling & Visual Polish Skill ⭐
**Status:** ✅ Prompt ready
**Location:** `.github/skills/gastrobrain-ui-polish/`
**Triggers:** "Polish the UI for...", "Help me style...", "This feels unfinished visually"

**Purpose:**
- Guide systematic visual refinement of Flutter UI
- Define visual identity and personality
- Create design tokens (color, typography, spacing, components)
- Apply consistent styling patterns
- Document reusable visual patterns
- Maintain visual consistency across features

**Checkpoint Flow:**
1. Visual Analysis (identify gaps and inconsistencies)
2. Identity Definition (define visual personality) [if needed]
3. Design Tokens Definition (create color, typography, spacing system)
4. Application Plan (map UI elements to tokens, prioritize)
5. Implementation (apply changes with Flutter best practices)
6. Refinement Iteration (polish based on review)
7. Pattern Documentation (capture for future use)

**Key Features:**
- Transforms functional UI into polished, professional interfaces
- Creates reusable design token system
- Considers bilingual support (EN/PT-BR)
- Tests across screen sizes
- Documents patterns for consistency
- Flutter Material Design best practices

**Outputs:**
- Polished UI with consistent visual identity
- Design tokens file (lib/theme/design_tokens.dart)
- Theme configuration
- Component patterns documented
- Before/after insights captured

---

#### 8. UI Component Implementation Skill
**Status:** 📋 Prompt needed
**Priority:** Medium (Phase 3)

**Triggers:** "Implement UI for #XXX", "create widget for #XXX", "Phase 2 - UI"

**Purpose:**
- Reads widget patterns (RecipeCard, MealCard, Dialogs)
- Follows UI conventions (Keys, SafeArea, responsive)
- Applies proper state management (Provider)
- Adds accessibility keys for testing
- Implements localization from start

**Checkpoint Flow:**
1. Widget structure and imports
2. State management setup
3. UI layout implementation
4. Styling and responsive design
5. Test keys and accessibility
6. Localization integration

---

#### 9. Service/Repository Implementation Skill
**Status:** 📋 Prompt needed
**Priority:** Low (Phase 4)

**Triggers:** "Implement service for #XXX", "create repository", "Phase 2 - service layer"

**Purpose:**
- Follows service patterns (MealEditService, etc.)
- Uses DatabaseHelper correctly
- Implements error handling (GastrobrainException)
- Adds dependency injection via ServiceProvider
- Includes comprehensive unit tests

**Checkpoint Flow:**
1. Service interface definition
2. Database access implementation
3. Error handling
4. Dependency injection setup
5. Unit test creation
6. Integration with providers

---

#### 10. Refactoring Skill
**Status:** 📋 Prompt needed
**Priority:** Low (Phase 4)

**Triggers:** "Refactor according to #XXX", "extract service", "consolidate code"

**Purpose:**
- Follows refactoring patterns (#234-237 consolidation)
- Maintains test coverage during refactoring
- Updates all call sites
- Preserves functionality (regression tests)
- Documents changes

**Checkpoint Flow:**
1. Analyze current implementation
2. Design refactored structure
3. Extract/consolidate code (one step at a time)
4. Update call sites
5. Verify tests still pass
6. Document changes

---

### **Tier 3: Quality & Finalization Skills**

#### 11. Issue Closing Skill
**Status:** 📋 Prompt needed
**Priority:** Low (Phase 4)

**Triggers:** "Close #XXX", "finalize #XXX", "issue complete"

**Purpose:**
- Verifies all roadmap checkboxes complete
- Confirms tests passing
- Updates GitHub Project status
- Generates commit message
- Creates merge instructions
- Closes issue with proper GitHub syntax

**Checkpoint Flow:**
1. Roadmap completion verification
2. Test suite verification
3. Acceptance criteria check
4. Generate commit message
5. GitHub Project update instructions
6. Issue closing with comment

---

## Skill Interaction Map

### Complete Issue Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    ISSUE CREATION (Optional)                 │
│  Skill #0: Issue Creation                                    │
│  Input: User report, bug discovery, feature idea             │
│  Output: Well-structured GitHub issue with estimate          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    SPRINT PLANNING                           │
│  Skill #1: Sprint Planning                                   │
│  Input: Open issues from Project #3                          │
│  Output: Sprint plan with 10-15 points, sequencing          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    ISSUE PLANNING                            │
│  Skill #2: Issue Roadmap                                     │
│  Input: Issue #XXX from sprint plan                          │
│  Output: 4-phase roadmap with checklists                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Phase 1:       │
                    │  Analysis       │
                    │  (Manual)       │
                    └─────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                 PHASE 2: IMPLEMENTATION                      │
│                                                               │
│  [Database Changes?]                                         │
│  → Skill #4: Database Migration (6 checkpoints)             │
│                                                               │
│  [UI Changes?]                                               │
│  → Skill #7: UI Component (6 checkpoints)                   │
│  → Skill #6: Localization (6 checkpoints)                   │
│                                                               │
│  [Service Changes?]                                          │
│  → Skill #8: Service/Repository (6 checkpoints)             │
│                                                               │
│  [Refactoring?]                                              │
│  → Skill #9: Refactoring (6 checkpoints)                    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   PHASE 3: TESTING                           │
│  Skill #3: Testing Implementation                            │
│  Input: Phase 3 from roadmap                                 │
│  Process: One test at a time with verification               │
│  Output: Complete test suite for issue                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Phase 4:       │
                    │  Documentation  │
                    │  (Manual)       │
                    └─────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PRE-MERGE REVIEW                          │
│  Skill #5: Code Review                                       │
│  Input: Completed issue #XXX                                 │
│  Process: 7-checkpoint systematic review                     │
│  Output: Merge approval + instructions                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    ISSUE CLOSING                             │
│  Skill #10: Issue Closing                                    │
│  Input: Merged code                                          │
│  Output: Issue closed, Project updated                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Real-World Example: Issue #199 (Meal Type Selection)

### Sprint Planning Phase
```
You: "Help me plan sprint 0.1.6"
Claude: [Uses Skill #1: Sprint Planning]
        → Analyzes 8 issues from backlog
        → Estimates capacity: 12 points for 5-day sprint
        → Sequences: #199 (3 pts) in day 4-5
        → Output: Sprint plan document
```

### Issue Planning Phase
```
You: "I want to deal with #199"
Claude: [Uses Skill #2: Issue Roadmap]
        → Fetches issue from GitHub
        → Generates 4-phase roadmap
        → Identifies: DB migration, UI changes, testing needs
        → Output: docs/planning/0.1.5/ISSUE-199-ROADMAP.md
```

### Phase 1: Analysis (Manual)
```
You: Review existing code, understand meal recording flow
```

### Phase 2: Implementation

#### Database Changes
```
You: "Create migration for #199"
Claude: [Uses Skill #4: Database Migration]
        
        CHECKPOINT 1/6: Create migration_v16.dart
        Ready? (y)
        
        CHECKPOINT 2/6: Add meal_type column (nullable)
        Verify: Check schema in SQLite
        Ready? (y)
        
        CHECKPOINT 3/6: Implement rollback
        Verify: Test up → down → up
        Ready? (y)
        
        [Continues through 6 checkpoints]
```

#### UI Changes
```
You: "Implement meal type dropdown"
Claude: [Uses Skill #7: UI Component]
        → Creates MealTypeDropdown widget
        → Adds to MealRecordingDialog
        → Implements state management
```

#### Localization
```
You: "Add localization for meal types"
Claude: [Uses Skill #6: Localization]
        → Adds meal_type_lunch, meal_type_dinner to ARB files
        → Shows usage: AppLocalizations.of(context).mealTypeLunch
```

### Phase 3: Testing
```
You: "Implement Phase 3 testing for #199"
Claude: [Uses Skill #3: Testing Implementation]
        
        Test Plan (6 tests):
        1. Setup
        2. Dropdown displays types
        3. Default selection
        4. Save meal type
        5. Load meal type
        6. Null handling
        
        TEST 1/6: Setup test file
        [Generates ONE test]
        Does it pass? (y)
        
        TEST 2/6: Dropdown displays types
        Learning from TEST 1: [mock patterns]
        [Generates ONE test]
        Does it pass? (y)
        
        [Continues one test at a time]
```

### Phase 4: Documentation (Manual)
```
You: Update README, add code comments
```

### Pre-Merge Review
```
You: "Review #199"
Claude: [Uses Skill #5: Code Review]
        
        CHECKPOINT 1/7: Git status
        ✓ Clean working directory
        
        CHECKPOINT 2/7: Roadmap completion
        ✓ All phases complete
        
        CHECKPOINT 3/7: Acceptance criteria
        ✓ All met
        
        CHECKPOINT 4/7: Technical standards
        Running flutter analyze... ✓ No issues
        Running flutter test... ✓ All pass
        
        [Continues through 7 checkpoints]
        
        === MERGE APPROVED ===
        [Provides merge instructions]
```

### Issue Closing
```
You: "Close #199"
Claude: [Uses Skill #10: Issue Closing]
        → Verifies merge complete
        → Generates: gh issue close 199 --comment "Merged to develop"
        → Updates: Project #3 status → Done
```

---

## Implementation Roadmap

### Phase 1: Core Skills (Weeks 1-2) ✅ READY

**Already Have Prompts:**
0. ✅ Issue Creation Skill
1. ✅ Sprint Planning Skill
2. ✅ Issue Roadmap Skill
3. ✅ Testing Implementation Skill
4. ✅ Database Migration Skill
5. ✅ Code Review Skill
7. ✅ UI Styling & Visual Polish Skill

**Action:** Create these 7 skills using provided prompts

**Expected Impact:**
- Transform informal reports into structured issues
- Complete sprint planning automation
- Systematic issue planning
- One-test-at-a-time testing
- Safe database migrations
- Systematic pre-merge reviews
- Professional UI polish with reusable design tokens

**Estimated Time:** 1-2 days to create all 7 skills

---

### Phase 2: High-Value Additions (Weeks 3-4)

**Priority Order:**

#### 6. Localization Update Skill (High Priority)
**Why:** Bilingual app requires constant localization work
**Effort:** Medium (similar to Database Migration)
**Dependencies:** None
**Impact:** Automates repetitive ARB file updates

**Create When:** After doing 2-3 localization updates manually to understand pain points

---

#### 7. UI Component Implementation Skill (Medium Priority)
**Why:** Many UI changes in typical sprints
**Effort:** Medium-High (more complex patterns)
**Dependencies:** Localization Skill (for integration)
**Impact:** Faster widget creation with conventions

**Create When:** After localization skill proven useful

---

### Phase 3: Specialized Skills (Month 2)

#### 8. Service/Repository Implementation Skill (Lower Priority)
**Why:** Less frequent than UI/testing work
**Effort:** Medium
**Dependencies:** Database Migration, Testing skills
**Impact:** Consistent service layer patterns

**Create When:** When doing major service refactoring (like #237)

---

#### 9. Refactoring Skill (Lower Priority)
**Why:** Occasional, not every sprint
**Effort:** Medium-High (handles many patterns)
**Dependencies:** Testing, Code Review skills
**Impact:** Safer refactoring with maintained coverage

**Create When:** When planning large refactoring work

---

### Phase 4: Completion (Month 3)

#### 10. Issue Closing Skill (Low Priority)
**Why:** Nice-to-have automation
**Effort:** Low (mostly instructions)
**Dependencies:** Code Review skill
**Impact:** Consistent closing workflow

**Create When:** After other skills mature and workflow is smooth

---

## Skill Development Guidelines

### Creating a New Skill

1. **Use it manually first** (3-5 times)
   - Understand the pain points
   - Identify repetitive patterns
   - Note what you wish was automated

2. **Document the manual workflow**
   - Write down your step-by-step process
   - Note where you pause and verify
   - Identify decision points

3. **Design checkpoint structure**
   - Break into 4-6 logical checkpoints
   - Each checkpoint should be verifiable
   - User confirmation between checkpoints

4. **Create the prompt** (use existing prompts as templates)
   - Clear trigger patterns
   - Project-specific context
   - Checkpoint-based flow
   - Examples from your codebase

5. **Test with real issues**
   - Use on actual work
   - Refine based on experience
   - Update prompt as needed

### Maintaining Skills

- **Review every 2-3 sprints:** Are patterns still current?
- **Update after major changes:** New testing patterns? Update skill
- **Share learnings:** Document what works in Sprint Estimation Diary
- **Deprecate if unused:** Don't maintain skills you don't use

---

## Skill Priority Matrix

### Immediate Value (Create First) ✅
- Issue Creation (transforms informal reports to structured issues)
- Sprint Planning
- Issue Roadmap
- Testing Implementation
- Database Migration
- Code Review
- UI Styling & Visual Polish (systematic visual refinement)

### High Value (Create Soon)
- Localization Update
- UI Component Implementation

### Medium Value (Create When Needed)
- Service/Repository Implementation
- Refactoring

### Nice to Have (Create Last)
- Issue Closing

---

## Success Metrics

### How to Know Skills Are Working

**Sprint Planning Skill:**
- Sprints stay within capacity (no overcommitment)
- Realistic estimates based on history
- Clear sequencing reduces context switching

**Issue Roadmap Skill:**
- No missed requirements in implementation
- Fewer "forgot to test X" moments
- Clear stopping points during work

**Testing Implementation Skill:**
- No more "fix 8 tests with same error" scenarios
- Tests pass first time more often
- Faster test writing overall

**Database Migration Skill:**
- No data loss incidents
- Rollback tested every time
- Migrations feel less scary

**Code Review Skill:**
- Fewer bugs found after merge
- Consistent quality standards
- Clear merge decisions

---

## Tips for Success

### Start Small
- Create skills #1-5 first
- Use them for 2-3 sprints
- Refine based on experience
- Then add more skills

### Iterate
- Skills improve with use
- Update prompts as you learn
- Don't be afraid to rewrite

### Be Patient
- First use might feel slower
- Second use is faster
- By fifth use, it's second nature

### Trust the Process
- Checkpoints prevent rushing
- Verification catches issues early
- Steady pace beats hasty speed

---

## Next Steps

1. **Create Core 5 Skills** (Phase 1)
   - Use the 5 prompts provided
   - Create in `.github/skills/` directory
   - Test with current work

2. **Use for 2-3 Sprints**
   - Track effectiveness
   - Note improvements
   - Document issues

3. **Refine and Add More**
   - Update prompts based on experience
   - Add Phase 2 skills when ready
   - Build your complete ecosystem

4. **Share Learnings**
   - Update Sprint Estimation Diary
   - Document skill effectiveness
   - Refine prompts continuously

---

## Conclusion

This skills ecosystem transforms your development workflow from:

**Before:** Manual planning → ad-hoc implementation → rushed testing → hope it works

**After:** Systematic planning → checkpoint-driven implementation → verified testing → confident merge

The checkpoint philosophy ensures:
- ✅ Steady, careful pace
- ✅ Frequent verification
- ✅ Early error detection
- ✅ No frantic surges
- ✅ High-quality results

Start with the 5 core skills, master them, then expand your ecosystem as needed.

---

**Document Version:** 1.0  
**Last Updated:** January 2026  
**Status:** Ready for implementation
