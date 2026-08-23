document.addEventListener('DOMContentLoaded', async () => {
  const deckSelect = document.getElementById('deck-select');
  const clipText = document.getElementById('clip-text');
  const clipBtn = document.getElementById('clip-btn');
  const statusMsg = document.getElementById('status-msg');

  function showStatus(text, isError = false) {
    statusMsg.innerText = text;
    statusMsg.style.display = 'block';
    statusMsg.className = 'status ' + (isError ? 'error' : 'success');
  }

  // 1. Fetch decks from local HTTP server
  try {
    const response = await fetch('http://localhost:57849/decks');
    if (!response.ok) throw new Error();
    const decks = await response.json();
    
    deckSelect.innerHTML = '';
    if (decks.length === 0) {
      deckSelect.innerHTML = '<option value="">No decks found</option>';
    } else {
      decks.forEach(d => {
        const opt = document.createElement('option');
        opt.value = d.id;
        opt.textContent = d.name;
        deckSelect.appendChild(opt);
      });
      clipBtn.disabled = false;
    }
  } catch (err) {
    deckSelect.innerHTML = '<option value="">Recall OS app not running</option>';
    showStatus('Could not connect to Synap desktop app. Make sure the application is open.', true);
  }

  // 2. Get selected text from active tab
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    const activeTab = tabs[0];
    if (!activeTab) return;
    
    chrome.scripting.executeScript({
      target: { tabId: activeTab.id },
      func: () => window.getSelection().toString()
    }, (results) => {
      if (results && results[0] && results[0].result) {
        clipText.value = results[0].result;
      }
    });
  });

  // 3. Send clip payload to localhost
  clipBtn.addEventListener('click', async () => {
    const selectedDeck = deckSelect.value;
    const textContent = clipText.value.trim();

    if (!selectedDeck) {
      showStatus('Please select a target deck.', true);
      return;
    }
    if (!textContent) {
      showStatus('Please select or enter some text context.', true);
      return;
    }

    clipBtn.disabled = true;
    showStatus('Processing with AI...');

    chrome.tabs.query({ active: true, currentWindow: true }, async (tabs) => {
      const activeTab = tabs[0] || {};
      
      try {
        const response = await fetch('http://localhost:57849/clip', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            selectedText: textContent,
            deckId: selectedDeck,
            url: activeTab.url || '',
            title: activeTab.title || ''
          })
        });

        if (!response.ok) {
          const errMsg = await response.text();
          throw new Error(errMsg || 'Server returned an error.');
        }

        const res = await response.json();
        showStatus(res.message || 'Clipped successfully!');
        setTimeout(() => window.close(), 1500);
      } catch (err) {
        showStatus('Error: ' + err.message, true);
        clipBtn.disabled = false;
      }
    });
  });
});
