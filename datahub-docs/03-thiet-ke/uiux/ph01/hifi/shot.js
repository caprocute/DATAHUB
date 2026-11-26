// Chụp ảnh bản hi-fi PH-01 (UI-01-01…17). Chạy: node shot.js (cần playwright)
// Khung 1440×900, deviceScaleFactor 1, chụp cả trang nếu cao hơn.
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
  for (let i = 1; i <= 17; i++) {
    const n = `ui-01-${String(i).padStart(2, '0')}`;
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png'), fullPage: true });
  }
  await b.close();
})();
