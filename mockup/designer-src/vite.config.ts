import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { viteSingleFile } from 'vite-plugin-singlefile';

/**
 * Bản build gộp tất cả vào một tệp `index.html` duy nhất.
 *
 * Lý do: mockup được mở trực tiếp bằng `file://` chứ không qua máy chủ. Trình duyệt
 * chặn việc nạp module ES qua `file://` vì quy tắc cùng nguồn, nên mọi mã và biểu
 * định kiểu phải nằm sẵn trong HTML, không tách ra tệp rời.
 */
export default defineConfig({
  plugins: [react(), viteSingleFile()],
  base: './',
  // `css/app.css` nằm ngoài thư mục dự án — nó là hệ thiết kế dùng chung của mockup
  // và phải giữ một bản duy nhất, nên cho phép đọc ngược lên thư mục mockup.
  server: { fs: { allow: ['../..'] } },
  build: {
    outDir: '../pages/designer',
    emptyOutDir: true,
    cssCodeSplit: false,
    assetsInlineLimit: Number.MAX_SAFE_INTEGER,
    chunkSizeWarningLimit: 8000,
  },
});
