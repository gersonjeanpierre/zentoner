import { defineConfig } from 'vite';
import angular from '@analogjs/vite-plugin-angular';

export default defineConfig({
  plugins: [angular()],
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  server: {
    port: 4200,
    open: true,
  },
  define: {
    'process.env': process.env
  }
});
