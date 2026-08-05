import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

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

    const deck = await prisma.deck.findUnique({
      where: { id },
      include: {
        cards: {
          select: { front: true, back: true, type: true }
        }
      }
    });

    if (!deck || deck.userId !== userId) {
      return NextResponse.json({ message: 'Not found or access denied' }, { status: 403 });
    }

    const exportData = {
      name: deck.name,
      description: deck.description,
      cards: deck.cards
    };

    return new NextResponse(JSON.stringify(exportData, null, 2), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Content-Disposition': `attachment; filename="${deck.name.replace(/\s+/g, '_')}_export.json"`
      }
    });
  } catch (error) {
    console.error('Export Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
