# UI Improvement: Scoreboard Repositioned to Right Side

## Overview

Moved the scoreboard from the top of the game screen to the right side to save vertical space and improve the overall layout during gameplay.

## Changes Made

### Layout Restructure

#### Before (Vertical Layout)

```
┌─────────────────────────────────┐
│         Scoreboard              │
│  Player 1: 5  Player 2: 3       │
├─────────────────────────────────┤
│                                 │
│         Card Image              │
│                                 │
├─────────────────────────────────┤
│      Guess Input / Result       │
└─────────────────────────────────┘
```

#### After (Horizontal Layout)

```
┌─────────────────────────┬──────────┐
│                         │ Score-   │
│     Card Image          │ board    │
│                         │          │
│                         │ P1: 5    │
├─────────────────────────┤ P2: 3    │
│  Guess Input / Result   │          │
└─────────────────────────┴──────────┘
```

### Code Changes

#### Changed from Column to Row

**Before:**

```dart
child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Scoreboard at top
    if (_scores.isNotEmpty)
      Scoreboard(...),
    const SizedBox(height: 16),
    CardDisplay(...),
    // ... rest of content
  ],
)
```

**After:**

```dart
child: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Main content (left side)
    Expanded(
      flex: 3,
      child: Column(
        children: [
          CardDisplay(...),
          // ... rest of content
        ],
      ),
    ),

    // Scoreboard (right side)
    if (_scores.isNotEmpty) ...[
      const SizedBox(width: 20),
      Container(
        width: 250,
        child: Scoreboard(...),
      ),
    ],
  ],
)
```

### Layout Specifications

#### Main Content Area (Left)

- **Flex**: 3 (takes 75% of available width)
- **Alignment**: Center vertically
- **Contains**:
  - Card display
  - Guess input / Result display
  - Waiting message (if applicable)

#### Scoreboard Area (Right)

- **Width**: Fixed 250px
- **Spacing**: 20px from main content
- **Alignment**: Top aligned
- **Visibility**: Only shown when scores exist

#### Responsive Behavior

- Main content expands to fill available space
- Scoreboard maintains fixed width
- Horizontal spacing: 20px between sections
- Vertical padding: 20px all around

## Benefits

### Space Efficiency

✅ **More vertical space** for card display  
✅ **Better use of horizontal space** on wide screens  
✅ **Reduced scrolling** needed during gameplay  
✅ **Card is more prominent** in the center

### User Experience

✅ **Scoreboard always visible** (no need to scroll)  
✅ **Cleaner layout** with better visual hierarchy  
✅ **More focus on the card** (main game element)  
✅ **Better for multiplayer** (scores always in view)

### Visual Design

✅ **Modern layout** utilizing horizontal space  
✅ **Better balance** between elements  
✅ **Professional appearance** similar to game UIs  
✅ **Scalable design** for different screen sizes

## Responsive Considerations

### Wide Screens (Desktop/Tablet Landscape)

- Scoreboard comfortably fits on right
- Main content has plenty of space
- Optimal layout utilization

### Medium Screens (Tablet Portrait)

- Still works well with 250px scoreboard
- Main content area remains usable
- Good balance maintained

### Narrow Screens (Mobile)

- May need future adjustment
- Consider stacking on very narrow screens
- Current layout works for most mobile devices

## Technical Details

### Flex Layout

- Main content uses `Expanded(flex: 3)`
- Takes 75% of available width
- Scoreboard takes remaining 25% (250px fixed)

### Alignment

- Row uses `crossAxisAlignment: CrossAxisAlignment.start`
- Scoreboard aligns to top
- Main content centers vertically

### Conditional Rendering

```dart
if (_scores.isNotEmpty) ...[
  const SizedBox(width: 20),
  Container(
    width: 250,
    child: Scoreboard(...),
  ),
]
```

Only shows when scores exist.

## Visual Comparison

### Before (Vertical)

**Pros:**

- Simple layout
- Works on all screen sizes

**Cons:**

- Takes vertical space
- Card appears smaller
- More scrolling needed

### After (Horizontal)

**Pros:**

- Better space utilization
- Card more prominent
- Scoreboard always visible
- Modern, professional look

**Cons:**

- May need adjustment for very narrow screens

## Files Modified

- `apps/client/lib/screens/game_screen.dart`

## Future Enhancements

1. **Responsive Breakpoints**
   - Stack vertically on screens < 768px
   - Horizontal layout on larger screens

2. **Collapsible Scoreboard**
   - Add toggle to hide/show
   - Save screen space when needed

3. **Scoreboard Animations**
   - Slide in from right
   - Highlight score changes

4. **Adaptive Width**
   - Adjust scoreboard width based on player count
   - Smaller for 2 players, larger for 4+

5. **Mobile Optimization**
   - Floating scoreboard overlay
   - Swipe to reveal/hide

## Testing Checklist

- [x] Scoreboard appears on right side
- [x] Main content properly centered
- [x] 20px spacing between sections
- [x] Scoreboard width is 250px
- [x] Layout works with multiple players
- [x] No overflow issues
- [x] Responsive to window resize
- [x] All game interactions still work
