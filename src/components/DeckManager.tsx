'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowLeft, Plus, PlayCircle, Edit3, Trash2, Sparkles, Download, Search } from 'lucide-react';
import CardEditorModal from './CardEditorModal';
import AIGeneratorModal from './AIGeneratorModal';

type Card = {
  id: string;
  type: string;
  front: string;
  back: string;
  extraFields: string;
};

type Deck = {
  id: string;
  name: string;
  description: string | null;
  cards: Card[];
};

export default function DeckManager({ initialDeck }: { initialDeck: Deck }) {
  const router = useRouter();
  const [deck] = useState<Deck>(initialDeck);
  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const [isAIOpen, setIsAIOpen] = useState(false);
  const [editingCard, setEditingCard] = useState<Card | null>(null);
  
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCardIds, setSelectedCardIds] = useState<Set<string>>(new Set());
  const [isDeletingBulk, setIsDeletingBulk] = useState(false);

  const handleDeleteCard = async (cardId: string) => {
    if (!confirm('Delete this flashcard forever?')) return;
    try {
      const res = await fetch(`/api/cards/${cardId}`, { method: 'DELETE' });
      if (res.ok) {
        router.refresh();
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleBulkDelete = async () => {
    if (selectedCardIds.size === 0) return;
    if (!confirm(`Delete ${selectedCardIds.size} flashcards forever?`)) return;
    
    setIsDeletingBulk(true);
    try {
      // Execute deletions in parallel
      await Promise.all(
        Array.from(selectedCardIds).map(cardId =>
          fetch(`/api/cards/${cardId}`, { method: 'DELETE' })
        )
      );
      setSelectedCardIds(new Set());
      router.refresh();
    } catch (err) {
      console.error(err);
      alert('Failed to delete some cards');
    } finally {
      setIsDeletingBulk(false);
    }
  };

  const toggleCardSelection = (cardId: string) => {
    const newSet = new Set(selectedCardIds);
    if (newSet.has(cardId)) {
      newSet.delete(cardId);
    } else {
      newSet.add(cardId);
    }
    setSelectedCardIds(newSet);
  };

  const toggleAllSelection = () => {
    if (selectedCardIds.size === filteredCards.length) {
      setSelectedCardIds(new Set());
    } else {
      setSelectedCardIds(new Set(filteredCards.map(c => c.id)));
    }
  };

  const filteredCards = deck.cards.filter(card => 
    card.front.toLowerCase().includes(searchQuery.toLowerCase()) || 
    card.back.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleOpenNewCard = () => {
    setEditingCard(null);
    setIsEditorOpen(true);
  };

  const handleOpenEditCard = (card: Card) => {
    setEditingCard(card);
    setIsEditorOpen(true);
  };

  const handleCloseEditor = () => {
    setIsEditorOpen(false);
    setEditingCard(null);
    router.refresh(); // Refresh the list after saving
  };

  return (
    <div>
      <div className="mb-6">
        <Link href="/" className="inline-flex items-center text-sm font-medium text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200">
          <ArrowLeft className="mr-1 h-4 w-4" />
          Back to Decks
        </Link>
      </div>

      <div className="sm:flex sm:items-center sm:justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100">{deck.name}</h1>
          {deck.description && <p className="mt-2 text-zinc-500 dark:text-zinc-400">{deck.description}</p>}
        </div>
        <div className="mt-4 flex gap-3 sm:mt-0">
          <Link
            href={`/review/${deck.id}`}
            className="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 hover:bg-zinc-50 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700 dark:hover:bg-zinc-700"
          >
            <PlayCircle className="-ml-0.5 mr-1.5 h-5 w-5 text-blue-500" aria-hidden="true" />
            Study Now
          </Link>
          <button
            onClick={() => setIsAIOpen(true)}
            className="inline-flex items-center rounded-md bg-zinc-800 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 dark:bg-zinc-700 dark:hover:bg-zinc-600"
          >
            <Sparkles className="-ml-0.5 mr-1.5 h-5 w-5 text-yellow-400" aria-hidden="true" />
            AI Generate
          </button>
          <a
            href={`/api/decks/${deck.id}/export`}
            download
            className="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 hover:bg-zinc-50 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700 dark:hover:bg-zinc-700"
          >
            <Download className="-ml-0.5 mr-1.5 h-5 w-5" aria-hidden="true" />
            Export
          </a>
          <button
            onClick={handleOpenNewCard}
            className="inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
          >
            <Plus className="-ml-0.5 mr-1.5 h-5 w-5" aria-hidden="true" />
            Add Card
          </button>
        </div>
      </div>

      <div className="mt-8 flow-root">
        {/* Toolbar: Search and Bulk Actions */}
        <div className="mb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="relative w-full sm:max-w-md">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <Search className="h-5 w-5 text-zinc-400" aria-hidden="true" />
            </div>
            <input
              type="text"
              className="block w-full rounded-md border-0 py-2 pl-10 pr-3 text-zinc-900 ring-1 ring-inset ring-zinc-300 placeholder:text-zinc-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 dark:bg-zinc-900 dark:text-zinc-100 dark:ring-zinc-700 sm:text-sm sm:leading-6"
              placeholder="Search cards..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          {selectedCardIds.size > 0 && (
            <div className="flex items-center gap-3">
              <span className="text-sm text-zinc-500 dark:text-zinc-400">
                {selectedCardIds.size} selected
              </span>
              <button
                onClick={handleBulkDelete}
                disabled={isDeletingBulk}
                className="inline-flex items-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 disabled:opacity-50"
              >
                <Trash2 className="-ml-0.5 mr-1.5 h-4 w-4" aria-hidden="true" />
                Delete Selected
              </button>
            </div>
          )}
        </div>

        <div className="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div className="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
            {deck.cards.length === 0 ? (
              <div className="rounded-lg border border-zinc-200 dark:border-zinc-800 border-dashed p-12 text-center">
                <h3 className="mt-2 text-sm font-semibold text-zinc-900 dark:text-zinc-100">No cards in this deck</h3>
                <p className="mt-1 text-sm text-zinc-500">Add some cards or generate them with AI.</p>
              </div>
            ) : (
              <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
                <thead>
                  <tr>
                    <th scope="col" className="relative px-4 sm:w-12 sm:px-6">
                      <input
                        type="checkbox"
                        className="absolute left-4 top-1/2 -mt-2 h-4 w-4 rounded border-zinc-300 text-blue-600 focus:ring-blue-600 dark:border-zinc-700 dark:bg-zinc-900"
                        checked={filteredCards.length > 0 && selectedCardIds.size === filteredCards.length}
                        onChange={toggleAllSelection}
                      />
                    </th>
                    <th scope="col" className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100 sm:pl-0 w-1/3">Front</th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100 w-1/3">Back</th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100 w-1/6">Type</th>
                    <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-0">
                      <span className="sr-only">Actions</span>
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800 bg-transparent">
                  {filteredCards.map((card) => (
                    <tr key={card.id} className={selectedCardIds.has(card.id) ? 'bg-zinc-50 dark:bg-zinc-800/50' : ''}>
                      <td className="relative px-4 sm:w-12 sm:px-6">
                        {selectedCardIds.has(card.id) && (
                          <div className="absolute inset-y-0 left-0 w-0.5 bg-blue-600" />
                        )}
                        <input
                          type="checkbox"
                          className="absolute left-4 top-1/2 -mt-2 h-4 w-4 rounded border-zinc-300 text-blue-600 focus:ring-blue-600 dark:border-zinc-700 dark:bg-zinc-900"
                          value={card.id}
                          checked={selectedCardIds.has(card.id)}
                          onChange={() => toggleCardSelection(card.id)}
                        />
                      </td>
                      <td className="whitespace-pre-wrap py-4 pl-4 pr-3 text-sm text-zinc-700 dark:text-zinc-300 sm:pl-0">
                        {card.front.length > 80 ? card.front.substring(0, 80) + '...' : card.front}
                      </td>
                      <td className="whitespace-pre-wrap px-3 py-4 text-sm text-zinc-700 dark:text-zinc-300">
                        {card.back.length > 80 ? card.back.substring(0, 80) + '...' : card.back}
                      </td>
                      <td className="whitespace-nowrap px-3 py-4 text-sm text-zinc-500">
                        <span className="inline-flex items-center rounded-md bg-zinc-100 dark:bg-zinc-800 px-2 py-1 text-xs font-medium text-zinc-600 dark:text-zinc-400">
                          {card.type}
                        </span>
                      </td>
                      <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                        <button onClick={() => handleOpenEditCard(card)} className="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 mr-4">
                          <Edit3 className="h-4 w-4" />
                        </button>
                        <button onClick={() => handleDeleteCard(card.id)} className="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300">
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {isEditorOpen && (
        <CardEditorModal
          deckId={deck.id}
          existingCard={editingCard}
          onClose={handleCloseEditor}
        />
      )}

      {isAIOpen && (
        <AIGeneratorModal
          deckId={deck.id}
          onClose={() => {
            setIsAIOpen(false);
            router.refresh();
          }}
        />
      )}
    </div>
  );
}
