import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function PUT(req: Request) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }

    const { 
      name, 
      retentionTargetPreference,
      llmProvider,
      llmApiKey,
      llmModel,
      llmBaseUrl
    } = await req.json();
    const userId = (session.user as any).id;

    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (retentionTargetPreference !== undefined) updateData.retentionTargetPreference = retentionTargetPreference;
    if (llmProvider !== undefined) updateData.llmProvider = llmProvider;
    if (llmApiKey !== undefined) updateData.llmApiKey = llmApiKey;
    if (llmModel !== undefined) updateData.llmModel = llmModel;
    if (llmBaseUrl !== undefined) updateData.llmBaseUrl = llmBaseUrl;

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: updateData,
    });

    return NextResponse.json({ message: 'Settings updated' }, { status: 200 });
  } catch (error) {
    console.error('Settings Update Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
