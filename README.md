# Synapse Grid

Synapse Grid is a web-based flashcard and spaced-repetition study app designed to outperform traditional platforms. It features a real spaced-repetition algorithm (FSRS), a real AI study copilot, and data portability.

## Tech Stack
- Next.js (App Router), TypeScript, Tailwind CSS
- Prisma ORM (SQLite out of the box, compatible with PostgreSQL)
- NextAuth.js for Authentication
- ts-fsrs for scheduling
- Universal LLM Client (Supports Anthropic, OpenAI, Google Gemini, Ollama, NVIDIA NIM)

## Setup Instructions

### Option 1: One-Click GUI Installer (Windows Only)
For a seamless installation experience on Windows without touching the terminal:
1. Double click the **`Install_Synapse_Grid.bat`** file in the project folder.
2. The custom installer window will appear. It automatically checks for Node.js (and installs it if missing), sets up the dependencies, runs the database migrations, and launches the app directly in your browser.

### Option 2: Manual Installation (Mac / Linux / Advanced Users)

#### 1. Environment Variables
Create a `.env.local` file in the root of your project:

```env
# NextAuth configuration
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="generate-a-strong-secret-key-here"

# Note: AI Provider keys are NOT needed in the .env file!
# You can configure Anthropic, OpenAI, Gemini, or Ollama directly from the app's Settings UI.
```

#### 2. Install Dependencies
```bash
npm install
```

#### 3. Database Initialization
```bash
npx prisma db push
```

#### 4. Start the Server
```bash
npm run dev
```

Visit `http://localhost:3000` to start studying!

## Testing

The FSRS Scheduler engine is unit tested using Vitest. To run tests:

```bash
npm run test
```
