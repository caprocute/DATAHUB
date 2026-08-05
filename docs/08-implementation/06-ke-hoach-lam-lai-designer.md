# IP-06 — Kế hoạch làm lại trình thiết kế luồng

> **Căn cứ.** [SRS PH-04/D](../07-srs/SRS-PH-04-designer.md) · quyết định của chủ dự án 2026-08-04:
> route riêng toàn màn hình · cấu hình kiểu Kaoto (tab theo nhóm + tìm trường) ·
> **viết lại toàn bộ `src/designer/`** kể cả lõi · phạm vi gồm danh sách, chạy thử,
> nhật ký chạy, phân tích thuộc tính node.
>
> **Quy ước.** `- [ ]` chỉ đánh `[x]` khi có bằng chứng chạy được. Mỗi gói map `FR-D-*`.

---

## 0. Điều phải giữ lại dù viết lại từ đầu

Viết lại mã, **không** viết lại bài học. Bốn lỗi dưới đây từng làm hỏng sản phẩm và
phải có test chặn ngay từ đầu ở mã mới:

| # | Lỗi đã gặp | Chặn bằng |
|---|---|---|
| 1 | `enrich` sinh `timeout` → **Camel từ chối nạp route** (`Field: timeout has already been configured as an expression`) | Test khẳng định `enrich` không có `timeout`; `pollEnrich` thì có |
| 2 | Bộ đếm mã nút đếm từ 0 → trùng mã nút do bộ đọc YAML đặt → React Flow bỏ nút | Test sinh mã sau khi nạp sơ đồ có sẵn |
| 3 | Nút thêm bằng mã thiếu `measured` → React Flow giữ `visibility: hidden`, nút vô hình | Test/kiểm chứng mọi lối thêm chặng |
| 4 | Tham chiếu `kind/name` không chuẩn hóa → sinh khóa `pattern/choice` sai DSL | Test YAML không chứa tiền tố loại |

**Nghiệm thu cuối cùng của cả đợt (BR-D-04):** Camel thật khởi động được route do
trình thiết kế sinh. Không đạt điều này thì coi như chưa xong.

---

## 1. Thứ tự thi công

```text
G0 nền  ──> G1 lõi ──> G2 danh sách ──> G3 designer ──> G4 cấu hình ──> G5 chạy thử+nhật ký ──> G6 duyệt ──> G7 nghiệm thu
```

Lý do thứ tự: lõi (sinh/đọc YAML, catalog, kiểm tra) không phụ thuộc giao diện nên làm
trước và test được ngay; các màn dựng trên lõi đã chắc.

---

## 2. G0 — Nền: dọn chỗ và dựng khung

- [x] **G0-1.** Xóa toàn bộ `apps/console/src/designer/` cũ (giữ lại thư mục
      `catalog/generated/` — đó là **dữ liệu sinh ra từ nguồn nhà sản xuất**, không phải mã).
- [x] **G0-2.** Cấu trúc mới:
      ```text
      src/flows/                 # nghiệp vụ luồng
        list/                    # D-01
        design/                  # D-02 + D-03
        test/                    # D-04
        runs/                    # D-05
        review/                  # D-06
      src/flows/core/            # lõi thuần, không phụ thuộc React
        catalog.ts  emit.ts  parse.ts  validate.ts  expression.ts  diff.ts
      ```
- [x] **G0-3.** Route mới trong `App.tsx`: `/flows`, `/flows/:code/design` (ngoài `AppShell`),
      `/flows/:code/test`, `/flows/:code/runs`, `/flows/review`.
- [x] **G0-4.** Sửa nốt lỗi deep link qua vòng đăng nhập (FR-D-2-4). *(kiểm chứng thật
      trên trình duyệt: mở `/flows/at-5812634/design` lúc chưa đăng nhập → Keycloak →
      **quay lại đúng trình thiết kế, canvas vẽ ra**; đăng nhập thường vẫn về `/flows`.
      Ba lỗi chồng nhau, xem mục 10.)*

## 3. G1 — Lõi (không giao diện, test trước)

- [x] **G1-1.** `catalog.ts`: nạp chỉ mục 751 nút, nạp lười lược đồ, tìm kiếm có xếp hạng,
      nhóm theo nhãn gốc, lọc theo vai trò. **Ảo hóa được** (trả về theo lát cắt).
- [x] **G1-2.** `emit.ts`: sơ đồ → Camel YAML DSL. Chuẩn hóa `kind/name`. **Bảng tra
      thuộc tính hợp lệ theo lược đồ gốc** — không tự bịa trường như lỗi `enrich`.
- [x] **G1-3.** `parse.ts`: YAML → sơ đồ; cấu trúc ngoài tập con báo lỗi kèm số dòng,
      giữ nguyên sơ đồ cũ.
- [x] **G1-4.** `validate.ts`: chặng bắt buộc, thiếu tham số bắt buộc, node mồ côi,
      `choice` không vét cạn, tham chiếu bộ chuyển đổi.
- [x] **G1-5.** `expression.ts`: Camel Simple / JSONPath, xem trước trên mẫu, gợi ý token.
- [x] **G1-6.** `diff.ts`: so sánh YAML theo dãy con chung dài nhất.
- [x] **G1-7.** Test lõi ≥ 70 ca, gồm **bốn ca chặn lỗi cũ ở §0**. *(122 ca xanh; bộ test
      bắt được lỗi thật: `choice` một nhánh rơi xuống lối tuần tự làm **mất điều kiện
      định tuyến** — đã sửa và nghiệm thu lại bằng Camel thật.)*

## 4. G2 — D-01 Danh sách luồng

- [x] **G2-1.** Bảng: lọc/tìm/sắp xếp/phân trang **phía máy chủ**. *(kiểm chứng: `size=3`
      trả 3/`total=4`; `q=demo`→1; `status=DRAFT`→1; `sort` chèn `;DROP TABLE` bị danh
      sách trắng đẩy về `updated_at`, bảng còn nguyên 4 dòng.)*
- [x] **G2-2.** Cột: mã · tên · trạng thái · phiên bản hiện hành/nháp · `git_commit_ref` ·
      nguồn→đích · người sửa cuối · thời điểm. *(thêm cột `route.updated_by`; luồng cũ
      để NULL — điền giá trị giả là bịa dữ liệu kiểm toán.)*
- [x] **G2-3.** Thao tác từng dòng: Thiết kế · Chạy thử · Nhật ký · Nhân bản · Đổi tên ·
      Tạm dừng/Kích hoạt · Xóa nháp (FR-D-002). *(kiểm chứng: đổi tên ghi được
      `updated_by`; nhân bản ra DRAFT v1 **không** kế thừa `git_commit_ref`; tạm dừng
      luồng DRAFT → 409, ACTIVE→PAUSED→ACTIVE chạy được; xóa phiên bản đang chạy → 409.)*
- [x] **G2-4.** Tạo luồng mới: chọn luồng trống hoặc mẫu, kiểm tra trùng mã ngay (FR-D-003).
- [x] **G2-5.** Lịch sử phiên bản + so sánh hai phiên bản (FR-D-004). *(API
      `GET /routes/{code}/versions`; `VersionHistory` cho chọn **hai mốc bất kỳ**.)*
- [x] **G2-6.** Trạng thái rỗng phân biệt "chưa có dữ liệu" và "bộ lọc không khớp".

## 5. G3 — D-02 Trình thiết kế toàn màn hình

- [x] **G3-1.** Khung toàn màn hình bằng **flexbox**, ẩn sidebar, canvas `flex: 1 1 0`
      + `min-height: 0`, không chiều cao cứng (FR-D-010).
- [x] **G3-2.** Điểm gãy responsive: ≥1440 canvas ≥60% · 1024–1440 gập panel phải ·
      <1024 hai panel thành ngăn kéo · không cuộn ngang ở khung ngoài.
- [x] **G3-3.** Bảng thành phần: tab theo loại, lọc nhãn có số đếm, tìm kiếm < 50 ms,
      **ảo hóa danh sách**, huy hiệu mức hỗ trợ, mô tả khi di chuột (FR-D-011).
- [x] **G3-4.** Canvas: kéo–thả, chèn giữa cạnh, chọn vùng, nhân bản, hoàn tác ≥50 bước,
      tự sắp xếp, minimap, chặng khóa (FR-D-012). *(bổ sung chọn vùng bằng Shift+kéo,
      giữ `panOnDrag` nên kéo nền vẫn di chuyển khung nhìn.)*
- [x] **G3-5.** Trạng thái lưu rõ ràng + tự lưu 30 giây + cảnh báo rời trang + chống ghi
      đè khi hai người cùng sửa (FR-D-013). *(tự lưu và cảnh báo đã có; bổ sung chống ghi
      đè: đọc lại bản máy chủ trước khi lưu, khác mốc lúc mở thì hỏi rõ thay vì ghi đè
      lặng lẽ — mất trắng công người khác mà không ai biết.)*
- [x] **G3-6.** Panel kiểm tra và panel YAML thu gọn được, nhớ trạng thái thu gọn.
      *(`localStorage` — đúng chỗ vì là tùy chọn hiển thị của riêng máy, khác nhật ký
      chạy vốn phải ở máy chủ.)*

## 6. G4 — D-03 Cửa sổ cấu hình chặng

- [x] **G4-1.** Cửa sổ **75%×75%**, tối thiểu 960×640, tối đa 1600×1000 (FR-D-020).
- [x] **G4-2.** Ba cột INPUT │ THAM SỐ │ OUTPUT; chỉ vùng giữa cuộn; đầu/chân cố định.
- [x] **G4-3.** Tab theo **nhóm gốc** `common/producer/consumer/security/scheduler/advanced`,
      ẩn tab rỗng, hiện số trường đã đặt/tổng (FR-D-021).
- [x] **G4-4.** Mặc định chỉ hiện trường bắt buộc + đã đặt; nút «Hiện tất cả (N)».
- [x] **G4-5.** **Ô tìm trong trường**, lọc xuyên mọi tab.
- [x] **G4-6.** Sinh điều khiển theo kiểu thật: `enum`→Select (876 trường), boolean→công tắc,
      số→ô số có biên, duration→số+đơn vị, biểu thức→trình soạn, bí mật→chọn kết nối,
      object/array→bảng khóa–giá trị (FR-D-022). *(bổ sung nốt bảng khóa–giá trị; JSON
      hỏng thì hiện ô thô để sửa, **không** nuốt mất cấu hình. Kiểm 8 ca biên.)*
- [x] **G4-7.** Mỗi trường hiện tiêu đề + mô tả gốc + mặc định + tên tham số Camel +
      dấu bắt buộc + cảnh báo `deprecated`.
- [x] **G4-8.** Kiểm tra tại chỗ, tổng lỗi ở chân cửa sổ, huy hiệu đỏ trên node (FR-D-023).
      *(đã có sẵn từ đợt trước — soi lại mã: `cfg__field--missing`, `missingCount` ở chân
      cửa sổ, chấm đỏ/vàng trên node.)*
- [x] **G4-9.** Bản tin mẫu + kế thừa từ chặng trước + xem trước biểu thức (FR-D-024).
      *(đã có sẵn — nhãn «kế thừa» và xem trước trong `ExpressionField`.)*

## 7. G5 — D-04 Chạy thử và D-05 Nhật ký chạy

- [x] **G5-1.** Màn chạy thử riêng: chọn phiên bản, chế độ, bản tin vào, biến môi trường.
- [x] **G5-2.** Chặn chạy khi còn lỗi kiểm tra. *(kiểm trước khi bấm và khóa nút; máy
      chủ vẫn là chốt chặn thật. Không kiểm được thì **không** chặn — khóa oan còn tệ hơn.)*
- [x] **G5-3.** Waterfall theo chặng, bấm chặng xem vào/ra (FR-D-030).
- [x] **G5-4.** Tô đường chạy lên sơ đồ khi quay lại D-02 (FR-D-031). *(`mapWaterfall` đã
      có sẵn nhưng **chưa từng được gọi** — `DesignerPage` vẫn truyền `EMPTY_RUN`. Nay
      tải lần chạy gần nhất và tô, có nút tắt.)*
- [x] **G5-5.** So sánh hai lần chạy (FR-D-032). *(ghép theo tên chặng, hiện chênh lệch ms.)*
- [x] **G5-6.** **Bảng CSDL mới** `ph04.route_test_run` + `route_test_run_stage`
      (lane L-CTRL) — lưu lịch sử chạy, `traceId`, kết quả từng chặng. *(kiểm chứng trên
      Postgres thật: chạy thử ghi 1 lần chạy + 9 chặng, đọc lại qua API đúng thứ tự.)*
- [x] **G5-7.** API danh sách/chi tiết lần chạy; **không ghi bí mật, không ghi PII thô**.
      *(soi bảng: chỉ có tên chặng `receive/schema/authz/…`, không cột nào chứa body/header.)*
- [x] **G5-8.** Màn nhật ký: lọc theo thời gian/kết quả/người chạy/phiên bản (FR-D-040/041).
- [x] **G5-9.** Dọn nhật ký quá 90 ngày, số ngày cấu hình được (FR-D-042). *(cron 03:15,
      `lgsp.routes.test-run-retention-days`; kiểm chứng CASCADE: xóa bản ghi 200 ngày tuổi
      kéo theo chặng con, lần chạy mới còn nguyên.)*

## 8. G6 — D-06 Duyệt

- [x] **G6-1.** Hàng đợi duyệt tách thành màn riêng.
- [x] **G6-2.** Bắt buộc xem diff trước khi quyết định (FR-D-050).
- [x] **G6-3.** Bốn mắt chặn ở máy chủ; giao diện ẩn nút và nói rõ lý do (FR-D-051).

## 9. G7 — Nghiệm thu

| Cổng | Kiểm | Kỳ vọng |
|---|---|---|
| **N-1** | `npm test` | ≥ 70 ca lõi xanh, gồm 4 ca chặn lỗi cũ |
| **N-2** | **Camel thật nạp YAML do designer sinh** | `Started <route-id>` · BUILD SUCCESS |
| **N-3** | Đo trên trình duyệt | NFR-D-01…05 đạt ngưỡng |
| **N-4** | Thu nhỏ cửa sổ 1024/1280/1440/1920 | Không vỡ bố cục, không cuộn ngang |
| **N-5** | Mở node 154 thuộc tính | Cửa sổ 75%, chia tab đúng nhóm, tìm trường chạy |
| **N-6** | e2e: tạo → thiết kế → chạy thử → xem nhật ký → gửi duyệt → duyệt → publish | Xanh trọn đường |
| **N-7** | Bàn phím + tương phản | Điều hướng được không cần chuột; đạt AA |

---

## 10. Lịch sử

| Ngày | Thay đổi |
|---|---|
| 2026-08-04 | Khởi tạo IP-06 theo quyết định làm lại toàn bộ `src/designer/` |
| 2026-08-05 | **G0-4 kiểm chứng thật trên trình duyệt** — lần đánh dấu trước là *sai*, chạy thử mới lộ ra vẫn rơi về `/flows`. Ba lỗi chồng nhau: (1) `Protected` đẩy sang `/login` ngay giữa lượt callback nên **gói cả URL callback vào `from=`**; (2) `handleOidcCallback` `replaceState` thẳng sang đích nhưng React Router không hay biết, route `index` của `/` liền đè sang `/flows`; (3) StrictMode gắn–tháo–gắn effect nên **cả hai lượt đều `cancelled`** trước khi `signinRedirectCallback` trả về, không lượt nào đặt được đích qua `setState`, mà `code` thì đã tiêu thụ. Cách sửa: đọc đích **đồng bộ từ tham số `state` ngay lúc nạp mô-đun**, không phụ thuộc thứ tự effect. |
| 2026-08-05 | **G0-4, G3-4/5/6, G4-6 xong**. G0-4: đích deep link chuyển sang query `?from=` vì `location.state` mất khi tải lại trang; nhân đó chặn open redirect (`//evil.com` lọt `startsWith('/')`), kiểm 11 ca. G3-5: chống ghi đè khi hai người cùng sửa. G4-6: bảng khóa–giá trị, JSON hỏng không nuốt dữ liệu, kiểm 8 ca biên. **Soi lại mã thấy G4-8 và G4-9 đã làm xong từ đợt trước** — trước đó tôi trả `[ ]` nhầm cho hai mục này |
| 2026-08-05 | **G2-1/2/3/5 + G5-2/4/5/6/7/9 xong**, kiểm chứng trên hệ thống chạy thật (Postgres + Keycloak + control): lọc/phân trang phía máy chủ; `sort` chèn `;DROP TABLE` bị danh sách trắng chặn, bảng còn nguyên; nhân bản không kế thừa `git_commit_ref`; tạm dừng luồng DRAFT → 409; chạy thử ghi 1 lần chạy + 9 chặng vào `ph04.route_test_run*`, đọc lại đúng thứ tự; soi bảng xác nhận **không lưu nội dung bản tin**; CASCADE dọn nhật ký quá hạn đúng. Test bắt lỗi trước khi lên môi trường: `List.of(...).contains(null)` ném NPE ở `RouteQuery` — `sort` null là trường hợp thường gặp nhất nên **mọi lần liệt kê không sắp xếp đều 500** |
| 2026-08-04 | **G1-7 xong**: 122 ca lõi xanh. Bộ test bắt lỗi bộ sinh: chặng rẽ nhánh chỉ có một cạnh ra không sinh khối `choice` nên điều kiện trên cạnh biến mất không báo lỗi — luật định tuyến thành chặng chạy vô điều kiện. Sửa: xét theo `BRANCHING` thay vì đếm cạnh. Nghiệm thu: `Started nghiem-thu-choice-mot-nhanh (direct://mot-nhanh)` trên Camel thật |
| 2026-08-04 | Xong G0–G6. **Nghiệm thu N-2 đạt**: Camel thật khởi động route do bộ sinh mới tạo (`Started nghiem-thu-br-d-04` · BUILD SUCCESS). **N-3/N-4 đo được**: gõ tìm kiếm 13,3 ms (ngưỡng 50) · ảo hóa 297 mục lọc chỉ dựng 18 phần tử DOM · canvas 68% ở 1920px (ngưỡng 60) · không cuộn ngang ở 1024/1280/1440/1920. **N-5**: cửa sổ cấu hình đúng 75% (960px), chia tab theo nhóm gốc. Bốn lỗi sửa dọc đường: `useBlocker` ngoài data router làm trắng trang · thiếu `@xyflow/react/dist/style.css` · thiếu `AntApp` ở gốc khiến `message.success` ném lỗi · thiếu bảng token nên nền node trong suốt |
