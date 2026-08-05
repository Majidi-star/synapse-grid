# Project Rules & Guidelines: Recall OS

## Code Style & Conventions
- **TypeScript:** Use strict types. Avoid `any`. Define interfaces for all models and API request/response bodies.
- **Next.js:** App Router conventions (server component by default, `'use client'` only when necessary).
- **Prisma:** Always run migrations and keep the database schema generic (avoid Postgres-only extensions/features).
- **CSS:** Use Tailwind CSS utility classes and ensure clean layout design.

## Recommended File Navigation Flow
- **Backend Changes:**
  - Read [SchedulerService](file:///c:/Projects/synapse-grid/src/services/scheduler.ts) or Prisma schema first.
  - Check service tests under `src/services/__tests__/`.
- **Frontend Changes:**
  - Start from app routes under `src/app/`.
  - Check shared components in `src/components/`.

## Grepping Guidelines
- Before opening any file, use `grep_search` to find usages of key classes or components (e.g., `SchedulerService`, `prisma`, `Card`).
- Avoid reading full config files (e.g., `config.json`, `.env`); instead grep for specific keys.

## Common Pitfalls
- **FSRS Scheduling:** Never let FSRS dates or logs become black-boxed; log scheduling outputs.
- **AI Injection:** Do not auto-add AI generated cards directly to decks; always queue them for review.
- **Data Export:** Ensure the Prisma schema enables serialization of the entire user graph in a single query.
