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
    const { deckId, type, front, back, extraFields } = await req.json();

    if (!deckId || !front || !type) {
      return NextResponse.json({ message: 'Missing required fields' }, { status: 400 });
    }

    // Verify deck ownership
    const deck = await prisma.deck.findUnique({
      where: { id: deckId },
    });
    if (!deck || deck.userId !== userId) {
      return NextResponse.json({ message: 'Deck not found or access denied' }, { status: 403 });
    }

    // Create Card and initialize CardScheduleState as NEW
    const newCard = await prisma.card.create({
      data: {
        deckId,
        type: type as CardType,
        front,
        back: back || '',
        extraFields: extraFields ? JSON.stringify(extraFields) : '{}',
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
      },
      include: {
        scheduleState: true
      }
    });

    return NextResponse.json(newCard, { status: 201 });
  } catch (error) {
    console.error('Create Card Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
