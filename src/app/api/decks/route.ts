import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// GET all decks for the authenticated user
export async function GET(req: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;

    // Fetch top-level decks (where parentDeckId is null) and include their subDecks recursively
    const decks = await prisma.deck.findMany({
      where: { 
        userId,
        parentDeckId: null 
      },
      include: {
        _count: {
          select: { cards: true }
        },
        subDecks: {
          include: {
            _count: {
              select: { cards: true }
            },
            // We can nest deeper if needed, but for MVP 1-2 levels is enough
            subDecks: true
          }
        },
        tags: true
      },
      orderBy: { createdAt: 'desc' }
    });

    return NextResponse.json(decks, { status: 200 });
  } catch (error) {
    console.error('Fetch Decks Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}

// POST create a new deck
export async function POST(req: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;
    const { name, description, parentDeckId } = await req.json();

    if (!name) {
      return NextResponse.json({ message: 'Deck name is required' }, { status: 400 });
    }

    const newDeck = await prisma.deck.create({
      data: {
        name,
        description,
        parentDeckId: parentDeckId || null,
        userId,
      },
    });

    return NextResponse.json(newDeck, { status: 201 });
  } catch (error) {
    console.error('Create Deck Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
