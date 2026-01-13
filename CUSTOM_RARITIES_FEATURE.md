# Custom Rarities Feature

## Overview

This feature allows users to select specific rarities for their game instead of using the default "secret only" filter. Users can now customize exactly which card rarities they want to include in their game.

## Backend Implementation

### 1. Updated GameConfig Interface

```typescript
export interface GameConfig {
  rounds: number;
  sets: string[]; // ['all'] or specific set IDs
  secretOnly: boolean;
  rarities?: string[]; // Optional custom rarities list
}
```

### 2. New API Endpoints

#### GET /game/rarities

Fetches all available rarities from the TCGdex API.

**Response:**

```json
[
  "Chromatique ultra rare",
  "Commune",
  "Couronne",
  "Deux Chromatiques",
  "Deux Diamants",
  "Deux Étoiles",
  "Double rare",
  "Dresseur Full Art",
  "HIGH-TECG rare",
  "Holo Rare",
  "Holo Rare V",
  "Holo Rare VMAX",
  "Holo Rare VSTAR",
  "Hyper rare",
  "Illustration rare",
  "Illustration spéciale rare",
  "LÉGENDE",
  "Magnifique",
  "Magnifique rare",
  "Méga Hyper Rare",
  "Peu Commune",
  "Quatre Diamants",
  "Radieux Rare",
  "Rare",
  "Rare Holo",
  "Rare Holo LV.X",
  "Rare Noir Blanc",
  "Rare Prime",
  "Sans Rareté",
  "Shiny rare",
  "Shiny rare V",
  "Shiny rare VMAX",
  "Trois Diamants",
  "Trois Étoiles",
  "Ultra Rare",
  "Un Chromatique",
  "Un Diamant",
  "Une Étoile"
]
```

#### POST /game/create

Updated to accept `rarities` array in the request body.

**Request Body:**

```json
{
  "rounds": 10,
  "sets": ["151"],
  "secretOnly": true,
  "rarities": ["Ultra Rare", "Hyper rare", "Illustration rare"]
}
```

### 3. How It Works

#### Priority System:

1. **Custom Rarities** (Highest Priority): If `rarities` array is provided in the config, use those exact rarities
2. **Cached Rarities**: If no custom rarities but `secretOnly` is true, use cached special rarities
3. **Auto-Filtered Rarities**: If cache is empty, fetch all rarities and filter out common ones

#### Example Flow:

```typescript
// User creates a game with custom rarities
POST /game/create
{
  "rounds": 10,
  "sets": ["151"],
  "secretOnly": true,
  "rarities": ["Ultra Rare", "Illustration rare", "Hyper rare"]
}

// Backend fetches cards matching these rarities:
// - Ultra Rare cards from set 151
// - Illustration rare cards from set 151
// - Hyper rare cards from set 151
```

### 4. Updated Methods

#### `fetchSecretRareCards(allowedSets, customRarities?)`

- Now accepts optional `customRarities` parameter
- If provided, uses custom rarities instead of auto-filtering
- Logs which rarities are being used for debugging

#### `getAvailableRarities()`

- New method to fetch all available rarities from TCGdex API
- Returns array of rarity strings
- Handles errors gracefully

## Frontend Integration Guide

### 1. Fetch Available Rarities

```typescript
const response = await fetch("http://localhost:3000/game/rarities");
const rarities = await response.json();
// Display these in a multi-select UI component
```

### 2. Create Game with Custom Rarities

```typescript
const gameConfig = {
  rounds: 10,
  sets: ["151"],
  secretOnly: true,
  rarities: selectedRarities, // Array of selected rarity names
};

const response = await fetch("http://localhost:3000/game/create", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(gameConfig),
});
```

### 3. Recommended UI Components

#### Multi-Select Dropdown

- Display all available rarities
- Allow users to select multiple rarities
- Show count of selected rarities
- Provide "Select All Special" preset button

#### Preset Buttons

- **All Rarities**: Select all rarities
- **Special Only**: Auto-select special/rare cards (default behavior)
- **Ultra Rare Only**: Select only ultra rare variants
- **Illustration Cards**: Select illustration-based rarities

#### Example UI Structure:

```
Game Creation Screen
├── Rounds: [Input]
├── Sets: [Multi-Select]
├── Rarities:
│   ├── [Preset: Special Only] [Preset: Ultra Rare Only]
│   └── [Multi-Select Dropdown]
│       ├── ☑ Ultra Rare
│       ├── ☑ Hyper rare
│       ├── ☑ Illustration rare
│       ├── ☐ Commune
│       └── ...
└── [Create Game Button]
```

## Testing

### Test the Rarities Endpoint

```bash
curl http://localhost:3000/game/rarities
```

### Test Game Creation with Custom Rarities

```bash
curl -X POST http://localhost:3000/game/create \
  -H "Content-Type: application/json" \
  -d '{
    "rounds": 5,
    "sets": ["151"],
    "secretOnly": true,
    "rarities": ["Ultra Rare", "Illustration rare"]
  }'
```

## Benefits

1. **User Control**: Users can fine-tune exactly which rarities they want
2. **Flexibility**: Works with any combination of rarities
3. **Backward Compatible**: If no rarities specified, uses default behavior
4. **Performance**: Caching system still works for default behavior
5. **Locale-Aware**: Works with French rarity names (can be extended to other locales)

## Future Enhancements

1. **Rarity Presets**: Save and load custom rarity combinations
2. **Rarity Statistics**: Show how many cards are available for each rarity
3. **Multi-Locale Support**: Support English, Japanese, etc.
4. **Rarity Grouping**: Group rarities by type (Common, Rare, Ultra Rare, etc.)
5. **Smart Suggestions**: Suggest popular rarity combinations
