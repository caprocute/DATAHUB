// Chụp ảnh bản hi-fi UI-12-01…19 (D03-06-PH12). Chạy: node shot.js
// Khung 1440×900, deviceScaleFactor 1, chụp cả trang nếu cao hơn.
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  for (let i = 1; i <= 19; i++) {
    const n = `ui-12-${String(i).padStart(2, '0')}`;
    const p = await b.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png'), fullPage: true });
    await p.close();
  }
  await b.close();
})();
