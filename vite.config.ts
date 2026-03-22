import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import {defineConfig, loadEnv} from 'vite';

export default defineConfig(({mode}) => {
  const env = loadEnv(mode, '.', '');
  return {
    plugins: [react(), tailwindcss()],
    define: {
      'process.env.GEMINI_API_KEY': JSON.stringify(env.GEMINI_API_KEY),
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    server: {
      hmr: process.env.DISABLE_HMR !== 'true',
      proxy: {
        '/api/gold-futures': {
          target: 'https://query1.finance.yahoo.com',
          changeOrigin: true,
          rewrite: (p) => p.replace('/api/gold-futures', ''),
          headers: { 'User-Agent': 'Mozilla/5.0' },
        },
        '/api/fx': {
          target: 'https://open.er-api.com',
          changeOrigin: true,
          rewrite: (p) => p.replace('/api/fx', ''),
        },
        '/api/sjc': {
          target: 'https://sjc.com.vn',
          changeOrigin: true,
          rewrite: (p) => p.replace('/api/sjc', ''),
        },
        '/api/btmc': {
          target: 'https://btmc.vn',
          changeOrigin: true,
          rewrite: (p) => p.replace('/api/btmc', ''),
        },
      },
    },
  };
});
