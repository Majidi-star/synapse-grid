import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient } from '@prisma/client';
import { generateCompletion } from '@/lib/llmClient';

const prisma = new PrismaClient();

export async function POST(req: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;
    const { deckId, messages, currentCardContext } = await req.json();

    if (!deckId || !messages) {
      return NextResponse.json({ message: 'Missing deckId or messages' }, { status: 400 });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { llmProvider: true, llmApiKey: true, llmModel: true, llmBaseUrl: true }
    });

    if (!user) {
      return NextResponse.json({ message: 'User not found' }, { status: 404 });
    }

    if (user.llmProvider !== 'ollama' && !user.llmApiKey) {
      return NextResponse.json({ message: 'AI API Key is not configured in Settings' }, { status: 400 });
    }

    // Optional: Fetch deck name and some stats to give the tutor context
    const deck = await prisma.deck.findUnique({
      where: { id: deckId },
      select: { name: true, description: true }
    });

    const systemPrompt = `You are Synapse Grid's AI Tutor. You are helping a student study their flashcard deck named "${deck?.name}".
${deck?.description ? `Deck Description: ${deck.description}` : ''}
${currentCardContext ? `The student is currently looking at this flashcard:\nFront: ${currentCardContext.front}\nBack: ${currentCardContext.back}\n` : ''}
Your goal is to help the student understand concepts they find difficult without just giving away answers immediately. Use the Socratic method when appropriate. Keep your answers concise, encouraging, and formatted clearly.`;

    const chatMessages = [
      { role: 'system' as const, content: systemPrompt },
      ...messages.map((m: any) => ({
        role: m.role,
        content: m.content
      }))
    ];

    const aiMessage = await generateCompletion(chatMessages, {
      provider: user.llmProvider,
      apiKey: user.llmApiKey || undefined,
      model: user.llmModel,
      baseUrl: user.llmBaseUrl || undefined
    });

    return NextResponse.json({ 
      message: aiMessage
    }, { status: 200 });

  } catch (error) {
    console.error('AI Tutor Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
