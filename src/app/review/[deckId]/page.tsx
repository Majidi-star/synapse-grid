import { getServerSession } from 'next-auth';
import { redirect } from 'next/navigation';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient } from '@prisma/client';
import StudySession from '@/components/StudySession';

const prisma = new PrismaClient();

export default async function ReviewPage({ params }: { params: { deckId: string } }) {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect('/login');
  }

  const userId = (session.user as any).id;
  const { deckId } = params;

  const deck = await prisma.deck.findUnique({
    where: { id: deckId },
  });

  if (!deck || deck.userId !== userId) {
    redirect('/');
  }

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-50 flex flex-col">
      <StudySession deckId={deckId} deckName={deck.name} />
    </div>
  );
}
