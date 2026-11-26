// Chụp ảnh bản hi-fi UI-15-01…28 (D03-06-PH15). Chạy: python3 gen_hifi.py && node shot.js
// Màn rộng: 1440 px, deviceScaleFactor 1, chụp cả trang. Màn 360 px (D05-01): UI-15-01, 04, 06, 08, 12, 13.
const { chromium } = require('playwright');
const path = require('path');
const MOBILE = ['01', '04', '06', '08', '12', '13'];
(async () => {
  const b = await chromium.launch();
  for (let i = 1; i <= 28; i++) {
    const n = String(i).padStart(2, '0');
    const sizes = [[1440, 900, '']].concat(MOBILE.includes(n) ? [[360, 740, '-360']] : []);
    for (const [w, h, suf] of sizes) {
      const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
      await p.goto('file://' + path.join(__dirname, `ui-15-${n}.html`));
      await p.screenshot({ path: path.join(__dirname, `ui-15-${n}${suf}.png`), fullPage: true });
      await p.close();
    }
  }
  await b.close();
})();
