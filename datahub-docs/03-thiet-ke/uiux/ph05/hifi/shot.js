// Chụp ảnh bản hi-fi PH-05 ở 1440×900. Chạy: node shot.js
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
  for (const n of ['ui-05-01', 'ui-05-04']) {
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png') });
  }
  await b.close();
})();
