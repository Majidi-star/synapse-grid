import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create test user
  const user = await prisma.user.upsert({
    where: { email: 'test@recallos.com' },
    update: {},
    create: {
      email: 'test@recallos.com',
      name: 'Test User',
      passwordHash: 'mock-hash', // Note: use bcrypt in real app
    },
  });

  // Create test deck
  const deck = await prisma.deck.create({
    data: {
      userId: user.id,
      name: 'TypeScript Basics',
      description: 'Core concepts of TypeScript',
      cards: {
        create: [
          {
            type: 'BASIC',
            front: 'What is TypeScript?',
            back: 'TypeScript is a strongly typed programming language that builds on JavaScript.',
            extraFields: '{}',
          },
          {
            type: 'CLOZE',
            front: 'TypeScript is developed and maintained by {{c1::Microsoft}}.',
            back: '',
            extraFields: '{}',
          }
        ]
      }
    }
  });

  console.log(`Created user ${user.email} and deck '${deck.name}' with cards.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
