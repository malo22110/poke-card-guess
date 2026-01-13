# Secret Rare Filter Implementation

## Overview

This document explains the implementation of the "secret only" filter for the Pokemon Card Guessing Game, which allows games to use only special/rare cards instead of all cards.

## Implementation Details

### 1. Dynamic Rarity Fetching

Instead of hardcoding a single rarity like "Secret Rare" or "Ultra Rare", the system now:

- Fetches all available rarities from the TCGdex API: `https://api.tcgdex.net/v2/fr/rarities`
- Filters out common/basic rarities
- Uses the remaining special rarities to fetch cards

### 2. Locale-Aware

The implementation is locale-aware and works with the French locale (`fr`):

- API endpoint: `https://api.tcgdex.net/v2/fr/rarities`
- French rarity names are used (e.g., "Ultra Rare", "Hyper rare", "Illustration rare")

### 3. Excluded Rarities

The following rarities are **excluded** from the special rare pool:

- `Commune` (Common)
- `Peu Commune` (Uncommon)
- `Rare` (Rare)
- `Rare Holo` (Rare Holo)
- `Holo Rare` (Holo Rare)
- `Sans Rareté` (None)
- `Un Diamant` (One Diamond)
- `Deux Diamants` (Two Diamonds)
- `Trois Diamants` (Three Diamonds)
- `Quatre Diamants` (Four Diamonds)
- `Une Étoile` (One Star)
- `Deux Étoiles` (Two Stars)
- `Trois Étoiles` (Three Stars)
- `Couronne` (Crown)

### 4. Included Special Rarities

All other rarities are included, such as:

- `Ultra Rare`
- `Hyper rare`
- `Illustration rare`
- `Illustration spéciale rare`
- `Shiny rare`
- `Radieux Rare`
- `Magnifique rare`
- `Double rare`
- And more...

### 5. Performance Optimization

- **Caching**: Special rarities are cached after the first fetch to avoid repeated API calls
- **Batch Fetching**: All special rare cards are fetched upfront when a game starts with `secretOnly: true`
- **Random Selection**: Cards are randomly selected from the pre-fetched pool without duplicates

### 6. Set Filtering

The implementation respects the `allowedSets` configuration:

- If specific sets are configured (e.g., `['151', 'sv1']`), only cards from those sets are fetched
- Uses the pipe operator (`|`) to match multiple sets in a single API call
- Example: `&set.id=151|sv1`

## API Calls

### Example API Call for Special Rare Cards

```
https://api.tcgdex.net/v2/fr/cards?rarity=eq:Ultra Rare&set.id=151
```

### Filtering Syntax

- **Rarity Filter**: `rarity=eq:Ultra Rare` (strict equality)
- **Set Filter**: `set.id=151|sv1` (multiple sets with pipe operator)
- **URL Encoding**: Rarity names with spaces are properly URL-encoded

## Code Structure

### New Interface: `CardSummary`

```typescript
export interface CardSummary {
  id: string;
  localId: string;
  name: string;
  image: string;
}
```

### New Method: `fetchSecretRareCards()`

- Fetches and caches special rarities
- Iterates through each special rarity
- Fetches cards for each rarity with optional set filtering
- Returns a combined array of all special rare cards

### Updated Method: `fetchGameCards()`

- Checks if `secretOnly` is enabled
- Pre-fetches all special rare cards if enabled
- Randomly selects from the pool without duplicates
- Falls back to the original method for non-secret games

## Configuration

### Game Config

```typescript
{
  rounds: 10,
  sets: ['151'],  // or ['all'] for all sets
  secretOnly: true  // Enable special rare cards only
}
```

### Default Settings

By default, new lobbies are created with:

- `rounds: 10`
- `sets: ['151']`
- `secretOnly: true`

## Logging

The implementation includes comprehensive logging:

- `Using cached special rarities` - When using cached data
- `Fetched and cached special rarities: [list]` - When fetching for the first time
- `Fetched X cards with rarity: [rarity]` - For each rarity fetched
- `Successfully fetched X total special rare cards` - Final count

## Future Improvements

1. **Configurable Exclusions**: Allow users to customize which rarities to exclude
2. **Multi-Locale Support**: Support switching between different locales (en, fr, es, etc.)
3. **Rarity Tiers**: Group rarities into tiers (common, rare, ultra-rare) for more granular control
4. **Cache Invalidation**: Add TTL or manual cache invalidation for rarities
