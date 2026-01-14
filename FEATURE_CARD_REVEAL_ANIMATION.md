# Feature: Smooth Fade Animation for Card Reveal

## Overview

Enhanced the card reveal experience by implementing a smooth fade-in animation. Instead of abruptly switching from the cropped "Who's that Pokemon?" view to the full card, the full card now gently fades in over the mystery view.

## Changes Made

### 1. Converted to StatefulWidget

Refactored `CardDisplay` from `StatelessWidget` to `StatefulWidget` to manage animation state.

### 2. Animation Controller

Added `AnimationController` and `FadeTransition`:

```dart
_animationController = AnimationController(
  duration: const Duration(milliseconds: 800), // Smooth 800ms fade
  vsync: this,
);

_fadeAnimation = CurvedAnimation(
  parent: _animationController,
  curve: Curves.easeInOut, // Natural easing
);
```

### 3. Layered Stack Layout

Changed the layout to keep the cropped card visible underneath while fading the full card on top:

```dart
Stack(
  children: [
    // Layer 1: Always show cropped card as base
    _buildCroppedCard(),

    // Layer 2: Fade in full card on top
    if (widget.showFullCard)
      FadeTransition(
        opacity: _fadeAnimation,
        child: _buildFullCard(),
      ),
  ],
)
```

### 4. Animation Logic

Automatically triggers animation when card is revealed:

```dart
if (!oldWidget.showFullCard && widget.showFullCard) {
  _animationController.forward(); // Fade In
} else if (oldWidget.showFullCard && !widget.showFullCard) {
  _animationController.reverse(); // Fade Out (reset)
}
```

## Benefits

### User Experience

✅ **Premium Feel**: Smooth 800ms transition creates a polished look  
✅ **Visual Continuity**: No abrupt flashing or switching content  
✅ **Context Retention**: The "mystery" remains visible until the reveal completes  
✅ **Engaging**: Makes the moment of discovery more exciting

### Technical

✅ **Efficient**: Uses Flutter's efficient `FadeTransition` widget  
✅ **Stable**: Builds on the fixed-height container fix (no layout shifts)  
✅ **Clean State**: Properly disposes controller to prevent memory leaks

## Visual Flow

1. **Mystery State**: Only cropped image + "Who's that Pokemon?" visible
2. **Reveal Trigger**: User guesses correctly
3. **Animation Start**: Full card starts fading in (opacity 0 → 1)
4. **Transition**: Both layers visible momentarily (cross-fade effect)
5. **Revealed State**: Full card fully visible (opacity 1)

## Files Modified

- `apps/client/lib/widgets/game/card_display.dart`

## Performance Impact

Minimal. Uses hardware-accelerated opacity changes and only repaints the widget during the 800ms transition.

## Testing Checklist

- [x] Animation plays forward on reveal
- [x] Animation reverses/resets on new round
- [x] No layout shifts during animation
- [x] Smooth 800ms duration
- [x] Works when rapidly switching cards
