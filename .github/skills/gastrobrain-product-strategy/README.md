# Gastrobrain Product Strategy & Health Skill

## Overview

The Product Strategy & Health skill acts as your combined Product Owner and Tech Lead - a strategic partner who helps you maintain the "wide picture" perspective on Gastrobrain's development. It ensures you balance feature delivery with code quality, manage technical debt proactively, and make strategic decisions that keep the project healthy and sustainable long-term.

**Think of it as:** Your strategic advisor who steps back from the day-to-day implementation to ask "Are we building the right things? Is our codebase healthy? Are we sustainable?"

## The Problem This Solves

As a solo developer, you can easily fall into these traps:

- **Feature factory syndrome** - Building feature after feature without time for quality
- **Tech debt accumulation** - Postponing refactoring until it becomes overwhelming
- **Unbalanced roadmaps** - 90% features, 10% quality work
- **Short-term thinking** - Optimizing for this sprint, not next quarter
- **Priority confusion** - "Everything is important!"
- **Quality erosion** - Code gets messier, tests get skipped, velocity slows

**This skill prevents those traps** by providing strategic guidance grounded in data and best practices.

## When to Use This Skill

### Trigger Scenarios

Use this skill when you need strategic guidance:

- **"Review the roadmap"** - Check if your plan is balanced and strategic
- **"Help me prioritize the backlog"** - Score and rank issues strategically
- **"Is my milestone balanced?"** - Validate feature/quality ratio
- **"Should I focus on features or quality?"** - Get data-driven recommendation
- **"What should I work on next?"** - Strategic priority guidance
- **"Strategic review of 0.X.Y"** - Full health and balance assessment
- **"Planning next quarter"** - Long-term strategic planning
- **"Is it time for a tech debt sprint?"** - Evaluate if quality sprint needed

### Common Trigger Phrases

- "Review the roadmap"
- "Help me prioritize"
- "Is this milestone balanced?"
- "Should I do refactoring now?"
- "What's my strategic priority?"
- "Evaluate project health"
- "Plan next quarter"

## How It Works

### The 5-Checkpoint Strategic Review

This skill uses a systematic 5-checkpoint process:

#### 1. Project Health Assessment 🏥
**Evaluates:** Code quality, technical debt, testing health, architecture sustainability

**Provides:** Health status indicators (🟢🟡🔴) for each dimension

**Example:**
```
Code Quality: 🟡 WARNING - 3 files >400 lines
Tech Debt: 🟢 HEALTHY - 18% of backlog, addressed quarterly
Testing: 🟢 HEALTHY - 87% coverage, 600+ tests growing
Architecture: 🟢 HEALTHY - Clean service layer, good separation
```

#### 2. Milestone Balance Analysis ⚖️
**Evaluates:** Feature vs. quality ratio using 70/20/10 rule

**Provides:** Balance assessment and adjustment recommendations

**Example:**
```
Current: 67% features, 24% quality, 9% other
Target: 70% features, 30% quality
Assessment: 🟢 HEALTHY - Well-balanced milestone
```

#### 3. Priority Recommendations 🎯
**Evaluates:** Strategic priority scores for issues

**Provides:** Top priorities, deferrals, and rationale

**Example:**
```
#250 Save button bug (Score: 18/20) → Do immediately
#199 Meal type feature (Score: 16/20) → Next sprint
#5 Shopping list (Score: 13/20) → Defer until design ready
```

#### 4. Roadmap Adjustments 🗺️
**Evaluates:** Whether current plan needs changes

**Provides:** Specific move-in/move-out recommendations

**Example:**
```
Move Out: #172 (instructions view) - nice-to-have
Move In: Create refactoring for WeeklyPlanScreen (>500 lines)
Result: Better balance (60% features, 35% quality)
```

#### 5. Action Plan ✅
**Provides:** Concrete next steps and success metrics

**Example:**
```
Immediate Actions:
- [ ] Add refactoring issue for WeeklyPlanScreen
- [ ] Defer #172 and #148 to next milestone
- [ ] Schedule tech debt sprint for Q2

Next Review: End of current sprint
Success Metrics: All files <400 lines by 0.1.8
```

## The 70/20/10 Balance Rule

### Recommended Allocation

For sustainable development, allocate sprint capacity as:

- **70% User Value** - Features, enhancements, UX improvements
- **20% Quality Work** - Testing, refactoring, tech debt
- **10% Innovation** - Exploration, prototypes, experiments

### Why This Matters

**Too much feature work (>80%):**
- ❌ Technical debt accumulates
- ❌ Code quality degrades
- ❌ Velocity slows over time
- ❌ Developer friction increases

**Too much quality work (>40%):**
- ❌ Feature delivery slows
- ❌ User value delayed
- ❌ Momentum lost

**Just right (70/20/10):**
- ✅ Sustainable velocity
- ✅ Code stays healthy
- ✅ Consistent feature delivery
- ✅ Proactive debt management

## Priority Scoring Framework

### How Issues Are Scored

Each issue evaluated across 4 dimensions:

1. **User Impact (1-5)** - How many users? How painful?
2. **Strategic Value (1-5)** - Vision alignment? Future enablement?
3. **Technical Health (1-5)** - Reduces debt? Improves architecture?
4. **Effort Score (1-5 inverted)** - Quick wins score higher

**Formula:** `(User Impact × 2) + Strategic + Health + Effort`

**Maximum:** 20 points (critical priority)
**Minimum:** 4 points (defer/avoid)

### Priority Levels

- **18-20: 🔴 CRITICAL** - Do immediately
- **15-17: 🟡 HIGH** - Next sprint
- **12-14: 🟢 MEDIUM** - Near-term backlog
- **8-11: ⚪ LOW** - Later backlog
- **4-7: ⚫ AVOID** - Reconsider if worth doing

## Health Indicators

### Code Quality Health

🟢 **HEALTHY:**
- Most files <300 lines
- No files >500 lines
- Regular refactoring every 2-3 sprints

🟡 **WARNING:**
- Multiple files 300-400 lines
- 1-2 files >400 lines
- Refactoring overdue (3+ sprints)

🔴 **CRITICAL:**
- Files >500 lines present
- No refactoring in 4+ sprints
- Velocity declining

### Technical Debt Health

🟢 **HEALTHY:**
- <20% of backlog is tech debt
- Addressed quarterly
- No debt >6 months old

🟡 **WARNING:**
- 20-40% of backlog is tech debt
- Addressed occasionally
- Some debt >6 months old

🔴 **CRITICAL:**
- >40% of backlog is tech debt
- Rarely addressed
- Debt >1 year old present

### Testing Health

🟢 **HEALTHY:**
- Coverage >85%
- Growing test suite
- Tests rarely break

🟡 **WARNING:**
- Coverage 70-85%
- Stagnant test suite
- Tests break occasionally

🔴 **CRITICAL:**
- Coverage <70%
- Declining test count
- Tests break frequently

## Tech Debt Sprint Planning

### When to Schedule

**Quarterly Pattern (Recommended):**
- Every 3-4 feature sprints
- 1 dedicated quality sprint
- 80% refactoring/testing, 20% critical bugs

**Immediate Sprint Needed When:**
- 🔴 Multiple files >500 lines
- 🔴 Test coverage <70%
- 🔴 Velocity declining >20%
- 🔴 >40% backlog is tech debt
- 🔴 Debt >1 year old present

### Tech Debt Sprint Structure

**Focus:** 80% quality, 20% critical bugs only

**Composition:**
- 50% Refactoring (large files, god classes, duplication)
- 30% Testing (coverage gaps, edge cases, E2E tests)
- 10% Documentation (architecture, patterns, READMEs)
- 10% Critical Bugs (P0 only, defer rest)

**Success Criteria:**
- All files <400 lines
- Test coverage >85%
- All debt >6 months closed
- Developers report reduced friction

## Review Cadence

### Monthly Strategic Review (Recommended)

**When:** First week of each month
**Duration:** 30-45 minutes
**Scope:** Full 5-checkpoint review

**Outcome:** Strategic review document with action plan

### Quarterly Planning (Recommended)

**When:** Start of each quarter
**Duration:** 1-2 hours
**Scope:** Deep strategic review

**Outcome:** Quarterly strategic plan with multi-milestone roadmap

### Sprint Review (Optional)

**When:** End of each sprint
**Duration:** 10-15 minutes
**Scope:** Quick health check

**Outcome:** Brief status update

## Integration with Other Skills

This skill works seamlessly with:

| Skill | How They Work Together |
|-------|------------------------|
| **Issue Roadmap** | Strategy validates roadmap balance before detailed planning |
| **Sprint Planning** | Ensures sprints are strategically aligned |
| **Refactoring** | Identifies when refactoring work needed |
| **Testing Implementation** | Ensures testing gets protected time |
| **UX Design** | Validates feature priorities align with user value |
| **Code Review** | Quality trends inform strategy |

## Skill Components

### SKILL.md
Main skill file containing:
- 5-checkpoint strategic review framework
- Project health assessment metrics and indicators
- Milestone balance rules (70/20/10)
- Priority scoring framework
- Roadmap adjustment patterns
- Tech debt sprint planning guide
- Architectural health assessment
- Review cadence recommendations

### templates/
Ready-to-use planning templates:
- **monthly_review_template.md** - Monthly strategic review document
- **quarterly_planning_template.md** - Quarterly planning document
- **tech_debt_sprint_template.md** - Tech debt sprint planning document

### examples/
Complete strategic review examples:
- **example_1_monthly_review.md** - Full 5-checkpoint monthly review
- **example_2_milestone_rebalancing.md** - Rebalancing an unbalanced milestone
- **example_3_tech_debt_sprint_planning.md** - When and how to plan quality sprint

## Quick Start Example

```
You: "Review the roadmap for 0.1.6"

Claude: [Loads Product Strategy & Health skill]

CHECKPOINT 1: Project Health Assessment

Analyzing Gastrobrain health metrics...

📊 Code Quality: 🟡 WARNING
- 3 files >400 lines (WeeklyPlanScreen: 547)
- Average: 287 lines (good)
- Last refactoring: 2 sprints ago (due)

📊 Technical Debt: 🟢 HEALTHY
- 6 tech debt issues (18% of backlog)
- Addressed quarterly

📊 Testing: 🟢 HEALTHY
- 600+ tests, 87% coverage
- Growing consistently

Overall: 🟢 GOOD HEALTH with 🟡 refactoring needed

Recommendation: Add refactoring for WeeklyPlanScreen (>500 lines)

Agree with assessment? (y/n)

[Continues through 5 checkpoints with user confirmation]
```

## Success Metrics

This skill is successful when:

- ✅ Roadmaps maintain 60-75% features, 25-35% quality balance
- ✅ Technical debt stays <20% of backlog
- ✅ Tech debt sprints scheduled quarterly
- ✅ No files >500 lines accumulate
- ✅ Test coverage remains >85%
- ✅ Velocity stable or improving
- ✅ Priorities validated strategically
- ✅ Quality work gets protected time

## The "Wide Picture" Promise

This skill ensures you never lose sight of:

- 🎯 **Strategic direction** - Building the right things
- 🏗️ **Code health** - Sustainable codebase
- ⚖️ **Balance** - Adequate quality work time
- 🔮 **Long-term vision** - Future milestone preparation
- 📊 **Metrics** - Objective health tracking
- 🚀 **Velocity** - Sustainable development pace

## Related Documentation

- [Issue Roadmap Skill](../gastrobrain-issue-roadmap/) - Detailed issue planning
- [Sprint Planning Skill](../gastrobrain-sprint-planning/) - Sprint execution planning
- [Refactoring Skill](../gastrobrain-refactoring/) - Code quality improvement
- [Testing Implementation Skill](../gastrobrain-testing-implementation/) - Test coverage
- [Architecture Documentation](../../docs/architecture/Gastrobrain-Codebase-Overview.md)

---

**Version**: 1.0.0
**Last Updated**: 2026-01-25
**Maintainer**: Gastrobrain Development Team

## Your Strategic Partner

You're not just a developer - you're building a product. This skill helps you think like a Product Owner and Tech Lead, making strategic decisions that balance user value with technical excellence for long-term success.

**Use it regularly. Listen to its recommendations. Keep your project healthy.**
