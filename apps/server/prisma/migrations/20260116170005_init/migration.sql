-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "picture" TEXT,
    "provider" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
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
    "fastestGuess" DOUBLE PRECISION NOT NULL DEFAULT 999.0,
    "deletedModesCount" INTEGER NOT NULL DEFAULT 0,
    "socials" TEXT,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Game" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "cardName" TEXT NOT NULL,
    "cardSet" TEXT NOT NULL,
    "correct" BOOLEAN NOT NULL,
    "playedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Game_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GameMode" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "creatorId" TEXT,
    "configJson" TEXT NOT NULL,
    "isOfficial" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GameMode_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GameModeUpvote" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "gameModeId" TEXT NOT NULL,

    CONSTRAINT "GameModeUpvote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GameSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "gameModeId" TEXT,
    "score" INTEGER NOT NULL,
    "maxScore" INTEGER NOT NULL,
    "rounds" INTEGER NOT NULL,
    "roundStats" TEXT,
    "playedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GameSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Trophy" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "tier" TEXT NOT NULL,
    "icon" TEXT NOT NULL,
    "requirement" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Trophy_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserTrophy" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "trophyId" TEXT NOT NULL,
    "unlockedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "progress" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "UserTrophy_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "GameModeUpvote_userId_gameModeId_key" ON "GameModeUpvote"("userId", "gameModeId");

-- CreateIndex
CREATE UNIQUE INDEX "Trophy_key_key" ON "Trophy"("key");

-- CreateIndex
CREATE INDEX "UserTrophy_userId_idx" ON "UserTrophy"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "UserTrophy_userId_trophyId_key" ON "UserTrophy"("userId", "trophyId");

-- AddForeignKey
ALTER TABLE "Game" ADD CONSTRAINT "Game_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GameMode" ADD CONSTRAINT "GameMode_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GameModeUpvote" ADD CONSTRAINT "GameModeUpvote_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GameModeUpvote" ADD CONSTRAINT "GameModeUpvote_gameModeId_fkey" FOREIGN KEY ("gameModeId") REFERENCES "GameMode"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GameSession" ADD CONSTRAINT "GameSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GameSession" ADD CONSTRAINT "GameSession_gameModeId_fkey" FOREIGN KEY ("gameModeId") REFERENCES "GameMode"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserTrophy" ADD CONSTRAINT "UserTrophy_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserTrophy" ADD CONSTRAINT "UserTrophy_trophyId_fkey" FOREIGN KEY ("trophyId") REFERENCES "Trophy"("id") ON DELETE CASCADE ON UPDATE CASCADE;
