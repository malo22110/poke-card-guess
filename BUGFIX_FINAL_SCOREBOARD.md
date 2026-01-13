# Bug Fix: Final Scoreboard Shows Incorrect Score

## Issue

The final scoreboard was displaying 9 instead of 10 when a player scored on all 10 rounds. The score during gameplay was correct, but the final score displayed after game completion was off by 1.

## Root Cause

### Backend (✅ Working Correctly)

The backend was calculating and sending scores correctly:

```
[Score Update] User guest-host-2jzpa1z0o scored! New score: 10
[Round Info] Current round: 10/10
[Round Complete] All players finished round 10
[Scores] Current scores: { 'guest-host-2jzpa1z0o': 10 }
[Round Advance] Advanced to round 11
[Game Finished] Final scores: { 'guest-host-2jzpa1z0o': 10 }
```

### Frontend (❌ Bug Found)

The Flutter app had two issues:

1. **Missing Score Update on Game Finish**
   - When `status: 'FINISHED'` was received, the app showed the error state
   - But it **didn't extract the final scores** from the response
   - The `_scores` map still had values from the previous round

2. **Local Score Increment Instead of Server Sync**
   - The `_showResult` method was incrementing score locally (`score++`)
   - This didn't sync with the server's authoritative score
   - Could lead to score drift over time

## Solution

### Fix 1: Update Scores on Game Finish

**File:** `apps/client/lib/screens/game_screen.dart`

**Before:**

```dart
if (data['status'] == 'FINISHED') {
   setState(() {
     error = 'Game Finished!';
     _isLoading = false;
   });
   return;
}
```

**After:**

```dart
if (data['status'] == 'FINISHED') {
   setState(() {
     // Extract final scores before showing finished state
     if (data['scores'] != null) {
       _scores = Map<String, int>.from(data['scores']);
     }
     error = 'Game Finished!';
     _isLoading = false;
   });
   return;
}
```

### Fix 2: Sync Scores from Server

**File:** `apps/client/lib/screens/game_screen.dart`

**Before:**

```dart
if (_isCorrect == true) {
  score++; // Simple local score update
  score = score;
}
```

**After:**

```dart
// Update scores from server response if available
if (result['scores'] != null) {
  _scores = Map<String, int>.from(result['scores']);
  // Update local score for header display
  if (_guestId != null && _scores.containsKey(_guestId)) {
    score = _scores[_guestId]!;
  }
} else if (_isCorrect == true) {
  // Fallback: increment local score if server didn't send scores
  score++;
}
```

## Impact

### Before Fix

- ❌ Final scoreboard showed score from round 9
- ❌ Last round score not reflected in final display
- ❌ Local score could drift from server score

### After Fix

- ✅ Final scoreboard shows correct score (10/10)
- ✅ Scores synced from server on every guess
- ✅ Header score and scoreboard always match
- ✅ No score drift between client and server

## Data Flow

### Correct Flow (After Fix)

```
Round 10 Guess (Correct)
         ↓
Backend: Score = 10
         ↓
Response: { correct: true, scores: { user: 10 } }
         ↓
Frontend: Updates _scores map
         ↓
Frontend: Updates header score = 10
         ↓
Round advances to 11 (> 10 total)
         ↓
Backend: Returns FINISHED with scores: { user: 10 }
         ↓
Frontend: Updates _scores map with final scores
         ↓
Final Scoreboard: Displays 10 ✅
```

## Testing

### Manual Test Steps

1. Create a game with 10 rounds
2. Answer all 10 questions correctly
3. Observe score incrementing: 1, 2, 3... 10
4. Wait for game to finish
5. Verify final scoreboard shows 10/10

### Expected Behavior

- Score updates immediately after each correct guess
- Header shows current score
- Scoreboard shows all players' scores
- Final scoreboard displays correct total score
- No discrepancy between gameplay score and final score

## Files Modified

- `apps/client/lib/screens/game_screen.dart`

## Related Fixes

- Backend already includes scores in guess responses (previous fix)
- Backend logging shows correct score progression
- This fix ensures frontend properly consumes that data

## Prevention

To prevent similar issues:

1. Always sync scores from server responses
2. Never rely solely on local score increments
3. Extract and update scores on every state change
4. Test final state transitions thoroughly
