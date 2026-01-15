import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Resetting database...');

  // 1. Delete UserTrophies (References User, Trophy)
  console.log('Deleting UserTrophies...');
  await prisma.userTrophy.deleteMany({});

  // 2. Delete GameSessions (References User, GameMode)
  console.log('Deleting GameSessions...');
  await prisma.gameSession.deleteMany({});

  // 3. Delete Games (References User)
  console.log('Deleting Games...');
  await prisma.game.deleteMany({});

  // 4. Delete Upvotes (References User, GameMode)
  console.log('Deleting GameModeUpvotes...');
  await prisma.gameModeUpvote.deleteMany({});

  // 5. Delete Custom GameModes (References User)
  console.log('Deleting Custom GameModes...');
  await prisma.gameMode.deleteMany({
    where: { isOfficial: false },
  });
  // For official modes, ensure creatorId is null just in case
  await prisma.gameMode.updateMany({
    where: { isOfficial: true },
    data: { creatorId: null },
  });

  // 6. Delete Users
  console.log('Deleting Users...');
  await prisma.user.deleteMany({});

  console.log(
    '✅ Database reset successful (Users, Sessions, UserTrophies cleared).',
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
