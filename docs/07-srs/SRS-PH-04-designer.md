# SRS PH-04/D — Trình thiết kế luồng tích hợp (bản chi tiết)

> **Vai trò.** Đặc tả chi tiết cho cụm màn thiết kế luồng, thay phần mô tả rút gọn ở
> [SRS PH-04 §6](SRS-PH-04-integration-core.md) khi hai bên khác nhau.
> Bám `FR-04-026…040` của SRS PH-04 · [SRS-19](SRS-19-rbac-matrix.md) · [ADR-015](../05-adr/README.md#adr-015) (Kaoto = catalog + ngữ nghĩa) · [ADR-017](../05-adr/README.md#adr-017) (XYFlow).
>
> **Lý do viết lại.** Bản trước dồn danh sách + thiết kế + chạy thử + duyệt vào **một màn**
> theo mockup. Hệ quả: không đủ không gian cho canvas, popup cấu hình quá nhỏ so với
> thực tế lược đồ Camel, và thiếu hẳn nghiệp vụ nhật ký chạy. Bản này tách màn theo
> **nhiệm vụ người dùng**, không theo bố cục mockup.

---

## 1. Số liệu nền — quyết định thiết kế dựa trên đây

Đo trực tiếp trên catalog đang dùng (`@kaoto/camel-catalog` nhánh `camel-quarkus/3.35.0`):

| Chỉ số | Giá trị | Hệ quả thiết kế |
|---|---|---|
| Tổng nút khả dụng | **751** (323 component · 74 EIP · 252 kamelet · 48 dataformat · 26 language · 21 entity · 7 loadbalancer) | Bảng thành phần phải có tab + lọc nhãn + tìm kiếm; không thể liệt kê phẳng |
| Thuộc tính mỗi component | trung vị **19**, p90 **64**, tối đa **154** | **Popup nhỏ là bất khả thi.** Cần cửa sổ lớn, chia nhóm, tìm trong trường |
| Nhóm thuộc tính gốc | `common` 1148 · `producer` 1536 · `consumer` 944 · `security` 994 · `scheduler` 898 · `advanced` 826+ | Chia tab theo đúng nhóm gốc, không tự đặt nhóm |
| Kiểu trường | string 4265 · boolean 2357 · integer 1277 · **enum 876** · object 130 | Phải sinh điều khiển theo kiểu; 876 trường enum bắt buộc dùng `Select`, không phải ô text |
| Thuộc tính bắt buộc | phần lớn component có **1–2** trường bắt buộc | Mặc định chỉ hiện trường bắt buộc + đã đặt; phần còn lại gập |

**Kết luận.** Yêu cầu "400 nút trông không khác gì nhau" được xử lý bằng: phân loại theo
nhãn gốc, huy hiệu mức hỗ trợ, mô tả gốc, và biểu mẫu sinh từ lược đồ thật theo kiểu dữ liệu.

---

## 2. Phân rã màn theo nhiệm vụ

Nguyên tắc: **một màn = một nhiệm vụ**. Không dồn nhiều nhiệm vụ vào một khung.

| Mã | Màn | Nhiệm vụ | Đường dẫn | Bố cục |
|---|---|---|---|---|
| **D-01** | Danh sách luồng | Tìm, lọc, theo dõi trạng thái, mở việc | `/flows` | Có khung ứng dụng (sidebar + đầu trang) |
| **D-02** | Trình thiết kế | Dựng và sửa **một tệp** (có thể chứa nhiều route) | `/flows/:code/design` | **Toàn màn hình**, ẩn sidebar |
| **D-03** | Cấu hình chặng | Đặt tham số **một** chặng | Lớp phủ trên D-02 | Cửa sổ **75%** màn hình |
| **D-04** | Chạy thử | Chạy và đọc kết quả một luồng | `/flows/:code/test` | Có khung ứng dụng |
| **D-05** | Nhật ký chạy | Tra lịch sử các lần chạy | `/flows/:code/runs` | Có khung ứng dụng |
| **D-06** | Duyệt | Thẩm định và phê duyệt phiên bản | `/flows/review` | Có khung ứng dụng |
| **D-07** | Danh mục thành phần | Tra cứu **751 nút** Camel đã vendor | `/components` | Có khung ứng dụng |
| **D-08** | Ánh xạ dữ liệu | Vẽ ánh xạ trường nguồn → đích | Lớp phủ trên D-02 | Cửa sổ lớn |

### 2.1. Luồng đi giữa các màn

```text
D-01 danh sách ──"Thiết kế"──> D-02 toàn màn hình ──nhấp đúp node──> D-03 cấu hình
     │                              │
     │                              └──"Lưu & chạy thử"──> D-04 ──"Xem lịch sử"──> D-05
     └──"Tạo luồng mới"──> D-02
     └──"Duyệt" (vai người duyệt)──> D-06 ──so sánh YAML──> quyết định
```

**Ràng buộc điều hướng**

- **D-2-1.** Mỗi màn có URL riêng; tải lại trang (F5) không mất chỗ đang đứng.
- **D-2-2.** Nút Quay lại của trình duyệt hoạt động đúng ở mọi bước.
- **D-2-3.** Rời D-02 khi còn thay đổi chưa lưu → hỏi xác nhận.
- **D-2-4.** Đường dẫn sâu (deep link) giữ được qua vòng đăng nhập.

---

## 3. D-01 — Danh sách luồng

### FR-D-001 — Danh sách có lọc và phân trang phía máy chủ · **M**

| Mục | Nội dung |
|---|---|
| **Đầu vào** | Từ khóa · trạng thái · hệ nguồn · hệ đích · khoảng ngày sửa |
| **Xử lý** | Truy vấn phía máy chủ, phân trang theo số trang, sắp xếp theo cột |
| **Đầu ra** | Bảng: mã · tên · trạng thái · phiên bản hiện hành · phiên bản nháp · `git_commit_ref` · hệ nguồn → hệ đích · người sửa cuối · thời điểm sửa cuối |
| **Ngoại lệ** | E1: Không có kết quả → nêu rõ do bộ lọc hay do chưa có dữ liệu, kèm lối thoát |

### FR-D-002 — Thao tác trên một luồng · **M**

Mỗi dòng có: **Thiết kế** (→ D-02) · **Chạy thử** (→ D-04) · **Nhật ký** (→ D-05) ·
**Nhân bản** · **Đổi tên** · **Tạm dừng/Kích hoạt** · **Xóa nháp**.
Thao tác đổi trạng thái luồng đang chạy phải hỏi xác nhận và ghi lý do.

### FR-D-003 — Tạo luồng mới · **M**

Chọn điểm xuất phát: **luồng trống** (chỉ có khung chặng bắt buộc) hoặc **mẫu có sẵn**
(`FR-04-030`). Nhập mã luồng (kiểm tra trùng ngay), tên, hệ nguồn, hệ đích → vào D-02.

### FR-D-004 — Lịch sử phiên bản · **S**

Xem danh sách phiên bản của một luồng: số hiệu, trạng thái, người tạo, thời điểm,
`git_commit_ref`; so sánh hai phiên bản bất kỳ; mở một phiên bản cũ ở chế độ chỉ đọc.

---

## 4. D-02 — Trình thiết kế toàn màn hình

### 4.1. Bố cục

```text
┌──────────────────────────────────────────────────────────────────────┐
│ ← Quay lại │ mã-luồng · v3 DRAFT │ ● chưa lưu │ [Lưu] [Chạy thử] [Gửi duyệt] │  ← thanh trên (cố định)
├────────────┬─────────────────────────────────────────┬───────────────┤
│ Bảng       │                                         │ Kiểm tra      │
│ thành phần │              CANVAS                     │ (findings)    │
│ (751 nút)  │         chiếm phần lớn không gian       │               │
│ thu gọn    │                                         │ YAML          │
│ được       │                                         │ thu gọn được  │
└────────────┴─────────────────────────────────────────┴───────────────┘
```

### FR-D-010 — Bố cục co giãn bằng flexbox · **M**

| Mục | Nội dung |
|---|---|
| **Xử lý** | Toàn bộ khung dùng flexbox; canvas nhận phần không gian còn lại (`flex: 1 1 0` + `min-height: 0`), không đặt chiều cao cứng |
| **Yêu cầu** | 1. Hai panel bên thu gọn được, trạng thái thu gọn nhớ theo người dùng<br>2. Màn ≥ 1440px: canvas rộng ≥ 60% bề ngang<br>3. Màn 1024–1440px: panel phải tự gập<br>4. Màn < 1024px: chỉ còn canvas + thanh trên; hai panel thành ngăn kéo<br>5. Không có thanh cuộn ngang ở khung ngoài ở bất kỳ bề rộng nào |
| **Ngoại lệ** | E1: Cửa sổ quá thấp (< 600px) → thanh trên rút gọn thành biểu tượng |

### FR-D-011 — Bảng thành phần cho 751 nút · **M**

1. Tab theo loại: *Dùng nhiều · Thành phần · Mẫu EIP · Kamelet · Định dạng · Ngôn ngữ*.
2. Lọc theo nhãn gốc trong từng loại (`cloud`, `messaging`, `database`…), kèm số lượng.
3. Tìm kiếm trên tên + tiêu đề + mô tả + nhãn; khớp đúng tên xếp trước; **≤ 50 ms**.
4. Mỗi mục hiện: biểu tượng theo nhóm · tiêu đề · tên Camel · huy hiệu `Preview`/`deprecated`.
5. Di chuột hiện mô tả gốc + cú pháp URI.
6. Lọc theo vai trò: chặng đầu luồng chỉ hiện nút dùng được làm `from`.
7. **Danh sách ảo hóa** — chỉ dựng phần tử trong tầm nhìn.

### FR-D-012 — Canvas · **M**

Trái→phải; thẻ node màu theo nhóm; cạnh cong; chèn giữa cạnh bằng `＋`; kéo–thả từ
bảng thành phần; chọn nhiều bằng vùng quét; nhân bản (`⌘D`); xóa; hoàn tác/làm lại
≥ 50 bước; tự sắp xếp; thu phóng; minimap khi > 20 node; **giữ mượt ở 200 node**.

Chặng khung chuẩn (`Tiếp nhận · Kiểm tra lược đồ · Ủy quyền · Ghi vết`) do mẫu tạo sẵn
nhưng **gỡ được**; gỡ thì `validate` cảnh báo, không chặn (BR-D-01 §10.1 — sửa 2026-08-06).

### FR-D-013 — Trạng thái lưu rõ ràng · **M**

Thanh trên luôn cho biết: **đã lưu** / **chưa lưu** / **đang lưu** / **lưu lỗi**.
Tự lưu nháp sau 30 giây không thao tác. Rời trang khi chưa lưu → hỏi xác nhận.
Hai người sửa cùng phiên bản → cảnh báo xung đột, **không ghi đè âm thầm**.

---

## 5. D-03 — Cửa sổ cấu hình chặng

> Đây là chỗ bản trước sai nặng nhất: cửa sổ nhỏ trong khi lược đồ có tới 154 thuộc tính.

### FR-D-020 — Khung cửa sổ · **M**

| Mục | Nội dung |
|---|---|
| **Kích thước** | **75% bề ngang × 75% chiều cao** màn hình, tối thiểu 960×640, tối đa 1600×1000 |
| **Bố cục** | Ba cột: **INPUT** (bản tin mẫu) │ **THAM SỐ** (vùng chính) │ **OUTPUT** (kết quả chạy thử) — học bố cục n8n |
| **Yêu cầu** | Chỉ vùng giữa cuộn; đầu và chân cửa sổ cố định; `Esc` đóng; đóng không mất thay đổi đã áp |
| **Ngoại lệ** | E1: Màn < 1024px → hai cột bên gập thành tab |

### FR-D-021 — Tổ chức trường theo nhóm gốc · **M**

1. Tab theo **nhóm gốc của catalog**: `common` · `producer` · `consumer` · `security` ·
   `scheduler` · `advanced`. Nhóm không có trường thì ẩn tab.
2. Tab đầu tiên mở sẵn là nhóm chứa trường bắt buộc.
3. Mỗi tab hiện số trường đã đặt / tổng số.
4. Mặc định hiện **trường bắt buộc + trường đã có giá trị**; còn lại sau nút
   «Hiện tất cả (N)» — vì trung vị 19 và p90 64 trường.
5. **Ô tìm trong trường**: gõ để lọc theo tên/tiêu đề/mô tả, xuyên mọi tab.

### FR-D-022 — Sinh điều khiển theo kiểu dữ liệu thật · **M**

| Kiểu trong lược đồ | Điều khiển | Ghi chú |
|---|---|---|
| `enum` (876 trường) | `Select` kèm mô tả từng giá trị | **Không** dùng ô text |
| `boolean` | Công tắc, hiện rõ giá trị mặc định | |
| `integer` / `number` | Ô số, có bước nhảy, kiểm tra biên | |
| `string` có `format: duration` | Ô số + đơn vị (ms/s/phút) | |
| `string` là biểu thức | Trình soạn biểu thức (FR-04-031) | |
| `string` là bí mật | **Chỉ chọn kết nối / tham chiếu Vault**, không ô tự do (FR-04-032) | |
| `object` / `array` | Bảng cặp khóa–giá trị thêm/bớt được | |

Mỗi trường hiện: tiêu đề gốc · mô tả gốc (di chuột) · giá trị mặc định · tên tham số
Camel · dấu bắt buộc · cảnh báo nếu `deprecated`.

### FR-D-023 — Kiểm tra tại chỗ · **M**

Sai kiểu, thiếu bắt buộc, giá trị ngoài `enum` → báo ngay tại trường.
Chân cửa sổ hiện tổng số lỗi. Chặng còn lỗi → huy hiệu đỏ trên node.

### FR-D-024 — Bản tin mẫu và xem trước · **M**

Cột INPUT nhận JSON/XML mẫu (FR-04-033); kế thừa mẫu của chặng trước nếu chặng
hiện tại chưa pin. Biểu thức xem trước ngay trên mẫu đó. Mẫu **không** đi vào định
nghĩa đem triển khai.

---

## 6. D-04 — Chạy thử một luồng

### FR-D-030 — Chạy thử · **M**

| Mục | Nội dung |
|---|---|
| **Đầu vào** | Phiên bản cần chạy · chế độ (MOCK / môi trường thử) · bản tin đầu vào · biến môi trường |
| **Xử lý** | 1. Kiểm tra hợp lệ trước khi chạy, có lỗi chặn thì không gọi<br>2. Gọi API chạy thử của máy chủ<br>3. Nhận kết quả theo từng chặng |
| **Đầu ra** | Waterfall theo chặng: trạng thái · thời gian · độ trễ tích lũy; bấm chặng xem đầu vào/đầu ra |
| **Ngoại lệ** | E1: Máy chủ lỗi → nêu rõ, giữ kết quả lần trước<br>E2: Quá hạn chờ → đánh dấu chặng treo |

### FR-D-031 — Đối chiếu với sơ đồ · **M**

Sau khi chạy, mở D-02 thì sơ đồ tô đường chạy: thành công / lỗi / bỏ qua, kèm số thứ tự.

### FR-D-032 — So sánh nhiều lần chạy · **S**

Chọn hai lần chạy để so thời gian từng chặng — tìm chặng chậm dần.

---

## 7. D-05 — Nhật ký chạy của luồng

> Nghiệp vụ **thiếu hẳn** ở bản trước.

### FR-D-040 — Lưu lịch sử chạy · **M**

| Mục | Nội dung |
|---|---|
| **Xử lý** | Mỗi lần chạy thử ghi một bản ghi: luồng · phiên bản · người chạy · thời điểm · chế độ · kết quả · tổng thời gian · `traceId` · kết quả từng chặng |
| **Đầu ra** | Bảng tra được theo khoảng thời gian, kết quả, người chạy, phiên bản |
| **Ràng buộc** | **Không ghi bí mật và không ghi dữ liệu cá nhân thô** vào nhật ký (CMP-23, FR-04-009) |

### FR-D-041 — Xem lại một lần chạy · **M**

Mở một bản ghi → thấy lại waterfall như lúc vừa chạy, kèm phiên bản định nghĩa
đã dùng. Có `traceId` để đối chiếu với PH-13.

### FR-D-042 — Dọn nhật ký · **S**

Nhật ký chạy thử giữ **90 ngày**, sau đó tự dọn. Số ngày cấu hình được.

---

## 8. D-06 — Duyệt phiên bản

Giữ nguyên `FR-04-029` và bổ sung:

### FR-D-050 — So sánh trước khi quyết định · **M**

Người duyệt **phải** xem được khác biệt giữa phiên bản chờ duyệt và phiên bản đang
chạy trước khi bấm phê duyệt: diff theo dòng, gộp đoạn không đổi, chuyển được sang
xem toàn bộ.

### FR-D-051 — Bốn mắt · **M**

Người tạo phiên bản không được tự duyệt. Chốt chặn ở **máy chủ** (403); giao diện
chỉ ẩn nút cho đỡ bấm nhầm.

---

## 8b. Yêu cầu bổ sung — clone mô hình Kaoto *(thêm 2026-08-06)*

> **Căn cứ.** [IP-07](../08-implementation/07-ke-hoach-clone-kaoto.md) · quyết định của chủ
> dự án 2026-08-05: clone **mô hình hoạt động** của Kaoto, giao diện giữ định hướng riêng.
> Bốn hạng mục thiếu so với Kaoto: quản lý route, Kamelet/Pipe/Test, danh mục, Bean/DataMapper.

### 8b.1. Tệp nhiều thực thể — `FR-D-005…008`

| Mã | Yêu cầu | Ưu tiên |
|---|---|:-:|
| **FR-D-005** | Một tệp chứa **nhiều route**; danh sách thực thể ở thanh bên trái D-02, chuyển qua lại giữ nguyên trạng thái từng sơ đồ | **M** |
| **FR-D-006** | Thêm / xóa / nhân bản route trong tệp | **M** |
| **FR-D-007** | Đổi mã route **cập nhật mọi tham chiếu** `direct:`/`seda:` trỏ tới nó; báo rõ số tham chiếu đã sửa, không đổi lặng lẽ | **M** |
| **FR-D-008** | `routeConfiguration` / `errorHandler` / `onException` cấp tệp | **S** |

**Ngoại lệ FR-D-007.** Chặng tiếp nhận không phải điểm gọi nội bộ (`rest:`, `kafka:`) thì
tên route không phải địa chỉ — không sửa gì, và nói rõ là không có tham chiếu nào đổi.

### 8b.2. Loại tài nguyên — `FR-D-060…064`

| Mã | Yêu cầu | Ưu tiên |
|---|---|:-:|
| **FR-D-060** | Chọn loại khi tạo mới: **Route · Kamelet · Pipe · Test** | **M** |
| **FR-D-061** | **Kamelet**: soạn `spec.definition` (tham số: tên, kiểu, mặc định, bắt buộc, mô tả) + `spec.template.from` | **M** |

> **Kiểu tham số lấy theo dữ liệu vendor, không theo enum lược đồ.** Enum của
> `KameletConfiguration.kameletProperties` là `string|number|boolean` — **sai cả hai đầu**:
> thiếu `integer` (kiểu phổ biến thứ ba) và có `number` mà **không kamelet gốc nào dùng**.
> Đếm trên 243 kamelet đã vendor: `string` 1256 · `boolean` 316 · `integer` 111 · `binary` 9 ·
> `long` 1. Trình soạn theo con số thật này; có test khóa danh sách với thư mục lược đồ.
| **FR-D-062** | Kamelet tự viết hiện **đầu** tab Kamelet, cạnh 243 kamelet dựng sẵn, có huy hiệu "tự viết" | **S** |
| **FR-D-063** | **Pipe**: `source` → `steps[]` → `sink`; canvas tuyến tính, khóa thao tác rẽ nhánh | **M** |
| **FR-D-064** | **Test**: gắn với một route, khai báo bản tin vào và khẳng định đầu ra | **S** |

> ⚠ **FR-D-064 — bộ chạy chưa có.** Mô hình và kiểm tra đã xong (mỗi ca **bắt buộc có ít
> nhất một khẳng định** — ca không khẳng định gì thì luôn đạt, vận hành tưởng đã kiểm mà
> thực ra không). Nhưng `RoutesService.testRun` hiện **mô phỏng**: dựng waterfall chín chặng
> cố định từ `stage.hashCode()`, **không nạp Camel**. Console nói rõ trạng thái này qua
> `runnerStatus()` thay vì để "PASSED" thành lời hứa sai.

**Ràng buộc dữ liệu.** Loại tài nguyên lưu ở cột riêng `resource_kind`, **không dùng lại**
`route_type` — cột đó mang ngữ nghĩa vận chuyển (`SYNC`/`ASYNC`), khác hẳn ngữ nghĩa loại tệp.

### 8b.3. Danh mục thành phần (D-07) — `FR-D-070…073`

> **Hai con số, đừng lẫn.** Chỉ mục có **751 nút** (số dùng cho bảng thành phần và D-07),
> nhưng chỉ **742 tệp lược đồ** trên đĩa: **9 kamelet không có tham số cấu hình** nên nhà
> sản xuất không phát hành lược đồ cho chúng (`dns-*-action`, `json-serialize-action`…).
> Chúng vẫn là mục hợp lệ trong danh mục — màn chi tiết phải hiện "không có tham số cấu
> hình" thay vì báo lỗi tải lược đồ.

| Mã | Yêu cầu | Ưu tiên |
|---|---|:-:|
| **FR-D-070** | Duyệt toàn bộ **751 nút** đã vendor, tab theo loại, lọc nhãn gốc có số đếm | **M** |
| **FR-D-071** | Tìm kiếm có xếp hạng, **ảo hóa** danh sách (ngưỡng NFR-D-02) | **M** |
| **FR-D-072** | Trang chi tiết: mô tả gốc, bảng thuộc tính theo nhóm, cú pháp URI, mức hỗ trợ, cảnh báo `deprecated`, **phụ thuộc Maven** | **M** |
| **FR-D-073** | Hiện rõ **nguồn và giấy phép** catalog (Apache-2.0, `camel-quarkus/3.35.0`) — nghĩa vụ tuân thủ | **M** |

> **Đường dẫn là `/components`, không phải `/catalog`.** `/catalog` đã là màn đăng ký và
> publish dịch vụ APISIX của PH-02 — cùng chữ "catalog" nhưng hai nghiệp vụ khác hẳn nhau.
>
> **Phụ thuộc của FR-D-072 có hai dạng, không gộp.** `component` mang tọa độ Maven đầy đủ
> (`groupId`/`artifactId`/`version`) → hiện khối `<dependency>` dán thẳng vào `pom.xml`.
> `kamelet` **không** có tọa độ riêng, chỉ khai phụ thuộc logic dạng `camel:aws2-s3` mà
> Camel tự phân giải — hiện nhầm dạng sẽ dẫn người dùng đi thêm artifact không tồn tại.
>
> **Thêm cảnh báo native.** 65/323 component chưa chạy được ở ảnh native, trong khi
> ADR-002/020 chốt Camel Quarkus native. Màn phải cảnh báo lúc *tra cứu*, không để người
> dùng phát hiện lúc build hỏng. Phân biệt "có extension nhưng native chưa chạy" với
> "không áp dụng" — gộp lại là cảnh báo nhầm cho toàn bộ pattern/dataformat/language.

### 8b.4. Bean, Metadata, DataMapper (D-08) — `FR-D-080…085`

| Mã | Yêu cầu | Ưu tiên |
|---|---|:-:|
| **FR-D-080** | **Bean registry** cấp tệp: `name`, `type`, `properties` | **M** |
| **FR-D-081** | Trường nhận bean hiện **Select** các bean đã khai, không bắt gõ tay `#beanName` | **S** |
| **FR-D-082** | **Metadata** cho Kamelet/Pipe: `name`, `labels`, `annotations` | **S** |
| **FR-D-083** | **DataMapper**: ba cột nguồn │ ánh xạ │ đích; ánh xạ 1–1 và **nhiều–1** (ghép) | **M** |
| **FR-D-084** | Thư viện hàm biến đổi: chuỗi (cắt/hoa/thường), số, giá trị mặc định | **S** |
| **FR-D-085** | Xem trước ánh xạ trên bản tin mẫu, **nói rõ nơi chạy** | **M** |

### Kiến trúc DataMapper — sửa 2026-08-07

**Sinh biểu thức JQ**, không nhúng AtlasMap. Đây là **thay đổi so với quyết định Q4** của
chủ dự án, dựa trên ba điều đo được trên chính mã dự án:

1. **Dự án đã có cơ chế ánh xạ chạy được, và không phải AtlasMap.** [ADR-013](../05-adr/README.md#adr-013)
   chốt CDM làm trung gian; `contracts/cdm/mappers/*.jq` là bộ ánh xạ; `CdmMapperTest` chứng
   minh nó chạy trên Camel thật. Thêm AtlasMap là **cơ chế ánh xạ thứ hai** song song —
   hai nguồn sự thật cho cùng một việc.
2. **Vấn đề thật là ánh xạ viết tay bằng Java.** `LegacyCitizenToPersonMapper` là 60 dòng
   Java cho ánh xạ 4 trường, còn tệp `.jq` cạnh nó chỉ là tài liệu — hai bản trôi khỏi nhau
   lúc nào không biết. Sinh JQ xóa hẳn lớp viết tay đó.
3. `atlasmap-runtime` **không có trong kho Maven offline**, không kiểm chứng được.

**Bằng chứng.** JQ sinh ra chạy bằng `jq` cho kết quả **giống hệt**
`legacy-citizen-to-person.jq` thật trên đúng bản tin mẫu của `CdmMapperTest`.

**FR-D-085 — nới so với bản đầu.** Bản đầu cấm mô phỏng ở trình duyệt vì "kết quả sẽ lệch".
Lý do đó vẫn đúng, nhưng engine máy chủ **chưa có** mà người dùng vẫn cần thấy ngay mình
ánh xạ đúng chưa. Nên: vẫn xem trước ở trình duyệt, **và dán nhãn đúng sự thật** — giấu
chuyện nó là mô phỏng mới là điều nguy hiểm, không phải bản thân việc mô phỏng.

**Chưa làm.** Ánh xạ **1–nhiều** (tách một nguồn ra nhiều đích) — cần cú pháp riêng cho
từng đích, để lại khi có ca dùng thật. Engine chạy thật ở máy chủ (`camel-quarkus-jq`) chờ
đợt có mạng.

**Giữ nguyên BR-D-02.** Bean **không** chứa bí mật — chỉ tham chiếu Vault / kết nối PH-05.

---

## 9. Yêu cầu phi chức năng

| Mã | Yêu cầu | Ngưỡng |
|---|---|---|
| **NFR-D-01** | Mở bảng thành phần 751 nút | < 300 ms |
| **NFR-D-02** | Gõ tìm kiếm trong bảng thành phần | < 50 ms mỗi lần gõ |
| **NFR-D-03** | Mở cửa sổ cấu hình (kể cả node 154 thuộc tính) | < 400 ms |
| **NFR-D-04** | Kéo node trên sơ đồ 200 chặng | ≥ 30 khung hình/giây |
| **NFR-D-05** | Sinh YAML sau mỗi thay đổi | < 100 ms |
| **NFR-D-06** | Bề rộng hỗ trợ | 1024–2560px không vỡ bố cục |
| **NFR-D-07** | Điều hướng bàn phím | Mọi chức năng chính dùng được không cần chuột |
| **NFR-D-08** | Tương phản màu | Đạt WCAG 2.1 AA |

---

## 10. Ràng buộc nghiệp vụ

| Mã | Ràng buộc |
|---|---|
| **BR-D-01** | Khung chuẩn là **mẫu gỡ được** lúc thiết kế; **bắt buộc lúc publish** với luồng đối ngoại — xem §10.1 |
| **BR-D-02** | Không lưu bí mật trong định nghĩa luồng — chỉ tham chiếu Vault / kết nối PH-05 |
| **BR-D-03** | Bản tin mẫu không đi vào định nghĩa đem triển khai |
| **BR-D-04** | YAML sinh ra **phải nạp được bằng Camel thật** — điều kiện nghiệm thu bắt buộc |
| **BR-D-04b** | YAML quay vòng (mở → lưu) **không được mất dữ liệu**: giữ nguyên biểu thức, cấu trúc lồng và comment — xem §10.2 |
| **BR-D-05** | Còn lỗi kiểm tra thì không gửi duyệt được |
| **BR-D-06** | Mọi thay đổi trạng thái luồng ghi nhật ký kiểm toán |

### 10.1. BR-D-01 — sửa 2026-08-06 *(trước đây: "không gỡ được")*

**Phát biểu mới.** Bốn chặng khung chuẩn là **mẫu khởi tạo**, người dùng gỡ được.
`validate` phát **cảnh báo** chứ không chặn. Chốt chặn thật nằm ở **máy chủ lúc publish**,
và chỉ áp cho **luồng đối ngoại**.

**Lý do sửa.** Mức "lỗi chặn" khiến không dựng nổi luồng trắng — mà Kamelet và Pipe thì
**về cấu trúc không thể** có bốn chặng này (Kamelet là mảnh dùng lại, Pipe là nối
nguồn–đích). Giữ nguyên ràng buộc cũ đồng nghĩa loại bỏ hai loại tài nguyên đó.

**Định nghĩa "luồng đối ngoại".** Luồng có `source_system` khớp `system_code` của một hồ
sơ kết nạp ở trạng thái `APPROVED`/`ACTIVE` trong PH-01. Luồng nội bộ (nối hai route bằng
`direct:`/`seda:`, tiện ích, thử nghiệm) chỉ nhận cảnh báo.

> ⚠ **Trạng thái thi hành.** Cơ chế đã có (`CamelYamlValidator` + cờ
> `lgsp.routes.strict-standard-stages`), **mặc định tắt**. Bốn luồng hiện có trong CSDL đều
> là luồng thử, `source_system` (`at-src`, `console`, `src`) không khớp hồ sơ kết nạp nào.
>
> **Cách nối với PH-01.** PH-01 phát sự kiện khi duyệt kết nạp; PH-04 nghe và giữ **bản sao
> đọc** ở `ph04.external_system`. Không gọi thẳng `OnboardingApi` vì cả hai mô-đun đều khai
> `allowedDependencies = "shared"` — kiến trúc cố ý giữ chúng độc lập. Bản sao là **cuối
> cùng sẽ nhất quán**; hệ thống vừa kết nạp có thể chậm một nhịp, hệ quả xấu nhất là cảnh
> báo thay vì chặn (nới lỏng chứ không siết nhầm). Hệ thống kết nạp trước khi có cơ chế này
> được nạp lại một lần bằng changeset — thiếu bước đó thì chốt chặn thả lọt đúng những luồng
> lâu đời nhất. Chi tiết: [IP-07 K1-7c](../08-implementation/07-ke-hoach-clone-kaoto.md).

### 10.2. BR-D-04b — vì sao BR-D-04 một mình không đủ

Ba lỗi mất dữ liệu thật, phát hiện 2026-08-05/06 bằng cách quay vòng chính các tệp trong
`routes/` (chi tiết: [IP-07](../08-implementation/07-ke-hoach-clone-kaoto.md)):

| Lỗi | Hệ quả |
|---|---|
| `setBody: {constant: "x"}` → `expression: {}` | **Thân bản tin biến mất** |
| `doTry`/`loadBalance`/`multicast`/`split` → khối rỗng | **Mất cả nhánh xử lý lỗi** |
| Comment xuất xứ `# routeCode=… version=…` bị thay bằng banner | **Mất dấu vết kiểm toán** (BR-D-06) |

Cả ba đều **im lặng** và YAML sinh ra **vẫn nạp được bằng Camel** — nên BR-D-04 không bắt
được. Bài học: "route khởi động được" **không** phải bằng chứng đủ; phải chứng minh bản tin
đi đúng nhánh và giá trị còn nguyên.

---

## 11. Ma trận màn ↔ yêu cầu

| Màn | FR |
|---|---|
| D-01 | FR-D-001…004 · FR-04-020/021/022 |
| D-02 | FR-D-010…013 · **FR-D-005…008** · **FR-D-060…064** · FR-04-026/027/034/038/039/040 |
| D-03 | FR-D-020…024 · FR-04-031/032/033/037 |
| D-04 | FR-D-030…032 · FR-04-028/035 |
| D-05 | FR-D-040…042 · FR-04-025 |
| D-06 | FR-D-050/051 · FR-04-029 |
| D-07 | FR-D-070…073 |
| D-08 | FR-D-080…085 |

---

## 12. Lịch sử

| Ngày | Thay đổi |
|---|---|
| 2026-08-07 | **Sửa theo thực tế thi công.** (1) **Kiến trúc DataMapper**: sinh **JQ** thay vì nhúng AtlasMap — lệch khỏi Q4, ba căn cứ đo trên mã thật ghi ở §8b.4; JQ sinh ra cho kết quả **giống hệt** mapper thật của repo. (2) **FR-D-085 nới**: vẫn xem trước ở trình duyệt nhưng **dán nhãn đúng sự thật** — engine máy chủ chưa có mà người dùng vẫn cần thấy ngay mình ánh xạ đúng chưa; giấu chuyện nó là mô phỏng mới nguy hiểm. (3) **FR-D-064**: ghi rõ bộ chạy Test **chưa có** — `testRun` đang mô phỏng, không nạp Camel. (4) **FR-D-061**: kiểu tham số Kamelet lấy theo dữ liệu 243 kamelet vendor thật dùng, không theo enum lược đồ vốn thiếu `integer` và thừa `number` |
| 2026-08-06 | **Cập nhật theo IP-07 (clone mô hình Kaoto).** (1) **Sửa BR-D-01**: khung chuẩn từ "không gỡ được" thành mẫu gỡ được lúc thiết kế, bắt buộc lúc publish với luồng đối ngoại — ràng buộc cũ loại bỏ hẳn Kamelet/Pipe vốn về cấu trúc không thể có bốn chặng đó; định nghĩa "đối ngoại" bám `system_code` của hồ sơ kết nạp PH-01 (§10.1). (2) **Thêm BR-D-04b**: quay vòng YAML không được mất dữ liệu — ba lỗi mất dữ liệu thật đã phát hiện đều *im lặng* và YAML vẫn nạp được bằng Camel, nên BR-D-04 một mình không bắt được (§10.2). (3) Thêm **FR-D-005…008** (tệp nhiều route), **FR-D-060…064** (Kamelet/Pipe/Test), **FR-D-070…073** (danh mục D-07), **FR-D-080…085** (Bean/Metadata/DataMapper D-08) và hai màn **D-07**, **D-08** |
| 2026-08-04 | Khởi tạo — tách sáu màn theo nhiệm vụ, chuẩn hóa cửa sổ cấu hình 75%, bổ sung nghiệp vụ nhật ký chạy (D-05) còn thiếu, đặt ngưỡng phi chức năng theo số liệu catalog thật |
