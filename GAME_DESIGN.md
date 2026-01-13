# PokeCard Guess - Game Design Document

## 1. Overview

PokeCard Guess is a competitive multiplayer game where players test their knowledge of Pokemon TCG cards. Players guess the Pokemon based on visual clues from card artwork.

## 2. User System

- **Authentication**: Users must log in (via Google or Facebook) to create or join games.
- **Identity**: Players are identified by their profile information (name, avatar) from the auth provider.

## 3. Game Management

### Creating a Game

- A logged-in user can create a new game room.
- Upon creation, a unique **Game ID** (e.g., alphanumeric code) is generated.
- The creator becomes the "Host" and can configure the game settings.

### Joining a Game

- Authenticated users can join an existing lobby by entering the **Game ID**.
- Multiplayer support allows multiple guessers in the same session (synchronization TBD).

## 4. Game Configuration

The Host can customize the card pool using the following filters:

- **Scope**:
  - **Specific Set**: (e.g., 'Paldea Evolved')
  - **Multiple Sets**: A custom selection of sets.
  - **Entire Block**: All sets within a series (e.g., 'Scarlet & Violet Era').
- **Card Type Filters**:
  - **Secret Cards Only**: valid only for Secret Rares (Collector number > Set printed total).
- **Game Length**:
  - **Variable Rounds**: Host defines the number of rounds (e.g., 10, 20, 50).
  - **Endless Mode**: Play continues until the host ends the game or all cards are exhausted.

## 5. Gameplay & Mechanics

- **The Turn**: A cropped or obscured image of a card is presented to all players simultaneously.
- **Guessing**: Players type the name of the Pokemon.
- **Scoring System**:
  - **Accuracy**: Points are only awarded for the correct Pokemon name.
  - **Speed Bonus**: The score calculation is time-sensitive.
    - **Max Score**: Instant correct answer.
    - **Decay**: Points decrease as time passes.
    - **First to Guess**: May receive an additional bonus (competitive mode).

## 6. Technical Requirements (Inferred)

- **Real-time Communication**: WebSockets (likely via NestJS Gateways) to sync game state, card reveals, and buzz-in timing between client and server.
- **Timer Sync**: Server-authoritative timer to ensure fairness.
