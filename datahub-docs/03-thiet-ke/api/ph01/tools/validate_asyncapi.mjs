// Kiểm AsyncAPI 3.0 của PH-01 bằng @asyncapi/parser 3. Chạy: node tools/validate_asyncapi.mjs asyncapi-onboarding.yaml
// Cần: npm i @asyncapi/parser@3. Thoát mã 1 khi có lỗi hoặc cảnh báo (severity 0, 1); gợi ý nâng phiên bản (severity 2) bỏ qua.
import { Parser } from '@asyncapi/parser';
import fs from 'fs';
const { document, diagnostics } = await new Parser().parse(fs.readFileSync(process.argv[2], 'utf8'));
const bad = diagnostics.filter((d) => d.severity <= 1);
for (const d of diagnostics) console.log(d.severity, d.code, d.message, (d.path || []).join('.'));
console.log(`kênh: ${document ? document.channels().length : 0}, operation: ${document ? document.operations().length : 0}, lỗi hoặc cảnh báo: ${bad.length}`);
process.exit(bad.length ? 1 : 0);
