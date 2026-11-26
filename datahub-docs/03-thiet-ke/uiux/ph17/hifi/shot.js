// Chụp ảnh bản hi-fi UI-17 (D03-06-PH17). Chạy: python3 gen_hifi.py && node shot.js
// Khung 1440 rộng (ui-17-01b: 1024, ui-17-01c: 1000), deviceScaleFactor 1, chụp cả trang khi cao hơn khung.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const W = { 'ui-17-01b': 1024, 'ui-17-01c': 1000 };
(async () => {
  const b = await chromium.launch();
  const names = fs.readdirSync(__dirname).filter(f => /^ui-17-.*\.html$/.test(f)).map(f => f.replace('.html', ''));
  for (const n of names) {
    const p = await b.newPage({ viewport: { width: W[n] || 1440, height: 900 }, deviceScaleFactor: 1 });
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png'), fullPage: true });
    await p.close();
  }
  await b.close();
})();
