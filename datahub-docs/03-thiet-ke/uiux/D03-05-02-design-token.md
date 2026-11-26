---
ma_tai_lieu: D03-05-02
ten: Design token và ánh xạ sang Ant Design v6
phien_ban: 0.3
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư giao diện, Nhà thiết kế, Kiểm thử viên, AI agent sinh mã
mo_ta: Đặc tả design token của Datahub gồm kiến trúc ba tầng, màu, vật liệu glass, bo góc, bóng, khoảng cách, chữ, chuyển động, ánh xạ sang Ant Design v6, đóng gói, kiểm tra tự động và giới hạn tùy biến theo tenant.
tai_lieu_lien_quan: ADR-020 Liquid Glass trên antd v6; ADR-021 Phông chữ; D00-01 Thuật ngữ và quy ước; D02-02 SRS; D03-05 Design system; D03-05-01 Vật liệu Liquid Glass; D03-05-03 Thành phần nguyên tử; D03-05-04 Thành phần phức hợp; D03-06-PH07 Màn hình danh mục
nguoi_lap: Luồng giao diện
---

# D03-05-02 · Design token và ánh xạ sang Ant Design v6

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Mọi màu, độ trong suốt, độ nhòe, bo góc, đổ bóng, khoảng cách, cỡ chữ và thời lượng chuyển động của giao diện đều đến từ một token được định nghĩa một lần, để nhà thiết kế, kỹ sư và kiểm thử viên cùng dùng một tên và một giá trị. Tài liệu là hợp đồng giá trị của design system, kèm ánh xạ sang Ant Design v6 và đoạn mã `ConfigProvider` dùng ngay, nhờ đó mockup, Storybook và ứng dụng thật không thể lệch nhau.

**Phạm vi.** Tài liệu gồm kiến trúc ba tầng token (chương 2), bảng màu gốc và token màu ngữ nghĩa (chương 3, 4), token vật liệu glass và độ nhòe (chương 5, 6), bo góc, bóng, khoảng cách, chữ, chuyển động, kích thước, lớp chồng, điểm ngắt, mật độ (chương 7 đến 12), ánh xạ sang antd v6 kèm mã tham chiếu (chương 13), đóng gói, kiểm tra tự động và tùy biến theo tenant (chương 14 đến 16). Quy tắc đặt kính nằm ở D03-05-01; đặc tả thành phần nằm ở D03-05-03, D03-05-04.

**Căn cứ.** STD-04 (WCAG 2.2, mức AA: tương phản chữ 4,5:1, phần tử đồ họa 3:1, vùng chạm tối thiểu 24×24 px); NFR-00-040, NFR-00-041, NFR-00-043, NFR-00-044, NFR-00-045 và FR-00-053 của SRS; ADR-020 (Liquid Glass trên antd v6) và ADR-021 (phông chữ Inter, JetBrains Mono).

**Những điểm hội đồng cần lưu ý.** (1) Giá trị tương phản được tính bằng tập lệnh theo công thức độ chói tương đối của WCAG 2.2, không ước lượng bằng mắt, và chạy lại trong CI mỗi khi đổi token. (2) Độ đục của bốn vật liệu glass được chọn theo trường hợp xấu nhất; những cặp chữ không đạt (ví dụ chữ liên kết trên `glass-chrome`) bị cấm đặt trực tiếp lên vật liệu đó. (3) Màu luôn đi kèm chữ hoặc ký hiệu, không dùng màu làm kênh duy nhất, kể cả màu khác biệt và màu nguồn dữ liệu. (4) Tenant chỉ được chọn một trong sáu bộ màu nhấn đã kiểm định, không nhập mã màu tự do, và màu trạng thái không đổi theo tenant. (5) Một tệp nguồn `tokens.json` sinh cả CSS variables lẫn đối tượng `theme` của antd, và CI chặn giá trị màu, cỡ, bo góc, bóng, `z-index` viết tay.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Tầng token | 3 (gốc, ngữ nghĩa, thành phần) |
| Vật liệu glass | 4, mỗi vật liệu có tương phản xấu nhất ghi trong bảng ở mục 5 |
| Màu chữ chính trên nút nhấn | 5,38:1 (chữ trắng trên `#0A66D8`) |
| Màu biểu đồ phân loại | 8, mỗi màu đạt ít nhất 3:1 với bề mặt đặc (mục 4.5) |
| Token màu khác biệt và màu nguồn | 4 màu khác biệt và 4 màu nguồn dữ liệu (mục 4.6) |
| Bộ màu nhấn cho tenant | 6 (mục 16) |
| Thang khoảng cách | Cơ sở 4 px |
| Phiên bản antd đã đối chiếu | 6.7.1 |
| Kiểm tra tự động trên mỗi PR đổi token | 4 (mục 15) |

: Con số chính của đặc tả design token

Các con số trên được lấy từ chương 2, 4, 5, 13, 15 và 16 của tài liệu này.

## 1. Mục đích và cách dùng tài liệu

Tài liệu này là **hợp đồng giá trị** của design system Datahub. Mọi màu, độ trong suốt, độ nhòe, bo góc, đổ bóng, khoảng cách, cỡ chữ, thời lượng chuyển động mà giao diện dùng đều phải đến từ một token được định nghĩa ở đây. Nhà thiết kế dùng cùng tên token trong tệp thiết kế, kỹ sư giao diện dùng tên đó trong mã, kiểm thử viên dùng bảng tương phản ở mục 4 để nghiệm thu NFR-00-041. Không có giá trị nào được "chép tay" vào thành phần (NFR-00-045).

Tài liệu gồm ba phần. Phần thứ nhất (mục 2 đến 12) định nghĩa token theo nhóm, mỗi token có giá trị ở chế độ sáng và chế độ tối. Phần thứ hai (mục 13) ánh xạ token sang hệ token của Ant Design v6 và cung cấp đoạn mã `ConfigProvider` có thể dùng ngay. Phần thứ ba (mục 14 đến 16) quy định cách đóng gói, kiểm tra tự động và giới hạn tùy biến theo tenant.

Các giá trị tương phản trong tài liệu được tính theo công thức độ chói tương đối của WCAG 2.2 bằng một tập lệnh kiểm tra, không ước lượng bằng mắt. Mỗi khi đổi giá trị token, tập lệnh này phải chạy lại trong CI (mục 15).

### 1.1. Mục đích của tài liệu

Tài liệu là nguồn chuẩn duy nhất về giá trị thị giác của design system. Hội đồng thẩm định dùng bảng tương phản để đánh giá NFR-00-041. Nhà thiết kế và kỹ sư dùng cùng tên token trong tệp thiết kế và trong mã; kiểm thử viên dùng chương 15 để nghiệm thu kiểm tra tự động.

### 1.2. Phạm vi

Bảng dưới phân định điều tài liệu này quy định và điều nằm ở tài liệu khác.

| Thuộc tài liệu này | Nằm ở tài liệu khác |
|---|---|
| Giá trị màu, glass, bo góc, bóng, khoảng cách, chữ, chuyển động, kích thước | Quy tắc đặt kính, cấu tạo CSS, chế độ hiển thị, hạ cấp: D03-05-01 |
| Ánh xạ sang antd v6 và mã `ConfigProvider` tham chiếu | Đặc tả hành vi, API từng thành phần: D03-05-03, D03-05-04 |
| Đóng gói token, kiểm tra tự động, giới hạn tùy biến theo tenant | Màn hình quản trị tenant: tập phân hệ PH-20 |
| Lý do chọn phông chữ ở mức tóm tắt | Quyết định phông chữ đầy đủ: ADR-021 |

: Phân định phạm vi giữa D03-05-02 và các tài liệu liên quan

### 1.3. Người đọc và cách đọc

Bảng dưới gợi ý phần cần đọc theo vai trò.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 4, 5, 16 | Đánh giá tương phản, vật liệu glass, giới hạn tùy biến theo tenant |
| Kỹ sư giao diện | Chương 2, 13, 14, 15 | Dùng token đúng tầng, cấu hình antd, đóng gói, lint |
| Nhà thiết kế | Chương 3 đến 12 | Dùng đúng tên token trong tệp thiết kế |
| Kiểm thử viên | Chương 4, 5, 15 | Nghiệm thu tương phản, kiểm tra tự động |
| AI agent sinh mã | Chương 2, 4, 13 | Chỉ dùng token ngữ nghĩa, không dùng giá trị thô |

: Người đọc D03-05-02 và phần cần đọc theo vai trò

### 1.4. Thuật ngữ và chữ viết tắt

Bảng dưới chỉ gồm thuật ngữ riêng của design token. Thuật ngữ chung theo D00-01 §2.

| Thuật ngữ | Giải thích |
|---|---|
| Token gốc (primitive) | Màu có tên trung lập như `blue-600`; thành phần không dùng trực tiếp |
| Token ngữ nghĩa (semantic) | Token đặt tên theo vai trò như `color-text-primary`; đổi giá trị giữa sáng và tối |
| Token thành phần (component) | Giá trị riêng của một thành phần như `table-row-height`; luôn tham chiếu token ngữ nghĩa |
| `--dh-*` | Tiền tố CSS variable do `@datahub/tokens` sinh ra |
| `TKN-*` | Mã truy vết của token, ví dụ `TKN-color-text-primary` |
| DTCG | Định dạng Design Tokens Community Group của tệp `tokens.json` |
| Tint | Lớp màu bán trong suốt của vật liệu glass |
| Bo góc đồng tâm | Quy tắc bán kính góc trong bằng bán kính góc ngoài trừ khoảng đệm |
| Seed, Map, Alias token | Ba lớp token toàn cục của antd v6 |

: Thuật ngữ riêng của design token

### 1.5. Tài liệu tham chiếu

Các tài liệu dưới đây được dẫn chiếu trong D03-05-02.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| STD-04 | WCAG 2.2 | Ngưỡng tương phản, vùng chạm |
| ADR-020, ADR-021 | Liquid Glass trên antd v6; phông chữ | Lý do chọn vật liệu và phông chữ |
| D00-01 | Thuật ngữ và quy ước | §6 quy ước đặt tên token |
| D02-02 | Đặc tả yêu cầu phần mềm (SRS) | NFR-00-040…045, FR-00-053 |
| D03-05 | Design system (tài liệu tổng) | Nguyên tắc, thứ tự ưu tiên giữa các tập |
| D03-05-01 | Vật liệu Liquid Glass | Quy tắc đặt kính dùng token chương 5 |
| D03-05-03, D03-05-04 | Thành phần nguyên tử, phức hợp | Thành phần dùng token |
| D03-06-PH07 | Màn hình danh mục | Nguồn đề nghị token màu khác biệt và màu nguồn dữ liệu |

: Tài liệu tham chiếu của D03-05-02

### 1.6. Cấu trúc tài liệu

Tài liệu đi từ kiến trúc token tới giá trị theo nhóm, rồi ánh xạ, đóng gói và kiểm tra. Bảng dưới tóm tắt từng chương.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 2 | Kiến trúc ba tầng token | Kỹ sư, nhà thiết kế |
| 3, 4 | Bảng màu gốc, token màu ngữ nghĩa, bảng tương phản | Nhà thiết kế, kiểm thử viên, hội đồng |
| 5, 6 | Token vật liệu glass, độ nhòe và độ trong | Kỹ sư, kiểm thử viên |
| 7 đến 11 | Bo góc, bóng, khoảng cách, chữ, chuyển động | Nhà thiết kế, kỹ sư |
| 12 | Kích thước, lớp chồng, điểm ngắt, mật độ | Kỹ sư |
| 13 | Ánh xạ sang antd v6, mã cấu hình tham chiếu | Kỹ sư, AI agent |
| 14, 15 | Đóng gói token, kiểm tra tự động | Kỹ sư, kiểm thử viên |
| 16 | Tùy biến theo tenant | Hội đồng, quản trị nền tảng |
| 17 | Truy vết | Quản lý chất lượng |

: Cấu trúc chương của D03-05-02

## 2. Kiến trúc ba tầng token

Token được tổ chức thành ba tầng. Tầng dưới cùng là **token gốc (primitive)**: bảng màu có tên trung lập như `blue-600`, `gray-900`; tầng này không bao giờ được thành phần dùng trực tiếp. Tầng giữa là **token ngữ nghĩa (semantic)**: tên mô tả vai trò như `color-text-primary`, `color-surface-solid`, `glass-chrome-tint`; đây là tầng mà thành phần dùng, và là tầng duy nhất thay đổi giá trị giữa sáng và tối. Tầng trên cùng là **token thành phần (component)**: giá trị riêng cho một thành phần, như chiều cao hàng bảng, độ rộng sidebar; tầng này luôn tham chiếu token ngữ nghĩa chứ không tham chiếu token gốc.

```{.mermaid caption="Kiến trúc ba tầng token"}
flowchart LR
  P[Token gốc<br/>blue-600, gray-900, white-a72] --> S[Token ngữ nghĩa<br/>color-text-primary<br/>glass-chrome-tint]
  S --> C[Token thành phần<br/>table-row-height<br/>sidebar-width]
  S --> A[antd v6 Seed/Map/Alias token<br/>colorPrimary, colorText]
  C --> AC[antd v6 Component token<br/>Table.rowHoverBg]
  S --> V[CSS variables --dh-*]
  C --> V
```

Sơ đồ cho thấy token ngữ nghĩa là điểm hội tụ: cùng một giá trị được phát ra hai đích. Đích thứ nhất là CSS variables `--dh-*`, được lớp vật liệu glass và các thành phần tự viết của `@datahub/ui` dùng. Đích thứ hai là đối tượng `theme` của antd v6, để các thành phần antd hiển thị đúng màu mà không cần CSS ghi đè. Vì hai đích sinh ra từ cùng một tệp nguồn, mockup, Storybook và ứng dụng thật không thể lệch nhau.

Quy ước đặt tên tuân theo D00-01 §6. CSS variable có dạng `--dh-{nhóm}-{vai trò}-{biến thể}`; mã truy vết có dạng `TKN-{nhóm}-{tên}`. Trong các bảng dưới đây, cột "Token" ghi phần tên sau tiền tố; ví dụ token `color-text-primary` có CSS variable `--dh-color-text-primary` và mã truy vết `TKN-color-text-primary`.

## 3. Bảng màu gốc

Bảng màu gốc chỉ dùng để định nghĩa token ngữ nghĩa. Màu chủ đạo là xanh lam "Lam Datahub", được chọn sẫm hơn màu xanh hệ thống của Apple (`#007AFF`) vì màu Apple chỉ đạt 4,02:1 khi đặt chữ trắng lên trên, không đủ ngưỡng 4,5:1 cho chữ thường. Thang xám bám thang xám của Apple nhưng chỉnh lại các nấc giữa để mỗi nấc chữ đều đạt ngưỡng trên mọi nền được phép.

| Nhóm | Nấc | Giá trị | Ghi chú sử dụng |
|---|---|---|---|
| blue | 50 | `#E8F1FC` | Nền nhấn nhẹ, hàng được chọn (sáng) |
| blue | 100 | `#D6E6FA` | Nền hover của vùng chọn |
| blue | 500 | `#1F74E0` | Không dùng cho nền có chữ trắng (chỉ 4,53:1, sát ngưỡng) |
| blue | 600 | `#0A66D8` | Màu chủ đạo; chữ trắng trên nền này đạt 5,38:1 |
| blue | 700 | `#0857BC` | Hover của nút chính (6,77:1) |
| blue | 800 | `#0749A0` | Trạng thái nhấn của nút chính (8,50:1) |
| blue | 300d | `#4C9EFF` | Chữ liên kết và vòng focus ở chế độ tối |
| blue | 900d | `#11233A` | Nền nhấn nhẹ ở chế độ tối |
| gray | 0 | `#FFFFFF` | Bề mặt đặc (sáng) |
| gray | 25 | `#F7F8FA` | Bề mặt đặc cấp hai (sáng) |
| gray | 50 | `#F2F3F7` | Nền canvas (sáng) |
| gray | 100 | `#EEEEF1` | Nền điền của điều khiển (sáng) |
| gray | 200 | `#D9D9DE` | Đường kẻ trang trí (sáng) |
| gray | 400 | `#868690` | Viền điều khiển, đạt 3:1 (sáng) |
| gray | 500 | `#9A9AA2` | Chữ bị vô hiệu (sáng) |
| gray | 600 | `#63636D` | Chữ cấp ba (sáng) |
| gray | 700 | `#4B4B55` | Chữ cấp hai (sáng) |
| gray | 900 | `#1D1D1F` | Chữ chính (sáng), bề mặt Tooltip |
| gray | 950d | `#0E0E10` | Nền canvas (tối) |
| gray | 900d | `#1C1C1E` | Bề mặt đặc (tối) |
| gray | 850d | `#242427` | Bề mặt đặc cấp hai (tối) |
| gray | 800d | `#2C2C2E` | Nền điền của điều khiển (tối) |
| gray | 700d | `#3A3A3E` | Đường kẻ trang trí (tối) |
| gray | 500d | `#7C7C84` | Viền điều khiển (tối) |
| gray | 400d | `#6C6C72` | Chữ bị vô hiệu (tối) |
| gray | 300d | `#A1A1A8` | Chữ cấp ba (tối) |
| gray | 200d | `#C7C7CC` | Chữ cấp hai (tối) |
| gray | 50d | `#F5F5F7` | Chữ chính (tối) |
| green | 700 / 300d | `#1A7F37` / `#3FB950` | Thành công |
| amber | 700 / 300d | `#8A5A00` / `#E3B341` | Cảnh báo (chữ) |
| amber | 500 | `#D4A017` | Cảnh báo (biểu tượng, phần tử đồ họa trên nền sáng chỉ dùng kèm viền) |
| red | 700 / 300d | `#B4232A` / `#FF6B6B` | Lỗi, phá hủy |
| red | 600 | `#C9252D` | Nền nút phá hủy (chữ trắng 5,55:1) |

: Bảng màu gốc theo nhóm, nấc và ghi chú sử dụng

Hậu tố `d` đánh dấu nấc chỉ dùng cho chế độ tối. Việc tách nấc tối riêng thay vì đảo thang sáng là có chủ đích: Apple dùng màu nhấn sáng hơn ở chế độ tối để giữ tương phản trên nền gần đen, và Datahub làm theo cách đó.

## 4. Token màu ngữ nghĩa

### 4.1. Bề mặt và nền

Bảng dưới đây định nghĩa các lớp nền. Thứ tự từ dưới lên là canvas, bề mặt đặc, bề mặt glass. Canvas là nền của toàn ứng dụng và cũng là "phông nền" mà lớp glass của sidebar làm nhòe, nên canvas có thêm một lớp dải màu rất nhẹ (`color-canvas-wash`) để glass có cái để khúc xạ; nếu canvas phẳng tuyệt đối thì glass trông như một mảng xám đục.

| Token | Sáng | Tối | Dùng cho |
|---|---|---|---|
| `color-canvas` | `#F2F3F7` | `#0E0E10` | Nền `body`, vùng nội dung |
| `color-canvas-wash` | `radial-gradient(1200px 600px at 10% -10%, #DCE8FB 0%, transparent 60%), radial-gradient(900px 500px at 100% 0%, #EDE7FB 0%, transparent 55%)` | `radial-gradient(1200px 600px at 10% -10%, #10233F 0%, transparent 60%), radial-gradient(900px 500px at 100% 0%, #1E1530 0%, transparent 55%)` | Lớp phủ trang trí trên canvas, cố định theo viewport |
| `color-surface-solid` | `#FFFFFF` | `#1C1C1E` | Thẻ, bảng, biểu mẫu, log, vùng nội dung trong Modal |
| `color-surface-solid-2` | `#F7F8FA` | `#242427` | Hàng tiêu đề bảng, vùng phụ trong thẻ, khối mã |
| `color-fill-control` | `#EEEEF1` | `#2C2C2E` | Nền điều khiển kiểu "filled", track của Segmented, Switch tắt |
| `color-fill-hover` | `rgba(0,0,0,0.04)` | `rgba(255,255,255,0.06)` | Lớp phủ khi rê chuột lên hàng, mục menu |
| `color-fill-pressed` | `rgba(0,0,0,0.08)` | `rgba(255,255,255,0.10)` | Lớp phủ khi nhấn |
| `color-fill-selected` | `#E8F1FC` | `#11233A` | Hàng được chọn, mục menu đang chọn |
| `color-fill-selected-hover` | `#D6E6FA` | `#16304F` | Rê chuột lên mục đang chọn |
| `color-scrim` | `rgba(15,17,21,0.32)` | `rgba(0,0,0,0.56)` | Lớp che phía sau Modal, Drawer |
| `color-surface-inverse` | `#1D1D1F` | `#F5F5F7` | Nền Tooltip, Toast |
| `color-text-on-inverse` | `#F5F5F7` | `#1D1D1F` | Chữ trên nền đảo |

: Token bề mặt và nền theo chế độ sáng, tối

### 4.2. Chữ và biểu tượng

Có bốn nấc chữ. Nấc cấp ba vẫn đạt 4,5:1 trên mọi nền đặc nên được dùng cho chữ giữ chỗ (placeholder), chú thích và nhãn phụ. Chỉ nấc "vô hiệu" được phép dưới ngưỡng, vì WCAG miễn yêu cầu tương phản cho thành phần bị vô hiệu hóa.

| Token | Sáng | Tối | Tương phản trên canvas / surface / surface-2 (sáng) | (tối) |
|---|---|---|---|---|
| `color-text-primary` | `#1D1D1F` | `#F5F5F7` | 15,18 / 16,83 / 15,84 | 17,71 / 15,63 / 14,22 |
| `color-text-secondary` | `#4B4B55` | `#C7C7CC` | 7,77 / 8,62 / 8,11 | 11,45 / 10,10 / 9,19 |
| `color-text-tertiary` | `#63636D` | `#A1A1A8` | 5,36 / 5,94 / 5,59 | 7,51 / 6,63 / 6,03 |
| `color-text-disabled` | `#9A9AA2` | `#6C6C72` | 2,52 / 2,79 / 2,63 (được miễn) | 3,70 / 3,26 / 2,97 (được miễn) |
| `color-text-link` | `#0A66D8` | `#4C9EFF` | 4,85 / 5,38 / 5,06 | 7,02 / 6,19 / 5,63 |
| `color-text-on-accent` | `#FFFFFF` | `#FFFFFF` | Trên `color-accent` 5,38 | 5,38 |
| `color-icon-primary` | `#1D1D1F` | `#F5F5F7` | Như chữ chính | |
| `color-icon-secondary` | `#63636D` | `#A1A1A8` | ≥ 3:1 theo ngưỡng phần tử đồ họa | |

: Token màu chữ và biểu tượng theo chế độ sáng, tối

### 4.3. Nhấn, viền và focus

Màu nhấn, viền điều khiển và vòng focus quyết định khả năng nhận biết thành phần tương tác. Bảng dưới đặt giá trị ở hai chế độ kèm lý do chọn để giữ tương phản chữ trắng trên nền nhấn.

| Token | Sáng | Tối | Ghi chú |
|---|---|---|---|
| `color-accent` | `#0A66D8` | `#0A66D8` | Nền nút chính, thanh tiến độ, Switch bật. Giữ nguyên ở chế độ tối để chữ trắng vẫn đạt 5,38:1 |
| `color-accent-hover` | `#0857BC` | `#1F74E0` | Tối: 4,53:1 với chữ trắng, chấp nhận vì là trạng thái tạm thời và chữ nút đậm 500 |
| `color-accent-pressed` | `#0749A0` | `#0749A0` | |
| `color-accent-subtle` | `#E8F1FC` | `#11233A` | Nền nhãn thông tin, nền nút "tinted" |
| `color-accent-on-subtle` | `#0A66D8` | `#4C9EFF` | Chữ trên nền nhấn nhẹ: 4,72 / 5,77 |
| `color-border-control` | `#868690` | `#7C7C84` | Viền ô nhập, Checkbox, Radio: đạt 3:1 (WCAG 1.4.11) |
| `color-border-subtle` | `#D9D9DE` | `#3A3A3E` | Đường kẻ phân cách, viền thẻ: chỉ trang trí, không mang thông tin |
| `color-border-glass-highlight` | `rgba(255,255,255,0.65)` | `rgba(255,255,255,0.14)` | Viền sáng phía trên của vật liệu glass (mép phản quang) |
| `color-border-glass-edge` | `rgba(0,0,0,0.08)` | `rgba(0,0,0,0.60)` | Đường viền ngoài mảnh của vật liệu glass |
| `color-focus-ring` | `#0A66D8` | `#4C9EFF` | Vòng focus 2px, cách thành phần 2px; 5,38 / 6,19 trên bề mặt |
| `color-focus-ring-inner` | `#FFFFFF` | `#0E0E10` | Vòng trong 2px tạo viền kép, đảm bảo 3:1 trên mọi nền kể cả nền nhấn |

: Token màu nhấn, viền và vòng focus theo chế độ sáng, tối

Viền kép của focus (một vòng màu nhấn bên ngoài, một vòng nền bên trong) là cách bảo đảm vòng focus đạt 3:1 dù thành phần nằm trên nền trắng, nền nhấn xanh hay nền glass. Đây là yêu cầu của NFR-00-041 cho "vòng focus ≥ 3:1".

### 4.4. Trạng thái

Mỗi trạng thái có bốn token: màu chữ dùng trên nền đặc, màu nền nhẹ, màu chữ trên nền nhẹ và màu đậm cho biểu tượng hoặc nền đặc. Thành phần `CMP-StatusTag` luôn dùng cặp "nền nhẹ + chữ trên nền nhẹ" nên tương phản không phụ thuộc lớp nền phía dưới, kể cả khi nhãn nằm trong một popover glass.

| Trạng thái | `…-text` (sáng / tối) | `…-bg` (sáng / tối) | `…-on-bg` (sáng / tối) và tương phản | `…-solid` |
|---|---|---|---|---|
| `color-success` | `#1A7F37` / `#3FB950` | `#E8F5EC` / `#12261A` | `#1A7F37` 4,52 / `#3FB950` 6,27 | `#1A7F37` |
| `color-warning` | `#8A5A00` / `#E3B341` | `#FFF4D6` / `#2B2111` | `#8A5A00` 5,41 / `#E3B341` 8,12 | `#D4A017` (biểu tượng, luôn kèm viền tối) |
| `color-error` | `#B4232A` / `#FF6B6B` | `#FDECEC` / `#2D1517` | `#B4232A` 5,72 / `#FF6B6B` 6,15 | `#C9252D` (nền nút phá hủy, chữ trắng 5,55) |
| `color-info` | `#0A66D8` / `#4C9EFF` | `#E8F1FC` / `#11233A` | `#0A66D8` 4,72 / `#4C9EFF` 5,77 | `#0A66D8` |
| `color-neutral` | `#4B4B55` / `#C7C7CC` | `#EEEEF1` / `#2A2A2E` | `#4B4B55` 7,44 / `#C7C7CC` 8,49 | `#63636D` |

: Token màu trạng thái theo bốn vai trò

Ánh xạ trạng thái vòng đời nghiệp vụ sang năm sắc thái trên (ví dụ "Đã công bố" là success, "Tạm dừng" là warning, "Thu hồi" là error, "Bản nháp" là neutral, "Chờ duyệt" là info) được quy định một lần ở `CMP-StatusTag` (D03-05-03) để mọi phân hệ dùng chung (FR-00-053).

### 4.5. Bảng màu biểu đồ

Biểu đồ dùng bảng màu phân loại tám màu. Mỗi màu đạt tối thiểu 3:1 với bề mặt đặc tương ứng (ngưỡng phần tử đồ họa), trừ màu thứ năm ở chế độ sáng chỉ đạt 3,25:1 nên được xếp cuối thứ tự sử dụng ưu tiên. Biểu đồ không bao giờ chỉ dựa vào màu: chuỗi dữ liệu luôn có nhãn trực tiếp hoặc chú giải kèm ký hiệu hình dạng (D03-05-04, `CMP-Chart`).

| Thứ tự | Token | Sáng (trên `#FFFFFF`) | Tối (trên `#1C1C1E`) |
|---|---|---|---|
| 1 | `color-chart-1` | `#0A66D8` 5,38 | `#4C9EFF` 6,19 |
| 2 | `color-chart-2` | `#0E8A7E` 4,24 | `#2DD4BF` 9,14 |
| 3 | `color-chart-3` | `#C2410C` 5,18 | `#FB923C` 7,52 |
| 4 | `color-chart-4` | `#7C3AED` 5,70 | `#A78BFA` 6,25 |
| 5 | `color-chart-5` | `#BE185D` 6,04 | `#F472B6` 6,42 |
| 6 | `color-chart-6` | `#4D7C0F` 4,99 | `#A3E635` 11,28 |
| 7 | `color-chart-7` | `#5B6474` 5,97 | `#A1A1AA` 6,64 |
| 8 | `color-chart-8` | `#B8860B` 3,25 | `#FACC15` 11,11 |

: Bảng màu biểu đồ tám màu phân loại

### 4.6. Màu khác biệt và màu nguồn dữ liệu

Hai nhóm token dưới đây được bổ sung ở bản 0.2 theo đề nghị của tập màn hình PH-07 (D03-06-PH07 Phụ lục A-02, A-03) và dùng chung cho mọi màn so sánh phiên bản (`CMP-DiffTable`, `CMP-EditableTable`, `CMP-FlowNode` ở chế độ khác biệt). Mỗi cặp nền nhẹ và chữ trên nền nhẹ đạt 4,5:1, nên nhãn đặt được trên nền đặc và trong `glass-overlay`. Màu luôn đi kèm chữ hoặc ký hiệu ("＋ Thêm", "~ Sửa", "− Ngừng"); không thành phần nào dùng màu khác biệt làm kênh duy nhất.

| Token | `…-bg` (sáng / tối) | `…-text` (sáng / tối) | Tương phản chữ trên nền (sáng / tối) | Ký hiệu đi kèm |
|---|---|---|---|---|
| `color-diff-added` | `#E8F5EC` / `#12261A` | `#1A7F37` / `#3FB950` | 4,52 / 6,27 | "＋", chữ "Thêm mới" |
| `color-diff-changed` | `#FFF4D6` / `#2B2111` | `#8A5A00` / `#E3B341` | 5,41 / 8,12 | "~", chữ "Đã sửa" |
| `color-diff-removed` | `#FDECEC` / `#2D1517` | `#B4232A` / `#FF6B6B` | 5,72 / 6,15 | "−", chữ gạch ngang, chữ "Ngừng dùng" hoặc "Đã xóa" |
| `color-diff-moved` | `#E8F1FC` / `#11233A` | `#0A66D8` / `#4C9EFF` | 4,72 / 5,77 | "↕", chữ "Di chuyển" |

: Màu khác biệt giữa hai phiên bản kèm ký hiệu đi kèm

Bốn token khác biệt dùng cùng giá trị với token trạng thái tương ứng ở mục 4.4 nhưng tách tên để có thể chỉnh riêng (ví dụ tăng độ đậm nền khác biệt trong lưới dày) mà không đổi nhãn trạng thái.

| Token | `…-bg` (sáng / tối) | `…-text` (sáng / tối) | Tương phản (sáng / tối) | Nghĩa |
|---|---|---|---|---|
| `color-source-local` | `#E8F1FC` / `#11233A` | `#0A66D8` / `#4C9EFF` | 4,72 / 5,77 | Dữ liệu do tỉnh tự quản (danh mục địa phương) |
| `color-source-national` | `#F1EBFE` / `#231B38` | `#6D28D9` / `#B79CFB` | 6,11 / 7,13 | Dữ liệu đồng bộ từ nguồn quốc gia (chỉ đọc) |
| `color-source-hybrid` | `#E3F4F1` / `#0F2926` | `#0B7268` / `#2DD4BF` | 5,10 / 8,26 | Nguồn quốc gia có mở rộng địa phương |
| `color-source-common` | `#EEEEF1` / `#2A2A2E` | `#4B4B55` / `#C7C7CC` | 7,44 / 8,49 | Danh mục dùng chung nền tảng (mọi tenant) |

: Màu nguồn dữ liệu của danh mục

Nhãn nguồn hiển thị bằng `CMP-Tag` có biểu tượng và chữ riêng cho mỗi nguồn (bảng nhãn ở D03-06-PH07 §5.1), nên người mù màu vẫn phân biệt được. Màn PH-07 bản 0.1 đặt tên các token này với tiền tố `TKN-` và hậu tố `-fg`; tên chuẩn là tên ở bảng trên với hậu tố `-text`.

## 5. Token vật liệu glass

Phần này chỉ liệt kê giá trị. Lý do chọn, quy tắc đặt glass ở đâu, chế độ giảm trong suốt và cơ chế tự hạ cấp trên máy yếu được thuyết minh ở D03-05-01.

Datahub có bốn vật liệu glass. Mỗi vật liệu là tổ hợp của màu phủ (tint) với độ đục alpha, độ nhòe phông nền, độ bão hòa và viền phản quang. Độ đục của từng vật liệu được chọn bằng cách tính **trường hợp xấu nhất**: giả định phông nền phía sau là đen tuyệt đối ở chế độ sáng và trắng tuyệt đối ở chế độ tối, rồi kiểm tra chữ trên màu tổng hợp. Cột cuối của bảng ghi tương phản của chữ chính, chữ cấp hai và chữ liên kết trong trường hợp xấu nhất đó.

| Vật liệu | Token tint (sáng / tối) | Độ nhòe | Bão hòa | Dùng cho | Tương phản xấu nhất (chính / cấp hai / liên kết), sáng — tối |
|---|---|---|---|---|---|
| `glass-chrome` | `rgba(255,255,255,0.72)` / `rgba(28,28,30,0.70)` | `blur-md` 24px | 180% | Sidebar, topbar khi nội dung chưa cuộn dưới nó | 8,45 / 4,33 / 2,70 — 5,76 / 3,72 / 2,28 (chỉ đặt trên canvas, xem ghi chú) |
| `glass-chrome-scrolled` | `rgba(255,255,255,0.86)` / `rgba(28,28,30,0.84)` | `blur-lg` 32px | 180% | Topbar khi nội dung đang cuộn bên dưới | 12,19 / 6,24 / 3,90 — 9,46 / 6,11 / 3,75 |
| `glass-modal` | `rgba(255,255,255,0.88)` / `rgba(28,28,30,0.88)` | `blur-xl` 40px | 160% | Khung Modal, Drawer, CommandPalette | 12,80 / 6,55 / 4,09 — 10,87 / 7,03 / 4,31 |
| `glass-overlay` | `rgba(255,255,255,0.94)` / `rgba(28,28,30,0.90)` | `blur-lg` 32px | 160% | Popover, Dropdown, danh sách chọn của Select, DatePicker, Notification | 14,73 / 7,54 / 4,71 — 11,63 / 7,52 / 4,61 |

: Bốn vật liệu glass với tint, độ nhòe, bão hòa và tương phản xấu nhất

Ghi chú quan trọng cho người triển khai. Vật liệu `glass-chrome` không đạt ngưỡng cho chữ cấp hai và chữ liên kết trong trường hợp xấu nhất, nhưng nó chỉ được đặt trên canvas, nơi phông nền do hệ thống kiểm soát; trên canvas, cả ba nấc chữ đạt lần lượt 16,36 / 8,38 / 5,23 (sáng) và 16,32 / 10,55 / 6,46 (tối). Khi topbar có nội dung cuộn bên dưới, nó **bắt buộc** chuyển sang `glass-chrome-scrolled` (xem D03-05-01 §5). Trên `glass-chrome-scrolled` và `glass-modal`, chữ màu nhấn (liên kết) dưới 4,5:1 trong trường hợp xấu nhất, nên **không đặt chữ liên kết cỡ thường trực tiếp lên hai vật liệu này**; liên kết trong Modal luôn nằm trong vùng nội dung đặc (`color-surface-solid`). Vật liệu `glass-overlay` đạt ngưỡng cho mọi nấc chữ kể cả trường hợp xấu nhất, nên nội dung của popover và menu thả xuống được đặt trực tiếp lên glass.

Các token phụ của vật liệu:

| Token | Sáng | Tối | Ý nghĩa |
|---|---|---|---|
| `glass-highlight-top` | `inset 0 1px 0 0 rgba(255,255,255,0.65)` | `inset 0 1px 0 0 rgba(255,255,255,0.12)` | Mép phản quang phía trên, mô phỏng ánh sáng chiếu từ trên |
| `glass-edge` | `0 0 0 0.5px rgba(0,0,0,0.08)` | `0 0 0 0.5px rgba(0,0,0,0.60)` | Đường viền ngoài mảnh tách glass khỏi nền cùng màu |
| `glass-inner-glow` | `inset 0 0 0 1px rgba(255,255,255,0.35)` | `inset 0 0 0 1px rgba(255,255,255,0.06)` | Viền sáng bên trong toàn chu vi |
| `glass-lite-tint` | `rgba(255,255,255,0.96)` / `rgba(28,28,30,0.96)` | | Tint ở chế độ "Giảm" (không nhòe) |
| `glass-off-tint` | `color-surface-solid` | | Tint ở chế độ "Tắt" (nền đặc hoàn toàn) |
| `glass-scroll-edge` | `linear-gradient(to bottom, rgba(242,243,247,0.9), rgba(242,243,247,0))` | `linear-gradient(to bottom, rgba(14,14,16,0.9), rgba(14,14,16,0))` | Dải mờ dần 16px dưới topbar khi nội dung cuộn |

: Token phụ của vật liệu glass: mép, viền, tint hạ cấp và dải scroll edge

## 6. Độ nhòe và độ trong

Độ nhòe phông nền của vật liệu glass được đặt theo một thang cố định để các vật liệu không tự chọn giá trị riêng. Bảng dưới liệt kê từng nấc và vật liệu dùng nấc đó.

| Token | Giá trị | Ghi chú |
|---|---|---|
| `blur-none` | `0` | Chế độ "Giảm" và "Tắt" |
| `blur-sm` | `12px` | Dự phòng; chưa có thành phần nào dùng |
| `blur-md` | `24px` | `glass-chrome` |
| `blur-lg` | `32px` | `glass-chrome-scrolled`, `glass-overlay` |
| `blur-xl` | `40px` | `glass-modal` |
| `saturate-glass` | `180%` | Tăng bão hòa giúp màu phông nền "sống" khi đi qua kính |
| `saturate-glass-muted` | `160%` | Cho lớp nổi phía trên nội dung, tránh màu chói |
| `opacity-disabled` | `0.4` | Không dùng cho chữ; chữ vô hiệu dùng `color-text-disabled` |

: Thang độ nhòe phông nền

Độ nhòe lớn hơn 40px không mang lại khác biệt thị giác đáng kể nhưng tăng chi phí GPU gần tuyến tính theo bán kính, nên 40px là trần.

## 7. Bo góc

Liquid Glass dùng nguyên tắc **bo góc đồng tâm (concentric)**: một hình nằm trong một hình khác thì bán kính góc bên trong bằng bán kính góc bên ngoài trừ khoảng đệm giữa hai hình. Nhờ vậy đường cong của hai góc song song với nhau và mắt nhìn thấy một khối liền. Quy tắc này được áp dụng bắt buộc cho Modal (khung glass bao vùng nội dung đặc), Card có ảnh, Segmented (track bao nút chọn) và nhóm nút.

| Token | Giá trị | Dùng cho |
|---|---|---|
| `radius-xs` | `4px` | Checkbox, Kbd, thanh tiến độ |
| `radius-sm` | `6px` | Điều khiển cỡ nhỏ (24px), Tag |
| `radius-md` | `10px` | Điều khiển cỡ chuẩn (32px): Button, Input, Select; mục menu |
| `radius-lg` | `14px` | Card, bảng, Popover, Dropdown |
| `radius-xl` | `20px` | Modal, Drawer (cạnh hở), CommandPalette, sidebar dạng nổi |
| `radius-2xl` | `28px` | Dự phòng cho bề mặt lớn trong cổng nhà phát triển |
| `radius-pill` | `9999px` | Nút dạng viên nang, Switch, StatusTag, thanh tìm kiếm trên topbar |
| `radius-concentric(outer, padding)` | `max(outer − padding, radius-xs)` | Hàm tính trong mã, không phải giá trị cố định |

: Thang bo góc và nơi dùng

Ví dụ áp dụng: Modal có `radius-xl` 20px và khoảng đệm 8px giữa khung glass và vùng nội dung đặc, nên vùng nội dung có bán kính 20 − 8 = 12px.

## 8. Đổ bóng và độ cao

Vật liệu glass cần bóng để tách khỏi nền, nhưng bóng của Liquid Glass rất mềm và rộng, không đậm như Material. Mỗi mức độ cao là tổ hợp của một bóng gần (sắc nét, nhỏ) và một bóng xa (mềm, rộng).

| Token | Sáng | Tối | Dùng cho |
|---|---|---|---|
| `shadow-0` | `none` | `none` | Bề mặt đặc nằm phẳng trên canvas |
| `shadow-1` | `0 1px 2px rgba(16,24,40,0.06), 0 1px 3px rgba(16,24,40,0.08)` | `0 1px 2px rgba(0,0,0,0.5)` | Card, bảng |
| `shadow-2` | `0 2px 6px rgba(16,24,40,0.06), 0 8px 24px rgba(16,24,40,0.08)` | `0 2px 6px rgba(0,0,0,0.5), 0 8px 24px rgba(0,0,0,0.4)` | Sidebar nổi, topbar khi cuộn |
| `shadow-3` | `0 4px 12px rgba(16,24,40,0.08), 0 16px 40px rgba(16,24,40,0.12)` | `0 4px 12px rgba(0,0,0,0.5), 0 16px 40px rgba(0,0,0,0.5)` | Popover, Dropdown |
| `shadow-4` | `0 8px 24px rgba(16,24,40,0.12), 0 32px 64px rgba(16,24,40,0.18)` | `0 8px 24px rgba(0,0,0,0.6), 0 32px 64px rgba(0,0,0,0.6)` | Modal, Drawer, CommandPalette |

: Thang đổ bóng và độ cao

Bóng của vật liệu glass luôn được ghép với `glass-highlight-top` và `glass-edge` thành một khai báo `box-shadow` duy nhất (D03-05-01 §4).

## 9. Khoảng cách và lưới

Khoảng cách dùng thang cơ sở 4px. Thành phần chỉ được dùng các nấc trong bảng.

| Token | Giá trị | Dùng điển hình |
|---|---|---|
| `space-0` | `0` | |
| `space-0-5` | `2px` | Khoảng giữa biểu tượng và chấm trạng thái |
| `space-1` | `4px` | Khoảng giữa biểu tượng và nhãn trong nút cỡ nhỏ |
| `space-2` | `8px` | Khoảng giữa các nút trong nhóm; đệm khung Modal |
| `space-3` | `12px` | Đệm ngang ô bảng chế độ gọn; khoảng nhãn và trường |
| `space-4` | `16px` | Đệm thẻ chế độ gọn; khoảng giữa các trường biểu mẫu |
| `space-5` | `20px` | Đệm thẻ chế độ chuẩn |
| `space-6` | `24px` | Lề vùng nội dung; khoảng giữa các khối |
| `space-8` | `32px` | Khoảng giữa các phần lớn của trang |
| `space-10` | `40px` | |
| `space-12` | `48px` | Khoảng trống trạng thái rỗng |
| `space-16` | `64px` | |

: Thang khoảng cách cơ sở 4px

Lưới bố cục, kích thước khung (topbar, sidebar), điểm ngắt và mật độ được định nghĩa ở mục 12 và được dùng trong D03-06-00.

## 10. Chữ

Họ chữ được chọn tại ADR-021: **Inter** cho giao diện và **JetBrains Mono** cho mã, log, định danh. Cả hai tự lưu trữ trong gói `@datahub/tokens` (không tải từ CDN), vì ứng dụng chạy trong trung tâm dữ liệu tỉnh có thể không ra Internet.

| Token | Giá trị |
|---|---|
| `font-family-sans` | `"Inter Variable", Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif` |
| `font-family-mono` | `"JetBrains Mono Variable", "JetBrains Mono", ui-monospace, "SF Mono", Menlo, Consolas, monospace` |
| `font-feature-ui` | `"cv11", "ss01"` (chữ số 1 có chân, a một tầng dễ đọc trên màn hình) |
| `font-feature-tabular` | `"tnum"` (chữ số đều độ rộng, bắt buộc cho cột số, thời gian, tiền) |

: Họ phông chữ và tính năng chữ

Thang cỡ chữ bám thang của antd để thành phần antd không lệch, nhưng chiều cao dòng được tăng cho tiếng Việt. Chữ Việt có dấu chồng hai tầng (ví dụ "Ể", "ỗ"), nếu chiều cao dòng dưới 1,4 thì dấu của dòng dưới chạm chân chữ của dòng trên.

| Token | Cỡ / chiều cao dòng / độ đậm | Dùng cho |
|---|---|---|
| `font-caption` | 12px / 18px / 400 | Chú thích, nhãn trục biểu đồ, chữ phụ trong bảng gọn |
| `font-footnote` | 13px / 20px / 400 | Mô tả trường biểu mẫu, chữ phụ |
| `font-body` | 14px / 22px / 400 | Chữ thân, ô bảng, điều khiển |
| `font-body-strong` | 14px / 22px / 500 | Nhãn trường, chữ nút, tiêu đề cột bảng |
| `font-callout` | 16px / 24px / 400 | Chữ thân trong cổng nhà phát triển, đoạn giải thích trong trạng thái rỗng |
| `font-title-3` | 16px / 24px / 600 | Tiêu đề thẻ, tiêu đề Drawer |
| `font-title-2` | 20px / 28px / 600 | Tiêu đề trang (PageHeader), tiêu đề Modal |
| `font-title-1` | 24px / 32px / 600 | Tiêu đề trang tổng quan |
| `font-display` | 30px / 38px / 700 | Số liệu KPI lớn |
| `font-display-lg` | 38px / 46px / 700 | Dự phòng cho trang chào |
| `font-mono-sm` | 12px / 18px / 400 mono | Log, khối mã trong bảng |
| `font-mono` | 13px / 20px / 400 mono | Khối mã, YAML, JSON |

: Thang cỡ chữ, chiều cao dòng và độ đậm

Cỡ chữ tối thiểu cho thông tin có nghĩa là 12px. Không dùng chữ in hoa toàn bộ cho tiêu đề tiếng Việt, vì dấu của chữ in hoa bị nén và khó đọc; nhãn nhóm menu dùng chữ thường cỡ `font-caption` độ đậm 600.

## 11. Chuyển động

Chuyển động của Liquid Glass gợi cảm giác vật liệu có quán tính: lớp nổi "bung" ra nhẹ từ điểm kích hoạt rồi dừng mềm. Datahub dùng đường cong kiểu lò xo đã giảm dao động để giữ cảm giác đó mà không làm người dùng phải chờ.

| Token | Giá trị | Dùng cho |
|---|---|---|
| `motion-duration-instant` | `80ms` | Đổi màu hover, focus |
| `motion-duration-fast` | `140ms` | Tooltip, Checkbox, Switch |
| `motion-duration-base` | `220ms` | Dropdown, Popover, mở rộng hàng |
| `motion-duration-slow` | `320ms` | Modal, Drawer, thu gọn sidebar |
| `motion-duration-slower` | `480ms` | Chuyển trang, hiệu ứng glass "đọng lại" khi mở lớp nổi |
| `motion-ease-standard` | `cubic-bezier(0.2, 0, 0, 1)` | Mặc định |
| `motion-ease-emphasized` | `cubic-bezier(0.32, 0.72, 0, 1)` | Lớp nổi xuất hiện, mô phỏng lò xo giảm chấn |
| `motion-ease-exit` | `cubic-bezier(0.3, 0, 1, 1)` | Lớp nổi biến mất |
| `motion-scale-enter` | `0.96 → 1` | Lớp nổi phóng từ 96% lên 100% khi xuất hiện |

: Token thời lượng và đường cong chuyển động

Khi người dùng bật giảm chuyển động (hệ điều hành `prefers-reduced-motion: reduce` hoặc công tắc trong cài đặt), mọi token thời lượng trên 80ms được đặt về `0ms` trừ hiệu ứng mờ dần (`opacity`), giữ ở `motion-duration-fast` để người dùng vẫn nhận ra có thay đổi. Phóng to, trượt và hiệu ứng thị sai bị tắt.

## 12. Kích thước, lớp chồng, điểm ngắt và mật độ

### 12.1. Kích thước điều khiển

Kích thước điều khiển có hai cột theo mật độ chuẩn và gọn, và cỡ nhỏ nhất vẫn đạt vùng chạm 24×24 px của WCAG 2.5.8. Bảng dưới là giá trị chuẩn cho điều khiển, biểu tượng và khung bố cục.

| Token | Chuẩn | Gọn | Ghi chú |
|---|---|---|---|
| `size-control-sm` | 24px | 24px | Đạt ngưỡng vùng chạm tối thiểu 24×24 (WCAG 2.5.8) |
| `size-control-md` | 32px | 28px | Mặc định |
| `size-control-lg` | 40px | 36px | Hành động chính trong trang trống, cổng nhà phát triển |
| `size-icon-sm` | 14px | 14px | Biểu tượng trong điều khiển cỡ nhỏ |
| `size-icon-md` | 16px | 16px | Biểu tượng mặc định |
| `size-icon-lg` | 20px | 20px | Biểu tượng điều hướng sidebar |
| `size-table-row` | 48px | 36px | Chiều cao hàng bảng |
| `size-topbar` | 56px | 48px | |
| `size-sidebar` | 256px | 232px | Sidebar mở rộng |
| `size-sidebar-collapsed` | 64px | 56px | Sidebar thu gọn chỉ còn biểu tượng |
| `size-page-max` | 1600px | 1600px | Chiều rộng tối đa vùng nội dung với trang biểu mẫu, chi tiết |
| `size-form-max` | 880px | 880px | Chiều rộng tối đa của một cột biểu mẫu |
| `size-drawer-md` | 560px | 560px | Drawer chuẩn |
| `size-drawer-lg` | 880px | 880px | Drawer chứa biểu mẫu hai cột hoặc so sánh |
| `size-modal-sm` / `md` / `lg` | 416 / 560 / 800px | như chuẩn | |

: Kích thước điều khiển ở mật độ chuẩn và gọn

### 12.2. Lớp chồng

Lớp chồng (`z-index`) được đặt thành thang token để Modal, Drawer, tooltip và hộp thoại hết phiên luôn xếp đúng thứ tự mà không thành phần nào tự chọn số. Bảng dưới liệt kê từ lớp nội dung tới lớp trên cùng.

| Token | Giá trị | Lớp |
|---|---|---|
| `z-base` | 0 | Nội dung |
| `z-sticky` | 100 | Tiêu đề bảng dính, thanh thao tác hàng loạt |
| `z-sidebar` | 200 | |
| `z-topbar` | 300 | |
| `z-drawer` | 1000 | Tương ứng `zIndexPopupBase` của antd |
| `z-modal` | 1000 | |
| `z-popover` | 1050 | |
| `z-toast` | 1100 | |
| `z-tooltip` | 1070 | |
| `z-session-dialog` | 1200 | Hộp thoại sắp hết phiên luôn nằm trên cùng (FR-00-003) |

: Thang lớp chồng z-index

### 12.3. Điểm ngắt

Datahub dùng nguyên điểm ngắt của antd để `Grid` và `useBreakpoint` hoạt động không cần cấu hình thêm. Độ phân giải mục tiêu tối thiểu là 1366×768 (máy văn phòng phổ biến); dưới `lg` (992px) giao diện quản trị vẫn dùng được nhưng sidebar chuyển thành Drawer và bảng cuộn ngang.

| Token | Giá trị | Hành vi bố cục |
|---|---|---|
| `bp-sm` | 576px | |
| `bp-md` | 768px | Biểu mẫu chuyển một cột |
| `bp-lg` | 992px | Sidebar chuyển thành Drawer bên dưới mức này |
| `bp-xl` | 1200px | Sidebar mặc định thu gọn ở 1200–1365px |
| `bp-xxl` | 1600px | Bảng điều khiển hiển thị lưới 4 cột |

: Điểm ngắt và hành vi bố cục

### 12.4. Mật độ

Mật độ "Chuẩn" là mặc định. Mật độ "Gọn" dành cho cán bộ vận hành xem nhiều dòng cùng lúc; người dùng chọn trong cài đặt cá nhân và lựa chọn được ghi nhớ. Mật độ được áp bằng thuộc tính `data-density` trên thẻ `html` và bằng `componentSize`/token của antd (mục 13.3).

## 13. Ánh xạ sang Ant Design v6

### 13.1. Nguyên tắc

Phiên bản antd được cố định trong `package.json` của `@datahub/ui` (tại thời điểm viết là nhánh 6.x, đã kiểm tra trên 6.7.1). Antd v6 tạo style bằng CSS-in-JS có hỗ trợ CSS variables và có thêm chế độ không chạy lúc thực thi (`zeroRuntime`). Datahub dùng chế độ CSS variables với tiền tố mặc định `ant` và `hashed: false` (một phiên bản antd duy nhất trong ứng dụng), để chuyển sáng tối chỉ đổi giá trị biến mà không sinh lại style. Mọi tùy biến theo thứ tự ưu tiên sau, và chỉ chuyển sang cách sau khi cách trước không làm được:

1. Token toàn cục (`theme.token`) cho màu, chữ, bo góc, kích thước.
2. Token thành phần (`theme.components`) cho giá trị riêng của một thành phần.
3. Thuộc tính ngữ nghĩa `classNames` và `styles` mà antd v6 cung cấp trên từng thành phần, để gắn lớp vật liệu glass (`dh-glass--overlay`, `dh-glass--modal`) vào đúng phần tử con (ví dụ phần `content` của Modal hay phần `popup` của Select).
4. CSS trong `@datahub/ui` chỉ cho những gì antd không có token, chủ yếu là `backdrop-filter`. CSS này chỉ được tham chiếu `var(--dh-*)` và `var(--ant-*)`.

Không được ghi đè lớp nội bộ của antd bằng bộ chọn kiểu `.ant-btn-primary:hover`, vì lớp nội bộ có thể đổi giữa các bản vá.

### 13.2. Ánh xạ token toàn cục

Bảng dưới đây là bảng ánh xạ đầy đủ những token toàn cục mà Datahub đặt giá trị; token antd không có trong bảng được để antd tự dẫn xuất.

| Token antd v6 | Sáng | Tối | Nguồn |
|---|---|---|---|
| `colorPrimary` | `#0A66D8` | `#0A66D8` | `color-accent` |
| `colorPrimaryHover` | `#0857BC` | `#1F74E0` | `color-accent-hover` (ghi đè vì antd dẫn xuất ra màu sáng hơn, không đạt tương phản với chữ trắng) |
| `colorPrimaryActive` | `#0749A0` | `#0749A0` | `color-accent-pressed` |
| `colorPrimaryBg` | `#E8F1FC` | `#11233A` | `color-accent-subtle` |
| `colorPrimaryBgHover` | `#D6E6FA` | `#16304F` | `color-fill-selected-hover` |
| `colorPrimaryText`, `colorLink` | `#0A66D8` | `#4C9EFF` | `color-text-link` |
| `colorLinkHover` | `#0857BC` | `#7AB6FF` | |
| `colorSuccess` | `#1A7F37` | `#3FB950` | `color-success-text` |
| `colorWarning` | `#8A5A00` | `#E3B341` | `color-warning-text` |
| `colorError` | `#B4232A` | `#FF6B6B` | `color-error-text` |
| `colorInfo` | `#0A66D8` | `#4C9EFF` | `color-info-text` |
| `colorBgBase` | `#FFFFFF` | `#1C1C1E` | Gốc để antd dẫn xuất |
| `colorTextBase` | `#1D1D1F` | `#F5F5F7` | Gốc để antd dẫn xuất |
| `colorBgLayout` | `#F2F3F7` | `#0E0E10` | `color-canvas` |
| `colorBgContainer` | `#FFFFFF` | `#1C1C1E` | `color-surface-solid` |
| `colorBgElevated` | `rgba(255,255,255,0.94)` | `rgba(28,28,30,0.90)` | `glass-overlay` tint; khi chế độ glass "Tắt" đổi thành `color-surface-solid` |
| `colorBgSpotlight` | `#1D1D1F` | `#F5F5F7` | `color-surface-inverse` (Tooltip) |
| `colorBgMask` | `rgba(15,17,21,0.32)` | `rgba(0,0,0,0.56)` | `color-scrim` |
| `colorText` | `#1D1D1F` | `#F5F5F7` | `color-text-primary` |
| `colorTextSecondary` | `#4B4B55` | `#C7C7CC` | `color-text-secondary` |
| `colorTextTertiary`, `colorTextPlaceholder`, `colorTextDescription` | `#63636D` | `#A1A1A8` | `color-text-tertiary` |
| `colorTextQuaternary`, `colorTextDisabled` | `#9A9AA2` | `#6C6C72` | `color-text-disabled` |
| `colorBorder` | `#868690` | `#7C7C84` | `color-border-control` |
| `colorBorderSecondary`, `colorSplit` | `#D9D9DE` | `#3A3A3E` | `color-border-subtle` |
| `colorFill` | `rgba(0,0,0,0.08)` | `rgba(255,255,255,0.10)` | `color-fill-pressed` |
| `colorFillSecondary` | `rgba(0,0,0,0.06)` | `rgba(255,255,255,0.08)` | |
| `colorFillTertiary` | `rgba(0,0,0,0.04)` | `rgba(255,255,255,0.06)` | `color-fill-hover` |
| `colorFillQuaternary` | `#EEEEF1` | `#2C2C2E` | `color-fill-control` |
| `fontFamily` | `font-family-sans` | như sáng | |
| `fontFamilyCode` | `font-family-mono` | như sáng | |
| `fontSize` | 14 | 14 | `font-body` |
| `lineHeight` | 1.5714 (22/14) | như sáng | |
| `borderRadius` | 10 | 10 | `radius-md` |
| `borderRadiusSM` | 6 | 6 | `radius-sm` |
| `borderRadiusLG` | 14 | 14 | `radius-lg` |
| `borderRadiusXS` | 4 | 4 | `radius-xs` |
| `controlHeight` | 32 (gọn: 28) | như sáng | `size-control-md` |
| `controlHeightSM` | 24 | 24 | `size-control-sm` |
| `controlHeightLG` | 40 (gọn: 36) | như sáng | `size-control-lg` |
| `lineWidthFocus` | 2 | 2 | Độ dày vòng focus |
| `controlOutlineWidth` | 2 | 2 | |
| `controlOutline` | `rgba(10,102,216,0.35)` | `rgba(76,158,255,0.45)` | Quầng focus của ô nhập (bổ sung, không thay vòng focus kép) |
| `motionDurationFast` | `0.14s` | như sáng | `motion-duration-fast` |
| `motionDurationMid` | `0.22s` | như sáng | `motion-duration-base` |
| `motionDurationSlow` | `0.32s` | như sáng | `motion-duration-slow` |
| `motionEaseOut` | `cubic-bezier(0.2, 0, 0, 1)` | như sáng | `motion-ease-standard` |
| `motionEaseOutBack` | `cubic-bezier(0.32, 0.72, 0, 1)` | như sáng | `motion-ease-emphasized` (thay hiệu ứng "nảy" mặc định của antd) |
| `boxShadow` | `shadow-3` | `shadow-3` | |
| `boxShadowSecondary` | `shadow-3` | `shadow-3` | Popover, Dropdown |
| `boxShadowTertiary` | `shadow-1` | `shadow-1` | Card |
| `wireframe` | `false` | `false` | |
| `zIndexPopupBase` | 1000 | 1000 | `z-modal` |

: Ánh xạ token toàn cục sang antd v6

Thuật toán: chế độ sáng dùng `theme.defaultAlgorithm`, chế độ tối dùng `theme.darkAlgorithm`, mật độ gọn ghép thêm `theme.compactAlgorithm`. Vì phần lớn token màu đã được đặt tường minh, thuật toán chủ yếu ảnh hưởng tới các token dẫn xuất ít gặp (ví dụ màu của bảng sắc độ preset dùng cho `Tag` có thuộc tính `color`). Datahub không dùng `Tag color="..."` với màu preset; nhãn màu luôn đi qua `CMP-StatusTag`.

### 13.3. Ánh xạ token thành phần

Bảng dưới đây liệt kê token thành phần antd được Datahub đặt giá trị. Tên token đã đối chiếu với định nghĩa kiểu trong gói antd 6.7.1.

| Thành phần antd | Token thành phần | Giá trị (sáng / tối) | Lý do |
|---|---|---|---|
| `Layout` | `bodyBg` | `transparent` | Để lộ canvas và lớp dải màu phía sau |
| `Layout` | `headerBg`, `siderBg`, `lightSiderBg` | `transparent` | Nền do lớp glass `dh-glass--chrome` đảm nhận |
| `Layout` | `headerHeight` | 56 (gọn 48) | `size-topbar` |
| `Layout` | `headerPadding` | `0 16px` | |
| `Menu` | `itemBg`, `subMenuItemBg`, `popupBg` | `transparent` / `transparent` / `colorBgElevated` | Menu nằm trên glass |
| `Menu` | `itemSelectedBg` | `#E8F1FC` / `#11233A` | `color-fill-selected` |
| `Menu` | `itemSelectedColor` | `#0A66D8` / `#4C9EFF` | `color-accent-on-subtle` (4,72 / 5,77 trên nền chọn) |
| `Menu` | `itemHoverBg` | `rgba(0,0,0,0.04)` / `rgba(255,255,255,0.06)` | `color-fill-hover` |
| `Menu` | `itemColor` | `#1D1D1F` / `#F5F5F7` | Chữ chính (sidebar trên glass chỉ dùng chữ chính và cấp hai) |
| `Menu` | `groupTitleColor` | `#4B4B55` / `#C7C7CC` | |
| `Menu` | `itemBorderRadius`, `subMenuItemBorderRadius` | 10 | `radius-md` |
| `Menu` | `itemHeight` | 40 (gọn 36) | |
| `Menu` | `itemMarginInline` | 8 | Mục chọn có khoảng hở hai bên, kiểu viên nang |
| `Menu` | `activeBarWidth`, `activeBarBorderWidth` | 0 | Bỏ thanh chỉ thị kiểu Material; dùng nền viên nang |
| `Menu` | `iconSize`, `collapsedIconSize` | 20 | `size-icon-lg` |
| `Table` | `headerBg` | `#F7F8FA` / `#242427` | `color-surface-solid-2` |
| `Table` | `headerColor` | `#4B4B55` / `#C7C7CC` | Chữ cấp hai, đậm 500 |
| `Table` | `rowHoverBg` | `#F7F8FA` / `#242427` | |
| `Table` | `rowSelectedBg`, `rowSelectedHoverBg` | `#E8F1FC` / `#11233A`, `#D6E6FA` / `#16304F` | |
| `Table` | `borderColor` | `#D9D9DE` / `#3A3A3E` | |
| `Table` | `cellPaddingBlock`, `cellPaddingInline` | 13 / 16 (gọn 7 / 12) | Đạt chiều cao hàng 48 (gọn 36) với dòng chữ 22px |
| `Table` | `headerBorderRadius` | 14 | `radius-lg` |
| `Table` | `stickyScrollBarBg` | `rgba(0,0,0,0.25)` / `rgba(255,255,255,0.25)` | |
| `Modal` | `contentBg`, `headerBg`, `footerBg` | `transparent` | Khung là lớp `dh-glass--modal`, vùng nội dung đặc do `CMP-Modal` dựng |
| `Modal` | `titleFontSize`, `titleLineHeight` | 20, 1.4 | `font-title-2` |
| `Drawer` | (dùng `classNames.section`) | | Drawer v6 không có token nền riêng; gắn lớp `dh-glass--modal` qua `classNames` |
| `Popover` | `popoverBg` | `rgba(255,255,255,0.94)` / `rgba(28,28,30,0.90)` | `glass-overlay` |
| `Tooltip` | `maxWidth` | 320 | Tooltip dùng `colorBgSpotlight` đặc, không glass |
| `Card` | `headerFontSize` | 16 | `font-title-3` |
| `Card` | `bodyPadding`, `headerPadding` | 20 (gọn 16) | |
| `Segmented` | `trackBg` | `#EEEEF1` / `#2C2C2E` | `color-fill-control` |
| `Segmented` | `itemSelectedBg` | `#FFFFFF` / `#48484A` | Nút chọn nổi lên như một mảnh kính trên track |
| `Segmented` | `trackPadding` | 2 | Bo góc đồng tâm: track 10, nút chọn 8 |
| `Tabs` | `inkBarColor`, `itemSelectedColor` | `#0A66D8` / `#4C9EFF` | |
| `Tabs` | `itemColor` | `#4B4B55` / `#C7C7CC` | |
| `Button` | `primaryShadow`, `defaultShadow`, `dangerShadow` | `none` | Bỏ bóng mặc định, độ nổi do vật liệu quyết định |
| `Button` | `fontWeight` | 500 | |
| `Tag` | `defaultBg` | `#EEEEF1` / `#2A2A2E` | |
| `Notification` | (dùng `classNames`) | | Gắn `dh-glass--overlay` |
| `Message` | `contentBg` | `#1D1D1F` / `#F5F5F7` | Toast dùng nền đảo đặc, đọc được trên mọi nền |
| `Switch` | `trackHeight`, `handleSize` | 22, 18 | Viên nang kiểu iOS thu nhỏ cho mật độ quản trị |

: Ánh xạ token thành phần sang antd v6

### 13.4. Mã cấu hình tham chiếu

Đoạn mã dưới đây là cấu hình chuẩn đặt trong `@datahub/ui/src/theme/`. Giá trị số và màu **được sinh** từ tệp nguồn token (mục 14); đoạn mã trong tài liệu minh họa cấu trúc và không được chép giá trị bằng tay vào ứng dụng.

```tsx
// @datahub/ui/src/theme/antd-theme.ts
import { theme, type ThemeConfig } from 'antd';
import { tokens } from '@datahub/tokens'; // sinh tự động từ tokens.json

export type DhMode = 'light' | 'dark';
export type DhDensity = 'comfortable' | 'compact';
export type DhGlass = 'full' | 'lite' | 'off';

export function buildAntdTheme(mode: DhMode, density: DhDensity, glass: DhGlass): ThemeConfig {
  const t = tokens[mode];
  const algorithms = [mode === 'dark' ? theme.darkAlgorithm : theme.defaultAlgorithm];
  if (density === 'compact') algorithms.push(theme.compactAlgorithm);

  const elevatedBg = glass === 'off' ? t.color.surfaceSolid : t.glass.overlay.tint;

  return {
    cssVar: { prefix: 'ant' },
    hashed: false,
    algorithm: algorithms,
    token: {
      colorPrimary: t.color.accent,
      colorPrimaryHover: t.color.accentHover,
      colorPrimaryActive: t.color.accentPressed,
      colorPrimaryBg: t.color.accentSubtle,
      colorPrimaryBgHover: t.color.fillSelectedHover,
      colorPrimaryText: t.color.textLink,
      colorLink: t.color.textLink,
      colorSuccess: t.color.successText,
      colorWarning: t.color.warningText,
      colorError: t.color.errorText,
      colorInfo: t.color.infoText,
      colorBgBase: t.color.surfaceSolid,
      colorTextBase: t.color.textPrimary,
      colorBgLayout: t.color.canvas,
      colorBgContainer: t.color.surfaceSolid,
      colorBgElevated: elevatedBg,
      colorBgSpotlight: t.color.surfaceInverse,
      colorBgMask: t.color.scrim,
      colorText: t.color.textPrimary,
      colorTextSecondary: t.color.textSecondary,
      colorTextTertiary: t.color.textTertiary,
      colorTextPlaceholder: t.color.textTertiary,
      colorTextDescription: t.color.textTertiary,
      colorTextDisabled: t.color.textDisabled,
      colorBorder: t.color.borderControl,
      colorBorderSecondary: t.color.borderSubtle,
      colorSplit: t.color.borderSubtle,
      fontFamily: t.font.familySans,
      fontFamilyCode: t.font.familyMono,
      fontSize: 14,
      lineHeight: 22 / 14,
      borderRadius: 10,
      borderRadiusSM: 6,
      borderRadiusLG: 14,
      borderRadiusXS: 4,
      lineWidthFocus: 2,
      motionDurationFast: '0.14s',
      motionDurationMid: '0.22s',
      motionDurationSlow: '0.32s',
      motionEaseOut: 'cubic-bezier(0.2, 0, 0, 1)',
      motionEaseOutBack: 'cubic-bezier(0.32, 0.72, 0, 1)',
      boxShadow: t.shadow[3],
      boxShadowSecondary: t.shadow[3],
      boxShadowTertiary: t.shadow[1],
      wireframe: false,
    },
    components: {
      Layout: { bodyBg: 'transparent', headerBg: 'transparent', siderBg: 'transparent',
                lightSiderBg: 'transparent', headerHeight: density === 'compact' ? 48 : 56,
                headerPadding: '0 16px' },
      Menu: { itemBg: 'transparent', subMenuItemBg: 'transparent', popupBg: elevatedBg,
              itemSelectedBg: t.color.fillSelected, itemSelectedColor: t.color.accentOnSubtle,
              itemHoverBg: t.color.fillHover, itemColor: t.color.textPrimary,
              groupTitleColor: t.color.textSecondary, itemBorderRadius: 10,
              subMenuItemBorderRadius: 10, itemHeight: density === 'compact' ? 36 : 40,
              itemMarginInline: 8, activeBarWidth: 0, activeBarBorderWidth: 0,
              iconSize: 20, collapsedIconSize: 20 },
      Table: { headerBg: t.color.surfaceSolid2, headerColor: t.color.textSecondary,
               rowHoverBg: t.color.surfaceSolid2, rowSelectedBg: t.color.fillSelected,
               rowSelectedHoverBg: t.color.fillSelectedHover, borderColor: t.color.borderSubtle,
               cellPaddingBlock: density === 'compact' ? 7 : 13,
               cellPaddingInline: density === 'compact' ? 12 : 16, headerBorderRadius: 14 },
      Modal: { contentBg: 'transparent', headerBg: 'transparent', footerBg: 'transparent',
               titleFontSize: 20, titleLineHeight: 1.4 },
      Popover: { popoverBg: elevatedBg },
      Tooltip: { maxWidth: 320 },
      Card: { headerFontSize: 16, bodyPadding: density === 'compact' ? 16 : 20,
              headerPadding: density === 'compact' ? 16 : 20 },
      Segmented: { trackBg: t.color.fillControl, itemSelectedBg: t.color.segmentedThumb, trackPadding: 2 },
      Tabs: { inkBarColor: t.color.textLink, itemSelectedColor: t.color.textLink,
              itemColor: t.color.textSecondary },
      Button: { primaryShadow: 'none', defaultShadow: 'none', dangerShadow: 'none', fontWeight: 500 },
      Message: { contentBg: t.color.surfaceInverse },
      Switch: { trackHeight: 22, handleSize: 18 },
    },
  };
}
```

```tsx
// @datahub/ui/src/theme/DhThemeProvider.tsx (rút gọn)
import { App as AntApp, ConfigProvider } from 'antd';
import viVN from 'antd/locale/vi_VN';
import dayjs from 'dayjs';
import 'dayjs/locale/vi';

export function DhThemeProvider({ children }: { children: React.ReactNode }) {
  const { mode, density, glass } = useDhPreferences(); // D03-05-01 §6
  const themeConfig = useMemo(() => buildAntdTheme(mode, density, glass), [mode, density, glass]);
  dayjs.locale('vi');

  useLayoutEffect(() => {
    const root = document.documentElement;
    root.dataset.theme = mode;       // 'light' | 'dark'
    root.dataset.density = density;  // 'comfortable' | 'compact'
    root.dataset.glass = glass;      // 'full' | 'lite' | 'off' (giá trị đã phân giải, không phải 'auto')
  }, [mode, density, glass]);

  return (
    <ConfigProvider
      theme={themeConfig}
      locale={viVN}
      componentSize={density === 'compact' ? 'small' : 'middle'}
      wave={{ disabled: true }}  /* bỏ hiệu ứng gợn sóng; Liquid Glass dùng phản hồi sáng dần */
    >
      <AntApp>{children}</AntApp>
    </ConfigProvider>
  );
}
```

Hai quyết định trong đoạn mã cần nêu rõ. Thứ nhất, `wave` bị tắt vì hiệu ứng gợn sóng khi nhấn là đặc trưng của antd và Material, trong khi Liquid Glass phản hồi bằng cách làm sáng bề mặt và hơi phóng to; phản hồi nhấn của Datahub được định nghĩa ở `CMP-Button`. Thứ hai, `AntApp` bao toàn ứng dụng để `message`, `notification`, `modal` tĩnh nhận đúng theme và ngữ cảnh; mã nghiệp vụ gọi chúng qua hook `App.useApp()` chứ không gọi hàm tĩnh.

## 14. Đóng gói token

Nguồn sự thật duy nhất là tệp `packages/tokens/tokens.json` theo định dạng Design Tokens Community Group (DTCG), mỗi token có `$value` cho chế độ sáng và phần mở rộng `$extensions.dh.dark` cho chế độ tối, cùng `$description` ghi mã `TKN-*`. Công cụ Style Dictionary đọc tệp này và sinh ba đầu ra:

| Đầu ra | Tệp | Người dùng |
|---|---|---|
| CSS variables | `dist/tokens.css` (khối `:root[data-theme="light"]` và `:root[data-theme="dark"]`) | Lớp glass, thành phần tự viết, mockup HTML |
| Đối tượng TypeScript | `dist/tokens.ts` (xuất `tokens.light`, `tokens.dark` có kiểu chặt) | `buildAntdTheme`, biểu đồ ECharts |
| Bảng tra cứu | `dist/tokens.md` | Tự chèn vào Storybook và kiểm tra lệch với tài liệu này |

: Ba đầu ra của công cụ đóng gói token

Phông chữ Inter và JetBrains Mono (bản biến thiên, định dạng WOFF2, tập con Latin + Latin Extended + Vietnamese) nằm trong `packages/tokens/fonts/` và được khai báo `@font-face` với `font-display: swap` trong `tokens.css`.

## 15. Kiểm tra tự động

CI của `@datahub/ui` chạy bốn kiểm tra trên mỗi PR thay đổi token hoặc thành phần.

| Kiểm tra | Công cụ | Điều kiện đạt |
|---|---|---|
| Tương phản token | Tập lệnh `scripts/contrast-check.ts` đọc `tokens.json`, tính tương phản cho mọi cặp chữ–nền được khai báo trong `pairs.json`, kể cả màu tổng hợp của vật liệu glass trong trường hợp xấu nhất | Mọi cặp đạt ngưỡng khai báo (4,5 cho chữ, 3 cho phần tử đồ họa) |
| Không dùng giá trị thô | Stylelint với `stylelint-declaration-strict-value` cho `color`, `background`, `border-radius`, `box-shadow`, `font-size`, `z-index`; ESLint chặn chuỗi màu hex trong `style={{}}` | 0 vi phạm (NFR-00-045) |
| Truy cập | axe-core chạy trên mọi story của Storybook ở cả hai chế độ và ba chế độ glass | 0 vi phạm mức A, AA (NFR-00-040) |
| Hồi quy hình ảnh | Playwright chụp story ở sáng, tối, glass `full` và `off` | Khác biệt điểm ảnh dưới ngưỡng đã duyệt |

: Bốn kiểm tra tự động trên mỗi PR đổi token

## 16. Tùy biến theo tenant

Datahub là sản phẩm đa tenant, mỗi tỉnh muốn thấy dấu ấn của mình. Tuy nhiên, cho phép tenant tự chọn màu bất kỳ sẽ phá vỡ toàn bộ bảng tương phản ở mục 4. Vì vậy phạm vi tùy biến bị giới hạn như sau.

| Hạng mục | Được tùy biến | Cách làm |
|---|---|---|
| Logo tỉnh, tên hiển thị | Có | Tải lên ở màn quản trị tenant (PH-20); logo SVG hoặc PNG nền trong, tự co về 32px chiều cao trên topbar |
| Màu nhấn | Chọn một trong sáu bộ đã kiểm định: Lam (mặc định), Lục lam `#0E7C86`, Chàm `#5B5BD6`, Tím `#6E40C9`, Đỏ son `#B4232A`, Hổ phách `#B35900` | Mỗi bộ có đủ các token `color-accent*` cho hai chế độ và đã qua `contrast-check`; tenant không nhập mã màu tự do |
| Lớp dải màu canvas | Theo màu nhấn đã chọn | Sinh tự động từ màu nhấn, độ bão hòa thấp |
| Phông chữ, bo góc, khoảng cách, vật liệu | Không | Giữ thống nhất giữa các tỉnh để tài liệu hướng dẫn và đào tạo dùng chung |

: Phạm vi tùy biến token theo tenant

Màu trạng thái (thành công, cảnh báo, lỗi) không đổi theo tenant, vì đổi màu nhấn sang đỏ son không được làm nhãn "Thu hồi" và nút chính trông giống nhau; khi tenant chọn bộ Đỏ son, nút phá hủy tự chuyển sang kiểu viền (`CMP-Button` biến thể `danger-outline`) để giữ khác biệt.

## 17. Truy vết

Bảng dưới nối yêu cầu phi chức năng và quyết định kiến trúc với mục của tài liệu này.

| Yêu cầu | Đáp ứng tại |
|---|---|
| NFR-00-040 WCAG 2.2 AA | Mục 4, 15 |
| NFR-00-041 Tương phản kể cả trên glass | Mục 4, 5 (tính trường hợp xấu nhất) |
| NFR-00-043 Giảm chuyển động, giảm trong suốt | Mục 5 (`glass-lite-tint`, `glass-off-tint`), 11 |
| NFR-00-044 Chế độ sáng, tối | Toàn bộ mục 3–8 có hai giá trị |
| NFR-00-045 Thống nhất giao diện, lint | Mục 13.1, 15 |
| FR-00-053 Nhãn trạng thái thống nhất | Mục 4.4 |
| RB-03, ADR-020, ADR-021 | Mục 10, 13 |

: Truy vết yêu cầu và ADR tới mục của D03-05-02

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: kiến trúc ba tầng token, bảng màu, token màu ngữ nghĩa, vật liệu glass, bo góc, bóng, khoảng cách, chữ, chuyển động, ánh xạ antd v6, đóng gói, kiểm tra, tùy biến theo tenant, truy vết |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Thêm token màu khác biệt và màu nguồn dữ liệu (mục 4.6) theo đề nghị của D03-06-PH07 |
| 0.3 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp, giữ nguyên nội dung kỹ thuật bản trước: thêm Tóm tắt cho hội đồng thẩm định; bổ sung chương 1 các mục 1.1–1.6 (mục đích, phạm vi, người đọc, thuật ngữ, tài liệu tham chiếu, cấu trúc); thêm đoạn mở cho mục 4.3, 6, 12.1, 12.2 và chương 17; viết lại 26 chú thích bảng cho cụ thể, bỏ chú thích trùng; thêm metadata mo_ta và tai_lieu_lien_quan |
