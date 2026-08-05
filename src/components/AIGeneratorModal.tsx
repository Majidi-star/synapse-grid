'use client';

import { useState } from 'react';
import { X, Loader2, Sparkles, Check, Trash2, Edit3 } from 'lucide-react';

interface AIGeneratorModalProps {
  deckId: string;
  onClose: () => void;
}

type GeneratedCard = {
  id: string;
  front: string;
  back: string;
  type: string;
  accepted?: boolean;
};

export default function AIGeneratorModal({ deckId, onClose }: AIGeneratorModalProps) {
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [results, setResults] = useState<GeneratedCard[]>([]);
  const [saving, setSaving] = useState(false);

  const handleGenerate = async () => {
    if (!text.trim()) {
      setError('Please provide text to extract cards from.');
      return;
    }
    
    setLoading(true);
    setError('');

    try {
      const res = await fetch('/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, deckId }),
      });

      if (res.ok) {
        const data = await res.json();
        // Mark all as initially 'accepted' to make it easy for user
        const mapped = data.cards.map((c: any) => ({ ...c, accepted: true }));
        setResults(mapped);
      } else {
        const data = await res.json();
        setError(data.message || 'Generation failed');
      }
    } catch (err) {
      setError('Network error occurred.');
    } finally {
      setLoading(false);
    }
  };

  const toggleAccept = (id: string) => {
    setResults(prev => prev.map(c => c.id === id ? { ...c, accepted: !c.accepted } : c));
  };

  const handleFrontChange = (id: string, newFront: string) => {
    setResults(prev => prev.map(c => c.id === id ? { ...c, front: newFront } : c));
  };

  const handleBackChange = (id: string, newBack: string) => {
    setResults(prev => prev.map(c => c.id === id ? { ...c, back: newBack } : c));
  };

  const handleSaveToDeck = async () => {
    const cardsToSave = results.filter(c => c.accepted);
    if (cardsToSave.length === 0) return;

    setSaving(true);
    try {
      // Save sequentially or in parallel. We'll do parallel for speed.
      await Promise.all(
        cardsToSave.map(card => 
          fetch('/api/cards', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              deckId,
              type: card.type,
              front: card.front,
              back: card.back
            })
          })
        )
      );
      
      onClose(); // Will trigger router.refresh() in parent
    } catch (err) {
      setError('Failed to save some cards.');
      setSaving(false);
    }
  };

  return (
    <div className="relative z-10" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div className="fixed inset-0 bg-zinc-500 bg-opacity-75 dark:bg-zinc-900 dark:bg-opacity-80 transition-opacity"></div>
      
      <div className="fixed inset-0 z-10 w-screen overflow-y-auto">
        <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <div className="relative transform overflow-hidden rounded-lg bg-white dark:bg-zinc-950 px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-4xl sm:p-6 border border-zinc-200 dark:border-zinc-800">
            <div className="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
              <button
                type="button"
                className="rounded-md bg-white dark:bg-zinc-950 text-zinc-400 hover:text-zinc-500 focus:outline-none"
                onClick={onClose}
              >
                <span className="sr-only">Close</span>
                <X className="h-6 w-6" aria-hidden="true" />
              </button>
            </div>
            
            <div className="sm:flex sm:items-start w-full">
              <div className="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left w-full">
                <h3 className="text-xl font-semibold leading-6 text-zinc-900 dark:text-zinc-100 flex items-center" id="modal-title">
                  <Sparkles className="mr-2 h-5 w-5 text-blue-500" />
                  AI Card Generator
                </h3>
                
                {results.length === 0 ? (
                  <div className="mt-6 w-full">
                    <p className="text-sm text-zinc-500 dark:text-zinc-400 mb-2">
                      Paste your study notes, lecture transcript, or text here. Claude 3.5 Sonnet will extract high-yield flashcards automatically.
                    </p>
                    <textarea
                      rows={10}
                      value={text}
                      onChange={(e) => setText(e.target.value)}
                      className="block w-full rounded-md border-0 py-2 px-3 text-zinc-900 dark:text-zinc-100 dark:bg-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 dark:ring-zinc-700 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
                      placeholder="The mitochondria is a double-membrane-bound organelle found in most eukaryotic organisms..."
                    />
                    
                    {error && <p className="mt-2 text-sm text-red-500">{error}</p>}

                    <div className="mt-5 sm:mt-6 sm:flex sm:flex-row-reverse">
                      <button
                        type="button"
                        onClick={handleGenerate}
                        disabled={loading}
                        className="inline-flex w-full justify-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 sm:ml-3 sm:w-auto disabled:opacity-50"
                      >
                        {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
                        {loading ? 'Analyzing...' : 'Generate Flashcards'}
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="mt-6 w-full max-h-[60vh] overflow-y-auto pr-2">
                    <p className="text-sm text-zinc-500 dark:text-zinc-400 mb-4">
                      Review the generated cards. Uncheck any you want to reject.
                    </p>
                    
                    <div className="space-y-4">
                      {results.map((card) => (
                        <div key={card.id} className={`p-4 rounded-lg border ${card.accepted ? 'border-blue-500/50 bg-blue-50 dark:bg-blue-900/10' : 'border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-900/50 opacity-60'}`}>
                          <div className="flex justify-between items-start mb-2">
                            <label className="flex items-center text-sm font-medium text-zinc-900 dark:text-zinc-100 cursor-pointer">
                              <input 
                                type="checkbox" 
                                checked={card.accepted}
                                onChange={() => toggleAccept(card.id)}
                                className="mr-2 h-4 w-4 rounded border-zinc-300 text-blue-600 focus:ring-blue-600"
                              />
                              {card.accepted ? 'Accepted' : 'Rejected'}
                            </label>
                          </div>
                          <div className="space-y-3 pl-6">
                            <div>
                              <span className="text-xs font-semibold text-zinc-500 block mb-1">Front</span>
                              <input 
                                type="text"
                                value={card.front}
                                onChange={(e) => handleFrontChange(card.id, e.target.value)}
                                disabled={!card.accepted}
                                className="block w-full rounded-md border-0 py-1.5 px-2 text-zinc-900 dark:text-zinc-100 bg-white dark:bg-zinc-950 shadow-sm ring-1 ring-inset ring-zinc-300 dark:ring-zinc-700 focus:ring-2 focus:ring-blue-600 sm:text-sm sm:leading-6 disabled:opacity-50"
                              />
                            </div>
                            <div>
                              <span className="text-xs font-semibold text-zinc-500 block mb-1">Back</span>
                              <input 
                                type="text"
                                value={card.back}
                                onChange={(e) => handleBackChange(card.id, e.target.value)}
                                disabled={!card.accepted}
                                className="block w-full rounded-md border-0 py-1.5 px-2 text-zinc-900 dark:text-zinc-100 bg-white dark:bg-zinc-950 shadow-sm ring-1 ring-inset ring-zinc-300 dark:ring-zinc-700 focus:ring-2 focus:ring-blue-600 sm:text-sm sm:leading-6 disabled:opacity-50"
                              />
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>

                    <div className="mt-5 sm:mt-6 sm:flex sm:flex-row-reverse sticky bottom-0 bg-white dark:bg-zinc-950 pt-4 pb-2 border-t border-zinc-200 dark:border-zinc-800">
                      <button
                        type="button"
                        onClick={handleSaveToDeck}
                        disabled={saving || !results.some(c => c.accepted)}
                        className="inline-flex w-full justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-green-500 sm:ml-3 sm:w-auto disabled:opacity-50"
                      >
                        {saving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
                        Save {results.filter(c => c.accepted).length} Cards to Deck
                      </button>
                      <button
                        type="button"
                        onClick={() => setResults([])} // Reset
                        disabled={saving}
                        className="mt-3 inline-flex w-full justify-center rounded-md bg-white dark:bg-zinc-900 px-3 py-2 text-sm font-semibold text-zinc-900 dark:text-zinc-300 shadow-sm ring-1 ring-inset ring-zinc-300 dark:ring-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-800 sm:mt-0 sm:w-auto"
                      >
                        Discard All
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
