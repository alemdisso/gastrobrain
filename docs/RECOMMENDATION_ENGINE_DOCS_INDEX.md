# Recommendation Engine Documentation Index

## Quick Navigation

This index provides an overview of all recommendation engine documentation and guides developers to the right resource.

## Documents Included

### 1. ANALYSIS_SUMMARY.md (7.8 KB)
**Best for**: Executive overview and quick understanding of issues

**Contents:**
- Analysis scope and key findings
- Positive aspects (multi-ingredient support works)
- 4 issues identified with severity levels
- Code architecture overview
- Test coverage analysis
- Actionable recommendations (high/medium/low priority)
- Conclusion and next steps

**Read this first** to get a complete picture of the recommendation engine analysis.

### 2. recommendation-engine-analysis.md (22 KB)
**Best for**: Deep technical understanding and implementation details

**Contents:**
- Detailed implementation of ProteinRotationFactor
- Multi-ingredient recipe handling walkthrough
- getRecipeProteinTypes() method analysis
- VarietyEncouragementFactor implementation
- RecommendationDatabaseQueries methods documentation
- Context building process
- Edge cases and error handling
- Testing coverage assessment
- Issue analysis with code examples

**Read this** when implementing changes or understanding the full system.

### 3. recommendation-architecture-diagram.txt (11 KB)
**Best for**: Visual understanding of system flow and architecture

**Contents:**
- 4-layer architecture visualization
- Database access layer diagram
- Context building layer diagram
- Recommendation factors layer diagram
- Scoring and ranking layer diagram
- Multi-ingredient recipe flow example (step-by-step)
- Duplicate protein issue illustration
- ASCII diagrams for all components

**Reference this** when explaining the system to others or planning changes.

### 4. recommendation-quick-reference.md (7.6 KB)
**Best for**: Developer quick lookup and debugging

**Contents:**
- File locations table
- Key methods reference with code examples
- Protein rotation factor quick reference
- Variety encouragement factor details
- Context data structure
- Database query methods summary
- Known issues and workarounds
- Testing information
- Performance notes
- Debugging tips with code snippets
- Weight profiles
- Extension guidelines

**Use this** while coding or debugging recommendation-related issues.

### 5. recommendation-scoring-algorithm.md (existing)
**Best for**: Algorithm documentation and scoring formulas

**Contents:**
- Factor details and weights
- Scoring formulas with examples
- Performance optimization notes

**Reference** for understanding the mathematical basis of scoring.

## Quick Issue Reference

Found an issue? Here's where to look:

| Issue | Summary | Location |
|-------|---------|----------|
| Duplicate proteins in scoring | Same protein counted multiple times | ANALYSIS_SUMMARY, recommendation-engine-analysis (Issue 1) |
| Secondary recipes ignored | Multi-recipe meals only use primary | ANALYSIS_SUMMARY, recommendation-engine-analysis (Issue 2) |
| Custom ingredients unsupported | Can't set protein type for custom ingredients | ANALYSIS_SUMMARY, recommendation-engine-analysis (Issue 3) |
| Hard-coded meal limits | 20 meals, 14-day limit hard-coded | ANALYSIS_SUMMARY, recommendation-engine-analysis (Issue 4) |

## Code Locations Quick Reference

| Component | File | Key Methods |
|-----------|------|-------------|
| Protein Rotation Factor | `lib/core/services/recommendation_factors/protein_rotation_factor.dart` | `calculateScore()` |
| Variety Factor | `lib/core/services/recommendation_factors/variety_encouragement_factor.dart` | `calculateScore()` |
| Database Queries | `lib/core/services/recommendation_database_queries.dart` | `getRecipeProteinTypes()`, `getRecentMeals()`, `getMealCounts()` |
| Main Service | `lib/core/services/recommendation_service.dart` | `getRecommendations()`, `_buildContext()`, `_scoreRecipes()` |
| Protein Type Model | `lib/models/protein_type.dart` | Enum with 10 protein types |
| Tests | `test/core/services/recommendation_factors/` | Various test files |

## Recommended Reading Order

### For New Team Members
1. Start with **ANALYSIS_SUMMARY.md** (5-10 min read)
2. Review **recommendation-architecture-diagram.txt** (5 min visual scan)
3. Skim **recommendation-quick-reference.md** (2 min bookmark)

### For Implementing Changes
1. Review **ANALYSIS_SUMMARY.md** recommendations section
2. Read relevant sections in **recommendation-engine-analysis.md**
3. Reference **recommendation-quick-reference.md** for code examples
4. Use **recommendation-scoring-algorithm.md** for formula verification

### For Debugging Issues
1. Consult **recommendation-quick-reference.md** debugging tips
2. Reference **recommendation-architecture-diagram.txt** for flow
3. Use **recommendation-engine-analysis.md** for detailed code examination

## Implementation Checklist

### High Priority: Fix Duplicate Protein Counting
- [ ] Read Issue 1 in ANALYSIS_SUMMARY.md
- [ ] Review code section "Step 5" in recommendation-engine-analysis.md
- [ ] Review "Duplicate Proteins" section in recommendation-architecture-diagram.txt
- [ ] Implement deduplication (Set vs List)
- [ ] Add test cases for duplicate proteins
- [ ] Update quick-reference.md with fix

### Medium Priority: Secondary Recipe Support
- [ ] Read Issue 2 in ANALYSIS_SUMMARY.md
- [ ] Review getRecentMeals() documentation
- [ ] Design multi-recipe handling
- [ ] Implement and test
- [ ] Update architecture diagram

### Medium Priority: Custom Ingredient Support
- [ ] Read Issue 3 in ANALYSIS_SUMMARY.md
- [ ] Design custom_protein_type field
- [ ] Update database schema
- [ ] Update getRecipeProteinTypes() logic
- [ ] Add tests

### Low Priority: Parameterize Limits
- [ ] Read Issue 4 in ANALYSIS_SUMMARY.md
- [ ] Move hardcoded values to config
- [ ] Update getRecentMeals() call site

## Key Takeaways

1. **Multi-ingredient recipes are supported** through averaging penalties
   - All ingredients fetched from database
   - All proteins extracted and considered
   - Penalties averaged across all main proteins

2. **4 issues identified**, mostly low-to-medium severity
   - Most critical: Duplicate protein counting
   - Others: Secondary recipes, custom ingredients, hard-coded limits

3. **System is well-architected**
   - Clean separation of concerns (DB → Context → Factors → Scoring)
   - Extensible factor system
   - Proper error handling

4. **Test coverage is good but has gaps**
   - Missing tests for multi-ingredient edge cases
   - Should add multi-recipe meal tests
   - Good baseline for expansion

## Contributing

When contributing to the recommendation engine:

1. Update relevant documentation when changing code
2. Add tests for edge cases (see test gap section)
3. Reference this index in PRs
4. Consider performance implications (see performance notes in quick-reference)

## Questions?

- **"How does protein rotation work?"** → recommendation-engine-analysis.md, Section 1
- **"Where's the scoring formula?"** → recommendation-scoring-algorithm.md
- **"How do I debug a recommendation issue?"** → recommendation-quick-reference.md Debugging Tips
- **"What are the known issues?"** → ANALYSIS_SUMMARY.md Issues section
- **"How does data flow through the system?"** → recommendation-architecture-diagram.txt

---

**Last Updated**: 2025-11-06
**Analysis Tool**: Claude Code (Haiku 4.5)
**Total Documentation**: 48.4 KB across 5 files
