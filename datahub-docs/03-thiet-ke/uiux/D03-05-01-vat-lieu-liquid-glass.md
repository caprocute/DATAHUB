---
ma_tai_lieu: D03-05-01
ten: Vật liệu Liquid Glass, chế độ hiển thị và cơ chế hạ cấp
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư giao diện, Nhà thiết kế, Kiểm thử viên, Kiến trúc sư, AI agent sinh mã
mo_ta: Đặc tả cách hiểu và hiện thực Liquid Glass trong Datahub, gồm quy tắc đặt vật liệu, cấu tạo CSS, chế độ hiển thị, cơ chế tự hạ cấp trên máy yếu và hai thành phần nền tảng CMP-GlassSurface, CMP-ThemeProvider.
tai_lieu_lien_quan: ADR-020 Liquid Glass trên antd v6; D00-01 Thuật ngữ và quy ước; D02-02 SRS; D03-01 SAD; D03-05 Design system; D03-05-02 Design token; D03-05-03 Thành phần nguyên tử; D03-05-04 Thành phần phức hợp; D03-06-00 IA, layout, mẫu màn hình
nguoi_lap: Luồng giao diện
---

# D03-05-01 · Vật liệu Liquid Glass, chế độ hiển thị và cơ chế hạ cấp

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Giao diện Datahub dùng phong cách Liquid Glass một cách có chọn lọc để có chiều sâu thị giác, nhưng không đánh đổi khả năng đọc và hiệu năng trên máy văn phòng của cơ quan nhà nước. Tài liệu đặc tả kính được đặt ở đâu và không đặt ở đâu, dựng bằng CSS ra sao, người dùng tắt hoặc giảm kính thế nào, và giao diện tự chuyển về nền đặc ra sao khi máy yếu. Hai thành phần nền tảng `CMP-GlassSurface` và `CMP-ThemeProvider` được đặc tả trọn vẹn tại đây.

**Phạm vi.** Tài liệu gồm cách hiểu Liquid Glass và phần Datahub lấy (chương 2), bản đồ vật liệu và các điều cấm (chương 3), cấu tạo CSS (chương 4), topbar thích ứng khi cuộn (chương 5), bốn tùy chọn người dùng và cách phân giải chế độ kính (chương 6), thuật toán tự hạ cấp (chương 7), chế độ sáng, tối, tương phản cao (chương 8), đặc tả hai thành phần nền tảng (chương 9) và sáu kịch bản kiểm thử (chương 10). Giá trị số của vật liệu nằm ở D03-05-02 §5 đến §8.

**Căn cứ.** STD-04 (WCAG 2.2, mức AA) cho tương phản và vùng chạm; NFR-00-040, NFR-00-041, NFR-00-043, NFR-00-044, NFR-00-045 và NFR-00-005 của SRS; rủi ro RSK-A05 của SAD (glass làm chậm máy yếu); ADR-020 (Liquid Glass trên antd v6).

**Những điểm hội đồng cần lưu ý.** (1) Kính chỉ thuộc lớp điều hướng và lớp nổi; bảng, biểu mẫu, log và biểu đồ luôn nằm trên nền đặc, vì chữ dày đặc trên nền thay đổi gây mỏi mắt và khó đạt tương phản. (2) Độ đục của kính được tính cho trường hợp xấu nhất (nền đen tuyệt đối ở chế độ sáng, trắng tuyệt đối ở chế độ tối), và có điều cấm đặt chữ liên kết hay chữ màu trạng thái trực tiếp lên hai vật liệu không đạt 4,5:1. (3) Lựa chọn tường minh của người dùng luôn thắng tín hiệu tự động; khi để "Tự động", tín hiệu truy cập (màu cưỡng bức, giảm trong suốt, tăng tương phản) được xét trước hiệu năng. (4) Máy yếu hoặc kết xuất phần mềm được tự động hạ về nền đặc, có lưới an toàn khi dùng thật, nên người dùng không phải tự phát hiện và tắt hiệu ứng. (5) Số phần tử có `backdrop-filter` hiển thị cùng lúc bị giới hạn tối đa bốn để giữ 60 khung hình mỗi giây khi cuộn trên máy bốn nhân.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Vật liệu glass | 4 (`glass-chrome`, `glass-chrome-scrolled`, `glass-modal`, `glass-overlay`) |
| Tùy chọn người dùng độc lập | 4 (chế độ màu, hiệu ứng kính, chuyển động, mật độ) |
| Chế độ kính đã phân giải | 3 (`full`, `lite`, `off`) |
| Điều cấm khi đặt vật liệu | 5 (mục 3.2) |
| Số phần tử `backdrop-filter` tối đa cùng lúc | 4 |
| Bước xếp hạng hiệu năng máy | 4; p90 khoảng cách khung ≤ 20 ms là hạng Cao, trên 34 ms là hạng Thấp |
| Ngưỡng chuyển topbar sang trạng thái cuộn | cuộn quá 4 px |
| Chu kỳ đo lại hiệu năng | 30 ngày |
| Kịch bản kiểm thử vật liệu | 6 (TS-00-UI-01…06) |
| Thành phần nền tảng đặc tả | 2 (`CMP-GlassSurface`, `CMP-ThemeProvider`) |

: Con số chính của đặc tả vật liệu Liquid Glass

Các con số trên được lấy từ chương 3, 5, 6, 7 và 10 của tài liệu này; hạng hiệu năng được đo trên từng máy và báo về PH-13 dưới dạng chỉ số tổng hợp.

## 1. Mục đích

Tài liệu này giải thích **Liquid Glass được hiểu và hiện thực như thế nào trong Datahub**: nó là gì, đặt ở đâu và không đặt ở đâu, được dựng bằng CSS ra sao trên nền Ant Design v6, làm thế nào để vẫn đạt WCAG 2.2 mức AA, và làm thế nào để giao diện tự chuyển về nền đặc khi người dùng yêu cầu hoặc khi máy không đủ mạnh. Hai thành phần nền tảng `CMP-GlassSurface` và `CMP-ThemeProvider` được đặc tả trọn vẹn tại đây, vì mọi thành phần khác của D03-05-03 và D03-05-04 dựa trên chúng.

Giá trị cụ thể của từng vật liệu (độ đục, độ nhòe, viền, bóng) nằm ở D03-05-02 §5 đến §8. Lý do chọn Liquid Glass thay cho phong cách shadcn của repo cũ được ghi ở ADR-020.

### 1.1. Mục đích của tài liệu

Tài liệu là nguồn chuẩn duy nhất về vật liệu kính của design system. Hội đồng thẩm định dùng nó để đánh giá việc dùng kính có làm giảm khả năng đọc hay hiệu năng không. Kỹ sư dùng chương 3, 4 và 9 khi viết thành phần; kiểm thử viên dùng chương 10 để nghiệm thu NFR-00-041 và NFR-00-043.

### 1.2. Phạm vi

Bảng dưới phân định điều tài liệu này quy định và điều nằm ở tài liệu khác.

| Thuộc tài liệu này | Nằm ở tài liệu khác |
|---|---|
| Cách hiểu Liquid Glass, bản đồ vật liệu, các điều cấm | Giá trị độ đục, độ nhòe, viền, bóng: D03-05-02 §5 đến §8 |
| Cấu tạo CSS, topbar thích ứng, chế độ hiển thị, hạ cấp | Lý do chọn Liquid Glass thay shadcn: ADR-020 |
| `CMP-GlassSurface`, `CMP-ThemeProvider` | Thành phần dùng kính (Modal, Drawer, Topbar…): D03-05-03, D03-05-04 |
| Kịch bản kiểm thử vật liệu `TS-00-UI-01…06` | Kiểm tra token tự động chung: D03-05-02 §15 |

: Phân định phạm vi giữa D03-05-01 và các tài liệu liên quan

### 1.3. Người đọc và cách đọc

Bảng dưới gợi ý phần cần đọc theo vai trò.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 2, 3, 7 | Đánh giá cách đặt kính, mức truy cập và cơ chế hạ cấp |
| Kỹ sư giao diện | Chương 3, 4, 6, 9 | Đặt vật liệu đúng, dùng `CMP-GlassSurface` và `CMP-ThemeProvider` |
| Nhà thiết kế | Chương 2, 3, 8 | Chọn vùng được phép dùng kính, hình dung chế độ sáng, tối |
| Kiểm thử viên | Chương 6, 7, 10 | Ca kiểm thử tương phản, hiệu năng, hạ cấp, màu cưỡng bức |
| Kiến trúc sư | Chương 6, 7 | Cơ chế lưu tùy chọn và đo hiệu năng phía trình duyệt |
| AI agent sinh mã | Chương 3, 4, 9 | Không tự chọn vật liệu, chỉ dùng thành phần đã đặc tả |

: Người đọc D03-05-01 và phần cần đọc theo vai trò

### 1.4. Thuật ngữ và chữ viết tắt

Bảng dưới chỉ gồm thuật ngữ riêng của vật liệu kính. Thuật ngữ chung theo D00-01 §2.

| Thuật ngữ | Giải thích |
|---|---|
| Liquid Glass | Ngôn ngữ vật liệu Apple giới thiệu năm 2025; Datahub chỉ lấy ba nguyên tắc: phân lớp, vật liệu thích ứng, hình khối mềm đồng tâm |
| Tint | Lớp màu bán trong suốt phủ lên kính, quyết định độ đọc được của chữ |
| `backdrop-filter` | Thuộc tính CSS làm nhòe và tăng bão hòa phần phông nền phía sau phần tử |
| Giếng nội dung | Vùng nền đặc bên trong một lớp nổi bằng kính, chứa biểu mẫu hoặc bảng |
| Chế độ kính | Ba giá trị đã phân giải `full`, `lite`, `off` của thuộc tính `data-glass` |
| Hạng hiệu năng máy | Kết quả xếp hạng Thấp, Trung bình, Cao từ phép đo trên trình duyệt |
| Scroll edge | Dải mờ dần dưới topbar khi nội dung cuộn bên dưới |
| Trường hợp xấu nhất | Phông nền giả định đen tuyệt đối (sáng) hoặc trắng tuyệt đối (tối) khi tính tương phản |

: Thuật ngữ riêng của vật liệu Liquid Glass

### 1.5. Tài liệu tham chiếu

Các tài liệu dưới đây được dẫn chiếu trong D03-05-01.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| STD-04 | WCAG 2.2 | Ngưỡng tương phản 4,5:1 và 3:1, vùng chạm |
| ADR-020 | Liquid Glass trên antd v6 | Lý do chọn và cách áp |
| D02-02 | Đặc tả yêu cầu phần mềm (SRS) | NFR-00-005, NFR-00-040…045 |
| D03-01 | Thiết kế kiến trúc tổng thể (SAD) | Rủi ro RSK-A05 |
| D03-05 | Design system (tài liệu tổng) | Nguyên tắc, thứ tự ưu tiên giữa các tập |
| D03-05-02 | Design token | Giá trị vật liệu, bảng tương phản |
| D03-05-03, D03-05-04 | Thành phần nguyên tử, phức hợp | Thành phần dùng vật liệu |
| D03-06-00 | IA, layout, mẫu màn hình | PTN-12 (Cài đặt cá nhân) |

: Tài liệu tham chiếu của D03-05-01

### 1.6. Cấu trúc tài liệu

Tài liệu đi từ khái niệm tới quy tắc, cấu tạo, hành vi và kiểm thử. Bảng dưới tóm tắt từng chương.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 2 | Liquid Glass là gì, Datahub lấy và không lấy gì | Hội đồng, nhà thiết kế |
| 3 | Bản đồ vật liệu, điều cấm, vì sao nội dung dùng nền đặc | Mọi người đọc |
| 4 | Cấu tạo vật liệu bằng CSS | Kỹ sư giao diện |
| 5 | Topbar thích ứng khi cuộn | Kỹ sư, kiểm thử viên |
| 6 | Bốn tùy chọn người dùng, phân giải chế độ kính, chống nhấp nháy | Kỹ sư, kiến trúc sư |
| 7 | Tự động hạ cấp trên máy yếu | Kỹ sư, hội đồng |
| 8 | Chế độ sáng, tối, tương phản cao | Nhà thiết kế, kiểm thử viên |
| 9 | Đặc tả `CMP-GlassSurface`, `CMP-ThemeProvider` | Kỹ sư, AI agent |
| 10 | Kiểm thử vật liệu | Kiểm thử viên |
| 11, 12 | Truy vết, đề xuất bổ sung D00-01 | Quản lý chất lượng |

: Cấu trúc chương của D03-05-01

## 2. Liquid Glass là gì và Datahub lấy gì từ nó

Liquid Glass là ngôn ngữ vật liệu mà Apple giới thiệu năm 2025 cho toàn bộ hệ điều hành của hãng. Ý tưởng cốt lõi là tách giao diện thành hai lớp. **Lớp nội dung** là thứ người dùng đến để xem và làm việc: bảng, biểu mẫu, văn bản, hình ảnh. **Lớp chức năng** là các điều khiển và thanh điều hướng nổi phía trên nội dung, được làm bằng một vật liệu giống kính: trong mờ, làm nhòe và khúc xạ những gì nằm sau nó, có mép phản quang, và đổi sắc độ theo nội dung bên dưới. Nhờ vậy điều hướng luôn hiện diện nhưng không tranh chỗ với nội dung, và người dùng cảm nhận được chiều sâu của giao diện.

Datahub là một ứng dụng quản trị dày dữ liệu chứ không phải ứng dụng tiêu dùng, nên không chép nguyên Liquid Glass mà chọn lọc ba nguyên tắc có giá trị thực sự cho người dùng hành chính:

1. **Phân lớp rõ ràng.** Glass chỉ thuộc về lớp chức năng (điều hướng và lớp nổi). Nội dung dày luôn nằm trên nền đặc. Người dùng nhờ đó phân biệt tức thì đâu là "khung" của ứng dụng và đâu là "việc" của mình.
2. **Vật liệu thích ứng.** Độ đục của kính tăng lên khi nội dung trượt bên dưới nó, để chữ trên kính luôn đọc được. Đây là phiên bản web của hiệu ứng "scroll edge" mà Apple dùng cho thanh điều hướng.
3. **Hình khối mềm và đồng tâm.** Bo góc lớn hơn antd mặc định, các hình lồng nhau có góc đồng tâm, điều khiển dạng viên nang, chuyển động có quán tính nhẹ.

Datahub **không** lấy các yếu tố sau, vì chi phí lớn hơn lợi ích trong bối cảnh máy văn phòng của cơ quan nhà nước: hiệu ứng khúc xạ cong (lensing) bằng bộ lọc SVG `feDisplacementMap` (chỉ chạy ổn trên trình duyệt nhân Chromium và tốn GPU), phản chiếu ánh sáng động theo con trỏ hoặc cảm biến, và kính trong suốt hoàn toàn kiểu "clear" (không đạt tương phản với nội dung tùy ý).

## 3. Quy tắc đặt vật liệu

### 3.1. Bản đồ vật liệu

Bảng dưới đây là quy tắc bắt buộc về việc mỗi vùng giao diện dùng vật liệu nào. Kỹ sư không tự chọn vật liệu cho thành phần; mỗi thành phần trong D03-05-03 và D03-05-04 đã ghi vật liệu theo bảng này.

| Vùng | Vật liệu | Lý do |
|---|---|---|
| Canvas (nền ứng dụng) | `color-canvas` + `color-canvas-wash` | Là "phông nền" để kính có cái để làm nhòe |
| Sidebar | `glass-chrome` | Lớp điều hướng; luôn nằm trên canvas nên phông nền được kiểm soát |
| Topbar khi trang ở đầu | `glass-chrome` | Lớp điều hướng |
| Topbar khi nội dung cuộn bên dưới | `glass-chrome-scrolled` + `glass-scroll-edge` | Nội dung tùy ý trượt bên dưới, cần độ đục cao hơn |
| Khung Modal, Drawer, CommandPalette | `glass-modal` | Lớp nổi lớn; nội dung bên trong đặt trong giếng nền đặc |
| Popover, Dropdown, danh sách chọn của Select/DatePicker/Cascader, Notification | `glass-overlay` | Lớp nổi nhỏ; vật liệu đạt tương phản mọi nấc chữ trong trường hợp xấu nhất |
| Thanh chọn nhiều nổi trên canvas thiết kế (`CMP-BulkActionBar` biến thể `floating`) | `glass-overlay` | Nổi trên sơ đồ. Thanh thao tác hàng loạt của bảng dính ở đầu thân bảng và là nền đặc (D03-05-04 §8.2) |
| Thanh công cụ nổi trên canvas thiết kế | `glass-overlay` | Nổi trên sơ đồ |
| Tooltip, Toast | `color-surface-inverse` đặc | Chữ nhỏ, xuất hiện trên mọi nền, cần tương phản tuyệt đối |
| Card, bảng, biểu mẫu, mô tả chi tiết, log, khối mã, biểu đồ, bề mặt và nút của canvas thiết kế, bảng thành phần, Inspector, thanh công cụ trình thiết kế | `color-surface-solid` hoặc `color-surface-solid-2` đặc | Lớp nội dung (D03-05-04 §11.0) |
| Vùng nội dung trong Modal, Drawer | `color-surface-solid` đặc (giếng nội dung) | Biểu mẫu và bảng trong lớp nổi vẫn là nội dung |

: Bản đồ vật liệu theo vùng giao diện

### 3.2. Các điều cấm

Có năm điều cấm. Thứ nhất, không đặt bảng, biểu mẫu, log hoặc khối văn bản dài trực tiếp lên kính, vì chữ dày đặc trên nền thay đổi gây mỏi mắt và khó đạt tương phản. Thứ hai, không xếp kính chồng lên kính, vì hai lớp nhòe chồng nhau tạo màu đục khó đoán và nhân đôi chi phí GPU; ngoại lệ duy nhất là một lớp `glass-overlay` (ví dụ danh sách chọn của Select) mở ra từ bên trong giếng nội dung của Modal, vì khi đó phông nền trực tiếp của overlay là nền đặc của giếng chứ không phải kính. Thứ ba, không dùng kính để trang trí cho Card hay ô KPI chỉ vì "đẹp", vì như vậy phá vỡ ý nghĩa phân lớp. Thứ tư, không đặt chữ liên kết cỡ thường hay chữ màu trạng thái trực tiếp trên `glass-chrome-scrolled` và `glass-modal`, vì hai vật liệu này không đạt 4,5:1 với chữ màu nhấn trong trường hợp xấu nhất (D03-05-02 §5). Thứ năm, không đặt hơn **bốn** phần tử có `backdrop-filter` cùng hiển thị trên màn hình (sidebar, topbar, một lớp nổi lớn, một lớp nổi nhỏ), vì đây là ngưỡng mà máy văn phòng bốn nhân vẫn giữ được 60 khung hình mỗi giây khi cuộn.

### 3.3. Vì sao nội dung dày phải dùng nền đặc

Yêu cầu nền đặc cho nội dung không chỉ là lựa chọn thẩm mỹ. Một bảng giao dịch thanh toán hay một trang log có hàng trăm chuỗi chữ cỡ 12–14px. Nếu nền phía sau chữ thay đổi theo vị trí cuộn, tương phản cục bộ của mỗi ký tự thay đổi theo, và người đọc phải điều tiết mắt liên tục. Ngoài ra, mỗi lần bảng ảo hóa vẽ lại hàng, trình duyệt phải tính lại lớp nhòe phía sau, làm giảm đáng kể độ mượt khi cuộn. Nền đặc giải quyết cả hai vấn đề với chi phí bằng không.

## 4. Cấu tạo vật liệu bằng CSS

Mỗi vật liệu glass được dựng từ năm lớp chồng lên nhau trên cùng một phần tử, theo thứ tự từ dưới lên:

```{.mermaid caption="Cấu tạo vật liệu bằng CSS"}
flowchart BT
  B[Phông nền phía sau<br/>canvas hoặc nội dung] --> F[backdrop-filter<br/>blur + saturate]
  F --> T[Tint<br/>background-color rgba]
  T --> H[Mép phản quang<br/>inset 0 1px highlight]
  H --> E[Viền ngoài mảnh<br/>0 0 0 0.5px edge]
  E --> S[Bóng đổ mềm<br/>shadow-2/3/4]
```

Sơ đồ đọc từ dưới lên. Trình duyệt lấy ảnh của vùng phía sau phần tử, làm nhòe và tăng bão hòa nó (`backdrop-filter`), phủ lên một lớp màu bán trong suốt (tint) quyết định độ đọc được của chữ, rồi vẽ mép phản quang phía trên, đường viền ngoài và bóng đổ trong cùng một khai báo `box-shadow`. Tint là lớp quan trọng nhất về truy cập: nó bảo đảm rằng dù phông nền là gì, màu tổng hợp vẫn đủ sáng (chế độ sáng) hoặc đủ tối (chế độ tối) để chữ đạt ngưỡng.

Mã CSS chuẩn trong `@datahub/ui/src/glass/glass.css`:

```css
/* Lớp cơ sở: chỉ dùng biến, không có giá trị thô */
.dh-glass {
  position: relative;
  isolation: isolate;
  background-color: var(--dh-glass-tint);
  -webkit-backdrop-filter: blur(var(--dh-glass-blur)) saturate(var(--dh-glass-saturate));
  backdrop-filter: blur(var(--dh-glass-blur)) saturate(var(--dh-glass-saturate));
  box-shadow: var(--dh-glass-highlight-top), var(--dh-glass-edge), var(--dh-glass-shadow);
  transition: background-color var(--dh-motion-duration-base) var(--dh-motion-ease-standard);
}

.dh-glass--chrome {
  --dh-glass-tint: var(--dh-glass-chrome-tint);
  --dh-glass-blur: var(--dh-blur-md);
  --dh-glass-saturate: var(--dh-saturate-glass);
  --dh-glass-shadow: none;
}
.dh-glass--chrome-scrolled {
  --dh-glass-tint: var(--dh-glass-chrome-scrolled-tint);
  --dh-glass-blur: var(--dh-blur-lg);
  --dh-glass-saturate: var(--dh-saturate-glass);
  --dh-glass-shadow: var(--dh-shadow-2);
}
.dh-glass--modal {
  --dh-glass-tint: var(--dh-glass-modal-tint);
  --dh-glass-blur: var(--dh-blur-xl);
  --dh-glass-saturate: var(--dh-saturate-glass-muted);
  --dh-glass-shadow: var(--dh-shadow-4);
}
.dh-glass--overlay {
  --dh-glass-tint: var(--dh-glass-overlay-tint);
  --dh-glass-blur: var(--dh-blur-lg);
  --dh-glass-saturate: var(--dh-saturate-glass-muted);
  --dh-glass-shadow: var(--dh-shadow-3);
}

/* Chế độ Giảm: giữ tint gần đặc, bỏ nhòe */
:root[data-glass="lite"] .dh-glass {
  --dh-glass-tint: var(--dh-glass-lite-tint);
  -webkit-backdrop-filter: none;
  backdrop-filter: none;
}

/* Chế độ Tắt: nền đặc hoàn toàn, chỉ giữ viền và bóng */
:root[data-glass="off"] .dh-glass {
  --dh-glass-tint: var(--dh-color-surface-solid);
  --dh-glass-highlight-top: 0 0 0 0 transparent;
  -webkit-backdrop-filter: none;
  backdrop-filter: none;
}

/* Trình duyệt không hỗ trợ backdrop-filter: tự về chế độ Giảm */
@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  .dh-glass { --dh-glass-tint: var(--dh-glass-lite-tint); }
}

/* Chế độ màu cưỡng bức của Windows (High Contrast) */
@media (forced-colors: active) {
  .dh-glass {
    background-color: Canvas;
    backdrop-filter: none;
    box-shadow: none;
    border: 1px solid CanvasText;
  }
}
```

Có ba chi tiết hiện thực cần lưu ý. Thuộc tính `isolation: isolate` tạo ngữ cảnh xếp chồng riêng, tránh trường hợp `backdrop-filter` của phần tử con làm nhòe nhầm chính phần tử cha. Tiền tố `-webkit-` vẫn cần cho Safari. Và vì antd v6 dựng Modal, Drawer, Popover, Dropdown bằng cổng (portal) gắn vào `body`, lớp glass được gắn qua thuộc tính ngữ nghĩa `classNames` của từng thành phần antd (ví dụ `classNames={{ container: 'dh-glass dh-glass--modal' }}` cho Modal, hay `classNames={{ popup: { root: 'dh-glass dh-glass--overlay' } }}` cho Select), không qua bộ chọn CSS lồng nhau. Tên khóa cụ thể của `classNames` cho từng thành phần được ghi trong đặc tả thành phần ở D03-05-03 và D03-05-04, đối chiếu với định nghĩa kiểu của bản antd đang cố định.

## 5. Topbar thích ứng khi cuộn

Topbar là nơi duy nhất mà nội dung tùy ý trượt bên dưới kính. Để giữ tương phản, topbar có hai trạng thái và chuyển giữa chúng theo vị trí cuộn của vùng nội dung chính.

```{.mermaid caption="Topbar thích ứng khi cuộn"}
stateDiagram-v2
  [*] --> AtTop
  AtTop: Ở đầu trang<br/>glass-chrome, không bóng
  Scrolled: Đang cuộn<br/>glass-chrome-scrolled, shadow-2, scroll-edge 16px
  AtTop --> Scrolled: scrollTop > 4px
  Scrolled --> AtTop: scrollTop = 0
```

Sơ đồ trạng thái cho thấy topbar chuyển sang `glass-chrome-scrolled` ngay khi nội dung cuộn quá 4px, và quay lại khi về đúng đầu trang. Ngưỡng 4px tránh nhấp nháy khi người dùng cuộn rất nhẹ bằng bàn di chuột. Việc phát hiện dùng `IntersectionObserver` trên một phần tử mốc cao 1px ở đầu vùng nội dung, không dùng sự kiện `scroll`, để không gây tính toán trên mỗi khung hình. Dải `glass-scroll-edge` cao 16px nằm ngay dưới topbar làm nội dung "tan" dần vào kính thay vì bị cắt sắc, và nó có `pointer-events: none` để không chặn thao tác với hàng bảng phía dưới.

## 6. Chế độ hiển thị và tùy chọn người dùng

### 6.1. Bốn tùy chọn độc lập

Người dùng điều chỉnh giao diện bằng bốn tùy chọn độc lập trong trang Cài đặt cá nhân (PTN-12, D03-06-00). Mỗi tùy chọn có giá trị "Theo hệ thống" hoặc "Tự động" là mặc định.

| Tùy chọn | Giá trị | Mặc định | Nguồn tín hiệu khi để mặc định |
|---|---|---|---|
| Chế độ màu | Theo hệ thống / Sáng / Tối | Theo hệ thống | `prefers-color-scheme` |
| Hiệu ứng kính | Tự động / Đầy đủ / Giảm / Tắt | Tự động | `prefers-reduced-transparency`, `prefers-contrast`, đo hiệu năng (mục 7) |
| Chuyển động | Theo hệ thống / Đầy đủ / Giảm | Theo hệ thống | `prefers-reduced-motion` |
| Mật độ | Chuẩn / Gọn | Chuẩn | Không có |

: Bốn tùy chọn giao diện độc lập, giá trị và mặc định

Lựa chọn được lưu ở hai nơi: `localStorage` để áp dụng ngay khi tải trang (chống nhấp nháy), và hồ sơ người dùng phía máy chủ để theo người dùng sang máy khác. Khi hai nơi khác nhau, giá trị máy chủ thắng sau khi đăng nhập xong.

### 6.2. Phân giải chế độ kính

Tùy chọn "Hiệu ứng kính" có bốn giá trị nhưng thuộc tính `data-glass` trên thẻ `html` chỉ nhận ba giá trị đã phân giải `full`, `lite`, `off`. Thuật toán phân giải như sau:

```{.mermaid caption="Phân giải chế độ kính"}
flowchart TD
  A[Tùy chọn người dùng] -->|Đầy đủ| FULL[full]
  A -->|Giảm| LITE[lite]
  A -->|Tắt| OFF[off]
  A -->|Tự động| B{forced-colors: active?}
  B -->|Có| OFF
  B -->|Không| C{prefers-reduced-transparency: reduce<br/>hoặc prefers-contrast: more?}
  C -->|Có| LITE
  C -->|Không| D{Hạng hiệu năng máy}
  D -->|Thấp| OFF
  D -->|Trung bình| LITE
  D -->|Cao| FULL
```

Sơ đồ cho thấy lựa chọn tường minh của người dùng luôn thắng mọi tín hiệu tự động. Khi để "Tự động", tín hiệu truy cập (màu cưỡng bức, giảm trong suốt, tăng tương phản) được xét trước tín hiệu hiệu năng, vì nhu cầu truy cập quan trọng hơn thẩm mỹ. Truy vấn `prefers-reduced-transparency` hiện mới được một phần trình duyệt hỗ trợ; trên trình duyệt chưa hỗ trợ, truy vấn đơn giản trả về không khớp và thuật toán đi tiếp tới bước hiệu năng, còn người dùng vẫn có công tắc thủ công để đáp ứng NFR-00-043.

### 6.3. Chống nhấp nháy khi tải

Một tập lệnh nội tuyến rất nhỏ (dưới 1 KB) đặt trong thẻ `head` của `index.html`, chạy trước khi React khởi động, đọc `localStorage` và các truy vấn phương tiện rồi gán ngay `data-theme`, `data-glass`, `data-density`, `data-motion` lên thẻ `html`. Nếu chưa có kết quả đo hiệu năng lưu trước đó, tập lệnh tạm gán `data-glass="lite"`; đây là giá trị an toàn vì vừa đọc tốt vừa nhẹ, và nó được nâng lên `full` sau khi phép đo ở mục 7 hoàn tất nếu máy đủ mạnh. Cách làm này tránh hiện tượng trang lóe trắng khi người dùng đang ở chế độ tối, và tránh việc máy yếu phải gánh hiệu ứng kính ngay ở lần vẽ đầu tiên.

## 7. Tự động hạ cấp trên máy yếu

### 7.1. Vì sao cần

Máy tính tại cơ quan nhà nước rất đa dạng: máy văn phòng đời cũ với đồ họa tích hợp, máy trạm ảo (VDI) hoặc phiên điều khiển từ xa nơi trình duyệt kết xuất bằng phần mềm (không có GPU). Trên những máy này, `backdrop-filter` có thể làm mỗi khung hình mất hàng chục mili giây, làm cuộn bảng giật và vi phạm chỉ tiêu INP ≤ 200 ms của NFR-00-005. Rủi ro này đã được ghi tại RSK-A05 của SAD. Cơ chế dưới đây bảo đảm người dùng không bao giờ phải tự phát hiện và tự tắt hiệu ứng.

### 7.2. Thuật toán xếp hạng

Phép đo chạy một lần sau khi ứng dụng tải xong và trình duyệt rảnh (`requestIdleCallback`), kết quả được lưu trong `localStorage` kèm thời điểm, và đo lại sau 30 ngày hoặc khi chuỗi nhận dạng trình duyệt thay đổi.

| Bước | Tín hiệu | Cách lấy | Kết luận |
|---|---|---|---|
| 1 | Kết xuất phần mềm | Đọc tên bộ kết xuất qua WebGL (`WEBGL_debug_renderer_info`); khớp mẫu `SwiftShader`, `llvmpipe`, `Software`, `Microsoft Basic Render` | Có → hạng **Thấp** |
| 2 | Tài nguyên phần cứng | `navigator.hardwareConcurrency` ≤ 2, hoặc `navigator.deviceMemory` ≤ 2 (chỉ có trên Chromium) | Có → hạng **Thấp**; ≤ 4 nhân hoặc ≤ 4 GB → ứng viên **Trung bình** |
| 3 | Đo khung hình thực tế | Gắn tạm một lớp `dh-glass--overlay` kích thước 480×320 ngoài màn hình nhìn thấy, cho một phần tử phía sau chuyển động trong 1 giây, đo khoảng cách giữa các khung bằng `requestAnimationFrame` | p90 khoảng cách ≤ 20 ms → **Cao**; 20–34 ms → **Trung bình**; > 34 ms → **Thấp** |
| 4 | Theo dõi khi dùng | `PerformanceObserver` loại `long-animation-frame` (hoặc `longtask` nếu không có) trong khi dùng thật | Từ 5 khung dài trên 100 ms trong 10 giây khi đang ở `full` → hạ xuống `lite` cho phiên hiện tại và ghi nhận |

: Bốn bước xếp hạng hiệu năng máy

Bước 4 là lưới an toàn: nếu phép đo ban đầu lạc quan (ví dụ máy đang rảnh lúc đo nhưng bận khi dùng), ứng dụng tự hạ cấp trong phiên. Mỗi lần tự hạ cấp, một thông báo nhỏ không chặn thao tác (`CMP-Toast`) cho người dùng biết "Đã giảm hiệu ứng kính để giao diện mượt hơn. Có thể đổi trong Cài đặt." Thông báo chỉ hiện một lần cho mỗi máy.

### 7.3. Đo lường và báo cáo

Kết quả xếp hạng (không kèm thông tin nhận dạng người dùng) được gửi về PH-13 dưới dạng chỉ số tổng hợp `ui_glass_tier_total{tier}` để đội sản phẩm biết tỷ lệ máy ở từng hạng theo tenant, phục vụ quyết định có nên giữ hay đơn giản hóa vật liệu trong các bản sau.

## 8. Chế độ sáng, tối và tương phản cao

Chế độ sáng và tối dùng chung toàn bộ cấu trúc vật liệu, chỉ khác giá trị token (D03-05-02). Ở chế độ tối, tint của kính là màu xám rất sẫm `rgba(28,28,30,…)` thay vì đen thuần, vì đen thuần làm kính trông như một lỗ thủng; mép phản quang mờ hơn nhiều (0,12 so với 0,65) để không tạo đường sáng chói trên nền tối.

Khi hệ điều hành báo `prefers-contrast: more`, ngoài việc phân giải kính về `lite` như mục 6.2, ứng dụng gán thêm `data-contrast="more"` để tăng `color-border-subtle` lên bằng `color-border-control` (mọi đường viền đều đạt 3:1) và tăng độ dày vòng focus lên 3px. Khi Windows bật chế độ màu cưỡng bức, khối `@media (forced-colors: active)` ở mục 4 trả mọi bề mặt về màu hệ thống; antd v6 đã tự xử lý phần lớn thành phần trong chế độ này, `@datahub/ui` chỉ bổ sung cho lớp glass và `CMP-StatusTag` (thêm viền để nhãn không biến mất khi nền bị bỏ).

## 9. Đặc tả thành phần nền tảng

### 9.1. CMP-GlassSurface

**Mục đích.** `CMP-GlassSurface` là thành phần nguyên thủy duy nhất được phép sinh ra vật liệu kính. Mọi thành phần khác cần kính (Topbar, Sidebar, Modal, Drawer, Popover, BulkActionBar nổi, thanh công cụ canvas) hoặc dùng `CMP-GlassSurface` làm phần tử gốc, hoặc gắn đúng các lớp CSS mà nó định nghĩa qua `classNames` của antd. Việc tập trung vào một chỗ cho phép kiểm soát số lớp `backdrop-filter` và áp chế độ kính thống nhất.

**Thuộc tính.**

```tsx
export type GlassMaterial = 'chrome' | 'chrome-scrolled' | 'modal' | 'overlay';

export interface GlassSurfaceProps extends React.HTMLAttributes<HTMLElement> {
  /** Vật liệu theo D03-05-01 §3.1. Bắt buộc. */
  material: GlassMaterial;
  /** Phần tử HTML gốc; mặc định 'div'. Topbar dùng 'header', Sidebar dùng 'nav'. */
  as?: 'div' | 'header' | 'nav' | 'aside' | 'section';
  /** Bo góc theo token; mặc định theo vật liệu (chrome: 0, modal: xl, overlay: lg). */
  radius?: 'none' | 'md' | 'lg' | 'xl' | 'pill';
  /** Tự chuyển chrome → chrome-scrolled theo phần tử mốc cuộn (chỉ cho Topbar). */
  adaptiveToScroll?: React.RefObject<HTMLElement>;
  children: React.ReactNode;
}
```

**Hành vi.** Thành phần đọc chế độ kính đã phân giải từ ngữ cảnh `CMP-ThemeProvider`. Ở môi trường phát triển, nó đếm số `GlassSurface` đang hiển thị qua một bộ đếm toàn cục và in cảnh báo trên bảng điều khiển khi vượt bốn, giúp phát hiện sớm vi phạm điều cấm thứ năm ở mục 3.2. Thành phần không tự gán vai trò ARIA; vai trò thuộc về thành phần dùng nó (ví dụ `banner` cho Topbar).

**Truy cập.** Kính là yếu tố trình bày thuần túy, không mang thông tin, nên không cần văn bản thay thế. Thành phần bảo đảm vòng focus của phần tử con không bị `overflow: hidden` cắt mất bằng cách đặt vùng đệm 2px bên trong.

**Ví dụ.**

```tsx
<GlassSurface as="header" material="chrome" adaptiveToScroll={contentTopSentinelRef}
              role="banner" className="dh-topbar">
  <TenantSwitcher />
  <SearchField variant="pill" />
  <NotificationCenter />
  <UserMenu />
</GlassSurface>
```

**Điều cấm.** Không lồng `GlassSurface` trong `GlassSurface`. Không truyền `style={{ background }}` để đổi tint. Không dùng cho Card, ô KPI hay hàng bảng.

### 9.2. CMP-ThemeProvider

**Mục đích.** `CMP-ThemeProvider` (tên thành phần trong mã là `DhThemeProvider`) bao toàn bộ ứng dụng `dh-console` và `dh-portal`. Nó phân giải bốn tùy chọn người dùng ở mục 6 thành giá trị cụ thể, gán thuộc tính dữ liệu lên thẻ `html`, dựng cấu hình theme antd v6 bằng `buildAntdTheme` (D03-05-02 §13.4), cung cấp ngôn ngữ tiếng Việt cho antd và dayjs, và cung cấp ngữ cảnh cho các thành phần cần biết chế độ hiện tại (ví dụ `CMP-Chart` cần đổi theme ECharts, `CMP-CodeEditor` cần đổi theme Monaco).

**Hook công khai.**

| Hook | Trả về | Dùng cho |
|---|---|---|
| `useDhPreferences()` | `{ colorScheme, glass, motion, density }` (giá trị người dùng chọn, có thể là `'system'`/`'auto'`) và hàm `setPreference` | Trang Cài đặt cá nhân |
| `useDhAppearance()` | `{ mode: 'light' \| 'dark', glass: 'full' \| 'lite' \| 'off', reducedMotion: boolean, density, glassTier }` (giá trị đã phân giải) | Thành phần cần biết chế độ thực tế |

: Hook công khai của CMP-ThemeProvider

**Thuộc tính dữ liệu trên thẻ `html`.** `data-theme` (`light`/`dark`), `data-glass` (`full`/`lite`/`off`), `data-motion` (`full`/`reduced`), `data-density` (`comfortable`/`compact`), `data-contrast` (`normal`/`more`). CSS của `@datahub/ui` chỉ được rẽ nhánh theo năm thuộc tính này, không tự đọc truy vấn phương tiện, để mọi lựa chọn thủ công của người dùng được tôn trọng nhất quán.

**Chuyển chế độ.** Khi người dùng đổi chế độ màu, provider thêm lớp `dh-theme-transition` vào thẻ `html` trong 220ms để màu nền và chữ chuyển mượt; lớp này bị bỏ qua khi `data-motion="reduced"`. Đổi chế độ không dựng lại cây React; chỉ giá trị biến CSS thay đổi, nhờ chế độ CSS variables của antd v6.

## 10. Kiểm thử vật liệu

Ngoài bốn kiểm tra chung ở D03-05-02 §15, vật liệu có bộ kiểm thử riêng:

| Mã kiểm thử đề xuất | Nội dung | Cách làm | Điều kiện đạt |
|---|---|---|---|
| TS-00-UI-01 | Tương phản chữ trên kính trong trường hợp xấu nhất | Story đặc biệt đặt từng vật liệu trên nền đen tuyệt đối (sáng) và trắng tuyệt đối (tối), chạy axe-core | Đạt đúng các cặp được phép ở D03-05-02 §5 |
| TS-00-UI-02 | Topbar thích ứng | Playwright cuộn bảng 200 dòng dưới topbar, chụp màn hình, đo tương phản vùng chữ topbar | ≥ 4,5:1 tại mọi vị trí cuộn |
| TS-00-UI-03 | Hiệu năng cuộn | Playwright với CPU giảm tốc 4 lần, cuộn bảng 1.000 dòng ảo hóa ở `data-glass="full"` | p95 thời lượng khung ≤ 33 ms |
| TS-00-UI-04 | Hạ cấp tự động | Giả lập bộ kết xuất `SwiftShader` | `data-glass` phân giải thành `off` |
| TS-00-UI-05 | Chế độ màu cưỡng bức | Playwright với `forcedColors: 'active'` | Mọi thành phần còn ranh giới nhìn thấy được, không mất chữ |
| TS-00-UI-06 | Tôn trọng lựa chọn thủ công | Đặt "Đầy đủ" trên máy hạng Thấp | `data-glass="full"`, không bị tự hạ cấp ở bước 1–3 (bước 4 vẫn hạ trong phiên và báo) |

: Sáu kịch bản kiểm thử vật liệu TS-00-UI-01 đến 06

## 11. Truy vết

Bảng dưới nối yêu cầu phi chức năng, rủi ro và quyết định kiến trúc với mục của tài liệu này.

| Yêu cầu | Đáp ứng tại |
|---|---|
| RB-03, ADR-020 Liquid Glass trên antd v6 | Mục 2, 3, 4 |
| NFR-00-041 Tương phản kể cả trên glass | Mục 3.1, 3.2 (điều cấm thứ tư), 5, 10 |
| NFR-00-043 Giảm chuyển động, giảm trong suốt, có công tắc | Mục 6 |
| NFR-00-044 Chế độ sáng, tối | Mục 6, 8, 9.2 |
| NFR-00-005 LCP, INP trên máy văn phòng | Mục 3.2 (giới hạn bốn lớp), 6.3, 7 |
| RSK-A05 Glass làm chậm máy yếu | Mục 7 |
| NFR-00-045 Thống nhất giao diện | Mục 9.1 (một điểm sinh vật liệu duy nhất) |

: Truy vết yêu cầu và rủi ro tới mục của D03-05-01

## 12. Đề xuất bổ sung D00-01

Đề xuất bổ sung các thuật ngữ sau vào D00-01 §2.2: "Lớp nội dung", "Lớp chức năng", "Vật liệu glass", "Giếng nội dung" (vùng nền đặc bên trong một lớp nổi bằng kính), "Bo góc đồng tâm", "Chế độ kính" (`full`/`lite`/`off`), "Hạng hiệu năng máy". Đề xuất mã kiểm thử dạng `TS-00-UI-{nn}` cho kịch bản kiểm thử giao diện dùng chung, nằm trong dải `TS-{PH}-{nn}` hiện có với `PH = 00`.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: cách hiểu Liquid Glass, bản đồ vật liệu, cấu tạo CSS, topbar thích ứng, chế độ hiển thị, tự hạ cấp, đặc tả CMP-GlassSurface và CMP-ThemeProvider, kiểm thử, truy vết |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp, giữ nguyên nội dung kỹ thuật bản trước: thêm Tóm tắt cho hội đồng thẩm định; bổ sung chương 1 các mục 1.1–1.6 (mục đích, phạm vi, người đọc, thuật ngữ, tài liệu tham chiếu, cấu trúc); thêm đoạn mở cho chương 11; viết lại 6 chú thích bảng cho cụ thể; thêm metadata mo_ta và tai_lieu_lien_quan |
