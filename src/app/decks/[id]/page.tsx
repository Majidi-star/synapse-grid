import { getServerSession } from 'next-auth';
import { redirect } from 'next/navigation';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient } from '@prisma/client';
import DeckManager from '@/components/DeckManager';

const prisma = new PrismaClient();

export default async function DeckPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect('/login');
  }

  const userId = (session.user as any).id;
  const { id } = params;

  const deck = await prisma.deck.findUnique({
    where: { id },
    include: {
      cards: {
        orderBy: { createdAt: 'desc' }
      }
    }
  });

  if (!deck || deck.userId !== userId) {
    redirect('/');
  }

  return (
    <div className="flex h-screen overflow-hidden bg-zinc-50 dark:bg-zinc-950">
      <main className="flex-1 overflow-y-auto">
        <div className="px-8 py-10 max-w-7xl mx-auto">
          <DeckManager initialDeck={deck as any} />
        </div>
      </main>
    </div>
  );
}
