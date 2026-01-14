# Scoring and Matching Rules

This document outlines the rules logic for validating guesses and calculating scores in the PokeCardGuess game.

## Guess Validation Rules

The guessing mechanism allows for flexibility to ensure a smooth user experience, accommodating typos and accent differences.

### 1. Minimum Length

- A guess must be at least **3 characters** long to be considered.

### 2. Normalization

- **Case Insensitivity**: "Pikachu" is treated the same as "pikachu".
- **Accent Insensitivity**: Accents are ignored. "Pokémon" is treated as "pokemon".
  - Example: "Hélionceau" == "Helionceau".

### 3. Matching Tiers

There are two types of successful guesses:

#### A. Perfect Match

- The user inputs the name **exactly** (after normalization).
- **Reward**: Higher score multiplier.

#### B. Fuzzy Match (Typo Tolerance)

- The user inputs a name that is "close enough" to the target name.
- Uses **Levenshtein Distance** algorithm.
- Allowed Distance:
  - Up to **3 errors** (insertions, deletions, substitutions) are permitted for standard names.
  - This handles cases like:
    - "Pikacu" instead of "Pikachu" (1 error).
    - "Pikatrou" instead of "Pikachu" (Accepting significant divergence if sufficient similarity exists).

#### C. Substring Match

- The user inputs a valid substring of the target name.
- Minimum length: **3 characters**.
- Example: "Gio" for "Charisme de Giovanni".
- **Reward**: Lower score multiplier.

## Scoring System

The score for a correct round is calculated based on **Time Taken** and **Accuracy**.

### Base Score (Time Component)

- **Maximum Time**: 30 seconds (30,000 ms).
- **Formula**: `BaseScore = max(0, 30000 - ElapsedMilliseconds)`.
- The faster you guess, the higher the base score.

### Final Score Calculation

- **Perfect Match**: `FinalScore = BaseScore`. (100% of potential points).
- **Fuzzy Match**: `FinalScore = BaseScore * 0.8`. (80% of potential points).
- **Substring Match**: `FinalScore = BaseScore * 0.5`. (50% of potential points).

---

**Examples:**

1. **Target**: "Pikachu"
   - User types: "Pikachu" (0.5s elapsed).
   - Match: **Perfect**.
   - Score: `(30000 - 500) * 1.0 = 29,500`.

2. **Target**: "Charizard"
   - User types: "Charizardd" (5.0s elapsed).
   - Match: **Fuzzy** (1 extra char).
   - Score: `(30000 - 5000) * 0.8 = 20,000`.
