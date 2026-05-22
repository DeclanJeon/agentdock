import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  // Tauri serves built assets from its app protocol, not from an HTTP root.
  // Relative asset paths prevent a blank native release window caused by /assets/* URLs.
  base: './',
  plugins: [react()],
  clearScreen: false,
  server: {
    host: '127.0.0.1',
    port: 1420,
    strictPort: true,
    watch: {
      ignored: ['**/.agent-work/**', '**/.agentdock/**'],
    },
  },
  envPrefix: ['VITE_', 'TAURI_'],
  publicDir: 'assets',
  build: {
    target: process.env.TAURI_PLATFORM === 'windows' ? 'chrome105' : 'safari13',
    minify: !process.env.TAURI_DEBUG,
    sourcemap: Boolean(process.env.TAURI_DEBUG),
  },
});
