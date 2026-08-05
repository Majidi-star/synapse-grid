import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { SchedulerService } from '@/services/scheduler';
import { Rating as PrismaRating } from '@prisma/client';

export async function POST(
  req: Request,
  { params }: { params: { deckId: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;
    const { cardId, rating } = await req.json();

    if (!cardId || !rating) {
      return NextResponse.json({ message: 'Missing cardId or rating' }, { status: 400 });
    }

    // Convert string rating to enum
    const prismaRating = PrismaRating[rating as keyof typeof PrismaRating];
    if (!prismaRating) {
      return NextResponse.json({ message: 'Invalid rating' }, { status: 400 });
    }

    await SchedulerService.recordReview(cardId, userId, prismaRating);

    return NextResponse.json({ message: 'Review recorded' }, { status: 200 });
  } catch (error) {
    console.error('Record Review Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
