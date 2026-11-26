// Chụp ảnh bản hi-fi UI-19-01…28 (D03-06-PH19). Chạy: node shot.js
// Màn quản trị: khung 1440×900, deviceScaleFactor 1 (chụp cả trang nếu cao hơn).
// UI-19-28 (trang người nộp trên điện thoại): 360×740, deviceScaleFactor 2.
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  for (let i = 1; i <= 28; i++) {
    const n = `ui-19-${String(i).padStart(2, '0')}`;
    const mobile = i === 28;
    const p = await b.newPage({ viewport: mobile ? { width: 360, height: 740 } : { width: 1440, height: 900 }, deviceScaleFactor: mobile ? 2 : 1 });
    await p.goto('file://' + path.join(__dirname, n + '.html'));
    await p.screenshot({ path: path.join(__dirname, n + '.png'), fullPage: !mobile });
    await p.close();
  }
  await b.close();
})();
