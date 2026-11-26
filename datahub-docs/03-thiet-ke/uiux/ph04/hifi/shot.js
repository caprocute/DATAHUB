// Chụp ảnh bản hi-fi PH-04 ở 1440×900, deviceScaleFactor 1. Chạy: node shot.js
// Sau khi chụp, nén ảnh về bảng màu 256 màu bằng: python3 nen_png.py (giữ tổng dung lượng ≤ 10 MB).
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
  for (let i = 1; i <= 21; i++) {
    const n = 'ui-04-' + String(i).padStart(2, '0');
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png') });
  }
  await b.close();
})();
