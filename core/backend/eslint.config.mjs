import eslint from "@eslint/js";
import tseslint from "@typescript-eslint/eslint-plugin";
import tsparser from "@typescript-eslint/parser";
import globals from "globals";

export default [
  {
    ignores: ["**/dist/**", "**/node_modules/**", "**/coverage/**"],
  },
  eslint.configs.recommended,
  {
    files: ["**/*.ts"],
    languageOptions: {
      parser: tsparser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: "module",
      },
      globals: {
        ...globals.node,
        ...globals.jest,
        NodeJS: "readonly",
        Express: "readonly",
      },
    },
    plugins: {
      "@typescript-eslint": tseslint,
    },
    rules: {
      "@typescript-eslint/explicit-function-return-type": "off",
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-unused-vars": ["error", {
        argsIgnorePattern: "^_",
        varsIgnorePattern: "^_",
        caughtErrorsIgnorePattern: "^_",
      }],
      "@typescript-eslint/no-unused-expressions": "error",
      "no-console": ["warn", { allow: ["warn", "error"] }],
      "no-unreachable": "error",
      "no-unused-labels": "error",
      "no-unused-vars": "off",
    },
  },
  // Overrides - must come after general rules
  {
    // Allow console.log in seed scripts and logger/email utilities
    files: ["**/prisma/**/*.ts", "**/lib/logger.ts", "**/services/email.service.ts"],
    rules: {
      "no-console": "off",
    },
  },
  {
    // Allow var in global type declarations
    files: ["**/lib/db.ts"],
    rules: {
      "no-var": "off",
    },
  },
];
