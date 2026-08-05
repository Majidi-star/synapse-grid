# Synapse Grid — Web App Build Prompt (for Antigravity)

Copy everything below the line into Antigravity as your project prompt.

---

## Project Brief

Build **Synapse Grid**, a web-based flashcard and spaced-repetition study app designed to outperform Quizlet, Anki, Brainscape, and RemNote. This is a **web-first MVP** — architect it cleanly so mobile and desktop clients can be added later without a rewrite, but do not build native mobile/desktop now.

**Positioning:** "The only flashcard app with a real spaced-repetition algorithm, a real AI study copilot, and none of your data locked in." Fast, clean, unshowy — a serious tool, not a gamified toy. The reward is the retention curve going up, not badges or streak-shaming.

**Explicitly not this app:** a generic note-taking/PKM tool (no freeform graph views, no infinite wikis), an engagement-farming quiz game, or a subscription trap that locks up the user's own data.

---

## Tech Stack

- **Framework:** Next.js (App Router), TypeScript throughout
- **Styling:** Tailwind CSS
- **Database:** PostgreSQL via Prisma ORM (design the schema to also work with SQLite later for a local-first desktop version — avoid Postgres-only features in the schema)
- **Auth:** NextAuth.js (email/password + Google OAuth at minimum)
- **Spaced repetition engine:** use the `ts-fsrs` npm package (an open-source TypeScript implementation of FSRS) rather than hand-rolling the algorithm. Wrap it behind a clean internal `SchedulerService` so the underlying algorithm library can be swapped later without touching the rest of the app.
- **AI integration:** Anthropic API (Claude) for card generation and the tutor chat. Use a server-side API layer — never call the LLM directly from the client. Structure prompts so the model can be swapped later (OpenAI, local Ollama) without rewriting call sites.
- **File/PDF parsing:** support PDF and plain text upload for AI card generation in this MVP (image/OCR and YouTube transcript support can come later — build the generation pipeline so new source types are pluggable).
- **State management:** React Server Components + minimal client state (Zustand or React Context) — avoid over-engineering with heavy client state libraries.
- **Testing:** Vitest for unit tests on the scheduler and card-generation logic at minimum — this logic must be correct and covered.

---

## Data Model (implement as Prisma schema)

- **User** — id, email, auth fields, createdAt, retentionTargetPreference (default 0.9)
- **Deck** — id, userId, name, description, parentDeckId (nullable, for nested decks), tags[], createdAt
- **Card** — id, deckId, type (basic | cloze | image_occlusion | multiple_choice | typed_answer), front, back, extraFields (JSON, for cloze text, occlusion regions, MC options, etc.), sourceRef (nullable — where this card came from, e.g. "AI-generated from lecture3.pdf p.4"), createdAt, updatedAt
- **ReviewLog** — id, cardId, userId, reviewedAt, rating (again | hard | good | easy), scheduledDays, elapsedDays, state (new | learning | review | relearning) — this is the raw event log FSRS needs to compute stability/difficulty
- **CardScheduleState** — id, cardId, due, stability, difficulty, elapsedDays, scheduledDays, reps, lapses, state, lastReview — the current FSRS scheduling state per card, derived from ReviewLog but cached for fast due-queue queries
- **AIGenerationJob** — id, userId, sourceType (pdf | text), sourceRef, status, generatedCardIds[], createdAt — tracks AI generation runs so users can review/accept/reject before cards enter rotation

Design the schema so a full data export (all of the above, for one user) can be serialized to clean JSON in one query — this backs the "open export" commitment.

---

## Core Features to Build (MVP scope — build in this order)

### 1. Auth & account
Sign up, log in, basic account settings including retention target preference.

### 2. Deck & card management
- Create/edit/delete decks, including nested subdecks
- Card editor supporting: basic front/back, cloze deletion, and image occlusion at minimum
- Rich text in cards (bold/italic/code blocks; LaTeX rendering is a stretch goal, don't block MVP on it)
- Tagging and full-text search across all of a user's cards/decks
- Bulk operations: move cards between decks, bulk tag, bulk delete

### 3. FSRS scheduling engine
- Wrap `ts-fsrs` in a `SchedulerService` with a clean interface: `getDueCards(userId)`, `recordReview(cardId, rating)`, `getForecast(userId, days)`
- Every card must show its real next-due date — no hidden/black-box scheduling
- Support burying siblings (don't show near-duplicate cards from the same generation batch back-to-back in one session)
- User-adjustable target retention rate in settings (default 90%), with a plain-language explanation of the tradeoff shown in the UI

### 4. Review session UI
- A due-card queue: pull cards due today, present one at a time, capture Again/Hard/Good/Easy rating, call `recordReview`
- Keyboard shortcuts for rating (1–4) as the primary interaction — this is a web app for power users, not a mobile swipe-first experience
- Session summary at the end: cards reviewed, accuracy, next cards due
- A "Custom Study" mode: cram mode (ignore scheduling, drill everything), filtered study (e.g., only cards missed this week)

### 5. Stats dashboard
- Retention curve over time
- Forecast of upcoming reviews (next 7/30 days)
- Heatmap of daily study activity
- Per-deck breakdown of due/new/mature card counts

### 6. AI card generation
- Upload a PDF or paste text → generate a batch of proposed cards via the Claude API
- Generated cards land in a **review queue**, not directly into the live deck — user must accept/edit/reject each one before it enters FSRS scheduling. This is a hard product requirement, not optional: never auto-inject AI content into rotation unsupervised.
- Auto-suggest card type per concept (cloze for lists/facts, basic Q&A for definitions)
- Basic duplicate detection against the user's existing cards in that deck before showing the review queue

### 7. AI tutor chat
- A chat interface scoped to one deck at a time
- The system prompt must inject: the deck's card contents, and the user's recent review performance on that deck (e.g., cards recently rated "Again") — the tutor must reference real specifics, not generic encouragement
- Support at minimum: explain a concept differently, generate an example/mnemonic on request, quiz the user conversationally

### 8. Import/export
- Export: full user data as JSON (schema above), and cards as CSV
- Import: Anki `.apkg` file parsing into Decks/Cards (this is a meaningful parsing task — treat it as its own subsystem; if full `.apkg` fidelity is too large for MVP, ship CSV import first and flag `.apkg` import as fast-follow)

---

## Explicitly Out of Scope for This Build

Do not implement any of the following in this pass — flag them as future work if the agent is tempted to add them:
- Native mobile or desktop apps (Electron/Tauri) — web only
- MCP tool integrations (Drive/Notion/GitHub ingestion) — later phase
- Collaboration/shared decks, public deck library, classroom tools
- Gamification (streaks, leaderboards, badges) beyond the honest stats dashboard above
- Voice mode
- Social features of any kind

---

## UX / Design Direction

- Clean, fast, information-dense but not cluttered — think "well-built professional tool," not "colorful edtech app for kids"
- Dark mode as a first-class option, not an afterthought
- The review session screen should be nearly chrome-free — the card is the entire focus, keyboard shortcuts visible but unobtrusive
- The due-queue / "what do I need to review today" view is the default landing page after login — not a dashboard of widgets, not a marketing-style home screen
- Loading and empty states matter: never show a blank screen during AI generation — show real progress (e.g., "Extracting text from PDF... Generating 12 cards... Checking for duplicates...")

---

## Build Instructions for Antigravity

1. Scaffold the Next.js + TypeScript + Tailwind + Prisma project structure first, with the full schema above migrated.
2. Build the `SchedulerService` and its unit tests before building any UI on top of it — this is the core correctness-critical piece.
3. Build deck/card CRUD and the review session UI next, so there's an end-to-end usable flashcard app (create cards → review them → see them rescheduled) before adding AI features.
4. Add AI generation and the tutor chat last, once the core loop works without them.
5. At each stage, prefer server actions / route handlers over ad-hoc client-side fetches, and keep the LLM API key server-side only.
6. Write a short README documenting how to run migrations, seed test data, and set required environment variables (DATABASE_URL, ANTHROPIC_API_KEY, NEXTAUTH_SECRET, etc.).
