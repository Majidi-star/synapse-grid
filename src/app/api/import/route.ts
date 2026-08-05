import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient } from '@prisma/client';
import { CardType, State } from '@/lib/constants';

const prisma = new PrismaClient();

export async function POST(req: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;
    const data = await req.json();

    if (!data.name || !Array.isArray(data.cards)) {
      return NextResponse.json({ message: 'Invalid import format' }, { status: 400 });
    }

    // Create the deck
    const deck = await prisma.deck.create({
      data: {
        userId,
        name: `${data.name} (Imported)`,
        description: data.description || 'Imported deck',
      }
    });

    // Create cards with initial schedule state
    const cardsToCreate = data.cards.map((c: any) => ({
      deckId: deck.id,
      type: (c.type as CardType) || CardType.BASIC,
      front: c.front || '',
      back: c.back || '',
      extraFields: '{}',
    }));

    // For better performance, we create the cards first, then create their schedule states.
    // However, Prisma doesn't support nested createMany. We can just loop if it's not massive, 
    // or use a transaction.

    const createdCards = [];
    for (const cardData of cardsToCreate) {
      const card = await prisma.card.create({
        data: {
          ...cardData,
          scheduleState: {
            create: {
              due: new Date(),
              stability: 0,
              difficulty: 0,
              elapsedDays: 0,
              scheduledDays: 0,
              reps: 0,
              lapses: 0,
              state: State.NEW,
            }
          }
        }
      });
      createdCards.push(card);
    }

    return NextResponse.json({ message: 'Import successful', deckId: deck.id, count: createdCards.length }, { status: 201 });
  } catch (error) {
    console.error('Import Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
