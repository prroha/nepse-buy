/**
 * Lint-Staged Configuration
 * Runs linters on staged files before commit
 */

export default {
  // ==========================================================================
  // Backend (Express + TypeScript)
  // ==========================================================================
  "core/backend/**/*.{ts,tsx}": [
    "eslint --config core/backend/eslint.config.mjs --fix --max-warnings=0",
  ],
  "core/backend/**/*.{json,md}": [
    "prettier --write",
  ],

  // ==========================================================================
  // Web (Next.js + TypeScript)
  // ==========================================================================
  "core/web/**/*.{ts,tsx,js,jsx}": [
    "eslint --config core/web/eslint.config.mjs --fix --max-warnings=0",
  ],
  "core/web/**/*.{json,md,css,scss}": [
    "prettier --write",
  ],

  // ==========================================================================
  // Mobile (Flutter/Dart)
  // ==========================================================================
  "core/mobile/**/*.dart": (filenames) => [
    `dart format ${filenames.join(" ")}`,
    `dart analyze ${filenames.map(f => f.replace(/\/[^/]+$/, "")).filter((v, i, a) => a.indexOf(v) === i).join(" ")} || true`,
  ],

  // ==========================================================================
  // Root level files
  // ==========================================================================
  "*.{json,md,yml,yaml}": [
    "prettier --write",
  ],

  // ==========================================================================
  // Prisma Schema
  // ==========================================================================
  "core/backend/prisma/schema.prisma": (filenames) =>
    filenames.map((f) => `npx prisma format --schema=${f}`),
};
