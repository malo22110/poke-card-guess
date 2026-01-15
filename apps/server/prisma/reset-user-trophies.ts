import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Delete all user trophies
  const result = await prisma.userTrophy.deleteMany({});
  console.log(`Deleted ${result.count} user trophies.`);

  // Reset User stats used for trophies
  const resultUsers = await prisma.user.updateMany({
    data: {
      totalScore: 0,
      totalAttempts: 0,
      gamesPlayed: 0,
      gamesWon: 0,
      currentStreak: 0,
      bestStreak: 0,
      cardsGuessed: 0,
      sharesCount: 0,
      totalDonated: 0,
      highScore: 0,
      timesBeatenHighScore: 0,
      uniqueSetsGuessed: null,
      rarityStats: null,
      bestRoundScore: 0,
      fastestGuess: 999.0,
    },
  });
  console.log(`Reset stats for ${resultUsers.count} users.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
