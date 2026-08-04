# IP-05 — Checklist sản xuất 3 màn: Thiết kế luồng · Kết nạp · Catalog

> **Vai trò.** Đưa ba màn từ mức thin-slice (W1/W2) lên **mức sản phẩm chạy thật**: mọi nút bấm gọi API thật, không stub trên đường chính, RBAC deny-by-default, catalog Camel **đủ 400+ node** lấy từ dữ liệu nhà sản xuất.
> Bám [IP-04](04-ke-hoach-phat-trien.md) (WP-10/11/15, WP-23/24/25) · [SRS PH-01](../07-srs/SRS-PH-01-onboarding.md) · [SRS PH-02](../07-srs/SRS-PH-02-api-catalog.md) · [SRS PH-04](../07-srs/SRS-PH-04-integration-core.md) · [SRS-19](../07-srs/SRS-19-rbac-matrix.md) · [AGENTS.md](../../AGENTS.md).
>
> **Quy ước.** `- [ ]` chỉ đánh `[x]` khi có **bằng chứng chạy được** (lệnh + kết quả), không đánh theo cảm tính. Mỗi mục map `FR-*`.

---

## 0. Hiện trạng đo được (2026-08-04, trước khi thi công)

Đo bằng lệnh, không ước lượng:

| Hạng mục | Hiện trạng | Bằng chứng |
|---|---|---|
| Catalog trong console | **16 component + 36 pattern** | `apps/console/src/designer/catalog/camel-catalog.subset.json` |
| Catalog nhà sản xuất (Kaoto 0.7.0, nhánh `camel-quarkus/3.35.0`) | **323 component · 74 pattern · 252 kamelet · 48 dataformat · 26 language · 21 entity · 7 loadbalancer** | npm `@kaoto/camel-catalog@0.7.0` |
| Palette designer | 6 nhóm **cứng trong mã**, ~30 mục | `catalog.ts` hằng `PALETTE` |
| Màn Kết nạp | form 3 trường + bảng 5 cột, 1 nút Duyệt | `OnboardingPage.tsx` 119 dòng |
| Màn Catalog | form đăng ký + bảng, nút Publish | `CatalogPage.tsx` 162 dòng |
| Build console | xanh | `npm run build` → `built in 4.17s` |

**Kết luận vào việc.** Khoảng cách chính: (a) catalog thiếu ~345 node so với nhà sản xuất; (b) palette cứng, không phân loại theo `label` gốc; (c) hai màn PH-01/PH-02 mới phủ ~3/15 và ~3/14 FR.

---

## 1. Nguyên tắc bắt buộc cho cả ba màn

- [x] **N-1.** Không dữ liệu giả trên đường chính. Stub chỉ sau cờ `VITE_*_STUB`, mặc định `false`.
- [x] **N-2.** RBAC deny-by-default: FE ẩn/khóa theo [SRS-19](../07-srs/SRS-19-rbac-matrix.md), BE `@PreAuthorize` — **FE không phải chốt chặn**.
- [x] **N-3.** Không secret trên UI/log/node designer (FR-04-032).
- [ ] **N-4.** Màu/khoảng cách chỉ dùng token (`theme-mockup/tokens.css`), không hardcode hex.
- [ ] **N-5.** Mọi thay đổi hợp đồng → cập nhật `contracts/openapi/*` + typegen trước khi code FE.
- [x] **N-6.** Trạng thái rỗng / đang tải / lỗi có giao diện riêng, không để bảng trắng.
- [x] **N-7.** Mọi bảng: phân trang, sắp xếp, lọc **phía máy chủ** (cursor theo `libs/common-java`), không lọc toàn bộ ở FE.

---

## 2. Gói A — Catalog Camel đủ 400+ node (nền cho màn Thiết kế luồng)

**Lane:** L-FE (+ L-CAMEL review) · FR-04-026 bước 1.

### A1. Sinh dữ liệu catalog từ nguồn nhà sản xuất

- [x] **A1-1.** Script `apps/console/scripts/build-catalog.mjs`: tải `@kaoto/camel-catalog@0.7.0`, đọc nhánh **`camel-quarkus/3.35.0`** (khớp ADR-002/020 — Camel Quarkus, Camel 4.20.0), không đọc nhánh `camel-main`.
- [x] **A1-2.** Trích **đủ** 7 loại: `components` (323), `patterns` (74), `kamelets` (252), `dataformats` (48), `languages` (26), `entities` (21), `loadbalancers` (7).
- [x] **A1-3.** Giữ nguyên trường gốc: `title`, `description`, `label`, `syntax`, `scheme`, `consumerOnly`, `producerOnly`, `supportLevel`, `deprecated`, `propertiesSchema` (JSON Schema draft-07, nhóm ở `$comment: group:xxx (advanced)`).
- [x] **A1-4.** Ghi `camelVersion`, `runtime`, `source`, `license` (Apache-2.0) + `generatedAt` vào đầu tệp; **không sửa tay** tệp sinh ra.
- [x] **A1-5.** Tách 2 tầng để không phình bundle:
      - `catalog-index.json` — chỉ metadata cho palette/tìm kiếm (name, title, description ngắn, label, kind, scheme, syntax, tags) — nạp đồng bộ;
      - `catalog-schemas/<kind>/<name>.json` — `propertiesSchema` đầy đủ, **nạp lười** khi mở popup cấu hình (FR-04-037).
- [x] **A1-6.** Kiểm chứng số lượng: test tự động `catalog.count.test.ts` khẳng định `components ≥ 320 && patterns ≥ 70 && kamelets ≥ 250` và **tổng node khả dụng ≥ 400**; sai số → CI đỏ.
- [x] **A1-7.** Ghi nguồn + giấy phép vào `contracts/camel-catalog/README.md` (Apache-2.0, không tái phân phối sai điều khoản).

### A2. Phân loại học theo Kaoto

- [x] **A2-1.** Nhóm palette sinh **từ `label` gốc của catalog**, không bịa nhóm: `cloud`(94) `messaging`(45) `database`(35) `transformation`(30) `clustering`(29) `core`(27) `container`(26) `file`(24) `cache`(24) `ai`(19) `api`(19) `management`(15) `iot`(14) `monitoring`(12) … — nhãn tiếng Việt map 1–1 trong bảng `LABEL_VI`, mã nhóm giữ tiếng Anh gốc.
- [x] **A2-2.** Tab palette theo **kind** kiểu Kaoto: *Thành phần · Mẫu EIP · Kamelet · Định dạng dữ liệu · Ngôn ngữ biểu thức*.
- [x] **A2-3.** Lọc theo vai trò như Kaoto: chặng `from` chỉ hiện mục **không** `producerOnly`; chặng `to`/step chỉ hiện mục **không** `consumerOnly`.
- [x] **A2-4.** Huy hiệu `supportLevel` (Stable/Preview) và `deprecated` (gạch ngang + cảnh báo khi chọn).
- [x] **A2-5.** Tìm kiếm mờ trên `name + title + description + label`, có bàn phím (↑↓ Enter), **≤ 50 ms** với 400+ mục (đo bằng test hiệu năng).
- [x] **A2-6.** Nhóm nghiệp vụ LGSP (`PALETTE` hiện tại) giữ lại thành tab **“Dùng nhiều”** đặt trước các tab gốc — không thay thế phân loại gốc.
- [x] **A2-7.** `toneOf()` suy màu theo `label` gốc thay vì danh sách tên cứng.

### A3. Máy chủ phục vụ catalog (production-path)

- [ ] **A3-1.** `GET /api/admin/v1/catalog/camel?runtime=quarkus&version=…` trả index; `GET …/camel/{kind}/{name}` trả schema — nguồn sự thật theo **phiên bản Camel đang chạy** (FR-04-026 bước 1).
- [ ] **A3-2.** FE ưu tiên API; **fallback** tệp đóng gói khi API lỗi, có cảnh báo nhìn thấy được (không im lặng).
- [ ] **A3-3.** `ETag` + `Cache-Control` cho index; FE cache theo phiên bản.
- [ ] **A3-4.** OpenAPI `contracts/openapi/control-camel-catalog-v0.yaml` + typegen.

---

## 3. Gói B — Màn **Thiết kế luồng** (UI-04-07 / 04-08 / 04-09 / 04-10)

**Lane:** L-FE · FR-04-026…040 · phụ thuộc Gói A, WP-23/25.

### B1. Canvas & mô hình

- [ ] **B1-1.** Canvas trái→phải, node thẻ màu theo nhóm, cạnh cong, chèn giữa cạnh bằng `＋` (UI-04-07).
- [ ] **B1-2.** Kéo–thả từ palette vào canvas **và** thả đúng vào giữa một cạnh (không chỉ nối cuối).
- [ ] **B1-3.** Bốn chặng bắt buộc (`Tiếp nhận · Kiểm tra lược đồ · Ủy quyền · Ghi vết`) khóa, không xóa/không kéo ra khỏi thứ tự hợp lệ (BR-04-001).
- [x] **B1-4.** Undo/redo ≥ 50 bước, gộp thao tác liên tiếp; phím tắt chuẩn.
- [x] **B1-5.** Sao chép / dán / nhân bản nhánh; xóa nhiều node bằng chọn vùng.
- [ ] **B1-6.** Tự bố cục (dagre) + nút “sắp xếp lại”, giữ vị trí thủ công nếu người dùng đã kéo.
- [ ] **B1-7.** Thu phóng, thu nhỏ toàn cảnh, minimap khi > 20 node.
- [ ] **B1-8.** Hiệu năng: 200 node vẫn mượt (đo FPS kéo thả), không dựng lại toàn canvas mỗi phím gõ.

### B2. Cấu hình một chặng (FR-04-037)

- [ ] **B2-1.** Popup mở bằng nhấp đúp; **không** dùng sidebar cố định.
- [ ] **B2-2.** Sinh biểu mẫu **từ `propertiesSchema` thật** của node đang chọn (nạp lười theo A1-5) — mọi kiểu: string/boolean/integer/number/enum/object/array/duration/bean-ref.
- [ ] **B2-3.** Nhóm trường theo `$comment: group:` — `common` mở sẵn, `(advanced)` gập.
- [ ] **B2-4.** Trường `required` đánh dấu, validate inline, chặn đóng khi lỗi cứng (hoặc cảnh báo rõ khi thoát).
- [ ] **B2-5.** Tab: *Tham số · Biểu thức · Ánh xạ (khi là mapper) · Dữ liệu mẫu · Ghi chú*.
- [x] **B2-6.** Không hiện lại secret đã lưu; trường credential → **chọn kết nối PH-05**, không có ô nhập tự do (FR-04-032).
- [ ] **B2-7.** Đổi tham số cập nhật YAML **sống** và badge chưa-đủ-cấu-hình (FR-04-034); đóng popup không mất thay đổi.

### B3. Biểu thức, dữ liệu mẫu, môi trường

- [x] **B3-1.** Trình soạn biểu thức Camel Simple / JSONPath / XPath: tô cú pháp, gợi ý `${header.*}`, `${body}`, `${exchangeProperty.*}` (FR-04-031).
- [x] **B3-2.** Xem trước kết quả biểu thức trên dữ liệu mẫu đã pin — hiện lỗi cú pháp tại chỗ.
- [x] **B3-3.** Pin dữ liệu mẫu theo chặng, lưu kèm `versionId + stageId`, badge trên node (FR-04-033); **không** lẫn vào DSL production.
- [x] **B3-4.** Biến môi trường `$env` theo DEV/UAT/PROD, hiện giá trị hiệu lực (FR-04-036) — không lộ giá trị nhạy cảm.

### B4. `choice`, ghi chú, luồng con

- [ ] **B4-1.** UI `choice`: thêm/xóa/sắp thứ tự nhánh `when`, đặt `otherwise` mặc định (FR-04-038); cảnh báo khi không vét cạn.
- [x] **B4-2.** Sticky note trên canvas, hiện khi duyệt (FR-04-039).
- [ ] **B4-3.** Luồng con `direct:`/`to` tới route khác — có điều hướng “mở luồng con” (FR-04-040).

### B5. Kiểm tra hợp lệ (FR-04-027)

- [ ] **B5-1.** Validate tức thời phía FE: thiếu `required`, node mồ côi, thiếu nhánh mặc định, chặng bắt buộc bị gỡ.
- [ ] **B5-2.** Validate phía máy chủ (`POST /routes/validate`) khi lưu/gửi duyệt — **chặn publish khi lỗi** (đã có, phải giữ).
- [x] **B5-3.** Panel phát hiện: lọc theo mức (lỗi/cảnh báo/gợi ý), bấm vào → chọn đúng node + cuộn tới trường lỗi.
- [ ] **B5-4.** Kiểm tra tham chiếu: bộ chuyển đổi/kết nối/adapter đã đăng ký chưa (E2 của FR-04-032).

### B6. YAML hai chiều

- [x] **B6-1.** Sinh Camel YAML DSL sau mỗi thay đổi, hiện song song (FR-04-026 bước 4).
- [x] **B6-2.** Sửa YAML tay → dựng lại canvas (round-trip thật, không chỉ `# @lgsp-canvas-v1` embed).
- [ ] **B6-3.** YAML sinh ra **nạp được bằng Camel thật** — test: `camel/dancu` load route sinh từ designer, không lỗi.
- [ ] **B6-4.** Khác biệt YAML giữa hai phiên bản hiển thị dạng diff khi duyệt.

### B7. Chạy thử & duyệt

- [x] **B7-1.** Chạy thử gọi API thật WP-25, bỏ hoàn toàn nhánh stub trên đường chính (`VITE_TEST_RUN_STUB` mặc định `false`).
- [x] **B7-2.** Waterfall theo 9 chặng: trạng thái, thời gian, offset; bấm chặng → xem input/output (đã giả danh hóa).
- [x] **B7-3.** Tô đường chạy trên sơ đồ sau khi chạy thử: thành công/lỗi/bỏ qua (FR-04-035).
- [x] **B7-4.** Gửi duyệt → **bốn mắt** (người gửi ≠ người duyệt, chặn ở BE) → publish tạo commit `routes/` (FR-04-029, WP-23).
- [x] **B7-5.** Màn duyệt UI-04-09: diff YAML + ghi chú + lịch sử quyết định.
- [ ] **B7-6.** Danh sách luồng UI-04-01: cột `status`, `version`, `git_commit_ref` **thật**, lọc/tìm/phân trang phía máy chủ.

### B8. Chất lượng

- [ ] **B8-1.** Tự lưu nháp định kỳ + cảnh báo rời trang khi có thay đổi chưa lưu.
- [ ] **B8-2.** Khóa biên tập lạc quan: hai người sửa cùng phiên bản → cảnh báo xung đột, không ghi đè âm thầm.
- [ ] **B8-3.** A11y: điều hướng bàn phím toàn bộ palette + popup, `aria-label` tiếng Việt, tương phản đạt AA.
- [ ] **B8-4.** Test: unit (validate, YAML codec, schema→form) + e2e Playwright kịch bản “tạo luồng → cấu hình → chạy thử → gửi duyệt → duyệt → publish”.

---

## 4. Gói C — Màn **Kết nạp hệ thống** (PH-01)

**Lane:** L-FE + L-CTRL · FR-01-001…015. Hiện mới phủ FR-01-001/006/008 mức tối thiểu.

### C1. Hồ sơ & quy trình

- [x] **C1-1.** Biểu mẫu nhiều bước theo FR-01-001/003: thông tin đơn vị · căn cứ pháp lý · hồ sơ năng lực kỹ thuật · đầu mối liên hệ · dịch vụ đề nghị dùng.
- [x] **C1-2.** Lưu nháp từng bước, quay lại sửa, không mất dữ liệu khi tải lại trang.
- [x] **C1-3.** Đính kèm tệp (quyết định, phương án kỹ thuật): kiểm kiểu/kích thước, quét mã độc trước khi nhận, lưu vào object storage (SeaweedFS theo ADR-020).
- [x] **C1-4.** Kiểm tra hợp lệ tự động FR-01-002: trùng mã hệ thống, thiếu trường, sai định dạng — hiện lỗi theo từng bước.
- [x] **C1-5.** Thẩm định pháp lý FR-01-004 và kỹ thuật FR-01-005 là **hai bước riêng**, mỗi bước có người phụ trách, ý kiến, kết luận.
- [x] **C1-6.** Phê duyệt FR-01-006: bốn mắt, ghi lý do khi từ chối, không tự duyệt hồ sơ mình nộp.
- [x] **C1-7.** Theo dõi tiến độ FR-01-007: dòng thời gian trạng thái + người thực hiện + mốc thời gian.

### C2. Danh tính kỹ thuật & bàn giao an toàn

- [x] **C2-1.** Cấp `clientId` qua Keycloak thật (FR-01-008), không sinh chuỗi giả.
- [x] **C2-2.** Bàn giao secret FR-01-009 **an toàn**: hiện **một lần**, có đếm ngược, sao chép rồi tự ẩn; **không** ghi vào log/nhật ký duyệt; không gửi qua email trong sản phẩm.
- [x] **C2-3.** API danh sách **không bao giờ** trả secret (giữ nguyên, có test khẳng định).
- [ ] **C2-4.** Kiểm thử kết nối FR-01-010 trước khi kích hoạt: nút “thử kết nối”, hiện kết quả từng bước.

### C3. Vòng đời thành viên

- [x] **C3-1.** Tạm ngừng / khôi phục FR-01-011 — có lý do, có hiệu lực tức thì trên gateway.
- [x] **C3-2.** Thu hồi kết nạp FR-01-012 — vô hiệu client, giữ nhật ký.
- [x] **C3-3.** Rà soát quyền định kỳ FR-01-013 — danh sách đến hạn, nhắc việc.
- [x] **C3-4.** Cập nhật hồ sơ FR-01-014 + danh bạ đầu mối FR-01-015.

### C4. Danh sách & chất lượng

- [x] **C4-1.** Bảng: tìm kiếm, lọc theo trạng thái/đơn vị, sắp xếp, phân trang **phía máy chủ**.
- [x] **C4-2.** Xem chi tiết hồ sơ dạng trang riêng (không chỉ dòng bảng).
- [x] **C4-3.** Xuất danh sách (CSV/XLSX) theo bộ lọc đang áp.
- [x] **C4-4.** RBAC: người nộp chỉ thấy hồ sơ đơn vị mình; `INTEGRATION_REVIEWER` thấy hàng chờ duyệt; kiểm chứng bằng test BE.
- [x] **C4-5.** Nhật ký kiểm toán mọi hành vi đổi trạng thái (ai · khi nào · từ đâu).
- [ ] **C4-6.** OpenAPI `control-onboarding` nâng lên v1 + typegen; e2e kịch bản đầy đủ nộp→thẩm định→duyệt→cấp danh tính→thử kết nối→kích hoạt.

---

## 5. Gói D — Màn **Catalog API** (PH-02)

**Lane:** L-FE + L-CTRL · FR-02-001…014. Hiện mới phủ FR-02-001/004/010 mức tối thiểu.

### D1. Đăng ký & đặc tả

- [ ] **D1-1.** Đăng ký dịch vụ FR-02-001 với đủ siêu dữ liệu: mã, tên, mô tả, đơn vị chủ quản, phân loại, mức nhạy cảm dữ liệu.
- [ ] **D1-2.** Kiểm tra đặc tả OpenAPI FR-02-002 **thật** (parse + lint), báo lỗi theo dòng; chặn đăng ký khi sai.
- [ ] **D1-3.** Nhập đặc tả từ **tệp hoặc URL** FR-02-003, không chỉ dán chuỗi vào ô văn bản.
- [ ] **D1-4.** Trình xem OpenAPI (danh sách endpoint, schema) — không bắt người dùng đọc YAML thô.

### D2. Vòng đời & phiên bản

- [ ] **D2-1.** Chuyển trạng thái FR-02-004 đúng máy trạng thái: `DRAFT → REVIEW → PUBLISHED → DEPRECATED → RETIRED`, chặn bước nhảy sai.
- [ ] **D2-2.** Phê duyệt phát hành FR-02-005 — bốn mắt, khác người đăng ký.
- [ ] **D2-3.** Quản lý phiên bản API FR-02-006: nhiều phiên bản song song, đánh dấu phiên bản hiện hành, diff giữa hai phiên bản.
- [ ] **D2-4.** Ngừng dùng FR-02-007: mốc ngày, thông báo bên tiêu dùng, chặn đăng ký mới.

### D3. Tiêu dùng, SLA, thống kê

- [ ] **D3-1.** Đăng ký sử dụng dịch vụ FR-02-011 — bên tiêu dùng gửi yêu cầu, bên cung cấp duyệt.
- [ ] **D3-2.** Cam kết chất lượng FR-02-012: hạn mức, TPS, thời gian phản hồi — **đẩy xuống APISIX** (rate-limit thật), không chỉ ghi bảng.
- [ ] **D3-3.** Thông báo thay đổi FR-02-013 tới bên tiêu dùng đã đăng ký.
- [ ] **D3-4.** Thống kê sử dụng FR-02-014: lượt gọi, tỉ lệ lỗi, độ trễ — đọc từ PH-13, không bịa số.

### D4. Liên thông

- [ ] **D4-1.** Sinh khung route cho PH-04 FR-02-010: từ dịch vụ đã publish tạo **luồng nháp** mở thẳng trong màn Thiết kế luồng.
- [ ] **D4-2.** Đăng ký danh mục lên hệ thống của Bộ FR-02-009 (có thể mock sandbox, nhưng đường mã là thật).
- [ ] **D4-3.** Đồng bộ APISIX qua **file declarative trong Git** (giữ nguyên nguyên tắc WP-11 — không gọi Admin API tay).
- [ ] **D4-4.** Liên kết hai chiều: dịch vụ ↔ luồng Camel ↔ hệ thống đã kết nạp.

### D5. Chất lượng

- [ ] **D5-1.** Bảng: tìm/lọc/sắp xếp/phân trang phía máy chủ; trạng thái rỗng có hướng dẫn.
- [ ] **D5-2.** Trang chi tiết dịch vụ: tab *Tổng quan · Đặc tả · Phiên bản · Bên tiêu dùng · SLA · Thống kê*.
- [ ] **D5-3.** RBAC theo SRS-19; nút Publish chỉ hiện với vai trò có quyền (đã có, mở rộng cho các hành vi mới).
- [ ] **D5-4.** OpenAPI `control-catalog` nâng lên v1 + typegen; e2e kịch bản đăng ký→duyệt→publish→đăng ký tiêu dùng→gọi thật qua gateway.

---

## 6. Thứ tự thi công

```text
A1 → A2 → A3        (catalog: dữ liệu trước, phân loại sau, API sau cùng)
   ↓
B1 → B2 → B3/B4 → B5 → B6 → B7 → B8    (designer, phụ thuộc A)
C1 → C2 → C3 → C4                       (kết nạp, song song với B)
D1 → D2 → D3/D4 → D5                    (catalog API, sau C2 vì cần danh tính)
```

Song song an toàn: **A** xong thì **B** và **C** chạy đồng thời (khác lane dữ liệu). **D** chờ **C2** (cấp danh tính) và **B7** (liên kết luồng).

---

## 7. Cổng nghiệm thu (không đánh `[x]` nếu thiếu bằng chứng)

| Cổng | Kiểm | Kỳ vọng |
|---|---|---|
| **G-A** | `npm test -- catalog.count` | ≥ 320 component · ≥ 70 pattern · ≥ 250 kamelet · tổng ≥ 400 |
| **G-A2** | Mở palette, đếm tab & nhóm | Nhóm sinh từ `label` gốc, không cứng trong mã |
| **G-B** | e2e designer | tạo→cấu hình từ schema thật→chạy thử API thật→gửi duyệt→duyệt (khác người)→publish có `git_commit_ref` |
| **G-B2** | Camel nạp YAML designer sinh ra | route khởi động không lỗi |
| **G-C** | e2e kết nạp | nộp→thẩm định pháp lý+kỹ thuật→duyệt→cấp clientId Keycloak→thử kết nối→kích hoạt; secret hiện đúng một lần, không có trong log |
| **G-D** | e2e catalog | đăng ký→lint OpenAPI→duyệt→publish→route APISIX trong Git→gọi thật 200 |
| **G-SEC** | gitleaks + rà log | không secret; danh sách API không trả secret |
| **G-A11Y** | smoke a11y | điều hướng bàn phím + tương phản AA trên cả ba màn |

---

## 8. Lịch sử

| Ngày | Thay đổi |
|---|---|
| 2026-08-04 | Khởi tạo IP-05 — checklist sản xuất ba màn; đo hiện trạng catalog 16+36 so với nguồn Kaoto 323+74+252 |
| 2026-08-04 | **Gói B**: so sánh YAML khi duyệt (B7-5), nhân bản chặng (B1-5); sửa lỗi trùng mã nút và `structuredClone` trong lịch sử — 68 test xanh |
| 2026-08-04 | **Gói C xong toàn bộ** (`2c35384` BE + FE): thêm đính kèm tệp (SeaweedFS), rà soát quyền định kỳ, xuất CSV — 14 AT xanh |
| 2026-08-04 | Gói C phần lõi (`184cb8b` BE + `02cad35` FE): thẩm định hai bước, bốn mắt, vòng đời thành viên, nhật ký kiểm toán — 8 AT chạy thật trên Postgres + e2e thin-slice xanh. Còn C1-3 (đính kèm tệp), C3-3 (rà soát định kỳ), C4-3 (xuất CSV) |
| 2026-08-04 | Round-trip YAML hai chiều + lọc bảng phát hiện — 53 test xanh |
| 2026-08-04 | Sửa lỗi tham chiếu `kind/name` (`4b0dbe3`) · tô đường chạy thử lên sơ đồ (FR-04-035) — 44 test xanh |
| 2026-08-04 | **Gói A xong** (`814bb1e`): 751 nút, phân loại theo nhãn gốc, 13 test chốt số lượng. **Gói B một phần** (`ef42681`): pin dữ liệu mẫu, trình soạn biểu thức, chặn secret trên node — 32 test xanh |
