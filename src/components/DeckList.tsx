'use client';

import { useState } from 'react';
import { useRef } from 'react';
import Link from 'next/link';
import { Layers, MoreVertical, Plus, Trash2, Edit2, PlayCircle, Upload } from 'lucide-react';
import { useRouter } from 'next/navigation';

type Deck = {
  id: string;
  name: string;
  description: string | null;
  _count: { cards: number };
  subDecks: Deck[];
};

export default function DeckList({ initialDecks }: { initialDecks: Deck[] }) {
  const [decks, setDecks] = useState<Deck[]>(initialDecks);
  const [isCreating, setIsCreating] = useState(false);
  const [newDeckName, setNewDeckName] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDeckName.trim()) return;
    
    setLoading(true);
    try {
      const res = await fetch('/api/decks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: newDeckName }),
      });
      
      if (res.ok) {
        setNewDeckName('');
        setIsCreating(false);
        router.refresh(); // Tell Next.js server components to re-fetch
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this deck? All cards inside will be deleted.')) return;
    try {
      const res = await fetch(`/api/decks/${id}`, { method: 'DELETE' });
      if (res.ok) {
        router.refresh();
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      setLoading(true);
      const text = await file.text();
      const jsonData = JSON.parse(text);

      const res = await fetch('/api/import', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(jsonData)
      });

      if (res.ok) {
        router.refresh();
      } else {
        alert('Import failed. Invalid file format.');
      }
    } catch (err) {
      alert('Error parsing JSON file.');
    } finally {
      setLoading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  return (
    <div className="mt-8">
      {isCreating && (
        <form onSubmit={handleCreate} className="mb-8 bg-white dark:bg-zinc-900 p-6 rounded-lg border border-zinc-200 dark:border-zinc-800 shadow-sm">
          <h3 className="text-lg font-medium text-zinc-900 dark:text-zinc-100 mb-4">Create New Deck</h3>
          <div className="flex gap-4">
            <input
              type="text"
              value={newDeckName}
              onChange={(e) => setNewDeckName(e.target.value)}
              placeholder="Deck Name (e.g., Biology 101)"
              className="flex-1 rounded-md border-0 py-2 px-3 text-zinc-900 ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-blue-600 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700"
              autoFocus
            />
            <button
              type="button"
              onClick={() => setIsCreating(false)}
              className="px-4 py-2 text-sm font-medium text-zinc-700 bg-white border border-zinc-300 rounded-md hover:bg-zinc-50 dark:bg-zinc-800 dark:text-zinc-300 dark:border-zinc-700 dark:hover:bg-zinc-700"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-500 disabled:opacity-50"
            >
              {loading ? 'Saving...' : 'Create'}
            </button>
          </div>
        </form>
      )}

      {!isCreating && (
        <div className="mb-6 flex justify-end gap-3">
          <input 
            type="file" 
            accept=".json" 
            ref={fileInputRef} 
            onChange={handleImport} 
            className="hidden" 
          />
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={loading}
            className="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 hover:bg-zinc-50 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700 dark:hover:bg-zinc-700 disabled:opacity-50"
          >
            <Upload className="-ml-0.5 mr-1.5 h-5 w-5" />
            Import Deck
          </button>
          <button
            onClick={() => setIsCreating(true)}
            className="inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
          >
            <Plus className="-ml-0.5 mr-1.5 h-5 w-5" />
            New Deck
          </button>
        </div>
      )}

      {decks.length === 0 && !isCreating ? (
        <div className="rounded-lg border border-zinc-200 dark:border-zinc-800 border-dashed p-12 text-center">
          <Layers className="mx-auto h-12 w-12 text-zinc-400" />
          <h3 className="mt-2 text-sm font-semibold text-zinc-900 dark:text-zinc-100">No decks</h3>
          <p className="mt-1 text-sm text-zinc-500">Get started by creating a new deck.</p>
        </div>
      ) : (
        <ul className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {decks.map((deck) => (
            <li key={deck.id} className="col-span-1 divide-y divide-zinc-200 dark:divide-zinc-800 rounded-lg bg-white dark:bg-zinc-900 shadow border border-zinc-200 dark:border-zinc-800 flex flex-col">
              <div className="flex w-full items-center justify-between space-x-6 p-6 flex-1">
                <div className="flex-1 truncate">
                  <div className="flex items-center space-x-3">
                    <h3 className="truncate text-lg font-medium text-zinc-900 dark:text-zinc-100">{deck.name}</h3>
                  </div>
                  <p className="mt-1 truncate text-sm text-zinc-500 dark:text-zinc-400">
                    {deck._count.cards} cards • {deck.subDecks?.length || 0} subdecks
                  </p>
                </div>
              </div>
              <div>
                <div className="-mt-px flex divide-x divide-zinc-200 dark:divide-zinc-800">
                  <div className="flex w-0 flex-1">
                    <Link
                      href={`/review/${deck.id}`}
                      className="relative -mr-px inline-flex w-0 flex-1 items-center justify-center gap-x-2 rounded-bl-lg border-transparent py-4 text-sm font-semibold text-blue-600 hover:bg-zinc-50 dark:hover:bg-zinc-800/50"
                    >
                      <PlayCircle className="h-5 w-5" aria-hidden="true" />
                      Study
                    </Link>
                  </div>
                  <div className="-ml-px flex w-0 flex-1">
                    <Link
                      href={`/decks/${deck.id}`}
                      className="relative inline-flex w-0 flex-1 items-center justify-center gap-x-2 border-transparent py-4 text-sm font-semibold text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800/50"
                    >
                      <Edit2 className="h-5 w-5 text-zinc-400" aria-hidden="true" />
                      Edit
                    </Link>
                  </div>
                  <div className="-ml-px flex w-0 flex-1">
                    <button
                      onClick={() => handleDelete(deck.id)}
                      className="relative inline-flex w-0 flex-1 items-center justify-center gap-x-2 rounded-br-lg border-transparent py-4 text-sm font-semibold text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
                    >
                      <Trash2 className="h-5 w-5" aria-hidden="true" />
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
