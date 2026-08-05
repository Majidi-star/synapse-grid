'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2 } from 'lucide-react';

interface SettingsFormProps {
  user: {
    name: string | null;
    email: string;
    retentionTargetPreference: number;
    llmProvider: string;
    llmApiKey: string | null;
    llmModel: string;
    llmBaseUrl: string | null;
  };
}

export default function SettingsForm({ user }: SettingsFormProps) {
  const router = useRouter();
  const [name, setName] = useState(user.name || '');
  const [retentionTarget, setRetentionTarget] = useState((user.retentionTargetPreference * 100).toString());
  
  const [llmProvider, setLlmProvider] = useState(user.llmProvider || 'anthropic');
  const [llmApiKey, setLlmApiKey] = useState(user.llmApiKey || '');
  const [llmModel, setLlmModel] = useState(user.llmModel || 'claude-3-5-sonnet-20241022');
  const [llmBaseUrl, setLlmBaseUrl] = useState(user.llmBaseUrl || '');

  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');

    try {
      const res = await fetch('/api/user/settings', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name,
          retentionTargetPreference: parseFloat(retentionTarget) / 100,
          llmProvider,
          llmApiKey,
          llmModel,
          llmBaseUrl
        }),
      });

      if (res.ok) {
        setMessage('Settings updated successfully.');
        router.refresh();
      } else {
        setMessage('Failed to update settings.');
      }
    } catch (err) {
      setMessage('An error occurred.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form className="space-y-8 divide-y divide-zinc-200 dark:divide-zinc-800" onSubmit={handleSubmit}>
      <div className="space-y-6 sm:space-y-5">
        <div>
          <h3 className="text-base font-semibold leading-6">Profile Details</h3>
          <p className="max-w-2xl text-sm text-zinc-500 dark:text-zinc-400">
            This information will be displayed publicly so be careful what you share.
          </p>
        </div>
        <div className="space-y-6 sm:space-y-5">
          <div className="sm:grid sm:grid-cols-3 sm:items-start sm:gap-4 sm:py-6">
            <label htmlFor="email" className="block text-sm font-medium leading-6 sm:pt-1.5">
              Email address
            </label>
            <div className="mt-2 sm:col-span-2 sm:mt-0">
              <input
                type="email"
                id="email"
                value={user.email}
                disabled
                className="block w-full max-w-lg rounded-md border-0 py-1.5 px-3 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 sm:max-w-xs sm:text-sm sm:leading-6 disabled:bg-zinc-100 disabled:text-zinc-500 dark:bg-zinc-900 dark:text-zinc-100 dark:ring-zinc-700 dark:disabled:bg-zinc-800"
              />
            </div>
          </div>
          <div className="sm:grid sm:grid-cols-3 sm:items-start sm:gap-4 sm:py-6">
            <label htmlFor="name" className="block text-sm font-medium leading-6 sm:pt-1.5">
              Full Name
            </label>
            <div className="mt-2 sm:col-span-2 sm:mt-0">
              <input
                type="text"
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="block w-full max-w-lg rounded-md border-0 py-1.5 px-3 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:max-w-xs sm:text-sm sm:leading-6 dark:bg-zinc-900 dark:text-zinc-100 dark:ring-zinc-700"
              />
            </div>
          </div>
        </div>
      </div>

      <div className="space-y-6 pt-8 sm:space-y-5 sm:pt-10">
        <div>
          <h3 className="text-base font-semibold leading-6">Spaced Repetition Algorithm</h3>
          <p className="max-w-2xl text-sm text-zinc-500 dark:text-zinc-400">
            Tune the FSRS scheduler settings to your preference.
          </p>
        </div>
        <div className="space-y-6 sm:space-y-5">
          <div className="sm:grid sm:grid-cols-3 sm:items-start sm:gap-4 sm:py-6">
            <label htmlFor="retention" className="block text-sm font-medium leading-6 sm:pt-1.5">
              Target Retention (%)
            </label>
            <div className="mt-2 sm:col-span-2 sm:mt-0">
              <input
                type="number"
                id="retention"
                min="70"
                max="99"
                value={retentionTarget}
                onChange={(e) => setRetentionTarget(e.target.value)}
                className="block w-full max-w-lg rounded-md border-0 py-1.5 px-3 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:max-w-xs sm:text-sm sm:leading-6 dark:bg-zinc-900 dark:text-zinc-100 dark:ring-zinc-700"
              />
              <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
                A higher target will result in more frequent reviews. FSRS recommends 90%.
              </p>
            </div>
          </div>
        </div>
      <div className="space-y-6 pt-8 sm:space-y-5 sm:pt-10">
        <div>
          <h3 className="text-base font-semibold leading-6">AI Provider Settings</h3>
          <p className="max-w-2xl text-sm text-zinc-500 dark:text-zinc-400">
            Configure the LLM that powers the Flashcard Generator and AI Tutor.
          </p>
        </div>
        <div className="space-y-6 sm:space-y-5">
          <div className="sm:grid sm:grid-cols-3 sm:items-start sm:gap-4 sm:py-6">
            <label htmlFor="llmProvider" className="block text-sm font-medium leading-6 sm:pt-1.5">
              Provider
            </label>
            <div className="mt-2 sm:col-span-2 sm:mt-0">
              <select
                id="llmProvider"
                value={llmProvider}
                onChange={(e) => setLlmProvider(e.target.value)}
                className="block w-full max-w-lg rounded-md border-0 py-1.5 px-3 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:max-w-xs sm:text-sm sm:leading-6 dark:bg-zinc-900 dark:text-zinc-100 dark:ring-zinc-700"
              >
                <option value="anthropic">Anthropic (Claude)</option>
                <option value="openai">OpenAI (ChatGPT)</option>
                <option value="google">Google Gemini (AI Studio)</option>
                <option value="ollama">Ollama (Local)</option>
                <option value="nvidia">NVIDIA NIM</option>
              </select>
            </div>
          </div>

          <div className="sm:grid sm:grid-cols-3 sm:items-start sm:gap-4 sm:py-6">
            <label htmlFor="llmModel" className="block text-sm font-medium leading-6 sm:pt-1.5">
              Model ID
            </label>
            <div className="mt-2 sm:col-span-2 sm:mt-0">
              <input
                type="text"
                id="llmModel"
                value={llmModel}
                onChange={(e) => setLlmModel(e.target.value)}
                placeholder="e.g. gpt-4o, claude-3-5-sonnet-20241022"
                className="block w-full max-w-lg rounded-md border-0 py-1.5 px-3 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:max-w-xs sm:text-sm sm:leading-6 dark:bg-zinc-900 dark:text-zinc-100 dark:ring-zinc-700"
              />
            </div>
          </div>

          <div className="sm:grid sm:grid-cols-3 sm:items-start sm:gap-4 sm:py-6">
            <label htmlFor="llmApiKey" className="block text-sm font-medium leading-6 sm:pt-1.5">
              API Key
            </label>
            <div className="mt-2 sm:col-span-2 sm:mt-0">
              <input
                type="password"
                id="llmApiKey"
                value={llmApiKey}
                onChange={(e) => setLlmApiKey(e.target.value)}
                placeholder={llmProvider === 'ollama' ? 'Not required for local Ollama' : 'Enter API Key'}
                className="block w-full max-w-lg rounded-md border-0 py-1.5 px-3 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:max-w-xs sm:text-sm sm:leading-6 dark:bg-zinc-900 dark:text-zinc-100 dark:ring-zinc-700"
              />
            </div>
          </div>

          {(llmProvider === 'ollama' || llmProvider === 'nvidia') && (
            <div className="sm:grid sm:grid-cols-3 sm:items-start sm:gap-4 sm:py-6">
              <label htmlFor="llmBaseUrl" className="block text-sm font-medium leading-6 sm:pt-1.5">
                Base URL
              </label>
              <div className="mt-2 sm:col-span-2 sm:mt-0">
                <input
                  type="text"
                  id="llmBaseUrl"
                  value={llmBaseUrl}
                  onChange={(e) => setLlmBaseUrl(e.target.value)}
                  placeholder="e.g. http://localhost:11434/v1/chat/completions"
                  className="block w-full max-w-lg rounded-md border-0 py-1.5 px-3 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:max-w-xs sm:text-sm sm:leading-6 dark:bg-zinc-900 dark:text-zinc-100 dark:ring-zinc-700"
                />
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="pt-5">
        <div className="flex justify-end items-center gap-x-4">
          {message && <span className="text-sm font-medium text-blue-600 dark:text-blue-400">{message}</span>}
          <button
            type="submit"
            disabled={loading}
            className="inline-flex justify-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 disabled:opacity-70 disabled:cursor-not-allowed"
          >
            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Save Settings
          </button>
        </div>
      </div>
    </form>
  );
}
