// Chụp ảnh bản hi-fi PH-12 ở 1440×900. Chạy: node shot.js (cần playwright cài sẵn)
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
  for (const n of ['ui-12-01', 'ui-12-13']) {
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png') });
  }
  await b.close();
})();
