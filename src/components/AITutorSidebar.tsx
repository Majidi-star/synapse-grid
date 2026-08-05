'use client';

import { useState, useRef, useEffect } from 'react';
import { Bot, Send, Loader2, X } from 'lucide-react';

interface AITutorSidebarProps {
  deckId: string;
  currentCard: any;
  onClose: () => void;
}

type Message = {
  role: 'user' | 'assistant';
  content: string;
};

export default function AITutorSidebar({ deckId, currentCard, onClose }: AITutorSidebarProps) {
  const [messages, setMessages] = useState<Message[]>([
    { role: 'assistant', content: "Hi! I'm your AI Tutor. Need help understanding this card?" }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || loading) return;

    const userMsg = input.trim();
    setInput('');
    const newMessages: Message[] = [...messages, { role: 'user', content: userMsg }];
    setMessages(newMessages);
    setLoading(true);

    try {
      const res = await fetch('/api/tutor', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          deckId,
          messages: newMessages,
          currentCardContext: currentCard
        }),
      });

      if (res.ok) {
        const data = await res.json();
        setMessages(prev => [...prev, { role: 'assistant', content: data.message }]);
      } else {
        setMessages(prev => [...prev, { role: 'assistant', content: "Sorry, I'm having trouble connecting right now." }]);
      }
    } catch (err) {
      setMessages(prev => [...prev, { role: 'assistant', content: "Network error occurred." }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="w-80 border-l border-zinc-800 bg-zinc-950 flex flex-col h-screen fixed right-0 top-0 z-20 shadow-2xl animate-in slide-in-from-right-80 duration-300">
      <div className="p-4 border-b border-zinc-800 flex justify-between items-center bg-zinc-900/50">
        <div className="flex items-center text-zinc-100 font-semibold">
          <Bot className="mr-2 h-5 w-5 text-blue-400" />
          AI Tutor
        </div>
        <button onClick={onClose} className="text-zinc-500 hover:text-zinc-300">
          <X className="h-5 w-5" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((m, i) => (
          <div key={i} className={`flex flex-col ${m.role === 'user' ? 'items-end' : 'items-start'}`}>
            <div 
              className={`max-w-[85%] rounded-2xl px-4 py-2 text-sm ${
                m.role === 'user' 
                  ? 'bg-blue-600 text-white rounded-br-none' 
                  : 'bg-zinc-800 text-zinc-200 rounded-bl-none'
              }`}
            >
              {m.content}
            </div>
          </div>
        ))}
        {loading && (
          <div className="flex items-start">
            <div className="bg-zinc-800 rounded-2xl rounded-bl-none px-4 py-3">
              <Loader2 className="h-4 w-4 animate-spin text-zinc-400" />
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="p-4 border-t border-zinc-800 bg-zinc-900/50">
        <form onSubmit={handleSend} className="relative flex items-center">
          <input
            type="text"
            value={input}
            onChange={e => setInput(e.target.value)}
            placeholder="Ask a question..."
            className="w-full bg-zinc-800 border-0 rounded-full py-2.5 pl-4 pr-12 text-sm text-zinc-100 placeholder:text-zinc-500 focus:ring-1 focus:ring-blue-500"
          />
          <button 
            type="submit" 
            disabled={loading || !input.trim()}
            className="absolute right-1.5 p-1.5 rounded-full bg-blue-600 text-white disabled:opacity-50 hover:bg-blue-500 transition-colors"
          >
            <Send className="h-4 w-4" />
          </button>
        </form>
      </div>
    </div>
  );
}
