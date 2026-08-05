'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowLeft, CheckCircle, Loader2, Bot } from 'lucide-react';
import AITutorSidebar from './AITutorSidebar';

type Card = {
  id: string;
  type: string;
  front: string;
  back: string;
  extraFields: string;
};

export default function StudySession({ deckId, deckName }: { deckId: string, deckName: string }) {
  const [queue, setQueue] = useState<Card[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [currentIndex, setCurrentIndex] = useState(0);
  const [showAnswer, setShowAnswer] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [showTutor, setShowTutor] = useState(false);
  const [sessionStats, setSessionStats] = useState({ again: 0, hard: 0, good: 0, easy: 0 });

  useEffect(() => {
    const fetchQueue = async () => {
      try {
        const res = await fetch(`/api/study/${deckId}`);
        if (res.ok) {
          const cards = await res.json();
          setQueue(cards);
        } else {
          setError('Failed to load study queue.');
        }
      } catch (err) {
        setError('Network error occurred.');
      } finally {
        setLoading(false);
      }
    };
    fetchQueue();
  }, [deckId]);

  const currentCard = queue[currentIndex];

  const submitRating = useCallback(async (rating: string) => {
    if (!currentCard || submitting) return;
    setSubmitting(true);
    
    try {
      await fetch(`/api/study/${deckId}/review`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cardId: currentCard.id, rating })
      });
      
      setSessionStats(prev => ({
        ...prev,
        [rating.toLowerCase()]: prev[rating.toLowerCase() as keyof typeof sessionStats] + 1
      }));

      // Move to next card
      setShowAnswer(false);
      setCurrentIndex(prev => prev + 1);
    } catch (err) {
      console.error(err);
    } finally {
      setSubmitting(false);
    }
  }, [currentCard, deckId, submitting]);

  // Keyboard bindings
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!currentCard) return;

      if (!showAnswer) {
        if (e.code === 'Space' || e.code === 'Enter') {
          e.preventDefault();
          setShowAnswer(true);
        }
      } else {
        switch (e.key) {
          case '1': submitRating('AGAIN'); break;
          case '2': submitRating('HARD'); break;
          case '3': submitRating('GOOD'); break;
          case '4': submitRating('EASY'); break;
          case ' ': // spacebar defaults to GOOD
          case 'Enter': 
            e.preventDefault();
            submitRating('GOOD'); 
            break;
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [currentCard, showAnswer, submitRating]);

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-zinc-500" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex-1 flex items-center justify-center flex-col gap-4">
        <p className="text-red-400">{error}</p>
        <Link href="/" className="text-blue-500 hover:underline">Return to Dashboard</Link>
      </div>
    );
  }

  if (currentIndex >= queue.length && queue.length > 0) {
    const totalReviewed = sessionStats.again + sessionStats.hard + sessionStats.good + sessionStats.easy;
    return (
      <div className="flex-1 flex items-center justify-center pt-16 px-4">
        <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-8 max-w-md w-full text-center shadow-xl">
          <CheckCircle className="h-16 w-16 text-green-500 mx-auto mb-6" />
          <h2 className="text-3xl font-bold mb-2 text-white">Session Complete!</h2>
          <p className="text-zinc-400 mb-8">You finished studying {deckName} for now.</p>
          
          <div className="grid grid-cols-2 gap-4 mb-8">
            <div className="bg-zinc-950 rounded-lg p-4">
              <div className="text-sm text-zinc-500 mb-1">Total Reviewed</div>
              <div className="text-2xl font-semibold text-white">{totalReviewed}</div>
            </div>
            <div className="bg-zinc-950 rounded-lg p-4">
              <div className="text-sm text-zinc-500 mb-1">Accuracy</div>
              <div className="text-2xl font-semibold text-white">
                {totalReviewed > 0 ? Math.round(((sessionStats.good + sessionStats.easy) / totalReviewed) * 100) : 0}%
              </div>
            </div>
          </div>
          
          <div className="flex justify-between items-center text-sm mb-8 px-4">
            <div className="flex flex-col items-center"><span className="text-red-400 font-bold">{sessionStats.again}</span><span className="text-zinc-500">Again</span></div>
            <div className="flex flex-col items-center"><span className="text-orange-400 font-bold">{sessionStats.hard}</span><span className="text-zinc-500">Hard</span></div>
            <div className="flex flex-col items-center"><span className="text-green-400 font-bold">{sessionStats.good}</span><span className="text-zinc-500">Good</span></div>
            <div className="flex flex-col items-center"><span className="text-blue-400 font-bold">{sessionStats.easy}</span><span className="text-zinc-500">Easy</span></div>
          </div>

          <Link 
            href="/" 
            className="block w-full rounded-md bg-blue-600 px-6 py-3 text-sm font-semibold text-white hover:bg-blue-500 transition-colors"
          >
            Return to Dashboard
          </Link>
        </div>
      </div>
    );
  }

  if (queue.length === 0 && !loading && !error) {
    return (
      <div className="flex-1 flex items-center justify-center flex-col gap-6">
        <CheckCircle className="h-16 w-16 text-green-500" />
        <h2 className="text-3xl font-bold text-white">You're all caught up!</h2>
        <p className="text-zinc-400">No due cards for {deckName} right now.</p>
        <Link 
          href="/" 
          className="rounded-md bg-zinc-800 px-6 py-3 text-sm font-semibold text-white hover:bg-zinc-700"
        >
          Return to Dashboard
        </Link>
      </div>
    );
  }

  const parseCloze = (text: string, show: boolean) => {
    if (currentCard.type !== 'CLOZE') return text;
    // Basic cloze parser: replaces {{c1::hidden text}} with either [...] or the text
    const clozeRegex = /\{\{c\d+::(.*?)\}\}/g;
    return text.replace(clozeRegex, (match, p1) => {
      return show 
        ? `<span class="text-blue-400 font-bold bg-blue-900/30 px-1 rounded">${p1}</span>` 
        : `<span class="text-zinc-500 font-bold bg-zinc-800 px-2 rounded">[...]</span>`;
    });
  };

  return (
    <div className="flex-1 flex flex-col items-center pt-8 px-4 sm:px-6">
      <div className="w-full max-w-3xl flex justify-between items-center mb-8">
        <Link href="/" className="inline-flex items-center text-sm font-medium text-zinc-400 hover:text-zinc-200">
          <ArrowLeft className="mr-1 h-4 w-4" />
          Dashboard
        </Link>
        <div className="flex items-center gap-4">
          <span className="text-sm font-medium text-zinc-500">
            {currentIndex + 1} / {queue.length}
          </span>
          <button 
            onClick={() => setShowTutor(true)}
            className="inline-flex items-center text-sm font-medium text-blue-400 hover:text-blue-300 bg-blue-500/10 hover:bg-blue-500/20 px-3 py-1.5 rounded-full transition-colors"
          >
            <Bot className="mr-1.5 h-4 w-4" />
            AI Tutor
          </button>
        </div>
      </div>

      <div className="w-full max-w-3xl flex-1 flex flex-col gap-8 pb-32">
        {/* Front of card */}
        <div className="bg-zinc-900 rounded-2xl p-8 sm:p-12 shadow-lg min-h-[200px] flex items-center justify-center text-center">
          <div 
            className="text-2xl sm:text-3xl leading-relaxed whitespace-pre-wrap"
            dangerouslySetInnerHTML={{ __html: parseCloze(currentCard.front, false) }}
          />
        </div>

        {/* Back of card (Answer) */}
        {showAnswer && (
          <div className="bg-zinc-900 border-t-4 border-blue-500 rounded-2xl p-8 sm:p-12 shadow-lg min-h-[200px] flex items-center justify-center text-center animate-in fade-in slide-in-from-bottom-4 duration-300">
            <div 
              className="text-xl sm:text-2xl leading-relaxed whitespace-pre-wrap text-zinc-300"
              dangerouslySetInnerHTML={{ 
                __html: currentCard.type === 'CLOZE' 
                  ? parseCloze(currentCard.front, true) 
                  : currentCard.back 
              }}
            />
          </div>
        )}
      </div>

      {/* Control Bar Fixed at Bottom */}
      <div className="fixed bottom-0 left-0 right-0 bg-zinc-950/80 backdrop-blur-md border-t border-zinc-800 p-4 sm:p-6 flex justify-center z-10">
        <div className="w-full max-w-3xl flex justify-center gap-4">
          {!showAnswer ? (
            <button
              onClick={() => setShowAnswer(true)}
              className="w-full max-w-md rounded-xl bg-blue-600 py-4 text-lg font-bold shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-600 transition-colors"
            >
              Show Answer <span className="text-blue-300 font-normal ml-2 text-sm">(Space)</span>
            </button>
          ) : (
            <div className="grid grid-cols-4 gap-2 sm:gap-4 w-full">
              <button onClick={() => submitRating('AGAIN')} disabled={submitting} className="flex flex-col items-center justify-center rounded-xl bg-red-900/40 border border-red-800/50 hover:bg-red-900/60 py-3 sm:py-4 transition-colors disabled:opacity-50">
                <span className="text-red-400 font-bold text-sm sm:text-lg">Again</span>
                <span className="text-red-500/70 text-xs hidden sm:block">1</span>
              </button>
              <button onClick={() => submitRating('HARD')} disabled={submitting} className="flex flex-col items-center justify-center rounded-xl bg-orange-900/40 border border-orange-800/50 hover:bg-orange-900/60 py-3 sm:py-4 transition-colors disabled:opacity-50">
                <span className="text-orange-400 font-bold text-sm sm:text-lg">Hard</span>
                <span className="text-orange-500/70 text-xs hidden sm:block">2</span>
              </button>
              <button onClick={() => submitRating('GOOD')} disabled={submitting} className="flex flex-col items-center justify-center rounded-xl bg-green-900/40 border border-green-800/50 hover:bg-green-900/60 py-3 sm:py-4 transition-colors disabled:opacity-50">
                <span className="text-green-400 font-bold text-sm sm:text-lg">Good</span>
                <span className="text-green-500/70 text-xs hidden sm:block">3 / Space</span>
              </button>
              <button onClick={() => submitRating('EASY')} disabled={submitting} className="flex flex-col items-center justify-center rounded-xl bg-blue-900/40 border border-blue-800/50 hover:bg-blue-900/60 py-3 sm:py-4 transition-colors disabled:opacity-50">
                <span className="text-blue-400 font-bold text-sm sm:text-lg">Easy</span>
                <span className="text-blue-500/70 text-xs hidden sm:block">4</span>
              </button>
            </div>
          )}
        </div>
      </div>

      {showTutor && currentCard && (
        <AITutorSidebar 
          deckId={deckId}
          currentCard={currentCard}
          onClose={() => setShowTutor(false)}
        />
      )}
    </div>
  );
}
