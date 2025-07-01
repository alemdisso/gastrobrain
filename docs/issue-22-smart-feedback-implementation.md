<!-- markdownlint-disable -->
# Issue #22: Smart Feedback System Implementation Plan

## Overview

This document outlines the implementation plan for Issue #22, which originally requested a Tinder-like swipe UI but was strategically pivoted to a smart feedback system based on the existing recommendation infrastructure.

## Strategic Decision

We chose to implement a **smart feedback integration** instead of complex swipe UI because:

- ✅ **90% of infrastructure already exists**: UserResponse enum, recommendation history, scoring engine
- ✅ **Better ROI**: Sophisticated recommendation personalization with minimal effort
- ✅ **Lower complexity**: 1-2 days vs 1-2 weeks implementation time
- ✅ **Immediate impact**: Users get personalized recommendations right away

## Feedback System Design

### Feedback Categories

#### 1. Immediate Actions (No Learning Impact)
- **"Not Today"** (`UserResponse.notToday`)
  - *Behavior*: Remove from current session only, no future impact
  - *Use Case*: "Good recipe, just not feeling it right now"
  - *UI*: ❌ "Skip" button

#### 2. Soft Feedback (Gentle Learning)
- **"Less Often"** (`UserResponse.lessOften`)
  - *Behavior*: Reduce future scoring by 15-20%
  - *Use Case*: "I don't hate it, but please suggest it less often"
  - *UI*: 👎 "Less Often" button

- **"More Often"** (`UserResponse.moreOften`)
  - *Behavior*: Boost future scoring by 15-20%
  - *Use Case*: "Great suggestion, show me this more often"
  - *UI*: ❤️ "More Often" button

#### 3. Hard Actions (Strong Learning Impact)
- **"Never Again"** (`UserResponse.neverAgain`)
  - *Behavior*: Reduce scoring by 40-50%
  - *Use Case*: "I really don't like this recipe"
  - *UI*: 🚫 "Never Again" button (requires confirmation)

### Extended UserResponse Enum

```dart
enum UserResponse { 
  // Existing responses
  accepted,     // Recipe was selected for meal plan
  rejected,     // Hard rejection 
  saved,        // Recipe saved for later
  ignored,      // No action taken
  
  // New feedback responses
  notToday,     // Dismissed for this session only (no learning impact)
  lessOften,    // Soft negative feedback - reduce recommendation frequency
  moreOften,    // Soft positive feedback - increase recommendation frequency  
  neverAgain,   // Strong negative feedback - significant penalty
}
```

## Implementation Phases

### Phase 1: Core Feedback ✅ COMPLETED
**Timeline**: 1-2 days  
**Status**: ✅ Done

#### Tasks Completed:
1. ✅ Extended `UserResponse` enum with 4 new feedback values
2. ✅ Added localization strings (English & Portuguese)
3. ✅ Enhanced `RecipeSelectionCard` widget with feedback buttons
4. ✅ Connected buttons to existing `updateRecommendationResponse()` method
5. ✅ Implemented session-only filtering for "Not Today" responses
6. ✅ Updated recommendation generation to save history for feedback tracking
7. ✅ Wrote comprehensive tests for new functionality

#### Files Modified:
- `lib/models/recipe_recommendation.dart` - Extended UserResponse enum
- `lib/widgets/recipe_selection_card.dart` - Added feedback UI
- `lib/screens/weekly_plan_screen.dart` - Connected feedback to database
- `lib/l10n/app_en.arb` & `lib/l10n/app_pt.arb` - Added localized strings
- `test/models/user_response_tracking_test.dart` - Added feedback tests

#### Technical Implementation:
- **UI Integration**: Feedback buttons appear below recipe badges in RecipeSelectionCard
- **Database Integration**: Uses existing `updateRecommendationResponse()` method
- **History Tracking**: Recommendation history is automatically saved when generating recommendations
- **Session Filtering**: "Not Today" responses remove recipes from current session only

### Phase 2: Learning Integration 🔄 IN PROGRESS
**Timeline**: 2-3 days  
**Status**: 🔄 Next Phase

#### Planned Tasks:
1. 🔄 Create `UserFeedbackFactor` for recommendation engine
2. ⏳ Implement scoring adjustments based on feedback history
3. ⏳ Add feedback weights to recommendation service configuration
4. ⏳ Test and tune feedback impact levels
5. ⏳ Add temporal decay for feedback (6-12 months)

#### Behavioral Impact Design:
- **notToday**: No impact on future scores
- **lessOften**: -15% penalty to FrequencyFactor and VarietyEncouragementFactor
- **moreOften**: +20% boost to FrequencyFactor 
- **neverAgain**: -40% penalty across multiple factors
- **accepted**: +25% boost (existing positive feedback)

#### Technical Approach:
- Create new scoring factor that reads recommendation history
- Apply feedback-based score adjustments during recommendation generation
- Implement feedback decay over time to prevent permanent penalties
- Add context awareness (weekday vs weekend feedback differences)

### Phase 3: UX Polish ⏳ FUTURE
**Timeline**: 1-2 days  
**Status**: ⏳ Future Enhancement

#### Planned Tasks:
1. ⏳ Add haptic feedback for button interactions
2. ⏳ Implement progressive disclosure UI (long press for advanced options)
3. ⏳ Add confirmation dialogs for "Never Again" actions
4. ⏳ Visual feedback state indicators (show previous responses)
5. ⏳ Enhanced animations for feedback actions
6. ⏳ Accessibility improvements for feedback system

## Current Architecture Integration

### Existing Infrastructure Leveraged:
- **Database Schema**: `recommendation_history` table with JSON serialization
- **Scoring Engine**: 6-factor recommendation system ready for new factor
- **UI Components**: `RecipeSelectionCard` and recommendation display system
- **Service Layer**: `RecommendationService` with pluggable factor architecture

### Database Flow:
1. **Recommendation Generation**: Saves to `recommendation_history` table with unique ID
2. **User Feedback**: Updates specific recommendation in history via `updateRecommendationResponse()`
3. **Future Recommendations**: New factor reads feedback history to adjust scores

## Testing Strategy

### Completed Tests:
- ✅ UserResponse enum serialization/deserialization
- ✅ Feedback database storage and retrieval
- ✅ All existing tests continue to pass

### Planned Tests for Phase 2:
- ⏳ UserFeedbackFactor scoring calculations
- ⏳ Feedback impact on recommendation rankings
- ⏳ Temporal decay functionality
- ⏳ Integration tests for complete feedback flow

## Success Metrics

### Phase 1 Success Criteria ✅:
- ✅ Users can provide feedback on recipe recommendations
- ✅ Feedback is persistently stored in database
- ✅ "Not Today" removes recipes from current session
- ✅ No existing functionality is broken

### Phase 2 Success Criteria 🔄:
- 🔄 Feedback visibly affects future recommendation rankings
- ⏳ Users see fewer "Less Often" recipes in subsequent sessions
- ⏳ Users see more "More Often" recipes in subsequent sessions
- ⏳ "Never Again" recipes effectively disappear from recommendations

### Phase 3 Success Criteria ⏳:
- ⏳ Feedback system feels polished and intuitive
- ⏳ Strong actions (Never Again) require confirmation
- ⏳ Users can see their previous feedback on recipes

## Future Enhancements

### Potential Swipe UI Integration:
After smart feedback is complete, the original swipe UI could be added as an **alternate input method**:
- Swipe left = "Less Often"
- Swipe right = "More Often"  
- Swipe up = "More Often" (stronger)
- Swipe down = "Not Today"

This would provide both button-based and gesture-based interaction while leveraging the same underlying feedback system.

### Analytics and Insights:
- User feedback patterns analysis
- Recipe recommendation improvement tracking
- A/B testing different feedback scoring weights

## Conclusion

The smart feedback system provides immediate value by leveraging existing infrastructure while maintaining the option for future UI enhancements. Phase 1 delivers a complete feedback collection system, Phase 2 adds the intelligence, and Phase 3 polishes the experience.

This approach follows the **deliberate, step-by-step methodology** outlined in CLAUDE.md, ensuring quality implementation with proper testing and validation at each stage.