# Feature: Game Modes and Leaderboards

## Overview

We have implemented a system for selectable Game Modes. Users can choose from official presets, community-created modes, or create their own.

## Features

1.  **Game Modes**:
    - **Official Modes**:
      - "The Classic": Set 151 (ev3.5), Secret Cards Only, 10 Rounds.
      - "The Pioneers": Base Set 1, Rare Cards Only, 10 Rounds.
    - **Custom Modes**: Users can define rounds, sets, and rarities.
    - **Community Modes**: Users can save their custom configs to be public.
2.  **Upvoting**:
    - Authenticated users can upvote community modes.
3.  **Leaderboards**:
    - Each Game Mode has a dedicated leaderboard showing top scores.

## Architecture

### Database (Prisma)

- **GameMode**: Stores configuration (JSON), name, description, creator.
- **GameModeUpvote**: Tracks upvotes.
- **GameSession**: Records the final score of a user for a full game loop (distinct from the per-card `Game`/Guess record).

### Backend

- **GameModesModule**: CRUD for game modes.
- **GameService**:
  - Accept `gameModeId` when creating a lobby.
  - On game finish, save `GameSession` to DB linked to `gameModeId`.

### Frontend

- **CreateGameScreen**:
  - Tabs for **Game Modes** (Presets) and **Custom**.
  - **Game Modes Tab**: Lists Official and Community modes. Support for selecting and upvoting.
  - **Custom Tab**: Existing config UI with new "Save as Community Mode" button.
- **LeaderboardScreen**:
  - Displays rankings per game mode.
  - Filter by mode (horizontal list).
- **LobbyScreen**:
  - Added button to access Leaderboards.

## Implementation Status

- [x] Update Prisma Schema (Models: GameMode, GameModeUpvote, GameSession).
- [x] Implement `GameModesModule` (NestJS) with seeding logic.
- [x] Update `GameService` to support Game Modes and Sessions.
- [x] Update Frontend UI for Game Creation (Tabs, Presets, Upvoting).
- [x] Implement "Save as Community Mode" feature.
- [x] Implement Leaderboard UI and Integration.
- [x] Connect Leaderboard to Lobby.
