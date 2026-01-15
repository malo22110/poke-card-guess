-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "picture" TEXT,
    "provider" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "profileCompleted" BOOLEAN NOT NULL DEFAULT false,
    "totalScore" INTEGER NOT NULL DEFAULT 0,
    "totalAttempts" INTEGER NOT NULL DEFAULT 0,
    "gamesPlayed" INTEGER NOT NULL DEFAULT 0,
    "gamesWon" INTEGER NOT NULL DEFAULT 0,
    "currentStreak" INTEGER NOT NULL DEFAULT 0,
    "bestStreak" INTEGER NOT NULL DEFAULT 0,
    "cardsGuessed" INTEGER NOT NULL DEFAULT 0,
    "sharesCount" INTEGER NOT NULL DEFAULT 0,
    "totalDonated" INTEGER NOT NULL DEFAULT 0,
    "highScore" INTEGER NOT NULL DEFAULT 0,
    "timesBeatenHighScore" INTEGER NOT NULL DEFAULT 0,
    "uniqueSetsGuessed" TEXT,
    "rarityStats" TEXT,
    "bestRoundScore" INTEGER NOT NULL DEFAULT 0,
    "fastestGuess" REAL NOT NULL DEFAULT 999.0,
    "socials" TEXT
);
INSERT INTO "new_User" ("bestRoundScore", "bestStreak", "cardsGuessed", "createdAt", "currentStreak", "email", "gamesPlayed", "gamesWon", "highScore", "id", "name", "picture", "profileCompleted", "provider", "rarityStats", "sharesCount", "socials", "timesBeatenHighScore", "totalAttempts", "totalDonated", "totalScore", "uniqueSetsGuessed", "updatedAt") SELECT "bestRoundScore", "bestStreak", "cardsGuessed", "createdAt", "currentStreak", "email", "gamesPlayed", "gamesWon", "highScore", "id", "name", "picture", "profileCompleted", "provider", "rarityStats", "sharesCount", "socials", "timesBeatenHighScore", "totalAttempts", "totalDonated", "totalScore", "uniqueSetsGuessed", "updatedAt" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
