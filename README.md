# Synapse Grid

Synapse Grid is a web-based flashcard and spaced-repetition study app designed to outperform traditional platforms. It features a real spaced-repetition algorithm (FSRS), a real AI study copilot, and data portability.

## Tech Stack
- Next.js (App Router), TypeScript, Tailwind CSS
- PostgreSQL via Prisma ORM
- NextAuth.js
- ts-fsrs for scheduling
- Anthropic Claude API for AI generation and chat

## Setup Instructions

### 1. Environment Variables

Create a `.env.local` file in the root of your project based on the `.env.example` format:

```env
# Database connection string (PostgreSQL recommended, but SQLite compatible)
DATABASE_URL="postgresql://user:password@localhost:5432/recallos"

# NextAuth configuration
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="generate-a-strong-secret-key-here"

# Google OAuth (Optional)
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"

# Anthropic API Key (Required for AI features)
ANTHROPIC_API_KEY="sk-ant-api03-..."
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Database Migrations

Run Prisma migrations to set up your database schema:

```bash
npx prisma migrate dev --name init
```

### 4. Seed Test Data

If you'd like to seed the database with mock decks and cards:

```bash
npx prisma db seed
```

*(Ensure you have configured `prisma.seed` in `package.json` to run your seed script, e.g., `ts-node prisma/seed.ts`)*

### 5. Start the Development Server

```bash
npm run dev
```

Visit `http://localhost:3000` to start studying.

## Testing

The FSRS Scheduler engine is unit tested using Vitest. To run tests:

```bash
npm run test
```
