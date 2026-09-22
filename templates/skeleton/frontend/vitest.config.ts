import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  // The automatic JSX runtime, so test files need no React import.
  esbuild: { jsx: 'automatic' },
  test: {
    // jsdom for component tests; the pure modules run fine in it too.
    environment: 'jsdom',
    globals: false,
    setupFiles: ['./tests/setup.ts'],
    include: ['tests/**/*.test.ts', 'tests/**/*.test.tsx'],
  },
});
