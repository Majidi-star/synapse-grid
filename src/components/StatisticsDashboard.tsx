'use client';

import { useState, useEffect } from 'react';
import { Loader2 } from 'lucide-react';

type ForecastItem = { date: string, count: number };
type HeatmapItem = { date: string, count: number };

export default function StatisticsDashboard() {
  const [forecast, setForecast] = useState<ForecastItem[]>([]);
  const [heatmap, setHeatmap] = useState<HeatmapItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const [resForecast, resHeatmap] = await Promise.all([
          fetch('/api/stats/forecast'),
          fetch('/api/stats/heatmap')
        ]);

        if (resForecast.ok && resHeatmap.ok) {
          setForecast(await resForecast.json());
          setHeatmap(await resHeatmap.json());
        } else {
          setError('Failed to load statistics.');
        }
      } catch (err) {
        setError('Network error occurred.');
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-zinc-500" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-md bg-red-50 p-4 dark:bg-red-900/20">
        <p className="text-sm font-medium text-red-800 dark:text-red-400">{error}</p>
      </div>
    );
  }

  const maxForecast = Math.max(...forecast.map(f => f.count), 10); // Minimum scale of 10

  return (
    <div className="space-y-12">
      
      {/* Forecast Section */}
      <div className="bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-sm rounded-xl p-6 sm:p-8">
        <h3 className="text-base font-semibold leading-6 text-zinc-900 dark:text-zinc-100 mb-6">30-Day Study Forecast</h3>
        <div className="h-64 flex items-end gap-1 sm:gap-2">
          {forecast.map((f, i) => {
            const height = `${(f.count / maxForecast) * 100}%`;
            const dateObj = new Date(f.date);
            const isToday = i === 0;
            return (
              <div key={f.date} className="flex-1 flex flex-col justify-end h-full group relative">
                <div 
                  className={`w-full rounded-t-sm transition-all ${isToday ? 'bg-blue-500' : 'bg-zinc-300 dark:bg-zinc-700 hover:bg-zinc-400 dark:hover:bg-zinc-600'}`}
                  style={{ height: f.count === 0 ? '4px' : height }}
                ></div>
                
                {/* Tooltip */}
                <div className="opacity-0 group-hover:opacity-100 absolute bottom-full mb-2 left-1/2 -translate-x-1/2 bg-zinc-800 text-white text-xs rounded py-1 px-2 whitespace-nowrap pointer-events-none z-10 transition-opacity">
                  {dateObj.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}: {f.count} cards
                </div>
              </div>
            );
          })}
        </div>
        <div className="flex justify-between mt-4 text-xs font-medium text-zinc-500 dark:text-zinc-400">
          <span>Today</span>
          <span>+15 Days</span>
          <span>+30 Days</span>
        </div>
      </div>

      {/* Heatmap Section */}
      <div className="bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-sm rounded-xl p-6 sm:p-8">
        <h3 className="text-base font-semibold leading-6 text-zinc-900 dark:text-zinc-100 mb-6">Review Heatmap</h3>
        <p className="text-sm text-zinc-500 dark:text-zinc-400 mb-6">
          Your daily review activity over the past 100 days.
        </p>
        
        {/* Simple flex grid for heatmap representation */}
        <div className="flex flex-wrap gap-1">
          {Array.from({ length: 100 }).map((_, i) => {
            // Reconstruct dates going backwards from today
            const d = new Date();
            d.setDate(d.getDate() - (99 - i));
            const dateString = d.toISOString().split('T')[0];
            const heat = heatmap.find(h => h.date === dateString)?.count || 0;
            
            // Color intensity logic
            let bgClass = 'bg-zinc-100 dark:bg-zinc-800'; // 0
            if (heat > 0 && heat <= 10) bgClass = 'bg-blue-200 dark:bg-blue-900/40';
            else if (heat > 10 && heat <= 50) bgClass = 'bg-blue-400 dark:bg-blue-700';
            else if (heat > 50) bgClass = 'bg-blue-600 dark:bg-blue-500';

            return (
              <div 
                key={i} 
                className={`w-3 h-3 sm:w-4 sm:h-4 rounded-sm ${bgClass}`}
                title={`${dateString}: ${heat} reviews`}
              ></div>
            );
          })}
        </div>
        <div className="mt-4 flex items-center gap-2 text-xs text-zinc-500">
          <span>Less</span>
          <div className="w-3 h-3 rounded-sm bg-zinc-100 dark:bg-zinc-800"></div>
          <div className="w-3 h-3 rounded-sm bg-blue-200 dark:bg-blue-900/40"></div>
          <div className="w-3 h-3 rounded-sm bg-blue-400 dark:bg-blue-700"></div>
          <div className="w-3 h-3 rounded-sm bg-blue-600 dark:bg-blue-500"></div>
          <span>More</span>
        </div>
      </div>

    </div>
  );
}
