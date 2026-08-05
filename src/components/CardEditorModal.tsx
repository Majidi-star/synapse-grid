'use client';

import { useState, useEffect } from 'react';
import { X, Loader2 } from 'lucide-react';

type Card = {
  id: string;
  type: string;
  front: string;
  back: string;
  extraFields: string;
};

interface CardEditorModalProps {
  deckId: string;
  existingCard: Card | null;
  onClose: () => void;
}

export default function CardEditorModal({ deckId, existingCard, onClose }: CardEditorModalProps) {
  const [type, setType] = useState(existingCard?.type || 'BASIC');
  const [front, setFront] = useState(existingCard?.front || '');
  const [back, setBack] = useState(existingCard?.back || '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (existingCard) {
      setType(existingCard.type);
      setFront(existingCard.front);
      setBack(existingCard.back);
    }
  }, [existingCard]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!front.trim()) {
      setError('Front side cannot be empty');
      return;
    }

    setLoading(true);
    setError('');

    const payload = {
      deckId,
      type,
      front,
      back,
      extraFields: {}
    };

    try {
      const url = existingCard ? `/api/cards/${existingCard.id}` : '/api/cards';
      const method = existingCard ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        onClose();
      } else {
        const data = await res.json();
        setError(data.message || 'Failed to save card');
      }
    } catch (err) {
      setError('An error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative z-10" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div className="fixed inset-0 bg-zinc-500 bg-opacity-75 dark:bg-zinc-900 dark:bg-opacity-80 transition-opacity"></div>
      
      <div className="fixed inset-0 z-10 w-screen overflow-y-auto">
        <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <div className="relative transform overflow-hidden rounded-lg bg-white dark:bg-zinc-950 px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-2xl sm:p-6 border border-zinc-200 dark:border-zinc-800">
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
                <h3 className="text-xl font-semibold leading-6 text-zinc-900 dark:text-zinc-100" id="modal-title">
                  {existingCard ? 'Edit Card' : 'Add New Card'}
                </h3>
                
                <form onSubmit={handleSubmit} className="mt-6 space-y-6 w-full">
                  <div>
                    <label htmlFor="card-type" className="block text-sm font-medium leading-6 text-zinc-900 dark:text-zinc-300">
                      Card Type
                    </label>
                    <select
                      id="card-type"
                      value={type}
                      onChange={(e) => setType(e.target.value)}
                      className="mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-zinc-900 dark:text-zinc-100 dark:bg-zinc-900 ring-1 ring-inset ring-zinc-300 dark:ring-zinc-700 focus:ring-2 focus:ring-blue-600 sm:text-sm sm:leading-6"
                    >
                      <option value="BASIC">Basic Q&A</option>
                      <option value="CLOZE">Cloze Deletion</option>
                    </select>
                  </div>

                  <div>
                    <label htmlFor="front" className="block text-sm font-medium leading-6 text-zinc-900 dark:text-zinc-300">
                      {type === 'CLOZE' ? 'Text (use {{c1::hidden text}} for cloze)' : 'Front (Question)'}
                    </label>
                    <div className="mt-2">
                      <textarea
                        id="front"
                        rows={4}
                        value={front}
                        onChange={(e) => setFront(e.target.value)}
                        className="block w-full rounded-md border-0 py-1.5 px-3 text-zinc-900 dark:text-zinc-100 dark:bg-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 dark:ring-zinc-700 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
                        placeholder={type === 'CLOZE' ? 'The capital of France is {{c1::Paris}}.' : 'What is the capital of France?'}
                      />
                    </div>
                  </div>

                  {type !== 'CLOZE' && (
                    <div>
                      <label htmlFor="back" className="block text-sm font-medium leading-6 text-zinc-900 dark:text-zinc-300">
                        Back (Answer)
                      </label>
                      <div className="mt-2">
                        <textarea
                          id="back"
                          rows={4}
                          value={back}
                          onChange={(e) => setBack(e.target.value)}
                          className="block w-full rounded-md border-0 py-1.5 px-3 text-zinc-900 dark:text-zinc-100 dark:bg-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 dark:ring-zinc-700 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
                          placeholder="Paris"
                        />
                      </div>
                    </div>
                  )}

                  {error && <p className="text-sm text-red-500">{error}</p>}

                  <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                    <button
                      type="submit"
                      disabled={loading}
                      className="inline-flex w-full justify-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 sm:ml-3 sm:w-auto disabled:opacity-50"
                    >
                      {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
                      {existingCard ? 'Save Changes' : 'Add Card'}
                    </button>
                    <button
                      type="button"
                      onClick={onClose}
                      className="mt-3 inline-flex w-full justify-center rounded-md bg-white dark:bg-zinc-900 px-3 py-2 text-sm font-semibold text-zinc-900 dark:text-zinc-300 shadow-sm ring-1 ring-inset ring-zinc-300 dark:ring-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-800 sm:mt-0 sm:w-auto"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
