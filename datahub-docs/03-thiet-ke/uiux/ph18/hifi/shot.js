// Chụp ảnh bản hi-fi UI-18 (D03-06-PH18). Chạy: python3 gen_hifi.py && node shot.js
// Khung 1440 rộng cho mọi ảnh, deviceScaleFactor 1, chụp cả trang khi cao hơn khung.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const W = {};
(async () => {
  const b = await chromium.launch();
  const names = fs.readdirSync(__dirname).filter(f => /^ui-18-.*\.html$/.test(f)).map(f => f.replace('.html', ''));
  for (const n of names) {
    const p = await b.newPage({ viewport: { width: W[n] || 1440, height: 900 }, deviceScaleFactor: 1 });
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png'), fullPage: true });
    await p.close();
  }
  await b.close();
})();
