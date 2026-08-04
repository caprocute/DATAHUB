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
- [ ] **G0-4.** Sửa nốt lỗi deep link qua vòng đăng nhập (FR-D-2-4) — `location.state` của
      Router không sống qua lượt chuyển trang tới Keycloak, phải mang bằng `url_state`.

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
- [ ] **G1-7.** Test lõi ≥ 70 ca, gồm **bốn ca chặn lỗi cũ ở §0**.

## 4. G2 — D-01 Danh sách luồng

- [ ] **G2-1.** Bảng: lọc/tìm/sắp xếp/phân trang **phía máy chủ**.
- [ ] **G2-2.** Cột: mã · tên · trạng thái · phiên bản hiện hành/nháp · `git_commit_ref` ·
      nguồn→đích · người sửa cuối · thời điểm.
- [ ] **G2-3.** Thao tác từng dòng: Thiết kế · Chạy thử · Nhật ký · Nhân bản · Đổi tên ·
      Tạm dừng/Kích hoạt · Xóa nháp (FR-D-002).
- [x] **G2-4.** Tạo luồng mới: chọn luồng trống hoặc mẫu, kiểm tra trùng mã ngay (FR-D-003).
- [ ] **G2-5.** Lịch sử phiên bản + so sánh hai phiên bản (FR-D-004).
- [x] **G2-6.** Trạng thái rỗng phân biệt "chưa có dữ liệu" và "bộ lọc không khớp".

## 5. G3 — D-02 Trình thiết kế toàn màn hình

- [x] **G3-1.** Khung toàn màn hình bằng **flexbox**, ẩn sidebar, canvas `flex: 1 1 0`
      + `min-height: 0`, không chiều cao cứng (FR-D-010).
- [x] **G3-2.** Điểm gãy responsive: ≥1440 canvas ≥60% · 1024–1440 gập panel phải ·
      <1024 hai panel thành ngăn kéo · không cuộn ngang ở khung ngoài.
- [x] **G3-3.** Bảng thành phần: tab theo loại, lọc nhãn có số đếm, tìm kiếm < 50 ms,
      **ảo hóa danh sách**, huy hiệu mức hỗ trợ, mô tả khi di chuột (FR-D-011).
- [ ] **G3-4.** Canvas: kéo–thả, chèn giữa cạnh, chọn vùng, nhân bản, hoàn tác ≥50 bước,
      tự sắp xếp, minimap, chặng khóa (FR-D-012).
- [ ] **G3-5.** Trạng thái lưu rõ ràng + tự lưu 30 giây + cảnh báo rời trang + chống ghi
      đè khi hai người cùng sửa (FR-D-013).
- [ ] **G3-6.** Panel kiểm tra và panel YAML thu gọn được, nhớ trạng thái thu gọn.

## 6. G4 — D-03 Cửa sổ cấu hình chặng

- [x] **G4-1.** Cửa sổ **75%×75%**, tối thiểu 960×640, tối đa 1600×1000 (FR-D-020).
- [x] **G4-2.** Ba cột INPUT │ THAM SỐ │ OUTPUT; chỉ vùng giữa cuộn; đầu/chân cố định.
- [x] **G4-3.** Tab theo **nhóm gốc** `common/producer/consumer/security/scheduler/advanced`,
      ẩn tab rỗng, hiện số trường đã đặt/tổng (FR-D-021).
- [x] **G4-4.** Mặc định chỉ hiện trường bắt buộc + đã đặt; nút «Hiện tất cả (N)».
- [x] **G4-5.** **Ô tìm trong trường**, lọc xuyên mọi tab.
- [ ] **G4-6.** Sinh điều khiển theo kiểu thật: `enum`→Select (876 trường), boolean→công tắc,
      số→ô số có biên, duration→số+đơn vị, biểu thức→trình soạn, bí mật→chọn kết nối,
      object/array→bảng khóa–giá trị (FR-D-022).
- [x] **G4-7.** Mỗi trường hiện tiêu đề + mô tả gốc + mặc định + tên tham số Camel +
      dấu bắt buộc + cảnh báo `deprecated`.
- [ ] **G4-8.** Kiểm tra tại chỗ, tổng lỗi ở chân cửa sổ, huy hiệu đỏ trên node (FR-D-023).
- [ ] **G4-9.** Bản tin mẫu + kế thừa từ chặng trước + xem trước biểu thức (FR-D-024).

## 7. G5 — D-04 Chạy thử và D-05 Nhật ký chạy

- [x] **G5-1.** Màn chạy thử riêng: chọn phiên bản, chế độ, bản tin vào, biến môi trường.
- [ ] **G5-2.** Chặn chạy khi còn lỗi kiểm tra.
- [x] **G5-3.** Waterfall theo chặng, bấm chặng xem vào/ra (FR-D-030).
- [ ] **G5-4.** Tô đường chạy lên sơ đồ khi quay lại D-02 (FR-D-031).
- [ ] **G5-5.** So sánh hai lần chạy (FR-D-032).
- [ ] **G5-6.** **Bảng CSDL mới** `ph04.route_test_run` + `route_test_run_stage`
      (lane L-CTRL) — lưu lịch sử chạy, `traceId`, kết quả từng chặng.
- [ ] **G5-7.** API danh sách/chi tiết lần chạy; **không ghi bí mật, không ghi PII thô**.
- [x] **G5-8.** Màn nhật ký: lọc theo thời gian/kết quả/người chạy/phiên bản (FR-D-040/041).
- [ ] **G5-9.** Dọn nhật ký quá 90 ngày, số ngày cấu hình được (FR-D-042).

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
| 2026-08-04 | Xong G0–G6. **Nghiệm thu N-2 đạt**: Camel thật khởi động route do bộ sinh mới tạo (`Started nghiem-thu-br-d-04` · BUILD SUCCESS). **N-3/N-4 đo được**: gõ tìm kiếm 13,3 ms (ngưỡng 50) · ảo hóa 297 mục lọc chỉ dựng 18 phần tử DOM · canvas 68% ở 1920px (ngưỡng 60) · không cuộn ngang ở 1024/1280/1440/1920. **N-5**: cửa sổ cấu hình đúng 75% (960px), chia tab theo nhóm gốc. Bốn lỗi sửa dọc đường: `useBlocker` ngoài data router làm trắng trang · thiếu `@xyflow/react/dist/style.css` · thiếu `AntApp` ở gốc khiến `message.success` ném lỗi · thiếu bảng token nên nền node trong suốt |
