// Chụp ảnh bản hi-fi ở 1440×900 (D03-06-PH07 §24.1). Chạy: node shot.js
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
  for (let i = 1; i <= 12; i++) {
    const n = `ui-07-${String(i).padStart(2, '0')}`;
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png') });
  }
  await b.close();
})();
