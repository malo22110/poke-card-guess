# Bug Fix: Last Round Score Not Added

## Issue

The last round's score was not being properly reflected in the final game results.

## Root Cause Analysis

### Original Flow

1. Player guesses correctly on last round
2. Score is incremented in backend
3. `roundFinished: true` is returned
4. `currentRound` is incremented (now > total rounds)
5. Gateway schedules next round after 3 seconds
6. `getCurrentRoundData` returns FINISHED status with scores

### The Problem

The scores WERE being calculated and stored correctly, but the response from `makeGuess` didn't include the updated scores. The frontend had to wait for the `nextRound` event to get the scores, but by then the game was already finished.

## Solution

### Changes Made

#### 1. Include Scores in Guess Response

**File:** `apps/server/src/game/game.service.ts`

Added scores to the `makeGuess` response:

```typescript
const result = {
  correct: true,
  name: currentCard.name,
  fullImageUrl: currentCard.fullImageUrl,
  set: currentCard.set,
  roundFinished: allFinished,
  scores: Object.fromEntries(lobby.scores), // ✅ Added
  currentRound: lobby.currentRound, // ✅ Added
  totalRounds: lobby.config.rounds, // ✅ Added
};
```

#### 2. Added Comprehensive Logging

To help debug score issues in the future:

```typescript
console.log(
  `[Score Update] User ${userId} scored! New score: ${currentScore + 1}`
);
console.log(
  `[Round Info] Current round: ${lobby.currentRound}/${lobby.config.rounds}`
);
console.log(
  `[Round Complete] All players finished round ${lobby.currentRound}`
);
console.log(`[Scores] Current scores:`, Object.fromEntries(lobby.scores));
console.log(`[Round Advance] Advanced to round ${lobby.currentRound}`);
console.log(`[Game Finished] Final scores:`, finalScores);
```

#### 3. Enhanced getCurrentRoundData

Added logging when game finishes:

```typescript
if (lobby.currentRound > lobby.cards.length) {
  lobby.status = "FINISHED";
  const finalScores = Object.fromEntries(lobby.scores);
  console.log(`[Game Finished] Final scores:`, finalScores);
  return {
    status: "FINISHED",
    scores: finalScores,
  };
}
```

## Impact

### Before Fix

- Frontend didn't receive scores immediately after last guess
- Had to wait for `nextRound` event
- Scores might appear delayed or missing

### After Fix

- ✅ Scores included in every guess response
- ✅ Frontend can update scoreboard immediately
- ✅ Last round score is always reflected
- ✅ Comprehensive logging for debugging

## Testing

### Manual Test Steps

1. Create a game with 3 rounds
2. Play through all rounds
3. On the last round, make a correct guess
4. Verify score increments immediately
5. Verify final scores are correct

### Expected Behavior

- Score updates immediately on correct guess
- Last round score is included in final tally
- No delay in score display
- Console logs show score progression

### Console Output Example

```
[Score Update] User user123 scored! New score: 3
[Round Info] Current round: 3/3
[Round Complete] All players finished round 3
[Scores] Current scores: { user123: 3 }
[Round Advance] Advanced to round 4
[Game Finished] Final scores: { user123: 3 }
```

## Files Modified

- `apps/server/src/game/game.service.ts`

## Related Issues

- Scores not updating in real-time
- Last round score missing
- Delayed score display

## Future Improvements

1. Add score validation tests
2. Implement score history tracking
3. Add score change animations in frontend
4. Consider adding score breakdown by round
