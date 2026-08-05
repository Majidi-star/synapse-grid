import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Helper to check ownership
async function checkOwnership(deckId: string, userId: string) {
  const deck = await prisma.deck.findUnique({
    where: { id: deckId },
    select: { userId: true }
  });
  return deck?.userId === userId;
}

export async function GET(
  req: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;
    const { id } = params;

    const isOwner = await checkOwnership(id, userId);
    if (!isOwner) {
      return NextResponse.json({ message: 'Deck not found or access denied' }, { status: 403 });
    }

    const deck = await prisma.deck.findUnique({
      where: { id },
      include: {
        _count: { select: { cards: true } },
        cards: {
          include: { tags: true },
          orderBy: { createdAt: 'desc' }
        },
        tags: true,
        subDecks: {
          include: { _count: { select: { cards: true } } }
        }
      }
    });

    return NextResponse.json(deck, { status: 200 });
  } catch (error) {
    console.error('Fetch Deck Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}

export async function PUT(
  req: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;
    const { id } = params;

    const isOwner = await checkOwnership(id, userId);
    if (!isOwner) {
      return NextResponse.json({ message: 'Access denied' }, { status: 403 });
    }

    const { name, description, parentDeckId } = await req.json();

    const updatedDeck = await prisma.deck.update({
      where: { id },
      data: {
        name,
        description,
        parentDeckId: parentDeckId || null,
      },
    });

    return NextResponse.json(updatedDeck, { status: 200 });
  } catch (error) {
    console.error('Update Deck Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}

export async function DELETE(
  req: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;
    const { id } = params;

    const isOwner = await checkOwnership(id, userId);
    if (!isOwner) {
      return NextResponse.json({ message: 'Access denied' }, { status: 403 });
    }

    // Prisma Cascade delete handles cards and tags automatically
    await prisma.deck.delete({
      where: { id },
    });

    return NextResponse.json({ message: 'Deck deleted successfully' }, { status: 200 });
  } catch (error) {
    console.error('Delete Deck Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
