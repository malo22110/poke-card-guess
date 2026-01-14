# Trophy System Feature

## Overview

Implement a trophy/achievement system to increase engagement and provide goals for players.

## Trophy Categories

### 🎯 Score-Based Trophies

**Note:** Max score per round is ~30,000 points (instant perfect answer). Typical 10-round game: 200k-300k points possible.

- **First Steps** - Score 50,000 total points (Bronze) - ~2-3 decent games
- **Rising Star** - Score 250,000 total points (Silver) - ~10 games
- **Card Master** - Score 1,000,000 total points (Gold) - ~40-50 games
- **Legend** - Score 5,000,000 total points (Diamond) - ~200+ games
- **Hall of Fame** - Score 10,000,000 total points (Diamond) - ~400+ games

### 🎮 Game-Based Trophies

- **Beginner** - Play 10 games (Bronze)
- **Regular** - Play 50 games (Silver)
- **Veteran** - Play 100 games (Gold)
- **Dedicated** - Play 500 games (Diamond)
- **Addicted** - Play 1,000 games (Diamond)

### 🏆 Win-Based Trophies

- **First Victory** - Win your first game (Bronze)
- **Winner** - Win 10 games (Silver)
- **Champion** - Win 50 games (Gold)
- **Unbeatable** - Win 100 games (Diamond)
- **Dominator** - Win 250 games (Diamond)

### 🔥 Streak Trophies

- **Hot Streak** - Win 3 games in a row (Silver)
- **On Fire** - Win 5 games in a row (Gold)
- **Unstoppable** - Win 10 games in a row (Diamond)
- **Legendary Streak** - Win 15 games in a row (Diamond)

### 🎴 Card-Based Trophies

- **Quick Guesser** - Guess 100 cards correctly (Bronze)
- **Card Expert** - Guess 500 cards correctly (Silver)
- **Card Genius** - Guess 1,000 cards correctly (Gold)
- **Pokédex Complete** - Guess 5,000 cards correctly (Diamond)
- **Master Collector** - Guess 10,000 cards correctly (Diamond)

### 🌟 Special Trophies

- **Perfect Round** - Score 25,000+ points in a single round (Special) - Nearly perfect answer
- **Speed Demon** - Guess a card in under 3 seconds (Special)
- **Lightning Fast** - Guess a card in under 2 seconds (Special)
- **Perfectionist** - Complete a game with 100% accuracy (Special)
- **Flawless Victory** - Win a 10+ round game with 100% accuracy (Special)
- **Night Owl** - Play a game between midnight and 4 AM (Fun)
- **Early Bird** - Play a game between 5 AM and 7 AM (Fun)
- **Weekend Warrior** - Play 20 games on a weekend (Fun)
- **Social Butterfly** - Share your score 10 times (Social)
- **Influencer** - Share your score 50 times (Social)

### 🏅 Leaderboard Trophies

- **Challenger** - Beat an existing #1 player to take their spot (Diamond) - Dethrone the champion!
- **Top Player** - Reach #1 on any game mode leaderboard (not created by you) (Gold)
- **Podium Finish** - Reach top 3 on any game mode leaderboard (Silver)
- **Top 10** - Reach top 10 on any game mode leaderboard (Bronze)
- **Multi-Mode Master** - Reach top 10 in 3 different game modes (Gold)

### 📈 Personal Best Trophies

- **Self Improvement** - Beat your own high score on any game mode (Bronze)
- **Consistency** - Beat your own high score 5 times (Silver)
- **Always Improving** - Beat your own high score 10 times (Gold)
- **Unstoppable Growth** - Beat your own high score 25 times (Diamond)

### 💎 Rarity Trophies

- **Rare Hunter** - Correctly guess 50 rare cards (Silver)
- **Ultra Rare Collector** - Correctly guess 25 ultra rare cards (Gold)
- **Secret Seeker** - Correctly guess 10 secret rare cards (Diamond)

### 🎨 Set Trophies

- **Set Explorer** - Guess cards from 10 different sets (Bronze)
- **Set Connoisseur** - Guess cards from 25 different sets (Silver)
- **Set Master** - Guess cards from 50 different sets (Gold)
- **Complete Collection** - Guess cards from 100 different sets (Diamond)

### ⚡ Speed Trophies

- **Fast Learner** - Complete a game in under 5 minutes (Silver)
- **Speedrunner** - Complete a 10-round game in under 3 minutes (Gold)
- **Time Attack Master** - Average under 5 seconds per guess over 20 games (Diamond)

## Database Schema

### Trophy Model

```prisma
model Trophy {
  id          String   @id @default(uuid())
  key         String   @unique // e.g., "first_steps", "card_master"
  name        String   // Display name
  description String   // Trophy description
  category    String   // "score", "games", "wins", "streak", "cards", "special"
  tier        String   // "bronze", "silver", "gold", "diamond", "special"
  iconUrl     String?  // Optional custom icon
  requirement Int      // Required value to unlock
  createdAt   DateTime @default(now())

  userTrophies UserTrophy[]
}

model UserTrophy {
  id          String   @id @default(uuid())
  userId      String
  trophyId    String
  unlockedAt  DateTime @default(now())
  progress    Int      @default(0) // Current progress toward trophy

  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  trophy      Trophy   @relation(fields: [trophyId], references: [id], onDelete: Cascade)

  @@unique([userId, trophyId])
  @@index([userId])
}
```

### User Model Updates

Add tracking fields:

```prisma
model User {
  // ... existing fields
  totalScore      Int @default(0)
  gamesPlayed     Int @default(0)
  gamesWon        Int @default(0)
  currentStreak   Int @default(0)
  bestStreak      Int @default(0)
  cardsGuessed    Int @default(0)
  sharesCount     Int @default(0)

  trophies        UserTrophy[]
}
```

## API Endpoints

### GET /trophies

Get all available trophies

```typescript
Response: Trophy[]
```

### GET /users/me/trophies

Get current user's trophies with progress

```typescript
Response: {
  unlocked: UserTrophy[],
  inProgress: { trophy: Trophy, progress: number }[]
}
```

### POST /trophies/check

Check and award trophies for user (called after game events)

```typescript
Body: { userId: string, event: string, value: number }
Response: { newTrophies: Trophy[] }
```

## Frontend Components

### TrophyCard Widget

Display individual trophy with:

- Icon/image
- Name and description
- Tier badge (bronze/silver/gold/diamond)
- Progress bar (if not unlocked)
- Unlock date (if unlocked)
- Locked/unlocked state

### TrophyList Widget

Grid/list view of all trophies with filters:

- All / Unlocked / Locked
- Category filter
- Tier filter

### TrophyNotification Widget

Toast/modal shown when trophy is unlocked:

- Animated trophy reveal
- Confetti effect
- Trophy details
- Share button

### ProfileTrophySection Widget

Compact trophy display on profile:

- Trophy count badge
- Recent trophies carousel
- "View All" button

## Implementation Steps

### Phase 1: Backend Setup

1. Create Prisma schema for Trophy and UserTrophy
2. Run migration
3. Create trophy seed data
4. Implement trophy service with check logic
5. Add API endpoints

### Phase 2: User Stats Tracking

1. Update User model with tracking fields
2. Modify game service to update stats after each game
3. Add middleware to track events (shares, logins, etc.)

### Phase 3: Frontend UI

1. Create trophy widgets
2. Add trophy screen to navigation
3. Integrate trophy display in profile
4. Implement trophy unlock notifications

### Phase 4: Integration

1. Call trophy check after game completion
2. Display new trophies to user
3. Add trophy sharing functionality
4. Test all trophy unlock conditions

## Trophy Icons

Use Font Awesome icons or custom SVG:

- 🥉 Bronze: `fa-medal` with bronze color
- 🥈 Silver: `fa-medal` with silver color
- 🥇 Gold: `fa-medal` with gold color
- 💎 Diamond: `fa-gem` with diamond color
- ⭐ Special: `fa-star` with special gradient

## Gamification Strategy

- Show progress bars to encourage completion
- Highlight "almost unlocked" trophies
- Send notifications for milestones
- Allow trophy sharing on social media
- Display trophy count on leaderboard
- Add trophy rarity percentage (% of players who have it)
