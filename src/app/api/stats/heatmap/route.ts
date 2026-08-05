import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(req: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;

    // Fetch the last 100 days of review logs to build the heatmap
    const hundredDaysAgo = new Date();
    hundredDaysAgo.setDate(hundredDaysAgo.getDate() - 100);

    const logs = await prisma.reviewLog.findMany({
      where: {
        userId,
        reviewedAt: { gte: hundredDaysAgo }
      },
      select: { reviewedAt: true }
    });

    const heatmap: Record<string, number> = {};

    logs.forEach(log => {
      const dateString = log.reviewedAt.toISOString().split('T')[0];
      heatmap[dateString] = (heatmap[dateString] || 0) + 1;
    });

    const heatmapData = Object.entries(heatmap).map(([date, count]) => ({ date, count }));

    return NextResponse.json(heatmapData, { status: 200 });
  } catch (error) {
    console.error('Fetch Heatmap Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
