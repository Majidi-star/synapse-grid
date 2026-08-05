import { getServerSession } from 'next-auth';
import { redirect } from 'next/navigation';
import { authOptions } from '@/app/api/auth/[...nextauth]/route';
import Link from 'next/link';
import { Settings, Layers, BarChart2, ArrowLeft } from 'lucide-react';
import LogoutButton from '@/components/LogoutButton';
import StatisticsDashboard from '@/components/StatisticsDashboard';

export default async function StatisticsPage() {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect('/login');
  }

  return (
    <div className="flex h-screen overflow-hidden">
      {/* Sidebar navigation */}
      <aside className="w-64 flex flex-col border-r border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-950">
        <div className="flex h-16 items-center px-6 border-b border-zinc-200 dark:border-zinc-800">
          <h1 className="text-xl font-bold tracking-tight">Synapse Grid</h1>
        </div>
        
        <nav className="flex-1 space-y-1 px-3 py-4">
          <Link href="/" className="flex items-center px-3 py-2 text-sm font-medium rounded-md hover:bg-zinc-200/50 dark:hover:bg-zinc-800/50">
            <Layers className="mr-3 h-5 w-5" />
            Decks
          </Link>
          <Link href="/statistics" className="flex items-center px-3 py-2 text-sm font-medium rounded-md bg-zinc-200/50 dark:bg-zinc-800/50">
            <BarChart2 className="mr-3 h-5 w-5" />
            Statistics
          </Link>
          <Link href="/settings" className="flex items-center px-3 py-2 text-sm font-medium rounded-md hover:bg-zinc-200/50 dark:hover:bg-zinc-800/50">
            <Settings className="mr-3 h-5 w-5" />
            Settings
          </Link>
        </nav>
        
        <div className="p-4 border-t border-zinc-200 dark:border-zinc-800">
          <div className="flex items-center">
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{session.user.name || 'User'}</p>
              <p className="text-xs text-zinc-500 truncate">{session.user.email}</p>
            </div>
            <LogoutButton />
          </div>
        </div>
      </aside>

      {/* Main content area */}
      <main className="flex-1 overflow-y-auto">
        <div className="px-8 py-10 max-w-7xl mx-auto">
          <div className="sm:flex sm:items-center sm:justify-between mb-8">
            <h2 className="text-2xl font-bold leading-7 text-zinc-900 dark:text-zinc-100 sm:truncate sm:text-3xl sm:tracking-tight">
              Study Statistics
            </h2>
          </div>
          
          <StatisticsDashboard />
        </div>
      </main>
    </div>
  );
}
