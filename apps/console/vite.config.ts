/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    include: ['src/**/*.test.ts', 'src/**/*.test.tsx'],
  },
  server: {
    host: '127.0.0.1',
    port: 5173,
    strictPort: true,
    proxy: {
      '/api': {
        target: process.env.VITE_PROXY_TARGET ?? 'http://localhost:8080',
        changeOrigin: true,
      },
      // Gọi thật (LIVE) từ màn chạy thử: /runtime/<hệ đích>/... → cổng runtime tương ứng.
      // Trình duyệt không gọi thẳng cổng runtime được vì CORS; đồng bộ danh sách với
      // RUNTIME_BASES ở src/flows/test/runtime.ts.
      '/runtime/camel-dancu': {
        target: 'http://localhost:8088',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/runtime\/camel-dancu/, ''),
      },
      '/runtime/camel-datdai': {
        target: 'http://localhost:8087',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/runtime\/camel-datdai/, ''),
      },
    },
  },
})
