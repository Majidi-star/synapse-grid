import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import { SchedulerService } from '@/services/scheduler';

export async function GET(req: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const userId = (session.user as any).id;

    // Get 30-day forecast
    const forecast = await SchedulerService.getForecast(userId, 30);

    return NextResponse.json(forecast, { status: 200 });
  } catch (error) {
    console.error('Fetch Forecast Error:', error);
    return NextResponse.json({ message: 'Internal Server Error' }, { status: 500 });
  }
}
