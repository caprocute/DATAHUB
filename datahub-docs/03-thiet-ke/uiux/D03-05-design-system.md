---
ma_tai_lieu: D03-05
ten: Design system Datahub (Liquid Glass trên Ant Design v6)
phien_ban: 0.5
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư giao diện, Nhà thiết kế, Kiểm thử viên, Kiến trúc sư, Hội đồng thẩm định, AI agent sinh mã
mo_ta: Tài liệu tổng của design system Datahub, nêu nguyên tắc thiết kế, cấu trúc bộ bốn tập con, kiến trúc kỹ thuật, quy trình đóng góp và tiêu chí nghiệm thu để mọi màn hình của dh-console và dh-portal dùng chung một ngôn ngữ giao diện.
tai_lieu_lien_quan: ADR-020 Liquid Glass trên antd v6; ADR-021 Phông chữ; ADR-022 Biểu tượng Lucide; ADR-023 Biểu đồ ECharts; D00-01 Thuật ngữ và quy ước; D02-02 SRS; D03-01 SAD; D03-05-01 Vật liệu Liquid Glass; D03-05-02 Design token; D03-05-03 Thành phần nguyên tử; D03-05-04 Thành phần phức hợp; D03-06-00 IA, layout, mẫu màn hình
nguoi_lap: Luồng giao diện
---

# D03-05 · Design system Datahub (Liquid Glass trên Ant Design v6)

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Mọi màn hình của `dh-console` (quản trị 20 phân hệ) và `dh-portal` (cổng nhà phát triển PH-15) phải trông và hoạt động nhất quán, đọc được trên máy văn phòng của cơ quan nhà nước và đạt WCAG 2.2 mức AA. Tài liệu này là tài liệu tổng của design system: nêu sáu nguyên tắc thiết kế, cách bốn tập con (vật liệu, token, thành phần nguyên tử, thành phần phức hợp) bổ sung cho nhau, kiến trúc kỹ thuật, quy trình đóng góp và tiêu chí nghiệm thu. Nhờ đó kỹ sư và AI agent sinh mã dựng màn hình bằng cách ghép thành phần đã đặc tả, không tự quyết định màu, khoảng cách hay hành vi.

**Phạm vi.** Tài liệu gồm nguyên tắc thiết kế (chương 2), cấu trúc và thứ tự ưu tiên giữa các tập (chương 3), kiến trúc hai gói `@datahub/tokens` và `@datahub/ui` (chương 4), quy trình đóng góp và quản trị (chương 5), tám tiêu chí nghiệm thu cho cổng G2 (chương 6), quan hệ với tài liệu repo gốc (chương 7). Giá trị token, đặc tả vật liệu và đặc tả từng thành phần nằm ở D03-05-01 đến D03-05-04; thiết kế màn hình cụ thể của từng phân hệ nằm ở D03-06.

**Căn cứ.** STD-04 (WCAG 2.2, mức AA); NFR-00-040…045 và FR-00-001…082 của SRS (yêu cầu dùng chung về giao diện); ADR-020 (Liquid Glass trên antd v6), ADR-021 (phông chữ), ADR-022 (Lucide), ADR-023 (ECharts); CMP-LAW-05 (Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15) cho nguyên tắc che dữ liệu cá nhân ngay trên màn hình.

**Những điểm hội đồng cần lưu ý.** (1) Nguyên tắc thứ nhất là đọc được trước, đẹp sau: kính chỉ dùng cho lớp điều hướng và lớp nổi, nội dung dày luôn nằm trên nền đặc, độ đục kính được tính cho trường hợp xấu nhất chứ không chọn bằng mắt. (2) Mỗi nhu cầu giao diện có đúng một thành phần đáp ứng, và lint trong CI chặn nhập thẳng `antd` cùng giá trị màu, cỡ, khoảng cách viết tay (NFR-00-045). (3) Người dùng quyết định chế độ sáng tối, giảm trong suốt, giảm chuyển động và mật độ; giao diện tự hạ hiệu ứng trên máy yếu. (4) Khi hai tập mâu thuẫn có quy tắc phân xử rõ: D03-05-02 thắng về giá trị thị giác, D03-05-01 về chỗ đặt kính, D03-05-03/04 về API và hành vi thành phần, D03-06-00 về cách dùng trong màn hình. (5) Cổng G2 chỉ mở khi đủ tám tiêu chí kiểm tra khách quan, trong đó có axe-core 0 vi phạm A/AA và kiểm tra thủ công bằng NVDA.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Nguyên tắc thiết kế | 6 (chương 2) |
| Tập con của design system | 4 (D03-05-01 đến D03-05-04) |
| Thành phần | 134: 46 nguyên tử, 86 phức hợp, 2 nền tảng (mục 3.1) |
| Mã `CMP-` | 49 ở tầng nguyên tử, 77 ở tầng phức hợp, cộng hai mã nền tảng `CMP-GlassSurface` và `CMP-ThemeProvider` |
| Mẫu màn hình chuẩn | 14 (PTN-01…14, ở D03-06-00) |
| Tiêu chí nghiệm thu design system | 8 (chương 6) |
| ADR nền tảng | 4 (ADR-020…023) |
| Phân hệ và cổng dùng chung | 20 phân hệ của `dh-console` và cổng PH-15 |

: Con số chính của design system Datahub

Các con số được lấy từ chương 3 và chương 6 của tài liệu này; số thành phần chi tiết nằm ở bảng tổng hợp của D03-05-03 và D03-05-04.

## 1. Mục đích và phạm vi

Design system Datahub là tập hợp các quyết định thị giác, token, thành phần và quy tắc tương tác mà mọi màn hình của `dh-console` (ứng dụng quản trị cho 20 phân hệ) và `dh-portal` (cổng nhà phát triển PH-15) bắt buộc tuân theo. Mục tiêu của nó là ba điều. Thứ nhất, người dùng ở bất kỳ phân hệ nào cũng gặp cùng một cách bố cục, cùng một kiểu nút, cùng một ý nghĩa màu, nên học một lần dùng mọi nơi. Thứ hai, kỹ sư và AI agent sinh mã có thể dựng màn hình mới chỉ bằng cách ghép thành phần đã đặc tả, không phải tự quyết định màu, khoảng cách hay hành vi. Thứ ba, hội đồng thẩm định có bằng chứng rằng giao diện đáp ứng WCAG 2.2 mức AA và các yêu cầu dùng chung FR-00-001…082 của SRS.

D03-05 là tài liệu chỉ mục. Nội dung chi tiết nằm trong các tập con ở mục 3. Thiết kế màn hình cụ thể của từng phân hệ (mã `UI-{PH}-{nn}`) nằm ở D03-06, trong đó D03-06-00 định nghĩa kiến trúc thông tin, khung bố cục và các mẫu màn hình chuẩn mà mọi tập phân hệ dùng lại.

### 1.1. Mục đích của tài liệu

Tài liệu là điểm vào duy nhất của design system: nó đặt nguyên tắc, chỉ đường tới bốn tập con và quy định cách thay đổi, nghiệm thu design system. Hội đồng thẩm định đọc tài liệu này để đánh giá giao diện có nhất quán, truy cập được và kiểm soát được hay không. Kỹ sư và AI agent đọc để biết tập nào quyết định điều gì khi dựng màn hình.

### 1.2. Phạm vi

Bảng dưới phân định điều tài liệu này quy định và điều nằm ở tài liệu khác.

| Thuộc tài liệu này | Nằm ở tài liệu khác |
|---|---|
| Sáu nguyên tắc thiết kế và thứ tự ưu tiên giữa các tập | Giá trị token và ánh xạ antd: D03-05-02 |
| Cấu trúc bộ tài liệu, kiến trúc hai gói, quy ước mã nguồn | Vật liệu kính, chế độ hiển thị, hạ cấp: D03-05-01 |
| Quy trình đóng góp, vai trò, nghiệm thu design system | Đặc tả từng thành phần: D03-05-03, D03-05-04 |
| Quan hệ với `ui_ux_rule.md`, mockup và ADR-016 của repo gốc | Kiến trúc thông tin, mẫu màn hình, vi văn bản: D03-06-00; màn hình từng phân hệ: tập D03-06-PH |

: Phân định phạm vi giữa D03-05 và các tài liệu liên quan

### 1.3. Người đọc và cách đọc

Bảng dưới gợi ý phần cần đọc theo vai trò.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 2, 6 | Đánh giá nguyên tắc, mức truy cập và tiêu chí nghiệm thu |
| Kỹ sư giao diện | Chương 3, 4, 5 | Biết tập nào thắng khi mâu thuẫn, quy ước mã, quy trình đưa thành phần mới vào |
| Nhà thiết kế | Chương 2, 3, 5 | Giữ tệp thiết kế đồng bộ tên token và `CMP-*` |
| Kiểm thử viên | Chương 6 | Nghiệm thu design system trước cổng G2 |
| Kiến trúc sư | Chương 4, 7 | Hiểu cấu trúc gói và quan hệ với repo gốc |
| AI agent sinh mã | Chương 2, 3, 4 | Dựng màn hình chỉ bằng thành phần đã đặc tả |

: Người đọc D03-05 và phần cần đọc theo vai trò

### 1.4. Thuật ngữ và chữ viết tắt

Bảng dưới chỉ gồm thuật ngữ riêng của design system. Thuật ngữ chung theo D00-01 §2.

| Thuật ngữ | Giải thích |
|---|---|
| Lớp nội dung, lớp chức năng | Hai lớp của giao diện: lớp nội dung là thứ người dùng làm việc trực tiếp (bảng, biểu mẫu, log), luôn nền đặc; lớp chức năng là điều hướng và lớp nổi, được phép dùng kính |
| Glass (kính) | Vật liệu trong mờ, làm nhòe phông nền, dùng cho lớp chức năng (D03-05-01) |
| Token | Giá trị thiết kế có tên (màu, bo góc, khoảng cách…), chia ba tầng gốc, ngữ nghĩa, thành phần (D03-05-02) |
| `CMP-*` | Mã thành phần của design system, ví dụ `CMP-DataTable` |
| `PTN-nn` | Mã mẫu màn hình chuẩn trong D03-06-00 |
| Chế độ kính | Ba giá trị đã phân giải `full`, `lite`, `off` của hiệu ứng kính |
| Cổng G2 | Mốc bắt đầu phát triển phân hệ, đòi hỏi design system đã nghiệm thu |

: Thuật ngữ riêng của design system

### 1.5. Tài liệu tham chiếu

Các tài liệu dưới đây được dẫn chiếu trong D03-05.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| STD-04 | WCAG 2.2 | Mức AA là ngưỡng truy cập bắt buộc |
| D02-02 | Đặc tả yêu cầu phần mềm (SRS) | NFR-00-040…045, FR-00-001…082 |
| D03-01 | Thiết kế kiến trúc tổng thể (SAD) | Rủi ro RSK-A05, nguyên tắc NT-10 |
| D03-05-01…04 | Bốn tập con của design system | Chi tiết vật liệu, token, thành phần |
| D03-06-00 | IA, layout, mẫu màn hình | Mẫu PTN-01…14, vi văn bản |
| ADR-020…023 | Quyết định về Liquid Glass, phông chữ, biểu tượng, biểu đồ | Lý do chọn công nghệ giao diện |

: Tài liệu tham chiếu của D03-05

### 1.6. Cấu trúc tài liệu

Tài liệu đi từ nguyên tắc tới cấu trúc, kiến trúc, quy trình rồi nghiệm thu. Bảng dưới tóm tắt từng chương.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 2 | Sáu nguyên tắc thiết kế | Mọi người đọc |
| 3 | Cấu trúc bộ tài liệu, quy mô, thứ tự ưu tiên giữa các tập | Kỹ sư, nhà thiết kế |
| 4 | Kiến trúc hai gói, quy ước mã nguồn | Kỹ sư, kiến trúc sư |
| 5 | Quy trình đóng góp và quản trị | Kỹ sư, nhà thiết kế, trưởng nhóm |
| 6 | Tiêu chí nghiệm thu cho cổng G2 | Kiểm thử viên, hội đồng |
| 7 | Quan hệ với tài liệu repo gốc | Kiến trúc sư |
| 8, 9 | Truy vết, đề xuất bổ sung D00-01 | Kiểm thử viên, quản lý chất lượng |

: Cấu trúc chương của D03-05

## 2. Nguyên tắc thiết kế

Sáu nguyên tắc dưới đây là cơ sở để giải quyết mọi tình huống mà tài liệu chưa quy định cụ thể. Khi hai nguyên tắc mâu thuẫn, nguyên tắc đứng trước được ưu tiên.

**Nguyên tắc 1: Đọc được trước, đẹp sau.** Mọi lựa chọn thẩm mỹ, kể cả vật liệu kính, phải đạt tương phản WCAG 2.2 AA trong trường hợp xấu nhất. Đây là lý do độ đục của kính được tính toán chứ không chọn bằng mắt, và là lý do nội dung dày luôn dùng nền đặc (D03-05-01 §3).

**Nguyên tắc 2: Kính thuộc về lớp chức năng.** Lớp điều hướng và lớp nổi là kính; lớp nội dung là nền đặc. Người dùng nhờ đó luôn biết đâu là khung ứng dụng và đâu là công việc của mình. Đây là cách hiểu trung thành với Liquid Glass của Apple, chứ không phải phủ kính lên mọi thứ (ADR-020).

**Nguyên tắc 3: Một cách làm cho một việc.** Mỗi nhu cầu giao diện có đúng một thành phần đáp ứng. Một trạng thái nghiệp vụ có đúng một màu ở mọi phân hệ (`CMP-StatusTag`). Một thao tác phá hủy luôn đi qua cùng một hộp xác nhận (`CMP-ConfirmDialog`, `CMP-ReasonDialog`). Không phân hệ nào tự dựng phiên bản riêng.

**Nguyên tắc 4: Trung thực về trạng thái.** Giao diện luôn cho biết hệ thống đang làm gì: đang tải, rỗng, lỗi, không có quyền, dữ liệu đã đổi bởi người khác, tác vụ đang chạy nền. Không có màn hình trắng, không có nút bấm không phản hồi (FR-00-053, FR-00-054, FR-00-080).

**Nguyên tắc 5: Bảo vệ dữ liệu ngay trên màn hình.** Dữ liệu cá nhân mức Nhạy cảm được che mặc định; mở xem cần quyền và lý do, và được ghi kiểm toán (NT-10, FR-00-034, FR-00-040). Bí mật chỉ hiển thị một lần.

**Nguyên tắc 6: Tôn trọng thiết bị và lựa chọn của người dùng.** Chế độ sáng tối, giảm trong suốt, giảm chuyển động, mật độ đều do người dùng quyết định, mặc định theo hệ điều hành. Giao diện tự giảm hiệu ứng trên máy yếu thay vì bắt người dùng chịu đựng (D03-05-01 §6, §7).

## 3. Cấu trúc bộ tài liệu

Bảng dưới đây liệt kê các tập của design system và tài liệu liên quan, cùng câu hỏi mà mỗi tập trả lời, để người đọc đi thẳng tới phần cần.

| Mã | Tài liệu | Trả lời câu hỏi |
|---|---|---|
| D03-05 | Design system (tài liệu này) | Nguyên tắc, cấu trúc, quy trình đóng góp, nghiệm thu |
| [D03-05-01](D03-05-01-vat-lieu-liquid-glass.md) | Vật liệu Liquid Glass, chế độ hiển thị và cơ chế hạ cấp | Kính đặt ở đâu, dựng bằng CSS thế nào, chế độ Đầy đủ/Giảm/Tắt, tự hạ cấp trên máy yếu; `CMP-GlassSurface`, `CMP-ThemeProvider` |
| [D03-05-02](D03-05-02-design-token.md) | Design token và ánh xạ sang Ant Design v6 | Giá trị màu, kính, bo góc, bóng, khoảng cách, chữ, chuyển động; bảng tương phản; cấu hình `ConfigProvider` |
| [D03-05-03](D03-05-03-thanh-phan-nguyen-tu.md) | Thành phần nguyên tử | Nút, ô nhập, chọn, nhãn trạng thái, che dữ liệu, thời gian, tiền, mã định danh… |
| [D03-05-04](D03-05-04-thanh-phan-phuc-hop.md) | Thành phần phức hợp và tổ chức | Bảng dữ liệu, biểu mẫu, Modal, Drawer, xác nhận, lịch sử, duyệt, log, biểu đồ, canvas thiết kế, khung ứng dụng |
| [D03-06-00](D03-06-00-ia-layout-mau-man-hinh.md) | Kiến trúc thông tin, khung bố cục và mẫu màn hình chuẩn | Cây điều hướng, URL, khung AppShell, 14 mẫu màn hình PTN-01…14, vi văn bản tiếng Việt |
| [ADR-020](../../00-chung/adr/ADR-020-liquid-glass-tren-antd-v6.md) | Liquid Glass trên antd v6 | Vì sao chọn phong cách này và cách áp |
| [ADR-021](../../00-chung/adr/ADR-021-font-chu-giao-dien.md) | Phông chữ | Vì sao Inter và JetBrains Mono, tự lưu trữ |
| [ADR-022](../../00-chung/adr/ADR-022-bieu-tuong-lucide.md) | Biểu tượng | Vì sao Lucide |
| [ADR-023](../../00-chung/adr/ADR-023-bieu-do-echarts.md) | Biểu đồ | Vì sao Apache ECharts |
| [D03-06-PH04](D03-06-PH04-man-hinh-tich-hop.md), [D03-06-PH07](D03-06-PH07-man-hinh-danh-muc.md) | Tập màn hình phân hệ đã đối chiếu với design system | Dùng design system thế nào trong một phân hệ cụ thể |

: Cấu trúc bộ tài liệu design system và câu hỏi mỗi tập trả lời

### 3.1. Quy mô và thứ tự ưu tiên giữa các tập (bản 0.2)

Bảng dưới cho biết quy mô của từng tập con ở bản 0.2, để hội đồng nắm được khối lượng đặc tả đã có.

| Tập | Nội dung | Số lượng |
|---|---|---|
| D03-05-02 | Token màu ngữ nghĩa, kính, bo góc, bóng, khoảng cách, chữ, chuyển động, lớp chồng, mật độ; bản 0.2 thêm màu khác biệt và màu nguồn dữ liệu (§4.6) | — |
| D03-05-03 | Thành phần nguyên tử | 46 thành phần, 52 mã `CMP-` (tính cả biến thể có mã riêng) |
| D03-05-04 | Thành phần phức hợp và tổ chức, gồm canvas thiết kế (§11), khung ứng dụng (§12), dữ liệu chuyên dụng (§13) | 86 thành phần, 88 mã `CMP-` |
| D03-06-00 | Kiến trúc thông tin, quy tắc URL, khung bố cục, mẫu màn hình, vi văn bản, checklist nghiệm thu màn hình, danh sách màn hệ cũ được giữ | 14 mẫu PTN-01…14 |

: Quy mô của bốn tập con ở bản 0.2

Tổng cộng design system có 134 thành phần: 46 nguyên tử, 86 phức hợp và hai thành phần nền tảng ở D03-05-01 (`CMP-GlassSurface`, `CMP-ThemeProvider`). Hai tập màn hình phân hệ đã đối chiếu với bản 0.2: D03-06-PH04 (bản 0.2) và D03-06-PH07 (bản 0.3); tên cũ của các tập này được ghi trong bảng bí danh ở D03-05-03 §9 và D03-05-04 §14.2.

Khi hai tập mâu thuẫn: **D03-05-02 thắng về giá trị thị giác** (màu, kích thước, độ mờ), **D03-05-01 thắng về chỗ đặt kính**, **D03-05-03/04 thắng về API và hành vi thành phần**, **D03-06-00 thắng về cách dùng trong màn hình** (mẫu bố cục, URL, vi văn bản). Tập màn hình phân hệ không được định nghĩa token hay thành phần dùng chung mới; nhu cầu mới ghi vào mục "Đề xuất bổ sung" của tập đó để Luồng giao diện đưa vào D03-05.

Thứ tự đọc khuyến nghị cho kỹ sư mới: D03-05 → D03-05-01 → D03-05-02 (lướt bảng, đọc kỹ mục 13) → D03-06-00 → tra D03-05-03, D03-05-04 khi dựng thành phần cụ thể.

## 4. Kiến trúc kỹ thuật của design system

Chương này mô tả cách design system được đóng gói thành hai gói trong monorepo giao diện và các quy ước mã nguồn mọi thành phần phải theo.

```{.mermaid caption="Kiến trúc kỹ thuật của design system"}
flowchart TB
  subgraph PKG[Gói dùng chung trong monorepo giao diện]
    TK["@datahub/tokens<br/>tokens.json (DTCG) → tokens.css, tokens.ts<br/>phông Inter, JetBrains Mono"]
    UI["@datahub/ui<br/>DhThemeProvider, GlassSurface<br/>CMP-* bọc antd v6, ProTable, XYFlow, Monaco, ECharts<br/>biểu tượng Lucide"]
    SB[Storybook<br/>tài liệu sống, axe, hồi quy hình ảnh]
  end
  TK --> UI
  UI --> SB
  UI --> CON[dh-console<br/>20 phân hệ, mỗi phân hệ một mô-đun route tải lười]
  UI --> POR[dh-portal<br/>cổng nhà phát triển PH-15]
  ANTD[antd 6.x<br/>@ant-design/pro-components] --> UI
```

Sơ đồ cho thấy design system gồm hai gói. Gói `@datahub/tokens` chứa nguồn sự thật về giá trị và sinh ra CSS variables cùng đối tượng TypeScript. Gói `@datahub/ui` chứa mọi thành phần `CMP-*`, bọc antd v6 cùng các thư viện chuyên dụng, và là gói duy nhất được nhập trực tiếp `antd`. Hai ứng dụng `dh-console` và `dh-portal` chỉ nhập `@datahub/ui`; quy tắc ESLint `no-restricted-imports` chặn nhập thẳng `antd` trong mã ứng dụng (trừ kiểu dữ liệu), để bảo đảm NFR-00-045 "100% màn hình dùng thành phần của `@datahub/ui`". Storybook là tài liệu sống: mỗi thành phần có story cho từng trạng thái ở sáng, tối và các chế độ kính, và mỗi story được axe-core kiểm tra trong CI.

Một số quy ước mã nguồn áp dụng cho mọi thành phần:

| Quy ước | Nội dung |
|---|---|
| Đặt tên | Thành phần `PascalCase` trùng phần tên sau `CMP-` (ví dụ `CMP-DataTable` là `DataTable`); hook `useCamelCase` |
| Kiểu | TypeScript chế độ `strict`; props được định nghĩa bằng `interface` xuất công khai |
| Ref | Mọi thành phần tương tác chuyển tiếp `ref` tới phần tử nhận focus |
| Kiểm thử | Thuộc tính `data-testid` theo dạng `{tên-thành-phần}-{phần}`; Testing Library ưu tiên truy vấn theo vai trò ARIA |
| Chuỗi | Không chuỗi giao diện cứng trong `@datahub/ui`; nhận qua props hoặc từ tệp ngôn ngữ `vi` |
| Chuyển động | Đọc `data-motion` thay vì tự đọc truy vấn phương tiện |

: Quy ước mã nguồn áp dụng cho mọi thành phần của @datahub/ui

## 5. Quy trình đóng góp và quản trị

Design system thay đổi theo một quy trình có kiểm soát, vì mỗi thay đổi ảnh hưởng tới mọi phân hệ.

```{.mermaid caption="Quy trình đóng góp và quản trị"}
flowchart LR
  N[Nhu cầu từ phân hệ] --> C{Thành phần hiện có<br/>đáp ứng được?}
  C -->|Có| U[Dùng, không tạo mới]
  C -->|Gần đủ| V[Đề xuất biến thể<br/>cho thành phần hiện có]
  C -->|Không| P[Đề xuất CMP mới]
  V --> R[Trưởng nhóm giao diện duyệt<br/>đặc tả trong D03-05-03/04]
  P --> R
  R --> I[Hiện thực trong @datahub/ui<br/>story + axe + test]
  I --> L[Phát hành phiên bản @datahub/ui<br/>ghi nhật ký thay đổi]
```

Sơ đồ mô tả rằng mọi nhu cầu giao diện mới trước hết được đối chiếu với thành phần hiện có. Chỉ khi không thành phần nào đáp ứng mới đề xuất thành phần mới, kèm mã `CMP-*` mới. Đặc tả được cập nhật trong tài liệu trước khi viết mã, và thành phần chỉ được phát hành khi có đủ story, đạt axe-core và có kiểm thử. Gói `@datahub/ui` theo phiên bản ngữ nghĩa: thay đổi phá vỡ API tăng số chính và có hướng dẫn chuyển đổi.

Vai trò liên quan: **trưởng nhóm giao diện** duyệt mọi thay đổi token và thành phần; **nhà thiết kế** giữ tệp thiết kế đồng bộ tên token và `CMP-*`; **kiểm thử viên** nghiệm thu theo mục 6; **trưởng nhóm phân hệ** chịu trách nhiệm màn hình của phân hệ mình dùng đúng mẫu PTN.

## 6. Nghiệm thu design system

Design system được coi là sẵn sàng cho cổng G2 (bắt đầu phát triển phân hệ) khi đáp ứng đủ các tiêu chí dưới đây. Mỗi tiêu chí có thể kiểm tra khách quan.

| Tiêu chí | Cách kiểm tra |
|---|---|
| Mọi token ở D03-05-02 có trong `tokens.json` và đạt `contrast-check` | CI |
| Mọi `CMP-*` mức M có story đủ trạng thái × sáng/tối × kính `full`/`off` | Danh mục Storybook đối chiếu bảng tổng hợp ở D03-05-03, D03-05-04 |
| axe-core 0 vi phạm A/AA trên mọi story | CI (NFR-00-040) |
| Bộ kiểm thử TS-00-UI-01…06 đạt | CI (D03-05-01 §10) |
| Màn mẫu cho mỗi PTN-01…14 dựng được chỉ bằng `@datahub/ui` | Ứng dụng mẫu `dh-console/sandbox` |
| Lint chặn giá trị thô và nhập thẳng `antd` hoạt động | CI (NFR-00-045) |
| Kiểm tra thủ công với NVDA trên Windows cho khung ứng dụng, bảng, biểu mẫu, Modal | Biên bản kiểm thử truy cập |
| Hiệu năng cuộn đạt trên máy chuẩn 4 nhân, 8 GB | TS-00-UI-03, Lighthouse CI (NFR-00-005) |

: Tám tiêu chí nghiệm thu design system trước cổng G2

## 7. Quan hệ với tài liệu repo gốc

Repo gốc có `docs/ui_ux_rule.md` (quy tắc màn CRUD), mockup HTML trong `mockup/` và ADR-016 (antd + shadcn). Bộ tài liệu này kế thừa có chọn lọc: các quy tắc CRUD-UI, CRUD-FLT, CRUD-TBL, CRUD-SEL, CRUD-PAG của `ui_ux_rule.md` được đưa vào đặc tả `CMP-DataTable`, `CMP-FilterBar` và PTN-01; danh sách trạng thái bắt buộc được đưa vào D03-06-00. ADR-016 bị thay bởi ADR-020. Mockup cũ dùng phong cách shadcn nên chỉ tham khảo về bố cục, không tham khảo về thị giác.

## 8. Truy vết

Bảng dưới nối yêu cầu và quyết định với mục của tài liệu này hoặc của các tập con.

| Yêu cầu | Đáp ứng tại |
|---|---|
| RB-03 React + antd v6, Liquid Glass | ADR-020, D03-05-01, D03-05-02 |
| NFR-00-040…045 | Mục 2, 4, 6; chi tiết ở các tập con |
| FR-00-001…082 (yêu cầu dùng chung về giao diện) | D03-05-04 (thành phần), D03-06-00 (mẫu màn hình) |
| RSK-A05 | D03-05-01 §7 |

: Truy vết yêu cầu, rủi ro và ADR tới mục của D03-05

## 9. Đề xuất bổ sung D00-01

Đề xuất mở rộng quy ước tên file ở D00-01 §9.1 cho tài liệu chia phần không theo phân hệ: `{mã-tài-liệu}-{nn}-{tên}.md`, trong đó `nn` là số phần hai chữ số (ví dụ `D03-05-01-vat-lieu-liquid-glass.md`, `D03-06-00-ia-layout-mau-man-hinh.md`). Mã tài liệu của phần ghi trong `ma_tai_lieu` là `D03-05-01`. Đề xuất bổ sung bốn ADR của luồng giao diện vào bảng D00-02 §4: ADR-020, ADR-021, ADR-022 (Lucide), ADR-023 (ECharts).

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: nguyên tắc thiết kế, cấu trúc bộ tài liệu, kiến trúc kỹ thuật, quy trình đóng góp, nghiệm thu |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Mở rộng quy mô: 44 thành phần nguyên tử, 75 thành phần phức hợp, màu khác biệt và màu nguồn dữ liệu, đối chiếu với D03-06-PH04 và D03-06-PH07 |
| 0.3 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp, giữ nguyên nội dung kỹ thuật bản trước: thêm Tóm tắt cho hội đồng thẩm định tổng hợp cả bộ D03-05-01…04; bổ sung chương 1 các mục 1.1–1.6 (mục đích, phạm vi, người đọc, thuật ngữ, tài liệu tham chiếu, cấu trúc); thêm đoạn mở cho mục 3.1, chương 4 và chương 8; viết lại chú thích bảng, bỏ chú thích trùng; thêm metadata mo_ta và tai_lieu_lien_quan |
| 0.4 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: cập nhật quy mô sau khi D03-05-02, 03, 04 nhận các đề nghị bổ sung của tập màn phân hệ (46 nguyên tử, 84 phức hợp, 132 thành phần; thêm token độ mờ, kích thước bảng bên, mục lục, cột đọc) |
| 0.5 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: cập nhật quy mô lên 134 thành phần (86 phức hợp) sau khi D03-05-04 thêm `CMP-CheckResult`, `CMP-Calendar` |
