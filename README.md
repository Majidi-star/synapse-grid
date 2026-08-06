# Synapse Grid

Synapse Grid is a web-based flashcard and spaced-repetition study app designed to outperform traditional platforms. It features a real spaced-repetition algorithm (FSRS), a real AI study copilot, and data portability.

## Tech Stack
- Next.js (App Router), TypeScript, Tailwind CSS
- Prisma ORM (SQLite out of the box, compatible with PostgreSQL)
- NextAuth.js for Authentication
- ts-fsrs for scheduling
- Universal LLM Client (Supports Anthropic, OpenAI, Google Gemini, Ollama, NVIDIA NIM)

## Distribution & Deployment (Portable Desktop App)

Synapse Grid is compiled as a fully self-contained portable desktop application. End-users do not need to install Node.js, run `npm install`, or have an internet connection to load dependencies.

### For End-Users: Running the Application
1. Extract the packaged zip file (e.g. `Synapse_Grid.zip`) onto your computer.
2. Double-click the **`Launch_Synapse_Grid.bat`** file inside the folder.
3. The server will boot locally and automatically open the application in your web browser at `http://localhost:3000`.

---

### For Developers: Building & Packaging the App
If you make changes to the source code and want to compile a new portable desktop bundle:

1. **Prerequisites**: Ensure you have Node.js installed on your development machine.
2. **Install Dependencies**: Run `npm install` once in the project root.
3. **Compile and Package**: Run the following command:
   ```bash
   npm run build:desktop
   ```
4. **Distribution**: This will compile the app and copy all required static assets, the SQLite database schema, and your local `node.exe` engine into a new `dist/` folder. Zip up the `dist/` folder and distribute it to any clean Windows machine!


## Testing

The FSRS Scheduler engine is unit tested using Vitest. To run tests:

```bash
npm run test
```
