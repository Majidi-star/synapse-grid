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
    const { text, deckId } = await req.json();

    if (!text || !deckId) {
      return NextResponse.json({ message: 'Missing text or deckId' }, { status: 400 });
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

    // Call Claude to generate flashcards
    const prompt = `
You are an expert tutor creating flashcards for spaced repetition (like Anki).
Analyze the following text and generate high-yield, atomic flashcards. 
Extract key facts, concepts, and definitions. Avoid overly complex cards.
Each card must have a "front" (question/prompt) and a "back" (concise answer).

Format the output strictly as a JSON array of objects.
Example:
[
  { "front": "What is the powerhouse of the cell?", "back": "Mitochondria" }
]

Do not include any markdown formatting, only the raw JSON array.

Text to analyze:
${text}
`;

    const rawJson = await generateCompletion([
      { role: 'system', content: 'You are an expert flashcard creator. Always return valid JSON arrays.' },
      { role: 'user', content: prompt }
    ], {
      provider: user.llmProvider,
      apiKey: user.llmApiKey || undefined,
      model: user.llmModel,
      baseUrl: user.llmBaseUrl || undefined
    });
    
    // Parse the JSON array
    let generatedCards = [];
    try {
      generatedCards = JSON.parse(rawJson);
    } catch (parseError) {
      console.error('JSON Parse Error:', rawJson);
      return NextResponse.json({ message: 'Failed to parse AI output' }, { status: 500 });
    }

    // Save the job and generated cards into the database
    // The user will review them before they are fully integrated, but for MVP we will just save them as unreviewed cards or create them in the deck directly.
    // Given the task says "User interactive Review Queue (Accept, Edit, Reject cards)", we will create an AIGenerationJob.

    const job = await prisma.aIGenerationJob.create({
      data: {
        userId,
        sourceType: 'text',
        sourceRef: 'Direct Input',
        status: 'PROCESSING'
      }
    });

    // Instead of adding them directly to the deck immediately, we add them with a linking `aiGenerationJobId` 
    // Wait, let's create them as cards but mark them somehow, or store them in a temporary structure.
    // Looking at `schema.prisma`, `Card` has `aiGenerationJobId`. We can add them to the deck, but we might want them separated until approved.
    // For simplicity, let's return them directly in the API response and let the client manage the "Accept/Reject" state before saving!
    // This is much faster and cleaner. We won't hit the DB until the user clicks "Accept".

    return NextResponse.json({ 
      cards: generatedCards.map((c: any) => ({
        id: Math.random().toString(36).substring(7), // Temp ID
        front: c.front,
        back: c.back,
        type: 'BASIC'
      }))
    }, { status: 200 });

  } catch (error) {
    console.error('AI Generation Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
