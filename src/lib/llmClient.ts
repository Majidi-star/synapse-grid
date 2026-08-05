export interface LLMConfig {
  provider: string; // 'anthropic', 'openai', 'google', 'ollama', 'custom'
  apiKey?: string;
  model: string;
  baseUrl?: string;
}

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export async function generateCompletion(
  messages: ChatMessage[],
  config: LLMConfig
): Promise<string> {
  const { provider, apiKey, model, baseUrl } = config;

  if (provider === 'anthropic') {
    // Anthropic API format
    // Requires x-api-key, anthropic-version
    // Messages must not include system in the array, system is a top-level param.
    const systemMessage = messages.find(m => m.role === 'system')?.content || '';
    const userMessages = messages.filter(m => m.role !== 'system');

    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey || '',
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: model || 'claude-3-5-sonnet-20241022',
        max_tokens: 2000,
        temperature: 0.2,
        system: systemMessage,
        messages: userMessages.map(m => ({ role: m.role, content: m.content }))
      })
    });

    if (!res.ok) {
      const errorText = await res.text();
      throw new Error(`Anthropic Error: ${res.status} ${errorText}`);
    }

    const data = await res.json();
    return data.content[0].text;
  }

  if (provider === 'google') {
    // Google Gemini API format
    // URL: https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}
    const systemMessage = messages.find(m => m.role === 'system')?.content;
    const userMessages = messages.filter(m => m.role !== 'system');

    const googleMessages = userMessages.map(m => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }]
    }));

    const reqBody: any = {
      contents: googleMessages,
      generationConfig: {
        temperature: 0.2,
      }
    };

    if (systemMessage) {
      reqBody.systemInstruction = {
        parts: [{ text: systemMessage }]
      };
    }

    const actualModel = model || 'gemini-1.5-flash';
    const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${actualModel}:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(reqBody)
    });

    if (!res.ok) {
      const errorText = await res.text();
      throw new Error(`Google GenAI Error: ${res.status} ${errorText}`);
    }

    const data = await res.json();
    return data.candidates[0].content.parts[0].text;
  }

  // Fallback to OpenAI-compatible API format (OpenAI, Ollama, NVIDIA NIM, Groq, etc.)
  // URL is usually https://api.openai.com/v1/chat/completions or custom
  let url = baseUrl;
  if (!url) {
    if (provider === 'openai') url = 'https://api.openai.com/v1/chat/completions';
    else if (provider === 'ollama') url = 'http://localhost:11434/v1/chat/completions';
    else if (provider === 'nvidia') url = 'https://integrate.api.nvidia.com/v1/chat/completions';
    else url = 'https://api.openai.com/v1/chat/completions'; // Default fallback
  }

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (apiKey) {
    headers['Authorization'] = `Bearer ${apiKey}`;
  }

  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      model: model || 'gpt-4o-mini',
      messages: messages,
      temperature: 0.2,
    })
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`OpenAI-compatible API Error: ${res.status} ${errorText}`);
  }

  const data = await res.json();
  return data.choices[0].message.content;
}
