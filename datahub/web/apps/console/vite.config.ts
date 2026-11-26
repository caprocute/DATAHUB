import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// Gọi API cùng gốc (/api/rdm/v1) như khi chạy sau APISIX; ở dev và e2e, proxy tới dh-data.
const apiTarget = process.env['DH_API_URL'] ?? 'http://localhost:8080';
const proxy = { '/api': { target: apiTarget, changeOrigin: false } };

export default defineConfig({
  plugins: [react()],
  server: { port: 5173, proxy },
  preview: { port: Number(process.env['DH_CONSOLE_PORT'] ?? 4173), strictPort: true, proxy },
  build: { sourcemap: false },
});
