// Chụp ảnh bản hi-fi UI-02-01…17 (D03-06-PH02). Chạy: node shot.js
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  for (let i = 1; i <= 17; i++) {
    const n = `ui-02-${String(i).padStart(2, '0')}`;
    const mobile = false;
    const p = await b.newPage({ viewport: mobile ? { width: 360, height: 740 } : { width: 1440, height: 900 }, deviceScaleFactor: mobile ? 2 : 1 });
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png'), fullPage: !mobile });
    await p.close();
  }
  await b.close();
})();
