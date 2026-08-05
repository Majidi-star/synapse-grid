import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient, CardType } from '@prisma/client';

const prisma = new PrismaClient();

async function checkCardOwnership(cardId: string, userId: string) {
  const card = await prisma.card.findUnique({
    where: { id: cardId },
    include: { deck: true }
  });
  return card?.deck.userId === userId;
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

    const isOwner = await checkCardOwnership(id, userId);
    if (!isOwner) {
      return NextResponse.json({ message: 'Access denied' }, { status: 403 });
    }

    const { type, front, back, extraFields } = await req.json();

    const updatedCard = await prisma.card.update({
      where: { id },
      data: {
        ...(type && { type: type as CardType }),
        ...(front !== undefined && { front }),
        ...(back !== undefined && { back }),
        ...(extraFields !== undefined && { extraFields: JSON.stringify(extraFields) }),
      },
    });

    return NextResponse.json(updatedCard, { status: 200 });
  } catch (error) {
    console.error('Update Card Error:', error);
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

    const isOwner = await checkCardOwnership(id, userId);
    if (!isOwner) {
      return NextResponse.json({ message: 'Access denied' }, { status: 403 });
    }

    await prisma.card.delete({
      where: { id },
    });

    return NextResponse.json({ message: 'Card deleted successfully' }, { status: 200 });
  } catch (error) {
    console.error('Delete Card Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
