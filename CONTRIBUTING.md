# Contributing to Synapse Grid

Thank you for your interest in contributing to Synapse Grid! This document outlines the guidelines and practices we use to build a world-class, spaced-repetition application.

---

## Code Quality Standards

Before writing code, make sure you understand the following guardrails:
1. **Type Safety:** Always use TypeScript strict mode. Avoid the use of `any` types.
2. **Formatting & Linting:** Code formatting is managed by Prettier and linting by ESLint. These are enforced before committing.
3. **Spaced Repetition correctness:** Any change impacting the scheduling algorithm MUST be covered by unit tests in the scheduler.

---

## Git Workflow & Conventional Commits

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for all commit messages. This helps automate release versioning and changelogs.

Format:
`type(scope): description`

Common types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation updates (README, CONTRIBUTING, inline docs)
- `style`: Code style changes (formatting, spacing, tailwind styling)
- `refactor`: Restructuring code without changing functionality
- `test`: Adding or updating tests
- `chore`: Updating build tasks, package manager configs, etc.

Commit messages are validated using `commitlint` via a git hook. If your commit message does not match the specification, the commit will be rejected.

---

## Local Development Setup

1. **Install Dependencies:**
   ```bash
   npm install
   ```
   *Husky hooks are initialized automatically during dependency installation.*

2. **Configure Environment Variables:**
   Create a `.env.local` file based on `.env.example` configurations.

3. **Prisma Setup:**
   Run the initial migration:
   ```bash
   npx prisma migrate dev
   ```
   Seed the database with default decks and cards:
   ```bash
   npx prisma db seed
   ```

4. **Run Development Server:**
   ```bash
   npm run dev
   ```

---

## Code Checking & Validation

### Formatting and Linting
Our pre-commit hooks will automatically check modified files. You can run formatting and linting manually using:
```bash
npm run lint
npm run format
```

### Running Unit Tests
We use Vitest for unit and integration verification:
```bash
npm run test
```

### Running E2E Web Tests
We use Playwright to simulate full user journeys:
```bash
npx playwright test
```
