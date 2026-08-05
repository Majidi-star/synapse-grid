import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { SchedulerService } from '@/services/scheduler';

export async function GET(
  req: Request,
  { params }: { params: { deckId: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;
    const { deckId } = params;

    const limit = 50; // Get up to 50 due cards at a time
    const dueCards = await SchedulerService.getDueCards(userId, limit, deckId);

    return NextResponse.json(dueCards, { status: 200 });
  } catch (error) {
    console.error('Fetch Due Cards Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
