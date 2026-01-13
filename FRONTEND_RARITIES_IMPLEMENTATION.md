# Frontend Implementation - Custom Rarities Feature

## Overview

Successfully implemented the custom rarities selection feature in the Flutter frontend, allowing users to select specific card rarities when creating a game.

## Changes Made

### 1. State Management

Added new state variables to `CreateGameScreen`:

- `_availableRarities`: List of all available rarities from API
- `_selectedRarities`: List of user-selected rarities
- `_isLoadingRarities`: Loading state for rarities fetch
- `_commonRarities`: Predefined list of common rarities to exclude by default

### 2. API Integration

#### Fetch Rarities

```dart
Future<void> _fetchRarities() async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/game/rarities'),
  );
  // Auto-select special rarities by default
  _selectSpecialRarities();
}
```

#### Send Rarities on Game Creation

```dart
body: jsonEncode({
  'rounds': _rounds.toInt(),
  'sets': [_selectedSetId],
  'secretOnly': _secretOnly,
  'rarities': _secretOnly && _selectedRarities.isNotEmpty
      ? _selectedRarities
      : null,
}),
```

### 3. UI Components

#### Preset Buttons

Three preset buttons for quick selection:

- **Special Only**: Selects all non-common rarities (default)
- **All Rarities**: Selects all available rarities
- **Clear All**: Deselects all rarities

#### Rarities Chips

- FilterChip widgets for each rarity
- Visual distinction between common (grey) and special (purple) rarities
- Selected chips highlighted in amber
- Click to toggle selection

#### Visual Features

- Section only shows when "Secret Cards Only" is enabled
- Shows count of selected rarities
- Loading spinner while fetching rarities
- Responsive wrap layout for chips
- Color-coded chips (grey for common, purple for special, amber for selected)

### 4. User Experience Flow

1. **Page Load**:
   - Fetches available sets and rarities
   - Auto-selects special rarities by default
   - Shows loading spinner until both are loaded

2. **Rarity Selection**:
   - Only visible when "Secret Cards Only" toggle is ON
   - Users can click preset buttons or individual chips
   - Real-time count of selected rarities

3. **Game Creation**:
   - Selected rarities sent to backend
   - If no rarities selected, sends `null` (uses backend default)
   - If "Secret Cards Only" is OFF, doesn't send rarities

## Code Structure

### New Methods

- `_fetchRarities()`: Fetches rarities from API
- `_selectSpecialRarities()`: Auto-selects non-common rarities
- `_selectAllRarities()`: Selects all rarities
- `_clearRarities()`: Clears all selections
- `_buildRaritiesSection()`: Builds the rarities UI
- `_buildPresetButton()`: Builds preset button widgets

### Updated Methods

- `didChangeDependencies()`: Added rarities fetch
- `_createGame()`: Added rarities to request body
- `build()`: Updated loading condition

## Visual Design

### Color Scheme

- **Background**: Gradient from `#1a237e` to `#5E35B1`
- **Common Rarities**: Grey chips with 30% opacity
- **Special Rarities**: Purple chips with 30% opacity
- **Selected Chips**: Amber background
- **Text**: White for unselected, Black for selected

### Layout

```
┌─────────────────────────────────────┐
│ Select Rarities                     │
│ X rarities selected                 │
├─────────────────────────────────────┤
│ [Special Only] [All] [Clear]        │
├─────────────────────────────────────┤
│ [Chip1] [Chip2] [Chip3] ...         │
│ [Chip4] [Chip5] [Chip6] ...         │
└─────────────────────────────────────┘
```

## Testing

### Manual Testing Steps

1. Open the app and navigate to Create Game screen
2. Verify rarities section appears when "Secret Cards Only" is ON
3. Click "Special Only" - should select all special rarities
4. Click "All Rarities" - should select all rarities
5. Click "Clear All" - should deselect all
6. Click individual chips to toggle selection
7. Create game and verify rarities are sent to backend

### Expected Behavior

- Rarities section hidden when "Secret Cards Only" is OFF
- Auto-selects special rarities on page load
- Visual feedback on chip selection
- Count updates in real-time
- Backend receives selected rarities array

## Integration Points

### Backend Endpoints Used

- `GET /game/rarities` - Fetch available rarities
- `POST /game/create` - Create game with rarities

### Data Flow

```
Frontend                    Backend
   │                          │
   ├─ GET /game/rarities ────>│
   │<─────── rarities[] ───────┤
   │                          │
   ├─ POST /game/create ─────>│
   │  {rarities: [...]}       │
   │<─────── lobby ────────────┤
```

## Future Enhancements

1. **Search/Filter**: Add search bar to filter rarities
2. **Grouping**: Group rarities by type (Common, Rare, Ultra, etc.)
3. **Presets**: Save custom preset combinations
4. **Statistics**: Show card count for each rarity
5. **Tooltips**: Add tooltips explaining each rarity
6. **Favorites**: Allow users to favorite certain rarities
7. **Multi-language**: Support different locales

## Files Modified

- `/apps/client/lib/screens/create_game_screen.dart`

## Dependencies

No new dependencies added. Uses existing:

- `flutter/material.dart`
- `http` package
- `dart:convert`
