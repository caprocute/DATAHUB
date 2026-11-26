---
ma_tai_lieu: D03-05-04
ten: Thành phần phức hợp và tổ chức
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư giao diện, Nhà thiết kế, Kiểm thử viên, AI agent sinh mã
nguoi_lap: Luồng giao diện
---

# D03-05-04 · Thành phần phức hợp và tổ chức

## 1. Mục đích, phạm vi và cách đọc

Tài liệu này đặc tả 75 thành phần phức hợp (composite) và thành phần tổ chức (organism) của design system Datahub, đóng gói trong `@datahub/ui`. Thành phần phức hợp là tổ hợp của các thành phần nguyên tử ở D03-05-03 (ví dụ `CMP-FormField` ghép nhãn, điều khiển, mô tả và thông báo lỗi); thành phần tổ chức là khối giao diện lớn mang nghiệp vụ dùng chung (ví dụ `CMP-DataTable`, `CMP-ApprovalPanel`) hoặc khung ứng dụng (`CMP-AppShell`, `CMP-Topbar`, `CMP-Sidebar`). Mẫu màn hình PTN-01…14 ở D03-06-00 được lắp hoàn toàn từ các thành phần trong tài liệu này, nên mọi hành vi dùng chung của FR-00 (danh sách, lọc, xuất, xác nhận, xung đột, lịch sử, duyệt, thông báo, lỗi) được hiện thực đúng một lần ở đây và mọi phân hệ kế thừa.

Tài liệu không định nghĩa lại giá trị. Mọi màu, bo góc, khoảng cách, cỡ chữ, thời lượng chuyển động lấy từ hợp đồng token D03-05-02 và được ghi bằng đúng tên token (ví dụ `color-surface-solid`, `radius-xl`). Vật liệu Liquid Glass, lớp `.dh-glass--*`, chế độ glass `full` / `lite` / `off` và thành phần nguyên thủy `CMP-GlassSurface` được đặc tả ở D03-05-01; tài liệu này chỉ quy định thành phần nào dùng vật liệu nào ở phần con nào.

Mỗi thành phần được đặc tả theo một khung cố định để kỹ sư và AI agent sinh mã có thể làm ngay mà không phải suy diễn. Đoạn mở đầu nêu mục đích, khi dùng và khi không dùng. Bảng đặc tả nêu nền thư viện và thuộc tính cố định, giải phẫu (anatomy) cùng vật liệu từng phần con, biến thể, kích thước, trạng thái, token, bàn phím và ARIA, quy tắc nội dung tiếng Việt, điều cấm. Sau bảng là giao diện TypeScript của props và một ví dụ TSX. Thành phần trọng điểm (`CMP-DataTable`, `CMP-Modal`, `CMP-ConfirmDialog`, `CMP-ReasonDialog`, `CMP-DiffViewer`, `CMP-AuditTrail`, `CMP-ApprovalPanel`, `CMP-JobProgress`, `CMP-SessionTimeoutDialog`, `CMP-Topbar`, `CMP-Sidebar`, `CMP-Toast`, `CMP-Alert`, `CMP-Banner`, `CMP-Chart`, `CMP-LogViewer`, `CMP-FilterBar`) có thêm các tiểu mục thuyết minh hành vi chi tiết.

Bảng dưới đây liệt kê các nhóm thành phần và mục tương ứng, giúp người đọc đi thẳng tới phần cần dùng.

| Mục | Nhóm | Thành phần |
|---|---|---|
| 3 | Biểu mẫu và lọc | `CMP-FormField`, `CMP-Form`, `CMP-SearchField`, `CMP-FilterBar` |
| 4 | Điều hướng | `CMP-Breadcrumb`, `CMP-PageHeader`, `CMP-Tabs`, `CMP-Pagination` |
| 5 | Phản hồi và trạng thái | `CMP-Alert`, `CMP-Banner`, `CMP-Toast`, `CMP-Notification`, `CMP-EmptyState`, `CMP-ResultPage` |
| 6 | Hiển thị dữ liệu | `CMP-Card`, `CMP-KpiCard`, `CMP-DescriptionList`, `CMP-Tree`, `CMP-Transfer`, `CMP-Chart` |
| 7 | Lớp nổi | `CMP-Modal`, `CMP-Drawer`, `CMP-ConfirmDialog`, `CMP-ReasonDialog`, `CMP-Popover`, `CMP-DropdownMenu`, `CMP-SessionTimeoutDialog` |
| 8 | Bảng dữ liệu | `CMP-DataTable`, `CMP-BulkActionBar` |
| 9 | Mã, log, so sánh | `CMP-CodeEditor`, `CMP-JsonViewer`, `CMP-LogViewer`, `CMP-DiffViewer` |
| 10 | Quy trình | `CMP-Steps`, `CMP-ApprovalPanel`, `CMP-JobProgress`, `CMP-AuditTrail`, `CMP-Timeline` |
| 11 | Canvas thiết kế | `CMP-FlowCanvas`, `CMP-FlowNode`, `CMP-GroupNode`, `CMP-StickyNote`, `CMP-NodePalette`, `CMP-Inspector`, `CMP-CanvasControls`, `CMP-Minimap`, `CMP-QuickInsert`, `CMP-DesignerToolbar`, `CMP-EntityRail`, `CMP-BottomPanel`, `CMP-Splitter` |
| 12 | Khung ứng dụng | `CMP-AppShell`, `CMP-Topbar`, `CMP-Sidebar`, `CMP-TenantSwitcher`, `CMP-UserMenu`, `CMP-CommandPalette`, `CMP-NotificationCenter`, `CMP-BackgroundTaskTray`, `CMP-ShortcutSheet`, `CMP-FullscreenBar`, `CMP-StatusBar` |
| 13 | Dữ liệu chuyên dụng | `CMP-EditableTable`, `CMP-KeyValueEditor`, `CMP-DynamicForm`, `CMP-SchemaTree`, `CMP-TreeGrid`, `CMP-DiffTable`, `CMP-VersionTimeline`, `CMP-DependencyGraph`, `CMP-CommentThread`, `CMP-DecisionPanel`, `CMP-EnvCard`, `CMP-EmbeddedDashboard`, `CMP-Wizard` |
| 14 | Tổng hợp | Bảng tổng hợp, tên gọi khác, checklist nghiệm thu, truy vết, đề xuất |

: Mục đích, phạm vi và cách đọc

## 2. Quy tắc chung cho mọi thành phần phức hợp

### 2.1. Quy tắc vật liệu

Vật liệu là quyết định thiết kế quan trọng nhất của mỗi thành phần, vì đặt sai glass sẽ làm hỏng tương phản (NFR-00-041) và hiệu năng (NFR-00-005). Quy tắc dưới đây áp dụng cho toàn bộ tài liệu; cột "Vật liệu" trong bảng đặc tả từng thành phần chỉ được chọn trong năm giá trị của bảng.

| Vật liệu | Lớp CSS | Được dùng cho | Điều kiện bắt buộc |
|---|---|---|---|
| `glass-chrome` | `.dh-glass--chrome` | Sidebar; topbar khi chưa có nội dung cuộn dưới nó; nút của TenantSwitcher, UserMenu, BackgroundTaskTray trên topbar | Chỉ đặt trên `color-canvas` (kèm `color-canvas-wash`), nơi phông nền do hệ thống kiểm soát; không đặt trên nội dung có thể cuộn hoặc di chuyển bên dưới |
| `glass-chrome-scrolled` | `.dh-glass--chrome-scrolled` | Topbar khi nội dung đang cuộn bên dưới | Chuyển tự động khi `scrollTop > 0` của vùng nội dung; kèm dải `glass-scroll-edge` |
| `glass-modal` | `.dh-glass--modal` | Khung Modal, Drawer, CommandPalette, khung Drawer của sidebar dưới `bp-lg` | Nội dung đặt trong giếng nội dung (content well) nền `color-surface-solid`, bo góc đồng tâm; không đặt chữ liên kết cỡ thường trực tiếp trên khung |
| `glass-overlay` | `.dh-glass--overlay` | Popover, DropdownMenu, popup của Select/DatePicker/TreeSelect, Notification, NotificationCenter, popup của TenantSwitcher, UserMenu và BackgroundTaskTray; điều khiển nổi trên canvas (CanvasControls, Minimap, QuickInsert, BulkActionBar `floating`); FullscreenBar | Nội dung đặt trực tiếp lên glass vì vật liệu đạt ngưỡng mọi nấc chữ ở trường hợp xấu nhất |
| Nền đặc | không lớp glass | Bảng, biểu mẫu, thẻ, log, mã, so sánh, biểu đồ, bề mặt canvas và nút trên canvas, NodePalette, Inspector, DesignerToolbar, BottomPanel, BulkActionBar dính đầu bảng, giếng nội dung | `color-surface-solid` hoặc `color-surface-solid-2`; Tooltip và Toast dùng nền đảo `color-surface-inverse` |

: Quy tắc vật liệu

Ba quy tắc phụ được kiểm tra trong review mã. Thứ nhất, không đặt glass chồng glass; ngoại lệ duy nhất là lớp `glass-overlay` mở từ bên trong `glass-modal` (ví dụ Select trong Modal), được phép vì overlay có độ đục 0,94. Thứ hai, ở chế độ glass `lite` và `off`, thành phần không đổi cấu trúc DOM mà chỉ đổi giá trị biến (`glass-lite-tint`, `glass-off-tint`, `blur-none`), do `CMP-ThemeProvider` điều khiển qua `data-glass` trên `<html>`; thành phần không tự đọc `prefers-reduced-transparency`. Thứ ba, vật liệu được gắn vào phần tử con của thành phần antd qua thuộc tính ngữ nghĩa `classNames` của antd v6 (đã đối chiếu antd 6.7.1: Modal có các khóa `root`, `wrapper`, `mask`, `container`, `header`, `title`, `body`, `footer`, `close`; Drawer có `section` thay cho `content` đã lỗi thời; Select có `popup.root`; Dropdown có `root`, `menu`; Popover và Tooltip có `root`, `container`), không ghi đè lớp nội bộ `.ant-*`.

### 2.2. Mô hình trạng thái dữ liệu

Mọi thành phần nhận dữ liệu từ máy chủ hiển thị đủ năm trạng thái, theo cùng một hợp đồng để người dùng gặp cùng trải nghiệm ở mọi phân hệ. Bảng sau là hợp đồng đó; cột cuối chỉ thành phần hiển thị trạng thái.

| Trạng thái | Điều kiện | Hiển thị | Thành phần |
|---|---|---|---|
| Đang tải lần đầu | Truy vấn chưa có dữ liệu (`isPending`) | Khung xương `CMP-Skeleton` đúng hình dạng nội dung; không dùng vòng quay toàn trang | `CMP-Skeleton` |
| Đang làm mới | Đã có dữ liệu, đang tải lại (`isFetching`) | Giữ dữ liệu cũ, hiện `CMP-ProgressBar` mảnh 2px ở mép trên vùng dữ liệu, `aria-busy="true"` | `CMP-ProgressBar` |
| Rỗng | Không có bản ghi nào và không có bộ lọc | `CMP-EmptyState` biến thể `no-data` kèm hành động tạo nếu có quyền | `CMP-EmptyState` |
| Không có kết quả | Không có bản ghi với bộ lọc hiện tại | `CMP-EmptyState` biến thể `no-result` kèm nút "Đặt lại bộ lọc" | `CMP-EmptyState` |
| Lỗi | Truy vấn lỗi | `CMP-Alert` loại `error` theo FR-00-080, có nút "Thử lại" | `CMP-Alert` |
| Không có quyền | Máy chủ trả 403 hoặc quyền xem bị thiếu | `CMP-EmptyState` biến thể `no-permission` trong phạm vi khối; toàn trang thì `CMP-ResultPage` 403 | `CMP-EmptyState`, `CMP-ResultPage` |

: Mô hình trạng thái dữ liệu

Truy vấn dùng TanStack Query với khóa luôn bắt đầu bằng mã tenant hiện tại (`['t', tenantId, ...]`). Quy ước này giúp `CMP-TenantSwitcher` xóa sạch bộ nhớ đệm khi đổi tenant và giúp không bao giờ hiển thị nhầm dữ liệu tỉnh khác (FR-00-004, FR-00-011).

### 2.3. Mô hình quyền và hành động

Thành phần không tự suy luận quyền từ vai trò. Mọi danh sách và chi tiết đối tượng nhận từ máy chủ trường `allowedActions: string[]` cho từng bản ghi, phản ánh đồng thời quyền của người dùng và trạng thái vòng đời (kế thừa docs/ui_ux_rule.md §9, FR-00-053). Thành phần chỉ hiển thị hành động có trong `allowedActions`; hành động không hợp lệ bị ẩn chứ không hiện ở trạng thái vô hiệu, trừ khi nghiệp vụ cần giải thích vì sao không làm được, khi đó nút ở trạng thái vô hiệu kèm `CMP-Tooltip` nêu lý do (ví dụ "Không thể xóa vì dịch vụ đang có 3 đăng ký sử dụng"). Máy chủ vẫn kiểm tra lại quyền trên mọi API.

### 2.4. Mô hình lỗi

Mọi lỗi từ API theo RFC 9457 (Problem Details) được chuẩn hóa ở tầng gọi API thành kiểu `DhApiError` dưới đây. Thành phần hiển thị lỗi (`CMP-Alert`, `CMP-Banner`, `CMP-ResultPage`, `CMP-Toast` loại lỗi) chỉ nhận kiểu này, nhờ đó yêu cầu FR-00-080 được đáp ứng ở một chỗ: thông điệp tiếng Việt, cách khắc phục, mã lỗi và mã truy vết sao chép được, không lộ stack trace.

```ts
// @datahub/ui/src/errors/types.ts
export interface DhApiError {
  status: number;            // mã HTTP
  code: `ERR-${string}`;     // mã lỗi nghiệp vụ, ví dụ 'ERR-07-004'
  title: string;             // điều gì sai, tiếng Việt, một câu
  hint?: string;             // cách khắc phục, tiếng Việt
  traceId?: string;          // T-TRACE, 32 ký tự hexa
  fieldErrors?: Array<{ field: string; message: string }>; // lỗi theo trường (FR-00-081)
  retryable?: boolean;       // hiển thị nút "Thử lại" khi true
}
```

### 2.5. Quy tắc chung về nội dung tiếng Việt

Nhãn nút là động từ hoặc cụm động từ viết hoa chữ đầu ("Lưu", "Thêm dịch vụ", "Xuất Excel"), không dùng "OK" hay "Đồng ý" chung chung khi có thể nêu hành động cụ thể. Tiêu đề dùng tên nghiệp vụ, không viết hoa toàn bộ. Thời điểm hiển thị qua `CMP-Timestamp` (DD/MM/YYYY HH:mm, múi Asia/Ho_Chi_Minh), số qua định dạng `1.234.567`, tiền qua `CMP-Money` ("1.250.000 ₫"). Ô không có giá trị hiển thị "—" (kế thừa CRUD-R-05). Thông điệp không đổ lỗi cho người dùng và luôn nói điều cần làm tiếp theo.

### 2.6. Quy ước mã nguồn

Thành phần được xuất từ `@datahub/ui` với tên `Dh{Tên}` (ví dụ `DhDataTable`), mã truy vết là `CMP-{Tên}`. Thành phần gọi `message`, `notification`, `modal` qua hook `App.useApp()` của antd, không gọi hàm tĩnh, để nhận đúng theme và ngữ cảnh. Biểu tượng dùng Lucide React nét 1.75 qua `CMP-Icon` (ADR-022). Thành phần không nhận `style` hay `className` tùy ý từ màn hình nghiệp vụ, trừ thuộc tính `className` dành cho bố cục (khoảng cách ngoài), để giữ NFR-00-045.

## 3. Biểu mẫu và lọc

### 3.1. CMP-FormField

`CMP-FormField` là đơn vị của mọi biểu mẫu: nó ghép nhãn, điều khiển nguyên tử (`CMP-Input`, `CMP-Select`, `CMP-DatePicker`…), mô tả hướng dẫn, bộ đếm ký tự và thông báo lỗi tại chỗ thành một khối có quan hệ ARIA đúng. Dùng cho mọi trường nhập liệu trong `CMP-Form`, `CMP-FilterBar`, `CMP-Inspector`. Không dùng cho giá trị chỉ đọc trên trang chi tiết (dùng `CMP-DescriptionList`) và không dùng bên ngoài một `CMP-Form`.

Bảng sau đặc tả thành phần.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Form.Item` của antd. Props cố định: `colon={false}`, `validateFirst`, `hasFeedback={false}` (không dùng biểu tượng phản hồi trong ô vì gây nhiễu), `required` lấy từ quy tắc `rules`. |
| Giải phẫu | (1) Nhãn, kèm dấu `*` cho trường bắt buộc (CRUD-C-01) và `CMP-Tooltip` giải thích nếu có; (2) điều khiển; (3) mô tả (`extra`); (4) bộ đếm ký tự cho trường văn bản dài (CRUD-C-02); (5) thông báo lỗi tại trường (FR-00-081). |
| Vật liệu | Không có nền riêng; kế thừa nền đặc của biểu mẫu chứa nó. |
| Biến thể | `vertical` (nhãn trên, mặc định); `horizontal` (nhãn trái, chỉ dùng trong `CMP-Inspector` và biểu mẫu hẹp); `inline` (chỉ trong `CMP-FilterBar`). |
| Kích thước | Chiều cao điều khiển `size-control-md`; khoảng giữa nhãn và điều khiển `space-1`; khoảng giữa hai trường `space-4`. |
| Trạng thái | Mặc định, focus, lỗi (viền `color-error-text`, biểu tượng và chữ lỗi; không chỉ đổi màu), cảnh báo, vô hiệu, chỉ đọc (CRUD-U-03: hiển thị giá trị dạng chữ, không ẩn), đang kiểm tra bất đồng bộ (`CMP-Spinner` cỡ nhỏ cạnh nhãn). |
| Token | `font-body-strong` (nhãn), `font-footnote` + `color-text-tertiary` (mô tả), `color-error-text` (lỗi), `color-text-secondary` (bộ đếm), `space-1`, `space-4`. |
| Bàn phím, ARIA | Nhãn là `<label for>`; điều khiển có `aria-describedby` trỏ tới mô tả và lỗi, `aria-invalid="true"` khi lỗi, `aria-required="true"` khi bắt buộc. Thông báo lỗi nằm trong vùng `role="alert"` chỉ khi xuất hiện sau thao tác gửi. |
| Nội dung | Nhãn là danh từ ngắn không có dấu hai chấm ("Mã dịch vụ"). Lỗi nêu điều cần sửa: "Mã chỉ gồm chữ hoa, số, dấu chấm, gạch dưới, gạch ngang; tối đa 64 ký tự." thay cho "Không hợp lệ". |
| Điều cấm | Không dùng chữ giữ chỗ (placeholder) thay nhãn; không hiển thị lỗi chỉ ở đầu trang; không đặt hai điều khiển trong một FormField trừ cặp khoảng (từ ngày, đến ngày). |

: CMP-FormField

```ts
export interface DhFormFieldProps {
  name: string | (string | number)[];
  label: string;
  required?: boolean;
  description?: React.ReactNode;
  help?: string;                 // nội dung Tooltip cạnh nhãn
  maxLength?: number;            // hiển thị bộ đếm "120/4.000"
  layout?: 'vertical' | 'horizontal' | 'inline';
  readOnly?: boolean;
  rules?: import('antd').FormRule[];
  children: React.ReactElement;  // một điều khiển nguyên tử
}
```

```tsx
<DhFormField name="code" label="Mã dịch vụ" required maxLength={64}
  description="Mã dùng trong đường dẫn API, không đổi được sau khi công bố."
  rules={[{ pattern: /^[A-Z0-9][A-Z0-9_.-]{0,63}$/, message: 'Mã chỉ gồm chữ hoa, số, dấu chấm, gạch dưới, gạch ngang.' }]}>
  <DhInput autoComplete="off" />
</DhFormField>
```

### 3.2. CMP-Form

`CMP-Form` là khung biểu mẫu nhập và sửa đối tượng, dùng trong PTN-03 (biểu mẫu trang), PTN-04 (biểu mẫu nhanh trong Drawer hoặc Modal) và PTN-05 (wizard). Thành phần đảm nhận các hành vi dùng chung: kiểm tra hợp lệ phía giao diện, chống gửi trùng, ánh xạ lỗi trường từ máy chủ, cảnh báo rời trang khi chưa lưu, và phát hiện xung đột ETag. Không dùng cho bộ lọc danh sách (dùng `CMP-FilterBar`).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Form` của antd. Props cố định: `layout="vertical"`, `requiredMark` tùy biến hiển thị `*`, `scrollToFirstError={{ behavior: 'smooth', block: 'center', focus: true }}`, `validateTrigger={['onBlur','onSubmit']}` (không kiểm tra theo từng phím để tránh lỗi xuất hiện khi người dùng chưa gõ xong). |
| Giải phẫu | (1) Nhóm trường (`section`) có tiêu đề `font-title-3` và mô tả; (2) lưới trường một hoặc hai cột; (3) thanh hành động (footer) gồm nút chính "Lưu", nút phụ "Hủy" và tùy chọn "Lưu và tạo tiếp"; (4) `CMP-Alert` tổng hợp lỗi ở đầu biểu mẫu khi lỗi máy chủ không gắn được vào trường. |
| Vật liệu | Nền đặc `color-surface-solid` bo `radius-lg` khi đứng trên canvas (PTN-03); khi nằm trong Modal hoặc Drawer, biểu mẫu nằm trong giếng nội dung đặc của khung đó và không có nền riêng. Thanh hành động của PTN-03 dính đáy (`position: sticky`, `z-sticky`) với nền `color-surface-solid` và đường kẻ `color-border-subtle` phía trên. |
| Biến thể | `page` (PTN-03, tối đa `size-form-max`), `panel` (trong Drawer/Modal), `wizard` (một bước của `CMP-Steps`). |
| Kích thước | Một cột tối đa `size-form-max`; hai cột khi rộng hơn `bp-md` và nghiệp vụ cho phép, khoảng cột `space-6`. |
| Trạng thái | Đang tải (Skeleton theo lưới trường), sẵn sàng, bẩn (dirty), đang gửi (nút "Lưu" ở trạng thái loading và khóa, CRUD-C-04/05), lỗi trường, lỗi chung, xung đột (mở `CMP-DiffViewer`, mục 9.4), không có quyền sửa (toàn bộ trường chuyển chỉ đọc và ẩn nút "Lưu"). |
| Token | `color-surface-solid`, `radius-lg`, `space-4`, `space-6`, `font-title-3`, `color-border-subtle`, `z-sticky`. |
| Bàn phím, ARIA | Enter trong ô một dòng gửi biểu mẫu; Ctrl/⌘+Enter gửi khi đang ở ô nhiều dòng; Esc trong biểu mẫu panel chuyển cho khung xử lý (đóng có cảnh báo nếu bẩn). Biểu mẫu là `<form>` có `aria-labelledby` trỏ tiêu đề; nhóm trường là `<fieldset>` với `<legend>`. Sau khi gửi lỗi, focus chuyển tới trường lỗi đầu tiên. |
| Nội dung | Nút chính nêu hành động: "Lưu", "Tạo dịch vụ", "Gửi duyệt". Cảnh báo rời trang: "Bạn có thay đổi chưa lưu. Rời trang sẽ mất các thay đổi này." với hai nút "Ở lại" và "Rời trang". |
| Điều cấm | Không tắt nút "Lưu" khi biểu mẫu chưa hợp lệ (người dùng không biết vì sao); thay vào đó cho bấm và chỉ ra lỗi. Không tự lưu ngầm đối tượng nghiệp vụ trừ khi SDD phân hệ quy định. |

: CMP-Form

Hành vi xung đột ETag được nối như sau: khi tải đối tượng, `CMP-Form` ghi lại `ETag`; khi gửi, nó đặt `If-Match`; nếu máy chủ trả 412, biểu mẫu giữ nguyên giá trị người dùng nhập, tải bản mới nhất và mở `CMP-DiffViewer` ở chế độ xung đột để người dùng chọn "Ghi đè" hoặc "Tải lại" (FR-00-052, CRUD-U-05).

```ts
export interface DhFormProps<T extends object> {
  variant?: 'page' | 'panel' | 'wizard';
  initialValues?: Partial<T>;
  etag?: string;                                       // từ phản hồi GET
  onSubmit: (values: T, ctx: { ifMatch?: string }) => Promise<void>;
  onConflict?: (latest: T, mine: T) => void;           // mặc định mở DhDiffViewer
  submitText?: string;                                  // mặc định "Lưu"
  allowSaveAndNew?: boolean;
  readOnly?: boolean;
  guardUnsaved?: boolean;                               // mặc định true
  sections: Array<{ key: string; title: string; description?: string; columns?: 1 | 2; children: React.ReactNode }>;
}
```

```tsx
<DhForm<ServiceDraft> variant="page" etag={etag} initialValues={service}
  onSubmit={(v, { ifMatch }) => updateService.mutateAsync({ ...v, ifMatch })}
  sections={[{ key: 'general', title: 'Thông tin chung', columns: 2, children: (<>
    <DhFormField name="name" label="Tên dịch vụ" required maxLength={255}><DhInput /></DhFormField>
    <DhFormField name="code" label="Mã dịch vụ" required readOnly><DhInput /></DhFormField>
  </>) }]} />
```

### 3.3. CMP-SearchField

`CMP-SearchField` là ô tìm kiếm từ khóa, có hai biến thể với vai trò khác nhau. Biến thể `inline` nằm trong `CMP-FilterBar` để tìm trong danh sách. Biến thể `capsule` là thanh tìm kiếm dạng viên nang trên `CMP-Topbar`, khi được kích hoạt sẽ mở `CMP-CommandPalette`. Không dùng SearchField để lọc dữ liệu đã tải ở trình duyệt khi danh sách phân trang máy chủ (CRUD-FLT-08).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Input` của antd với `prefix` là biểu tượng Lucide `Search`, `allowClear`, `type="search"`. Biến thể `capsule` là phần tử `<button>` giả ô nhập (không nhận gõ), mở CommandPalette. |
| Giải phẫu | (1) Biểu tượng tìm; (2) ô nhập; (3) nút xóa; (4) gợi ý phím tắt `CMP-Kbd` "Ctrl K" hoặc "⌘ K" (chỉ `capsule`). |
| Vật liệu | `inline`: nền `color-fill-control` trên nền đặc. `capsule`: nền `color-fill-control` bán trong trên `glass-chrome` của topbar; không tạo lớp glass thứ hai. |
| Biến thể | `inline`, `capsule`. |
| Kích thước | `inline`: cao `size-control-md`, rộng 240–360px theo cột lưới. `capsule`: cao `size-control-md`, rộng tối thiểu 280px, bo `radius-pill`. |
| Trạng thái | Rỗng, có giá trị (hiện nút xóa), focus, đang tìm (`CMP-Spinner` thay biểu tượng tìm), vô hiệu. |
| Token | `color-fill-control`, `color-text-tertiary` (chữ giữ chỗ), `radius-md` (`inline`), `radius-pill` (`capsule`), `size-icon-md`. |
| Bàn phím, ARIA | `inline`: Enter thực hiện tìm (CRUD-FLT-03), Esc xóa nội dung. `role="searchbox"`, `aria-label` theo ngữ cảnh ("Tìm dịch vụ"). `capsule`: Enter/Space mở CommandPalette, `aria-haspopup="dialog"`, `aria-keyshortcuts="Control+K Meta+K"`. |
| Nội dung | Chữ giữ chỗ nêu phạm vi: "Tìm theo mã hoặc tên dịch vụ". Tìm không phân biệt hoa thường và dấu tiếng Việt ở máy chủ (FR-00-020). |
| Điều cấm | Không tìm tự động theo từng phím trên danh sách máy chủ; chỉ tìm khi Enter hoặc sau khi ngừng gõ 400ms nếu SDD cho phép. Không cắt khoảng trắng giữa từ. |

: CMP-SearchField

```ts
export interface DhSearchFieldProps {
  variant?: 'inline' | 'capsule';
  value?: string;
  onSearch?: (keyword: string) => void;   // gọi khi Enter, đã trim
  placeholder: string;
  ariaLabel?: string;
  loading?: boolean;
}
```

```tsx
<DhSearchField variant="inline" placeholder="Tìm theo mã hoặc tên dịch vụ"
  value={params.q} onSearch={(q) => setParams({ q, page: 1 })} />
```

### 3.4. CMP-FilterBar

`CMP-FilterBar` là thanh lọc phía trên `CMP-DataTable` trong PTN-01 và PTN-08. Nó gom ô tìm kiếm, các bộ lọc cơ bản luôn hiển thị, bộ lọc nâng cao thu gọn được, nút "Tìm kiếm", "Đặt lại" và menu bộ lọc đã lưu. FilterBar là nguồn duy nhất ghi điều kiện lọc lên URL, nên người dùng có thể chia sẻ đường dẫn và quay lại danh sách mà không mất bộ lọc (FR-00-022, CRUD-FLT-07).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Form` của antd `layout="inline"` cho hàng cơ bản và lưới `Row/Col` cho vùng nâng cao; không dùng `search` dựng sẵn của ProTable (đặt `search={false}` ở `CMP-DataTable`) để bố cục và đồng bộ URL thống nhất. |
| Giải phẫu | (1) `CMP-SearchField` `inline`; (2) tối đa ba bộ lọc cơ bản; (3) nút "Bộ lọc nâng cao" kèm `CMP-Badge` số bộ lọc nâng cao đang áp dụng; (4) vùng nâng cao (lưới 3–4 cột); (5) nút "Tìm kiếm" (chính) và "Đặt lại"; (6) menu "Bộ lọc đã lưu" (`CMP-DropdownMenu`); (7) hàng nhãn bộ lọc đang áp dụng (`CMP-Tag` đóng được) khi vùng nâng cao thu gọn. |
| Vật liệu | Nền đặc `color-surface-solid`, chung khối với bảng (FilterBar và DataTable cùng một thẻ bo `radius-lg`, ngăn cách bằng `color-border-subtle`). |
| Biến thể | `standard` (cơ bản + nâng cao), `simple` (chỉ ô tìm và tối đa hai bộ lọc, cho danh sách nhỏ), `embedded` (trong Drawer, không có bộ lọc đã lưu). |
| Kích thước | Đệm `space-4` (gọn `space-3`); khoảng giữa điều khiển `space-2`; điều khiển `size-control-md`. |
| Trạng thái | Mặc định, đang áp dụng (Badge số lượng, hàng nhãn), vùng nâng cao mở/đóng (ghi nhớ theo người dùng và màn hình), có lỗi (khoảng ngày sai: lỗi tại trường, khóa "Tìm kiếm"), không có quyền lưu bộ lọc (ẩn menu lưu). |
| Token | `color-surface-solid`, `color-border-subtle`, `radius-lg`, `space-2`, `space-3`, `space-4`, `motion-duration-base` (mở vùng nâng cao). |
| Bàn phím, ARIA | Enter ở bất kỳ ô nào thực hiện tìm; nút mở rộng có `aria-expanded` và `aria-controls`; vùng nâng cao là `role="region"` với nhãn "Bộ lọc nâng cao"; sau "Đặt lại", focus về ô tìm và vùng `aria-live="polite"` thông báo "Đã đặt lại bộ lọc". |
| Nội dung | Nhãn nút "Tìm kiếm", "Đặt lại", "Bộ lọc nâng cao", "Lưu bộ lọc này…". Nhãn bộ lọc đang áp dụng dạng "Trạng thái: Đã công bố, Tạm dừng". |
| Điều cấm | Không lọc trên dữ liệu đã tải; không giữ trang hiện tại khi đổi bộ lọc (luôn về trang 1, CRUD-FLT-06); không đặt quá ba bộ lọc ở hàng cơ bản. |

: CMP-FilterBar: Khía cạnh, Đặc tả

**Hành vi chi tiết.** Thứ nhất, FilterBar giữ một bản nháp điều kiện trong trạng thái cục bộ; chỉ khi người dùng bấm "Tìm kiếm" hoặc Enter, bản nháp mới được ghi lên URL bằng `setSearchParams` (thay `replace` cho lần ghi đầu, `push` cho các lần sau để nút quay lại của trình duyệt hoạt động) và trang về 1. Bộ lọc dạng Select đơn hoặc Segmented có thể áp dụng ngay khi đổi nếu SDD phân hệ quy định, nhưng mặc định là áp dụng khi bấm tìm. Thứ hai, quy ước tham số URL thống nhất cho mọi danh sách được nêu ở bảng dưới, nhờ đó backend và frontend không hiểu khác nhau (bài học của docs/ui_ux_rule.md §2.2).

| Tham số URL | Ý nghĩa | Ví dụ |
|---|---|---|
| `q` | Từ khóa, đã trim | `q=da%20nang` |
| `trang` | Trang, bắt đầu từ 1 trên URL (API dùng `page` bắt đầu từ 0); bỏ khi bằng 1 | `trang=3` |
| `co` | Số dòng mỗi trang, thuộc 10/20/50/100; bỏ khi bằng 20 | `co=50` |
| `sap-xep` | `{trường}:{tang|giam}`; nhiều tiêu chí nối bằng dấu phẩy khi bảng hỗ trợ | `sap-xep=ngay-tao:giam` |
| `{tên-trường}` | Giá trị lọc theo mã giá trị `kebab-case`; nhiều giá trị nối bằng dấu phẩy (FR-00-023) | `trang-thai=phat-hanh,tam-dung` |
| `{tên-trường}-tu`, `{tên-trường}-den` | Khoảng thời gian, dạng `yyyy-MM-dd`, bao gồm hai đầu; với một khoảng duy nhất của màn dùng `tu`, `den` | `ngay-tao-tu=2026-11-01` |
| `nang-cao` | Vùng nâng cao đang mở (`1`) | `nang-cao=1` |

: CMP-FilterBar: Tham số URL, Ý nghĩa

Bảng tham số này là cụ thể hóa của quy tắc URL ở D03-06-00 §2.4 (tài liệu đó thắng khi có khác biệt). Hook `useDhListParams` ánh xạ hai chiều giữa tên tham số tiếng Việt trên URL và tên tham số API (`page`, `size`, `sort`, tên trường camelCase) bằng bảng ánh xạ khai báo cùng `DhFilterDef`, nên mã gọi API không phụ thuộc tên trên URL.

Thứ ba, "Đặt lại" xóa toàn bộ tham số `q` và tham số lọc, giữ `co` và đưa `trang` về 1 (CRUD-FLT-05). Thứ tư, "Bộ lọc đã lưu" (FR-00-024) lưu một tên do người dùng đặt cùng chuỗi tham số URL (trừ `trang`) qua API tùy chọn người dùng, phạm vi theo tenant và theo màn hình; menu liệt kê bộ lọc đã lưu, cho đặt một bộ lọc làm mặc định khi mở màn hình, đổi tên và xóa. Lưu bộ lọc mở `CMP-Modal` cỡ `sm` với một trường "Tên bộ lọc" (tối đa 64 ký tự, không trùng trong phạm vi màn hình).

```ts
export interface DhFilterDef {
  name: string;                         // tên tham số trên URL, kebab-case tiếng Việt không dấu, ví dụ 'trang-thai'
  apiName?: string;                     // tên tham số API nếu khác, ví dụ 'status'
  label: string;
  kind: 'select' | 'multiSelect' | 'treeSelect' | 'dateRange' | 'number' | 'text' | 'boolean';
  options?: Array<{ value: string; label: string }> | (() => Promise<Array<{ value: string; label: string }>>);
  basic?: boolean;                      // hiển thị ở hàng cơ bản (tối đa 3)
}
export interface DhFilterBarProps {
  screenKey: string;                    // khóa lưu bộ lọc và trạng thái mở, ví dụ 'ph02.services'
  searchPlaceholder: string;
  filters: DhFilterDef[];
  variant?: 'standard' | 'simple' | 'embedded';
  allowSave?: boolean;                  // mặc định true với variant standard
  onApply?: (params: URLSearchParams) => void; // mặc định ghi URL
}
```

```tsx
<DhFilterBar screenKey="ph02.services" searchPlaceholder="Tìm theo mã hoặc tên dịch vụ"
  filters={[
    { name: 'trang-thai', apiName: 'status', label: 'Trạng thái', kind: 'multiSelect', basic: true, options: serviceStatusOptions },
    { name: 'co-quan', apiName: 'owner', label: 'Cơ quan chủ quản', kind: 'treeSelect', basic: true, options: loadAgencies },
    { name: 'ngay-tao', apiName: 'created', label: 'Ngày tạo', kind: 'dateRange' },
  ]} />
```

## 4. Điều hướng

### 4.1. CMP-Breadcrumb

`CMP-Breadcrumb` hiển thị đường dẫn chức năng từ nhóm menu tới màn hình hiện tại (CRUD-UI-01), đặt trong `CMP-PageHeader` phía trên tiêu đề trang. Đường dẫn được sinh từ cấu hình định tuyến và IA (D03-06-00), không viết tay ở từng màn hình. Không dùng Breadcrumb thay cho Tabs hay Steps, và không hiển thị ở trang tổng quan cấp cao nhất.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Breadcrumb` của antd với `items` sinh từ `route.handle.crumb`; dấu phân cách là biểu tượng Lucide `ChevronRight` cỡ `size-icon-sm`. |
| Giải phẫu | (1) Các mục cha là liên kết; (2) mục cuối là chữ thường, `aria-current="page"`; (3) mục rút gọn "…" khi quá 4 cấp, mở `CMP-DropdownMenu` liệt kê cấp ẩn. |
| Vật liệu | Không nền; đặt trực tiếp trên `color-canvas` của vùng nội dung (phông nền kiểm soát được, liên kết đạt 4,85:1). |
| Biến thể | `default`; `with-object` khi mục cuối là tên đối tượng, cắt chữ ở 40 ký tự kèm Tooltip. |
| Kích thước | Chữ `font-footnote`; cao 20px; khoảng dưới tới tiêu đề `space-1`. |
| Trạng thái | Mặc định, hover mục cha (gạch chân), focus, đang tải tên đối tượng (`CMP-Skeleton` dạng dòng ngắn). |
| Token | `font-footnote`, `color-text-link` (mục cha), `color-text-secondary` (mục cuối), `color-icon-secondary` (phân cách). |
| Bàn phím, ARIA | `<nav aria-label="Đường dẫn">` chứa danh sách có thứ tự; Tab đi qua từng liên kết. |
| Nội dung | Dùng tên nhóm và tên màn hình như trên Sidebar; tên đối tượng dùng tên hiển thị, không dùng UUID. |
| Điều cấm | Không làm mục cuối thành liên kết; không thêm biểu tượng nhà cho mục đầu. |

: CMP-Breadcrumb

```ts
export interface DhBreadcrumbProps {
  items?: Array<{ title: string; href?: string }>; // mặc định sinh từ router
  objectTitle?: string;                             // thay mục cuối bằng tên đối tượng
  loadingObject?: boolean;
}
```

```tsx
<DhBreadcrumb objectTitle={service?.name} loadingObject={isPending} />
```

### 4.2. CMP-PageHeader

`CMP-PageHeader` là phần đầu của mọi trang nội dung: Breadcrumb, tiêu đề nghiệp vụ, nhãn trạng thái của đối tượng, hành động chính đặt trên bên phải (CRUD-UI-03), nút quay lại khi có màn hình cha (CRUD-UI-04), và nút trợ giúp theo ngữ cảnh (FR-00-082) khi màn hình có mục HDSD riêng. Dùng ở PTN-01…12. Không dùng trong Modal hoặc Drawer (khung đó có tiêu đề riêng).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Thành phần tự viết bằng `Flex` của antd; không dùng `PageHeader` của ProComponents để giữ cấu trúc thống nhất. |
| Giải phẫu | (1) `CMP-Breadcrumb`; (2) nút quay lại `CMP-IconButton` (`ArrowLeft`); (3) tiêu đề `CMP-Heading` cấp 1; (4) `CMP-StatusTag` và `CMP-Identifier` của đối tượng; (5) mô tả ngắn một dòng; (6) vùng hành động: tối đa một nút chính, hai nút phụ, còn lại gom vào `CMP-DropdownMenu` "Thao tác khác"; (7) hàng `CMP-Tabs` cấp trang (tùy chọn). |
| Vật liệu | Không nền, đặt trên `color-canvas`. Khi trang cuộn, PageHeader không dính; chỉ Topbar dính. Riêng PTN-02 có thể bật `stickyActions` để vùng hành động thu thành thanh dính dưới Topbar trên nền đặc `color-surface-solid` kèm `shadow-1`. |
| Biến thể | `list` (tiêu đề + hành động tạo), `detail` (tiêu đề + trạng thái + hành động theo `allowedActions`), `form` (tiêu đề + nút quay lại, hành động nằm ở footer biểu mẫu). |
| Kích thước | Tiêu đề `font-title-2`; khoảng dưới tới nội dung `space-6`; nút `size-control-md`. |
| Trạng thái | Đang tải (Skeleton tiêu đề và nút), sẵn sàng, đối tượng không còn tồn tại (chuyển sang `CMP-ResultPage` 404), không có quyền hành động (ẩn vùng hành động). |
| Token | `font-title-2`, `font-footnote`, `color-text-primary`, `color-text-secondary`, `space-2`, `space-6`. |
| Bàn phím, ARIA | Tiêu đề là `<h1>` duy nhất của trang và là đích của lối tắt "Bỏ qua tới nội dung"; nút quay lại có `aria-label="Quay lại {tên màn hình cha}"`. |
| Nội dung | Tiêu đề là tên nghiệp vụ ("Danh sách dịch vụ", "Dịch vụ tra cứu hộ tịch"), không dùng "Quản lý…" chung chung. |
| Điều cấm | Không đặt quá một nút chính; không đặt hành động phá hủy ở vị trí nút chính. |

: CMP-PageHeader

```ts
export interface DhPageHeaderProps {
  title: string;
  variant?: 'list' | 'detail' | 'form';
  backTo?: string;                     // có thì hiện nút quay lại
  status?: React.ReactNode;            // DhStatusTag
  identifier?: string;
  description?: string;
  primaryAction?: React.ReactNode;
  secondaryActions?: React.ReactNode[];
  moreActions?: DhMenuItem[];          // vào DropdownMenu "Thao tác khác"
  helpTopic?: string;                  // khóa mục HDSD, FR-00-082
  tabs?: React.ReactNode;
  stickyActions?: boolean;
}
```

```tsx
<DhPageHeader variant="detail" title={service.name} identifier={service.code}
  status={<DhStatusTag lifecycle={service.status} />} backTo="/services" helpTopic="ph02.service-detail"
  primaryAction={can('PUBLISH') && <DhButton type="primary" onClick={publish}>Công bố</DhButton>}
  moreActions={buildActions(service.allowedActions)} />
```

### 4.3. CMP-Tabs

`CMP-Tabs` chia nội dung cùng một đối tượng thành các phần ngang hàng, ví dụ trang chi tiết có các tab "Thông tin", "Phiên bản", "Đăng ký sử dụng", "Lịch sử" (FR-00-043). Tab cấp trang ghi khóa tab lên URL (`?tab=history`) để chia sẻ được. Không dùng Tabs cho các bước tuần tự (dùng `CMP-Steps`) hoặc để chuyển giữa các chế độ xem nhỏ (dùng `CMP-SegmentedControl`).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Tabs` của antd, `items`, `destroyOnHidden={false}` cho tab nhẹ và `true` cho tab tải dữ liệu nặng; `tabPlacement="top"` (thuộc tính `tabPosition` đã lỗi thời ở v6). |
| Giải phẫu | (1) Danh sách tab với thanh chỉ thị (ink bar); (2) biểu tượng tùy chọn; (3) `CMP-Badge` số đếm tùy chọn; (4) vùng nội dung tab; (5) nút cuộn khi tràn. |
| Vật liệu | Thanh tab không nền khi đặt trên canvas; khi nằm trong `CMP-Card` thì kế thừa nền đặc. Vùng nội dung luôn là khối nền đặc. |
| Biến thể | `page` (cấp trang, đồng bộ URL), `card` (trong thẻ, không đồng bộ URL). |
| Kích thước | Cao 44px (gọn 36px); chữ `font-body-strong`; khoảng giữa tab `space-6`. |
| Trạng thái | Chưa chọn, hover, chọn, focus, vô hiệu (kèm Tooltip lý do), tab tải lỗi (nội dung tab hiển thị `CMP-Alert`, thanh tab không đổi). |
| Token | `color-text-secondary` (chưa chọn), `color-text-link` (chọn, ink bar), `font-body-strong`, `color-border-subtle` (đường kẻ dưới). |
| Bàn phím, ARIA | Mẫu ARIA Tabs: `role="tablist"`, `role="tab"`, `aria-selected`, `aria-controls`; mũi tên trái/phải chuyển tab, Home/End về đầu/cuối, kích hoạt thủ công bằng Enter/Space với tab tải dữ liệu nặng. |
| Nội dung | Nhãn danh từ ngắn; tab nhật ký kiểm toán luôn tên "Lịch sử" và đặt cuối. |
| Điều cấm | Không lồng Tabs trong Tabs quá hai cấp; không quá 7 tab cấp trang. |

: CMP-Tabs

```ts
export interface DhTabsProps {
  variant?: 'page' | 'card';
  items: Array<{ key: string; label: string; icon?: React.ReactNode; count?: number; disabledReason?: string; children: React.ReactNode }>;
  urlParam?: string;      // mặc định 'tab' với variant page
}
```

```tsx
<DhTabs variant="page" items={[
  { key: 'info', label: 'Thông tin', children: <ServiceInfo /> },
  { key: 'subs', label: 'Đăng ký sử dụng', count: 12, children: <SubscriptionTable /> },
  { key: 'history', label: 'Lịch sử', children: <DhAuditTrail objectType="SERVICE" objectId={id} /> },
]} />
```

### 4.4. CMP-Pagination

`CMP-Pagination` điều hướng giữa các trang của danh sách phân trang máy chủ. Thành phần thường được `CMP-DataTable` dựng sẵn; nó chỉ được dùng độc lập cho danh sách dạng thẻ hoặc kết quả tìm kiếm. Không dùng cho danh sách cuộn vô hạn (`CMP-LogViewer`, `CMP-NotificationCenter`).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Pagination` của antd. Props cố định: `showSizeChanger`, `pageSizeOptions={[10,20,50,100]}`, `defaultPageSize={20}` (FR-00-021), `showQuickJumper` khi tổng số trang > 5 (CRUD-PAG-05), `showTotal`, `hideOnSinglePage={false}`. |
| Giải phẫu | (1) Tổng số bản ghi sau lọc (CRUD-PAG-01); (2) nút trang trước; (3) các số trang với trang hiện tại nổi bật (CRUD-PAG-03); (4) nút trang sau; (5) bộ chọn số dòng mỗi trang; (6) ô nhảy trang. |
| Vật liệu | Kế thừa nền đặc của bảng hoặc thẻ chứa nó. |
| Biến thể | `full` (mặc định), `simple` (chỉ trước/sau và "Trang 3/12", cho Drawer hẹp). |
| Kích thước | Nút `size-control-sm` ở chế độ gọn, `size-control-md` ở chế độ chuẩn; đệm trên `space-3`. |
| Trạng thái | Trang đầu (khóa nút trước, CRUD-PAG-04), trang cuối (khóa nút sau), đang tải trang mới (giữ số trang mới nổi bật, bảng ở trạng thái làm mới), tổng bằng 0 (ẩn số trang, giữ tổng "0 bản ghi"). |
| Token | `color-fill-selected` + `color-accent-on-subtle` (trang hiện tại), `color-text-secondary` (tổng), `font-body`, `font-feature-tabular`. |
| Bàn phím, ARIA | `<nav aria-label="Phân trang">`; trang hiện tại có `aria-current="page"`; ô nhảy trang chỉ nhận số nguyên trong `[1, tổng số trang]` (CRUD-PAG-07), giá trị ngoài khoảng bị kẹp và thông báo qua `aria-live`. |
| Nội dung | Tổng: "Tổng 1.234 bản ghi"; bộ chọn: "20 / trang"; ô nhảy: "Đến trang". Tổng số trang tính `ceil(total / size)` (CRUD-PAG-06). |
| Điều cấm | Không để tổng, số dòng mỗi trang và tổng số trang lệch nhau; không giữ trang lớn hơn tổng số trang sau khi xóa (CRUD-D-08: tự lùi về trang cuối hợp lệ). |

: CMP-Pagination

```ts
export interface DhPaginationProps {
  page: number; size: number; total: number;
  onChange: (page: number, size: number) => void;
  variant?: 'full' | 'simple';
}
```

```tsx
<DhPagination page={params.page} size={params.size} total={data.totalElements}
  onChange={(page, size) => setParams({ page: size !== params.size ? 1 : page, size })} />
```

## 5. Phản hồi và trạng thái

Nhóm này quy định cách hệ thống nói với người dùng. Bảng dưới đây giúp chọn đúng thành phần theo mức độ quan trọng và vị trí, tránh tình trạng mỗi phân hệ dùng một kiểu thông báo.

| Tình huống | Thành phần | Tồn tại bao lâu |
|---|---|---|
| Kết quả thao tác vừa làm thành công (lưu, xóa, sao chép) | `CMP-Toast` | Tự ẩn sau 4 giây |
| Lỗi hoặc cảnh báo gắn với một khối nội dung | `CMP-Alert` | Đến khi điều kiện hết |
| Thông tin ảnh hưởng toàn ứng dụng (bảo trì, mất kết nối, đang xem tenant khác) | `CMP-Banner` | Đến khi điều kiện hết hoặc người dùng đóng |
| Sự kiện không đồng bộ cần chú ý (tác vụ nền xong, việc mới chờ duyệt) | `CMP-Notification` và mục trong `CMP-NotificationCenter` | Notification tự ẩn sau 8 giây; mục trong trung tâm tồn tại theo chính sách lưu |
| Khối không có dữ liệu | `CMP-EmptyState` | Theo dữ liệu |
| Toàn trang không hiển thị được (403, 404, 500, bảo trì) hoặc kết quả cuối của một quy trình | `CMP-ResultPage` | Theo trang |

: Phản hồi và trạng thái

### 5.1. CMP-Alert

`CMP-Alert` là khối thông báo nằm trong luồng nội dung, gắn với một vùng cụ thể: lỗi tải dữ liệu của bảng, lỗi chung của biểu mẫu, cảnh báo trước một thao tác, thông tin hướng dẫn. Đây là thành phần chính hiện thực FR-00-080 cho lỗi trong trang.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Alert` của antd v6 với `title` (thuộc tính `message` đã lỗi thời), `description`, `action`, `showIcon`, `closable` chỉ cho loại `info`/`success`. Biểu tượng thay bằng Lucide: `Info`, `CircleCheck`, `TriangleAlert`, `CircleX`. |
| Giải phẫu | (1) Biểu tượng loại; (2) tiêu đề: điều gì xảy ra; (3) mô tả: nguyên nhân và cách khắc phục; (4) dòng kỹ thuật cho lỗi: "Mã lỗi ERR-07-004 · Mã truy vết 4bf92f35…" kèm `CMP-CopyButton` sao chép cả hai; (5) hành động ("Thử lại", "Mở cài đặt"); (6) nút đóng tùy chọn. |
| Vật liệu | Nền đặc theo loại: `color-info-bg`, `color-success-bg`, `color-warning-bg`, `color-error-bg`; chữ dùng cặp `…-on-bg` tương ứng nên tương phản không phụ thuộc nền phía dưới. |
| Biến thể | Loại `info`, `success`, `warning`, `error`; kiểu `inline` (một dòng) và `block` (có mô tả, hành động). |
| Kích thước | Đệm `space-3` × `space-4`; bo `radius-md`; biểu tượng `size-icon-md` (`block`: `size-icon-lg`). |
| Trạng thái | Hiển thị, đang thử lại (nút "Thử lại" loading), đã đóng (ghi nhớ trong phiên nếu có `dismissKey`). |
| Token | `color-{loại}-bg`, `color-{loại}-on-bg`, `color-text-secondary` (dòng kỹ thuật), `font-body-strong` (tiêu đề), `font-body`, `font-mono-sm` (mã), `radius-md`. |
| Bàn phím, ARIA | Lỗi và cảnh báo xuất hiện sau thao tác dùng `role="alert"`; thông tin tĩnh dùng `role="status"` hoặc không có vai trò. Không chuyển focus vào Alert, trừ lỗi chung của biểu mẫu sau khi gửi. |
| Nội dung | Tiêu đề nói điều gì sai bằng ngôn ngữ nghiệp vụ ("Không tải được danh sách dịch vụ"), mô tả nói cách khắc phục ("Kiểm tra kết nối mạng rồi bấm Thử lại. Nếu lỗi lặp lại, gửi mã truy vết cho bộ phận hỗ trợ."). |
| Điều cấm | Không hiển thị stack trace, tên lớp Java, câu SQL hay thông điệp tiếng Anh thô; không dùng Alert cho kết quả thành công tạm thời (dùng Toast). |

: CMP-Alert

```ts
export interface DhAlertProps {
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  description?: React.ReactNode;
  error?: DhApiError;                 // tự dựng title/hint/mã lỗi/mã truy vết
  onRetry?: () => void;               // hiện nút "Thử lại" khi có
  action?: React.ReactNode;
  dismissKey?: string;
}
```

```tsx
{query.isError && <DhAlert type="error" error={query.error} onRetry={() => query.refetch()}
  title="Không tải được danh sách dịch vụ" />}
```

### 5.2. CMP-Banner

`CMP-Banner` là dải thông báo toàn chiều rộng nằm ngay dưới Topbar, phía trên PageHeader, cho thông tin ảnh hưởng toàn ứng dụng: lịch bảo trì, mất kết nối máy chủ, đang truy cập liên tenant với vai trò nền tảng (FR-00-012), phiên bản giao diện mới cần tải lại, tenant đã đổi ở thẻ trình duyệt khác. Lỗi trong Banner theo đúng FR-00-080 như Alert.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Alert` của antd với `banner`, bọc trong vùng do `CMP-AppShell` quản lý (hàng đợi tối đa 2 banner, ưu tiên `error` > `warning` > `info`). |
| Giải phẫu | (1) Biểu tượng; (2) thông điệp một dòng; (3) liên kết hoặc nút hành động ("Tải lại trang", "Xem chi tiết"); (4) mã lỗi và mã truy vết khi là lỗi; (5) nút đóng (trừ banner bắt buộc như truy cập liên tenant). |
| Vật liệu | Nền đặc `color-{loại}-bg`; không dùng glass vì banner nằm trong luồng nội dung, dưới Topbar. |
| Biến thể | `info`, `warning`, `error`, `cross-tenant` (nền `color-warning-bg`, có tên tenant đang truy cập và nút "Kết thúc truy cập"). |
| Kích thước | Cao tối thiểu 40px; đệm ngang bằng lề vùng nội dung `space-6`. |
| Trạng thái | Hiển thị, đã đóng (ghi nhớ theo `id` banner), tự hết khi điều kiện kết thúc (ví dụ kết nối khôi phục: chuyển thành Toast "Đã kết nối lại"). |
| Token | `color-{loại}-bg`, `color-{loại}-on-bg`, `font-body`, `space-6`, `z-base`. |
| Bàn phím, ARIA | `role="status"` cho thông tin, `role="alert"` cho mất kết nối; banner nằm trước `<main>` trong thứ tự focus nhưng sau lối tắt "Bỏ qua tới nội dung". |
| Nội dung | "Hệ thống bảo trì từ 22:00 đến 23:30 ngày 25/11/2026. Các thay đổi chưa lưu trong thời gian này có thể bị mất." |
| Điều cấm | Không dùng Banner cho thông báo của một màn hình cụ thể; không xếp quá hai banner. |

: CMP-Banner

```ts
export interface DhBannerProps {
  id: string;
  type: 'info' | 'warning' | 'error' | 'cross-tenant';
  message: React.ReactNode;
  action?: { label: string; onClick: () => void };
  error?: DhApiError;
  dismissible?: boolean;
}
```

```tsx
const { pushBanner } = useDhShell();
pushBanner({ id: 'offline', type: 'error', message: 'Mất kết nối tới máy chủ. Hệ thống sẽ tự thử lại.', dismissible: false });
```

### 5.3. CMP-Toast

`CMP-Toast` xác nhận ngắn gọn kết quả của thao tác người dùng vừa thực hiện ("Đã lưu dịch vụ", "Đã sao chép mã truy vết"). Toast dùng nền đảo đặc để đọc được trên mọi nền, kể cả khi nổi trên glass. Không dùng Toast cho lỗi cần người dùng xử lý (dùng Alert hoặc lỗi tại trường) và không dùng cho sự kiện không đồng bộ (dùng Notification).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `message` của antd gọi qua `App.useApp()` (không gọi `message.success` tĩnh); token thành phần `Message.contentBg` = `color-surface-inverse` đã đặt ở D03-05-02 §13.3. |
| Giải phẫu | (1) Biểu tượng loại (Lucide); (2) thông điệp một dòng; (3) hành động tùy chọn "Hoàn tác" hoặc "Xem" (liên kết chữ trên nền đảo). |
| Vật liệu | Nền đảo đặc `color-surface-inverse`, chữ `color-text-on-inverse`; không glass. |
| Biến thể | `success`, `info`, `warning`, `error` (chỉ cho lỗi tức thời không cần xử lý, ví dụ "Không sao chép được vào bộ nhớ tạm"), `loading` (thao tác ngắn dưới 3 giây). |
| Kích thước | Cao tối thiểu 40px, rộng tối đa 480px, bo `radius-pill`; vị trí giữa trên, cách Topbar `space-2`. |
| Trạng thái | Xuất hiện (phóng `motion-scale-enter`, `motion-ease-emphasized`), hiển thị 4 giây (8 giây nếu có hành động), tạm dừng đếm khi rê chuột hoặc focus, biến mất (`motion-ease-exit`). |
| Token | `color-surface-inverse`, `color-text-on-inverse`, `radius-pill`, `shadow-3`, `z-toast`, `motion-duration-base`. |
| Bàn phím, ARIA | Vùng chứa `role="status"` `aria-live="polite"`; Toast lỗi dùng `aria-live="assertive"`. Toast có hành động không tự ẩn khi đang được focus; phím tắt Alt+T chuyển focus tới Toast gần nhất có hành động. |
| Nội dung | Mẫu "Đã {động từ} {đối tượng}" ("Đã xóa 3 dịch vụ"). Không quá 80 ký tự. |
| Điều cấm | Không xếp quá 3 Toast cùng lúc (`maxCount: 3`); không đặt nội dung quan trọng duy nhất trong Toast vì nó tự biến mất. |

: CMP-Toast

```ts
export function useDhToast(): {
  success(msg: string, opts?: { action?: { label: string; onClick: () => void } }): void;
  info(msg: string): void; warning(msg: string): void; error(msg: string): void;
  loading(msg: string): () => void; // trả về hàm đóng
};
```

```tsx
const toast = useDhToast();
await deleteMany.mutateAsync(ids);
toast.success(`Đã xóa ${formatNumber(ids.length)} dịch vụ`);
```

### 5.4. CMP-Notification

`CMP-Notification` là thẻ thông báo nổi góc trên phải cho sự kiện không đồng bộ: tác vụ nền đã xong (FR-00-054, FR-00-031), có việc mới chờ duyệt (FR-00-070), cảnh báo vận hành. Mỗi Notification đồng thời được ghi thành một mục trong `CMP-NotificationCenter`, nên người dùng bỏ lỡ vẫn xem lại được.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `notification` của antd qua `App.useApp()`, `placement="topRight"`, `top` = `size-topbar` + `space-2`, `classNames={{ root: 'dh-glass--overlay' }}`. |
| Giải phẫu | (1) Biểu tượng loại; (2) tiêu đề; (3) mô tả hai dòng; (4) hành động ("Tải tệp", "Mở yêu cầu"); (5) thời điểm `CMP-Timestamp` tương đối; (6) nút đóng. |
| Vật liệu | `glass-overlay` (nội dung đặt trực tiếp lên glass). |
| Biến thể | `info`, `success`, `warning`, `error`, `approval` (biểu tượng `ClipboardCheck`). |
| Kích thước | Rộng 384px; bo `radius-lg`; đệm `space-4`. |
| Trạng thái | Xuất hiện, hiển thị 8 giây (không tự ẩn với `error` và `approval`), tạm dừng khi rê chuột/focus, đóng. |
| Token | `glass-overlay`, `radius-lg`, `shadow-3`, `font-body-strong`, `font-footnote`, `z-toast`. |
| Bàn phím, ARIA | `role="status"`; không cướp focus; nút đóng có `aria-label="Đóng thông báo"`. |
| Nội dung | "Xuất dữ liệu xong. Tệp danh-sach-dich-vu.xlsx (12.345 dòng) sẵn sàng tải đến 14:30 ngày 22/11/2026." |
| Điều cấm | Không chứa dữ liệu Hạn chế hoặc Nhạy cảm trong thông báo (đồng bộ với tinh thần FR-00-062); không quá 3 thẻ cùng lúc. |

: CMP-Notification

```ts
export function useDhNotify(): (n: { type: 'info'|'success'|'warning'|'error'|'approval'; title: string; description?: string; action?: { label: string; href?: string; onClick?: () => void } }) => void;
```

```tsx
notify({ type: 'success', title: 'Xuất dữ liệu xong', description: 'Tệp sẵn sàng tải trong 24 giờ.', action: { label: 'Tải tệp', href: job.downloadUrl } });
```

### 5.5. CMP-EmptyState

`CMP-EmptyState` lấp chỗ trống khi một khối không có dữ liệu để hiển thị, để bảng hoặc thẻ không bao giờ trắng trơn (CRUD-TBL-12). Thành phần phân biệt rõ bốn nguyên nhân vì mỗi nguyên nhân dẫn tới một hành động khác nhau.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Empty` của antd với `image` thay bằng minh họa đơn sắc dựng từ biểu tượng Lucide cỡ 48px. Được gán làm `locale.emptyText` của Table và `renderEmpty` của `ConfigProvider`. |
| Giải phẫu | (1) Minh họa; (2) tiêu đề; (3) mô tả `font-callout`; (4) hành động chính; (5) liên kết hướng dẫn tùy chọn. |
| Vật liệu | Kế thừa nền đặc của khối chứa. |
| Biến thể | `no-data` ("Chưa có dịch vụ nào", hành động "Thêm dịch vụ" nếu có quyền); `no-result` ("Không tìm thấy dữ liệu phù hợp", hành động "Đặt lại bộ lọc"); `no-permission` ("Bạn chưa có quyền xem nội dung này", hướng dẫn liên hệ quản trị tỉnh); `error-lite` (dùng trong khối nhỏ khi không đủ chỗ cho Alert). |
| Kích thước | `default` (khoảng trống trên dưới `space-12`), `compact` (`space-6`, cho thẻ nhỏ và Popover). |
| Trạng thái | Tĩnh. |
| Token | `color-icon-secondary`, `font-title-3`, `font-callout`, `color-text-secondary`, `space-6`, `space-12`. |
| Bàn phím, ARIA | Minh họa `aria-hidden="true"`; tiêu đề là đoạn văn, không phải heading, khi nằm trong bảng. |
| Nội dung | Tiêu đề khẳng định trạng thái, mô tả gợi ý việc làm tiếp: "Thử bỏ bớt điều kiện lọc hoặc tìm bằng từ khóa khác." |
| Điều cấm | Không dùng chung một thông điệp "Không có dữ liệu" cho cả bốn nguyên nhân. |

: CMP-EmptyState

```ts
export interface DhEmptyStateProps {
  variant: 'no-data' | 'no-result' | 'no-permission' | 'error-lite';
  title?: string; description?: string;
  action?: React.ReactNode; size?: 'default' | 'compact';
}
```

```tsx
<DhEmptyState variant="no-result" action={<DhButton onClick={resetFilters}>Đặt lại bộ lọc</DhButton>} />
```

### 5.6. CMP-ResultPage

`CMP-ResultPage` là nội dung toàn trang khi trang không hiển thị được (403, 404, 500, 503 bảo trì, đối tượng đã bị xóa) và là trang kết quả cuối của một quy trình (gửi duyệt thành công, khởi tạo tenant xong). Đây là thành phần lõi của PTN-13.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Result` của antd với `icon` thay bằng minh họa Lucide 64px; `status` không dùng ảnh mặc định của antd. |
| Giải phẫu | (1) Minh họa; (2) tiêu đề `font-title-1`; (3) mô tả; (4) khối kỹ thuật cho lỗi (mã lỗi, mã truy vết, thời điểm, nút sao chép); (5) hành động chính ("Về trang chủ", "Thử lại", "Xem yêu cầu"); (6) hành động phụ ("Liên hệ hỗ trợ"). |
| Vật liệu | Nền đặc `color-surface-solid` bo `radius-lg` đặt giữa vùng nội dung; không glass. |
| Biến thể | `403`, `404`, `500`, `503`, `deleted` (đối tượng đã xóa mềm: kèm thông tin người xóa, thời điểm và nút "Khôi phục" nếu `allowedActions` có `RESTORE`, FR-00-051), `success`, `info`. |
| Kích thước | Rộng tối đa `size-form-max`; khoảng trống trên `space-16`. |
| Trạng thái | Tĩnh; nút "Thử lại" có trạng thái loading. |
| Token | `font-title-1`, `font-callout`, `font-mono-sm`, `color-surface-solid`, `radius-lg`, `space-16`. |
| Bàn phím, ARIA | Tiêu đề là `<h1>`; khi điều hướng tới trang lỗi, focus chuyển vào tiêu đề để trình đọc màn hình đọc ngay. |
| Nội dung | 403: "Bạn không có quyền truy cập trang này. Nếu cần quyền, hãy liên hệ quản trị tỉnh và gửi kèm mã truy vết bên dưới." 404: "Không tìm thấy trang hoặc đối tượng. Đường dẫn có thể đã thay đổi hoặc đối tượng đã bị xóa." |
| Điều cấm | Không hiển thị thông điệp kỹ thuật thô; trang 403 không tiết lộ đối tượng có tồn tại hay không ở tenant khác (FR-00-011). |

: CMP-ResultPage

```ts
export interface DhResultPageProps {
  status: '403' | '404' | '500' | '503' | 'deleted' | 'success' | 'info';
  title?: string; description?: React.ReactNode;
  error?: DhApiError; primaryAction?: React.ReactNode; secondaryAction?: React.ReactNode;
}
```

```tsx
<DhResultPage status="success" title="Đã gửi yêu cầu công bố"
  description="Yêu cầu đang chờ Quản trị tỉnh duyệt. Bạn sẽ nhận thông báo khi có kết quả."
  primaryAction={<DhButton type="primary" href={`/requests/${req.id}`}>Xem yêu cầu</DhButton>} />
```


## 6. Hiển thị dữ liệu

### 6.1. CMP-Card

`CMP-Card` là khối nền đặc cơ bản nhóm nội dung liên quan trên trang chi tiết, dashboard và trang cài đặt. Card là "bề mặt đặc nằm trên canvas" theo mô hình lớp của D03-05-02 §4.1. Không dùng Card để bọc một bảng đã có khung riêng (`CMP-DataTable` tự có thẻ) và không lồng Card trong Card.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Card` của antd, `variant="outlined"`; token thành phần `headerFontSize`, `bodyPadding`, `headerPadding` theo D03-05-02 §13.3. |
| Giải phẫu | (1) Tiêu đề `font-title-3`; (2) phụ đề hoặc mô tả; (3) vùng hành động đầu thẻ (`extra`): tối đa hai `CMP-IconButton` hoặc một nút chữ; (4) thân; (5) chân thẻ tùy chọn (liên kết "Xem tất cả"). |
| Vật liệu | Nền đặc `color-surface-solid`, viền `color-border-subtle`, `shadow-1`. Vùng phụ trong thẻ dùng `color-surface-solid-2`. Card có ảnh đầu thẻ dùng bo góc đồng tâm cho ảnh. |
| Biến thể | `default`, `section` (không viền, dùng làm nhóm trong trang cài đặt), `interactive` (cả thẻ bấm được, hover dùng `color-fill-hover`, dùng cho lưới lựa chọn). |
| Kích thước | Đệm `space-5` (gọn `space-4`); bo `radius-lg`. |
| Trạng thái | Đang tải (Skeleton thân), sẵn sàng, rỗng (EmptyState `compact`), lỗi (Alert `inline` trong thân), không có quyền (EmptyState `no-permission` `compact`). |
| Token | `color-surface-solid`, `color-surface-solid-2`, `color-border-subtle`, `shadow-1`, `radius-lg`, `space-4`, `space-5`, `font-title-3`. |
| Bàn phím, ARIA | Card có tiêu đề là `<section aria-labelledby>`; biến thể `interactive` là một phần tử `<a>` hoặc `<button>` duy nhất bao toàn thẻ, không chứa phần tử tương tác lồng nhau. |
| Nội dung | Tiêu đề danh từ ngắn ("Thông tin kết nối", "Lượt gọi 7 ngày"). |
| Điều cấm | Không đặt glass cho Card; không lồng Card. |

: CMP-Card

```ts
export interface DhCardProps {
  title?: string; subtitle?: string; extra?: React.ReactNode; footer?: React.ReactNode;
  variant?: 'default' | 'section' | 'interactive'; href?: string; onClick?: () => void;
  loading?: boolean; error?: DhApiError; empty?: boolean; children?: React.ReactNode;
}
```

```tsx
<DhCard title="Thông tin kết nối" extra={<DhCopyButton value={endpoint} label="Sao chép địa chỉ" />}>
  <DhDescriptionList items={connectionItems} column={2} />
</DhCard>
```

### 6.2. CMP-KpiCard

`CMP-KpiCard` hiển thị một chỉ số quan trọng trên dashboard (PTN-06) và trang tổng quan phân hệ: giá trị lớn, đơn vị, so sánh với kỳ trước và biểu đồ nhỏ (sparkline) tùy chọn. Không dùng KpiCard cho số liệu không có ý nghĩa so sánh hoặc cho danh sách số liệu (dùng `CMP-DescriptionList`).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Mở rộng `CMP-Card`; giá trị dùng `Statistic` của antd với `formatter` theo định dạng số Việt Nam; sparkline là `CMP-Chart` biến thể `spark`. |
| Giải phẫu | (1) Nhãn chỉ số; (2) giá trị lớn và đơn vị; (3) chỉ báo thay đổi: mũi tên Lucide `TrendingUp`/`TrendingDown`, phần trăm và chữ "so với 7 ngày trước"; (4) sparkline; (5) liên kết "Xem chi tiết". |
| Vật liệu | Nền đặc như Card. |
| Biến thể | `default`, `with-spark`, `status` (giá trị là trạng thái sức khỏe, dùng `CMP-StatusTag`), `filter` (cả thẻ là nút bật tắt lọc nhanh danh sách, `aria-pressed`, không sparkline; từ bản 0.2, mục 14.2). |
| Kích thước | Giá trị `font-display`; nhãn `font-footnote`; cao tối thiểu 120px; lưới 4 cột từ `bp-xxl`, 2 cột dưới `bp-xl`. |
| Trạng thái | Đang tải (Skeleton giá trị), sẵn sàng, không có dữ liệu kỳ trước (ẩn chỉ báo thay đổi, ghi "Chưa đủ dữ liệu so sánh"), lỗi (giá trị "—" kèm biểu tượng cảnh báo và Tooltip lỗi). |
| Token | `font-display`, `font-feature-tabular`, `font-footnote`, `color-success-text`, `color-error-text`, `color-text-secondary`. |
| Bàn phím, ARIA | Toàn thẻ có nhãn đọc liền mạch: "Lượt gọi API hôm nay: 1.234.567, tăng 12,5% so với 7 ngày trước"; sparkline `aria-hidden="true"` vì giá trị đã có ở chữ. |
| Nội dung | Chiều tăng không mặc định là tốt: thành phần nhận `goodDirection` để tô `color-success-text` hay `color-error-text` (ví dụ tỷ lệ lỗi tăng là xấu); màu luôn kèm mũi tên và chữ "tăng"/"giảm". |
| Điều cấm | Không làm tròn mất nghĩa (dùng "1,2 triệu" chỉ khi có Tooltip giá trị đầy đủ); không chỉ dùng màu để báo tăng giảm. |

: CMP-KpiCard

```ts
export interface DhKpiCardProps {
  label: string; value: number | null; unit?: string;
  format?: 'number' | 'percent' | 'money' | 'duration';
  delta?: { value: number; periodLabel: string }; goodDirection?: 'up' | 'down';
  spark?: number[]; href?: string; loading?: boolean; error?: DhApiError;
}
```

```tsx
<DhKpiCard label="Tỷ lệ lỗi gateway" value={0.42} format="percent" goodDirection="down"
  delta={{ value: 0.08, periodLabel: 'so với 7 ngày trước' }} spark={errorRateSeries} href="/monitoring/gateway" />
```

### 6.3. CMP-DescriptionList

`CMP-DescriptionList` trình bày các cặp nhãn–giá trị chỉ đọc trên trang chi tiết (PTN-02), trong Drawer xem nhanh và trong khối "Thông tin hệ thống" (người tạo, ngày tạo, người cập nhật, ngày cập nhật, CRUD-R-03/04). Không dùng cho dữ liệu có thể sửa tại chỗ (dùng `CMP-Form` chế độ chỉ đọc chuyển sang sửa).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Descriptions` của antd, `layout="vertical"` khi hẹp hơn `bp-md`, `"horizontal"` khi rộng; `colon={false}`; `column` 1–3. |
| Giải phẫu | (1) Tiêu đề nhóm tùy chọn; (2) nhãn; (3) giá trị, dùng thành phần nguyên tử phù hợp (`CMP-Timestamp`, `CMP-Money`, `CMP-Identifier`, `CMP-MaskedValue`, `CMP-StatusTag`); (4) nút sao chép cạnh giá trị định danh. |
| Vật liệu | Kế thừa nền đặc của Card hoặc giếng nội dung. |
| Biến thể | `default`, `system-info` (bốn trường hệ thống cố định ở cuối trang chi tiết), `bordered` (có đường kẻ, dùng trong so sánh). |
| Kích thước | Nhãn `font-footnote` `color-text-tertiary`; giá trị `font-body`; khoảng hàng `space-3`. |
| Trạng thái | Đang tải (Skeleton theo số trường), sẵn sàng, giá trị rỗng hiển thị "—" (CRUD-R-05), giá trị bị che (`CMP-MaskedValue` với nút "Hiện" khi có quyền, FR-00-034). |
| Token | `font-footnote`, `font-body`, `color-text-tertiary`, `color-text-primary`, `space-3`. |
| Bàn phím, ARIA | Dựng bằng `<dl>`, `<dt>`, `<dd>`; giá trị dài cắt dòng bằng `…` và mở rộng bằng nút "Xem thêm" (không chỉ Tooltip, vì Tooltip không chọn chữ được). |
| Nội dung | Nhãn như nhãn biểu mẫu tương ứng để người dùng nhận ra cùng trường. |
| Điều cấm | Không để giá trị trống; không đặt hành động sửa trong từng ô. |

: CMP-DescriptionList

```ts
export interface DhDescriptionListProps {
  items: Array<{ key: string; label: string; value: React.ReactNode; span?: number; copyable?: string }>;
  column?: 1 | 2 | 3; variant?: 'default' | 'system-info' | 'bordered'; loading?: boolean; title?: string;
}
```

```tsx
<DhDescriptionList variant="system-info" items={[
  { key: 'cb', label: 'Người tạo', value: s.createdByName },
  { key: 'ca', label: 'Ngày tạo', value: <DhTimestamp value={s.createdAt} /> },
]} />
```

### 6.4. CMP-Tree

`CMP-Tree` hiển thị dữ liệu phân cấp: danh mục dùng chung nhiều cấp (PH-07), đơn vị hành chính, cây cơ quan, cây thư mục dự án tích hợp. Đây là cột trái của PTN-08 (cây + bảng). Không dùng Tree cho dữ liệu phẳng hoặc chỉ hai cấp ít mục (dùng nhóm trong Select hoặc Tabs).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Tree` của antd, `blockNode`, `virtual` với `height` khi trên 200 nút, `loadData` cho tải lười theo cấp, `showLine={{ showLeafIcon: false }}`. |
| Giải phẫu | (1) Ô tìm trong cây (lọc cục bộ với cây đã tải, hoặc tìm máy chủ trả đường dẫn để mở rộng); (2) nút mở/đóng; (3) biểu tượng loại nút; (4) nhãn có tô đậm phần khớp; (5) số đếm con tùy chọn; (6) menu ngữ cảnh "⋯" theo `allowedActions` của nút. |
| Vật liệu | Nền đặc `color-surface-solid` (cột trái của PTN-08 là một thẻ đặc, không phải glass). |
| Biến thể | `navigate` (chọn một nút để lọc bảng bên phải), `checkable` (chọn nhiều, ba trạng thái cha), `draggable` (sắp xếp lại; bắt buộc có lệnh "Di chuyển tới…" trong menu ngữ cảnh làm phương án không kéo thả theo WCAG 2.5.7). |
| Kích thước | Cao nút 32px (gọn 28px); thụt cấp 24px; rộng cột 280–360px, kéo giãn được bằng tay nắm có phương án bàn phím (mũi tên trái/phải khi tay nắm có focus). |
| Trạng thái | Đang tải gốc (Skeleton 6 dòng), đang tải con (Spinner ở nút), rỗng, lỗi tải con (biểu tượng lỗi ở nút, nút "Thử lại"), nút bị vô hiệu, nút đã chọn (`color-fill-selected`). |
| Token | `color-fill-selected`, `color-fill-hover`, `color-accent-on-subtle`, `color-border-subtle` (đường nối), `font-body`, `radius-md`. |
| Bàn phím, ARIA | Mẫu ARIA Tree: `role="tree"`, `role="treeitem"`, `aria-expanded`, `aria-level`, `aria-setsize`, `aria-posinset`; mũi tên lên/xuống di chuyển, phải mở/vào con, trái đóng/về cha, Home/End, ký tự đầu để nhảy, Space chọn ở biến thể `checkable`. |
| Nội dung | Nhãn nút dạng "Mã · Tên" khi mã có nghĩa ("79 · TP. Hồ Chí Minh"). |
| Điều cấm | Không chỉ cho kéo thả để sắp xếp; không tải toàn bộ cây lớn hơn 5.000 nút một lần. |

: CMP-Tree

```ts
export interface DhTreeNode { key: string; title: string; isLeaf?: boolean; count?: number; allowedActions?: string[]; children?: DhTreeNode[] }
export interface DhTreeProps {
  variant?: 'navigate' | 'checkable' | 'draggable';
  treeData: DhTreeNode[]; loadChildren?: (key: string) => Promise<DhTreeNode[]>;
  selectedKey?: string; onSelect?: (key: string) => void;
  checkedKeys?: string[]; onCheck?: (keys: string[]) => void;
  onMove?: (key: string, targetParentKey: string, index: number) => Promise<void>;
  searchable?: boolean; nodeActions?: (node: DhTreeNode) => DhMenuItem[];
}
```

```tsx
<DhTree variant="navigate" searchable treeData={roots} loadChildren={fetchChildUnits}
  selectedKey={params.unit} onSelect={(unit) => setParams({ unit, page: 1 })} />
```

### 6.5. CMP-Transfer

`CMP-Transfer` chuyển mục giữa hai danh sách "Có thể chọn" và "Đã chọn", dùng khi tập lựa chọn lớn và người dùng cần thấy rõ những gì đã chọn: gán quyền cho vai trò (PH-12), chọn trường dữ liệu được khai thác (PH-09), chọn dịch vụ vào gói sử dụng (PH-02). Không dùng khi dưới 10 lựa chọn (dùng nhóm `CMP-Checkbox`) hoặc khi chỉ chọn một.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Transfer` của antd, `showSearch`, `oneWay={false}`, `pagination` khi trên 200 mục; với danh sách máy chủ lớn dùng `render` tùy biến và tìm máy chủ. |
| Giải phẫu | (1) Hai khung danh sách có tiêu đề và số đếm ("Có thể chọn (124)", "Đã chọn (8)"); (2) ô tìm mỗi khung; (3) ô chọn tất cả ba trạng thái; (4) hai nút chuyển "Thêm" và "Bỏ"; (5) mục có mô tả phụ. |
| Vật liệu | Nền đặc; mỗi khung `color-surface-solid` viền `color-border-subtle`. |
| Biến thể | `default`, `with-description` (mục hai dòng). |
| Kích thước | Mỗi khung rộng tối thiểu 280px, cao 360px; nút chuyển `size-control-md`. |
| Trạng thái | Đang tải, rỗng mỗi khung (EmptyState `compact`), mục vô hiệu (kèm Tooltip lý do, ví dụ "Quyền này chỉ dành cho vai trò nền tảng"), lỗi tải. |
| Token | `color-surface-solid`, `color-border-subtle`, `color-fill-selected`, `radius-lg`, `font-body`. |
| Bàn phím, ARIA | Mỗi khung là `role="listbox"` `aria-multiselectable="true"`; Space chọn mục, nút chuyển có nhãn chữ "Thêm vào đã chọn" và "Bỏ khỏi đã chọn" (không chỉ mũi tên); số đếm cập nhật qua `aria-live="polite"`. |
| Nội dung | Tiêu đề khung theo nghiệp vụ ("Quyền có thể gán", "Quyền đã gán"). |
| Điều cấm | Không chỉ dùng kéo thả để chuyển mục. |

: CMP-Transfer

```ts
export interface DhTransferProps<K extends string = string> {
  dataSource: Array<{ key: K; title: string; description?: string; disabledReason?: string }>;
  targetKeys: K[]; onChange: (keys: K[]) => void;
  titles: [string, string]; loading?: boolean; onSearch?: (dir: 'left' | 'right', q: string) => void;
}
```

```tsx
<DhTransfer titles={['Quyền có thể gán', 'Quyền đã gán']} dataSource={permissions}
  targetKeys={form.permissions} onChange={setPermissions} />
```

### 6.6. CMP-Chart

`CMP-Chart` là lớp bọc Apache ECharts (ADR-023) cho mọi biểu đồ của `dh-console` và `dh-portal`: lưu lượng API, tỷ lệ lỗi, độ trễ, chất lượng dữ liệu, chỉ tiêu báo cáo. Thành phần bảo đảm biểu đồ lấy màu, chữ, lưới từ token, đọc được ở cả hai chế độ sáng tối, không dựa vào màu làm phương tiện duy nhất, và luôn có bảng dữ liệu thay thế cho trình đọc màn hình (NFR-00-040).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `echarts/core` nhập theo nhu cầu (tree-shaking): `LineChart`, `BarChart`, `PieChart`, `HeatmapChart`, `GridComponent`, `TooltipComponent`, `LegendComponent`, `DataZoomComponent`, `AriaComponent`, `SVGRenderer` (mặc định) và `CanvasRenderer` (khi trên 5.000 điểm). Theme `datahub-light` và `datahub-dark` đăng ký bằng `echarts.registerTheme` từ `tokens.light`/`tokens.dark` của `@datahub/tokens`; đổi chế độ thì khởi tạo lại biểu đồ với theme mới. |
| Giải phẫu | (1) Tiêu đề và mô tả ngắn (nằm ngoài canvas biểu đồ, là chữ HTML); (2) thanh công cụ: chọn khoảng thời gian (`CMP-SegmentedControl` "1 giờ / 24 giờ / 7 ngày / 30 ngày"), nút "Xem dạng bảng", nút "Tải PNG/CSV"; (3) vùng vẽ; (4) nhãn trực tiếp ở cuối mỗi đường hoặc trên mỗi cột; (5) chú giải có ký hiệu hình dạng; (6) Tooltip; (7) bảng dữ liệu thay thế. |
| Vật liệu | Vùng vẽ nền đặc `color-surface-solid` (biểu đồ nằm trong `CMP-Card`). Tooltip của ECharts dùng nền đảo đặc `color-surface-inverse` như `CMP-Tooltip`, không glass. |
| Biến thể | `line`, `area`, `bar`, `stacked-bar`, `pie` (chỉ khi tối đa 5 phần và có nhãn phần trăm trực tiếp), `heatmap`, `spark` (không trục, không tương tác, cho KpiCard). |
| Kích thước | Cao mặc định 280px (`spark`: 40px); chữ trục `font-caption`; nhãn dữ liệu `font-caption` đậm 500. |
| Trạng thái | Đang tải (Skeleton hình chữ nhật đúng chiều cao), rỗng ("Chưa có dữ liệu trong khoảng thời gian này"), lỗi (Alert `inline`), dữ liệu một phần (chú thích "Thiếu dữ liệu từ 10:00 đến 10:15" và khoảng trống trên đường, không nối giả). |
| Token | `color-chart-1` … `color-chart-8` theo thứ tự ưu tiên (màu 8 dùng cuối), `color-text-secondary` (chữ trục), `color-border-subtle` (lưới), `color-surface-inverse` + `color-text-on-inverse` (Tooltip), `font-family-sans`, `font-caption`, `font-feature-tabular`, `motion-duration-base` (tắt khi giảm chuyển động). |
| Bàn phím, ARIA | Phần tử chứa có `role="figure"` và `aria-labelledby` trỏ tiêu đề, `aria-describedby` trỏ đoạn tóm tắt sinh tự động (ví dụ "Lượt gọi tăng từ 12.300 lên 18.900 trong 7 ngày, cao nhất ngày 20/11/2026"). Tùy chọn `aria: { enabled: true, decal: { show: true } }` của ECharts bật hoa văn (decal) phân biệt chuỗi khi in hoặc khi người dùng bật chế độ tương phản. Nút "Xem dạng bảng" mở `<table>` HTML thật (có `<caption>`, `<th scope>`) thay thế vùng vẽ; bảng này luôn có trong DOM ở dạng ẩn trực quan để trình đọc màn hình truy cập. Tooltip mở được bằng bàn phím: khi vùng vẽ có focus, mũi tên trái/phải di chuyển giữa các điểm dữ liệu và giá trị được đọc qua `aria-live="polite"`. |
| Nội dung | Số theo định dạng Việt Nam trong trục và Tooltip (`1.234.567`, `12,5%`); thời gian trục `HH:mm` hoặc `DD/MM`; tiêu đề nêu đại lượng và đơn vị ("Độ trễ p95 (ms)"). |
| Điều cấm | Không dùng biểu đồ 3D, biểu đồ tròn trên 5 phần, hai trục tung khác đơn vị trừ khi có nhãn rõ; không phân biệt chuỗi chỉ bằng màu; không viết mã màu hex trong `option`. |

: CMP-Chart

Theme được sinh như đoạn mã dưới đây; biểu đồ nghiệp vụ không tự đặt `color`, `textStyle` hay `backgroundColor`. Nhãn trực tiếp được bật bằng `endLabel` cho đường và `label.show` cho cột; khi có trên 4 chuỗi, thành phần chuyển sang chú giải có ký hiệu (`legend.icon` lần lượt `circle`, `rect`, `triangle`, `diamond`…) để giữ phân biệt không dựa vào màu.

```ts
// @datahub/ui/src/chart/theme.ts
import * as echarts from 'echarts/core';
import { tokens } from '@datahub/tokens';
for (const mode of ['light', 'dark'] as const) {
  const t = tokens[mode];
  echarts.registerTheme(`datahub-${mode}`, {
    color: [t.color.chart1, t.color.chart2, t.color.chart3, t.color.chart4, t.color.chart5, t.color.chart6, t.color.chart7, t.color.chart8],
    backgroundColor: 'transparent',
    textStyle: { fontFamily: t.font.familySans, color: t.color.textSecondary },
    categoryAxis: { axisLine: { lineStyle: { color: t.color.borderSubtle } }, splitLine: { show: false } },
    valueAxis: { splitLine: { lineStyle: { color: t.color.borderSubtle } } },
    tooltip: { backgroundColor: t.color.surfaceInverse, borderWidth: 0, textStyle: { color: t.color.textOnInverse } },
  });
}

export interface DhChartProps {
  kind: 'line' | 'area' | 'bar' | 'stacked-bar' | 'pie' | 'heatmap' | 'spark';
  title: string; description?: string; unit?: string;
  series: Array<{ name: string; data: Array<[string | number, number | null]> }>;
  xType?: 'time' | 'category'; height?: number;
  loading?: boolean; error?: DhApiError; summary?: string; // ghi đè tóm tắt tự sinh
  onRangeChange?: (range: '1h' | '24h' | '7d' | '30d') => void;
}
```

```tsx
<DhCard title="Lượt gọi API theo ngày">
  <DhChart kind="line" title="Lượt gọi API theo ngày" unit="lượt" xType="time"
    series={[{ name: 'Thành công', data: okSeries }, { name: 'Lỗi', data: errSeries }]}
    loading={q.isPending} error={q.error ?? undefined} onRangeChange={setRange} />
</DhCard>
```

## 7. Lớp nổi

Lớp nổi là nơi vật liệu glass được dùng nhiều nhất, nên nhóm này tuân thủ chặt mục 2.1. Bảng dưới đây tóm tắt cách các lớp nổi xếp chồng và vật liệu của chúng, để kỹ sư biết lớp nào được mở từ lớp nào.

| Thành phần | Vật liệu khung | Nội dung | Lớp chồng | Được mở từ bên trong Modal/Drawer |
|---|---|---|---|---|
| `CMP-Modal`, `CMP-ConfirmDialog`, `CMP-ReasonDialog` | `glass-modal` | Giếng nội dung đặc | `z-modal` | Không (cấm Modal chồng Modal); ConfirmDialog là ngoại lệ có kiểm soát, xem 7.3 |
| `CMP-Drawer` | `glass-modal` | Giếng nội dung đặc | `z-drawer` | Không mở Drawer từ Modal; từ Drawer chỉ được mở ConfirmDialog/ReasonDialog |
| `CMP-Popover`, `CMP-DropdownMenu`, popup Select | `glass-overlay` | Trực tiếp trên glass | `z-popover` | Có (ngoại lệ glass trên glass được phép) |
| `CMP-SessionTimeoutDialog` | `glass-modal` | Giếng nội dung đặc | `z-session-dialog` | Luôn nằm trên mọi lớp |

: Lớp nổi

### 7.1. CMP-Modal

`CMP-Modal` là hộp thoại chặn (modal dialog) cho tác vụ ngắn cần tập trung: biểu mẫu nhanh ít trường (PTN-04), xem trước, chọn đối tượng. Nó là khung chung mà `CMP-ConfirmDialog`, `CMP-ReasonDialog`, `CMP-SessionTimeoutDialog` và `CMP-CommandPalette` kế thừa. Không dùng Modal cho biểu mẫu trên 8 trường hoặc có cuộn dài (dùng `CMP-Drawer` hoặc trang PTN-03), không dùng để hiển thị thông báo thành công (dùng Toast), và không mở Modal từ trong Modal.

#### 7.1.1. Giải phẫu và vật liệu

Modal có cấu trúc hai lớp theo nguyên tắc bo góc đồng tâm của Liquid Glass. Lớp ngoài là **khung glass** dùng vật liệu `glass-modal`, bo `radius-xl` (20px), đệm `space-2` (8px). Lớp trong là **giếng nội dung** nền `color-surface-solid`, bo 20 − 8 = 12px, tính bằng hàm `radius-concentric(radius-xl, space-2)` của D03-05-02 §7. Tiêu đề và nút đóng nằm trên khung glass (chữ chính đạt 12,80:1 ở trường hợp xấu nhất); thân và mọi liên kết nằm trong giếng đặc (vì chữ liên kết trên `glass-modal` chỉ đạt 4,09:1 ở trường hợp xấu nhất). Footer nằm trên khung glass, chỉ chứa nút (nút có nền riêng, không phụ thuộc tương phản với khung).

| Phần con | Khóa `classNames` (antd 6.7.1) | Vật liệu, token |
|---|---|---|
| Lớp che phía sau | `mask` | `color-scrim`; `mask={{ blur: false, closable: false }}` (không nhòe lớp che để tránh glass chồng glass và tiết kiệm GPU) |
| Khung | `container` | `.dh-glass--modal`, `radius-xl`, `shadow-4` ghép `glass-highlight-top` và `glass-edge`; đệm `space-2` |
| Đầu (tiêu đề, nút đóng) | `header`, `title`, `close` | Trên khung glass; tiêu đề `font-title-2` `color-text-primary`; đệm `space-4` `space-4` `space-3` |
| Thân (giếng nội dung) | `body` | `color-surface-solid`, bo 12px, đệm `space-5` (gọn `space-4`), cuộn nội bộ khi cao hơn 70vh |
| Chân (footer) | `footer` | Trên khung glass; đệm `space-3` `space-4`; nút căn phải: nút phụ trước, nút chính sau cùng |

: Giải phẫu và vật liệu

Ở chế độ glass `off`, khung có nền `glass-off-tint` (`color-surface-solid`) và giếng nội dung có thêm viền `color-border-subtle` để vẫn phân biệt hai lớp. Ở chế độ `lite`, khung dùng `glass-lite-tint` và `blur-none`.

#### 7.1.2. Hành vi

Bảng sau quy định hành vi bắt buộc của Modal; đây là các điểm hay bị làm sai khi dùng antd mặc định.

| Hành vi | Quy định | Cấu hình antd |
|---|---|---|
| Bẫy focus (focus trap) | Focus không rời Modal khi mở; Tab và Shift+Tab vòng trong Modal | `focusable={{ trap: true, focusTriggerAfterClose: true }}` |
| Focus ban đầu | Vào trường nhập đầu tiên nếu là biểu mẫu; vào nút an toàn (Hủy) nếu là xác nhận phá hủy; nếu không có thì vào tiêu đề (`tabIndex=-1`) | Tự xử lý trong `afterOpenChange` |
| Trả focus | Khi đóng, focus về phần tử đã mở Modal | `focusTriggerAfterClose: true` |
| Esc | Đóng Modal; nếu biểu mẫu bẩn thì hỏi "Bỏ thay đổi?" ngay trong giếng nội dung (dải Alert `warning` với nút "Bỏ thay đổi" và "Tiếp tục sửa"), không mở Modal thứ hai | `keyboard` |
| Bấm lớp che | Không đóng (tránh mất dữ liệu do bấm nhầm) | `mask={{ closable: false }}` |
| Cuộn nền | Khóa cuộn trang | `scrollLock` (mặc định) |
| Chồng Modal | Cấm. `DhModal` kiểm tra ngăn xếp lớp nổi của `CMP-AppShell`; mở Modal khi đã có Modal sẽ ghi cảnh báo ở môi trường phát triển và thay nội dung Modal hiện tại bằng bước kế tiếp (mẫu "điều hướng trong Modal") | Ngăn xếp `useDhOverlayStack` |
| Hủy khi ẩn | Có, để biểu mẫu mở lại ở trạng thái mới | `destroyOnHidden` |
| Chuyển động | Phóng `motion-scale-enter` với `motion-duration-slow` và `motion-ease-emphasized`; đóng `motion-ease-exit`; giảm chuyển động thì chỉ mờ dần | Token `motionDurationSlow`, `motionEaseOutBack` |
| Đang gửi | Nút chính loading, nút đóng và Esc tạm khóa cho tới khi có kết quả | `confirmLoading`, `keyboard={!submitting}` |

: Hành vi: Hành vi, Quy định

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Modal` của antd v6. Props cố định: `centered`, `mask={{ blur: false, closable: false }}`, `focusable={{ trap: true, focusTriggerAfterClose: true }}`, `destroyOnHidden`, `classNames={{ container: 'dh-glass--modal dh-modal__frame', body: 'dh-modal__well' }}`, `width` từ `size-modal-sm`/`md`/`lg`. Không dùng `Modal.confirm` tĩnh; dùng `CMP-ConfirmDialog`. |
| Biến thể | `form` (thân là `CMP-Form` `panel`, footer có "Hủy" và nút chính), `view` (chỉ nút "Đóng"), `select` (thân là danh sách chọn, nút chính "Chọn"). |
| Kích thước | `sm` = `size-modal-sm` (416px, xác nhận), `md` = `size-modal-md` (560px, mặc định), `lg` = `size-modal-lg` (800px, xem trước, so sánh); dưới `bp-md` Modal chiếm toàn chiều rộng trừ lề `space-4`. |
| Trạng thái | Đang mở, đang tải nội dung (Skeleton trong giếng), sẵn sàng, đang gửi, lỗi gửi (Alert trong giếng, không đóng Modal), bẩn (cảnh báo khi đóng), đóng. |
| Token | `glass-modal`, `radius-xl`, `space-2`, `color-surface-solid`, `color-scrim`, `shadow-4`, `glass-highlight-top`, `glass-edge`, `font-title-2`, `z-modal`, `motion-duration-slow`, `motion-ease-emphasized`, `motion-ease-exit`, `size-modal-sm`, `size-modal-md`, `size-modal-lg`. |
| Bàn phím, ARIA | `role="dialog"`, `aria-modal="true"`, `aria-labelledby` trỏ tiêu đề, `aria-describedby` trỏ đoạn mô tả đầu giếng nếu có; nút đóng `aria-label="Đóng"`, vùng chạm ≥ 24×24. |
| Nội dung | Tiêu đề là hành động hoặc đối tượng ("Thêm khóa truy cập"); nút chính lặp lại động từ của tiêu đề ("Thêm"); nút phụ luôn là "Hủy". |
| Điều cấm | Không chồng Modal; không đặt liên kết hoặc chữ cấp hai trực tiếp trên khung glass; không đóng khi bấm lớp che; không đặt bảng dữ liệu đầy đủ trong Modal (dùng Drawer `lg` hoặc trang). |

: Hành vi: Khía cạnh, Đặc tả

```ts
export interface DhModalProps {
  open: boolean; onClose: () => void;
  title: string; description?: string;
  size?: 'sm' | 'md' | 'lg'; variant?: 'form' | 'view' | 'select';
  primaryText?: string; onPrimary?: () => Promise<void> | void; primaryDanger?: boolean;
  submitting?: boolean; dirty?: boolean; loading?: boolean; error?: DhApiError;
  initialFocus?: 'first-field' | 'cancel' | 'title';
  children: React.ReactNode;
}
```

```tsx
<DhModal open={open} onClose={close} title="Thêm khóa truy cập" size="md" variant="form"
  primaryText="Thêm" onPrimary={form.submit} submitting={create.isPending} dirty={form.isDirty}>
  <DhForm variant="panel" onSubmit={create.mutateAsync} sections={[{ key: 'k', title: 'Thông tin khóa', children: <KeyFields /> }]} />
</DhModal>
```

### 7.2. CMP-Drawer

`CMP-Drawer` là ngăn trượt từ cạnh phải cho biểu mẫu nhanh nhiều trường (PTN-04), xem nhanh chi tiết một dòng từ danh sách mà không rời danh sách, bộ lọc mở rộng trên màn hẹp, và khung Sidebar dưới `bp-lg`. Không dùng Drawer cho tác vụ cần toàn màn (dùng trang), không mở Drawer từ Modal, và không mở Drawer chồng Drawer quá một cấp (chỉ cho phép một Drawer con `md` trên Drawer `lg` khi xem chi tiết phần tử con, dùng thuộc tính đẩy `push`).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Drawer` của antd v6. Props cố định: `placement="right"` (sidebar: `"left"`), `size` lấy `size-drawer-md` hoặc `size-drawer-lg`, `mask={{ blur: false, closable: true }}` cho xem nhanh và `closable: false` khi là biểu mẫu, `focusable={{ trap: true, focusTriggerAfterClose: true }}`, `destroyOnHidden`, `classNames={{ section: 'dh-glass--modal dh-drawer__frame', body: 'dh-drawer__well' }}` (khóa `content` đã lỗi thời, dùng `section`). `resizable` bật cho Drawer xem chi tiết, có phương án bàn phím (tay nắm nhận focus, mũi tên trái/phải đổi độ rộng 16px). |
| Giải phẫu | (1) Lớp che `color-scrim`; (2) khung `glass-modal`, chỉ bo cạnh hở (`radius-xl` ở hai góc trái khi đặt bên phải), đệm `space-2`; (3) đầu: tiêu đề `font-title-3`, phụ đề, `CMP-StatusTag`, vùng `extra` (nút "Mở trang đầy đủ"), nút đóng; (4) giếng nội dung đặc bo 12px; (5) chân: thanh nút giống Modal. |
| Vật liệu | Khung `glass-modal`; giếng `color-surface-solid`; footer trên khung glass chỉ chứa nút. |
| Biến thể | `form`, `view` (xem nhanh, có Tabs thu gọn), `filter`, `nav` (sidebar dưới `bp-lg`). |
| Kích thước | `md` = `size-drawer-md` (560px), `lg` = `size-drawer-lg` (880px); dưới `bp-md` chiếm toàn chiều rộng. |
| Trạng thái | Như Modal; thêm trạng thái "đang xem bản ghi không còn tồn tại" (giếng hiển thị `CMP-EmptyState` với nội dung "Bản ghi đã bị xóa hoặc thay đổi" và nút "Tải lại danh sách"). |
| Token | `glass-modal`, `radius-xl`, `space-2`, `color-surface-solid`, `color-scrim`, `shadow-4`, `size-drawer-md`, `size-drawer-lg`, `z-drawer`, `motion-duration-slow`, `motion-ease-emphasized`. |
| Bàn phím, ARIA | `role="dialog"`, `aria-modal="true"`, `aria-labelledby`; Esc đóng (hỏi nếu bẩn); khi Drawer xem nhanh mở từ một dòng bảng, mũi tên lên/xuống kèm Alt chuyển sang bản ghi trước/sau mà không đóng Drawer. |
| Nội dung | Như Modal. Drawer xem nhanh luôn có liên kết "Mở trang đầy đủ" để có URL chia sẻ được. |
| Điều cấm | Không mở Drawer từ Modal; không đặt liên kết trực tiếp trên khung; không dùng Drawer bên trái ngoài biến thể `nav`. |

: CMP-Drawer

```ts
export interface DhDrawerProps extends Omit<DhModalProps, 'size' | 'variant'> {
  size?: 'md' | 'lg'; variant?: 'form' | 'view' | 'filter' | 'nav';
  status?: React.ReactNode; fullPageHref?: string;
  onPrev?: () => void; onNext?: () => void; resizable?: boolean;
}
```

```tsx
<DhDrawer open={!!selectedId} onClose={() => setSelectedId(undefined)} variant="view" size="md"
  title={app?.name ?? ''} status={<DhStatusTag lifecycle={app?.status} />} fullPageHref={`/apps/${selectedId}`}
  onPrev={selectPrev} onNext={selectNext}>
  <AppQuickView id={selectedId} />
</DhDrawer>
```

### 7.3. CMP-ConfirmDialog

`CMP-ConfirmDialog` xin xác nhận trước thao tác phá hủy hoặc không hoàn tác được: xóa (xóa mềm theo FR-00-051), thu hồi khóa, hủy yêu cầu, gửi thông báo (CRUD-ACT-03). Đây là hiện thực của vế "phải yêu cầu xác nhận" trong FR-00-050. Khi thao tác còn ảnh hưởng vận hành (tạm dừng dịch vụ, thu hồi đăng ký, hoàn tiền), dùng `CMP-ReasonDialog` thay thế vì cần lý do.

ConfirmDialog có ba mức nghiêm trọng, chọn theo hậu quả của thao tác. Bảng sau là quy tắc chọn mức; SDD phân hệ ghi rõ mức cho từng thao tác.

| Mức | Khi dùng | Hình thức xác nhận | Ví dụ |
|---|---|---|---|
| `normal` | Thao tác thay đổi trạng thái, hoàn tác được | Hai nút, nút chính màu nhấn | "Gửi thông báo phiên bản MB01?" |
| `destructive` | Xóa mềm, thu hồi; khôi phục được bởi quản trị | Hai nút, nút chính phá hủy (`color-error-solid`), focus ban đầu ở "Hủy" | "Xóa dịch vụ Tra cứu hộ tịch?" |
| `dangerous` | Xóa đối tượng có phụ thuộc rộng, xóa tenant, thu hồi chứng thư gốc, xóa hàng loạt trên 50 bản ghi | Như `destructive` và bắt buộc gõ đúng tên hoặc mã đối tượng; nút chính chỉ bật khi khớp | "Nhập T68 để xác nhận xóa tenant" |

: CMP-ConfirmDialog: Mức, Khi dùng

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Modal` cỡ `sm`, biến thể nội bộ `confirm`; gọi qua hook `useDhConfirm()` trả về `Promise<boolean>`. |
| Giải phẫu | (1) Biểu tượng mức (Lucide `TriangleAlert` cho `destructive`/`dangerous`) trên khung; (2) tiêu đề dạng câu hỏi; (3) trong giếng: mô tả hậu quả, danh sách đối tượng bị ảnh hưởng (tối đa 5 dòng rồi "và 12 bản ghi khác"), phụ thuộc bị ảnh hưởng (ví dụ "3 đăng ký sử dụng sẽ ngừng hoạt động"); (4) ô nhập xác nhận (mức `dangerous`) với nhãn "Nhập {mã} để xác nhận"; (5) footer: "Hủy" và nút chính mang động từ cụ thể. |
| Vật liệu | Như Modal: khung `glass-modal`, giếng đặc. |
| Biến thể | `normal`, `destructive`, `dangerous`; `bulk` (thêm số lượng, CRUD-D-02). |
| Kích thước | `size-modal-sm`. |
| Trạng thái | Chờ xác nhận, chưa khớp tên (nút chính vô hiệu, mô tả nói rõ cần gõ gì), đang thực hiện (nút loading, khóa Esc), lỗi (Alert trong giếng, giữ hộp thoại), thành công một phần với hàng loạt (chuyển sang bảng kết quả từng bản ghi, CRUD-D-09, CRUD-SEL-08). |
| Token | Như Modal, thêm `color-error-solid` (nút chính phá hủy), `color-error-text` (biểu tượng), `color-warning-text`. |
| Bàn phím, ARIA | `role="alertdialog"`, `aria-describedby` trỏ đoạn hậu quả; focus ban đầu: `normal` vào nút chính, `destructive` vào "Hủy", `dangerous` vào ô nhập; Enter không kích hoạt nút phá hủy khi focus đang ở "Hủy". So khớp tên phân biệt hoa thường, cắt khoảng trắng hai đầu, không cho dán từ bộ nhớ tạm bị chặn (cho phép dán để hỗ trợ công nghệ hỗ trợ). |
| Nội dung | Tiêu đề "Xóa dịch vụ “Tra cứu hộ tịch”?"; mô tả "Dịch vụ sẽ bị gỡ khỏi danh mục và không thể gọi được nữa. Quản trị tỉnh có thể khôi phục trong 30 ngày." Nút chính "Xóa dịch vụ", không dùng "Đồng ý" hay "OK". |
| Điều cấm | Không dùng `Popconfirm` cho thao tác phá hủy (khó dùng với bàn phím, nội dung quá ngắn); không đặt nút phá hủy làm focus mặc định; không xác nhận bằng hộp thoại `window.confirm`. |

: CMP-ConfirmDialog: Khía cạnh, Đặc tả

ConfirmDialog là trường hợp duy nhất được mở từ bên trong Drawer hoặc Modal (ví dụ xóa một dòng con trong Drawer). Khi đó `DhModal` không mở lớp thứ hai mà thay giếng nội dung hiện tại bằng nội dung xác nhận, giữ nguyên khung, và trả về nội dung cũ khi hủy; nhờ vậy quy tắc "không chồng Modal" vẫn được giữ.

```ts
export interface DhConfirmOptions {
  severity?: 'normal' | 'destructive' | 'dangerous';
  title: string; consequence: React.ReactNode;
  affected?: string[]; affectedTotal?: number;
  confirmText: string;                 // động từ cụ thể, ví dụ "Xóa dịch vụ"
  typeToConfirm?: string;              // bắt buộc với dangerous
  onConfirm: () => Promise<DhBulkResult | void>;
}
export interface DhBulkResult { succeeded: string[]; failed: Array<{ id: string; label: string; reason: string }> }
export function useDhConfirm(): (opts: DhConfirmOptions) => Promise<boolean>;
```

```tsx
const confirm = useDhConfirm();
await confirm({ severity: 'dangerous', title: `Xóa tenant “${t.name}”?`, typeToConfirm: t.code,
  consequence: 'Toàn bộ người dùng của tenant sẽ mất quyền truy cập. Dữ liệu được giữ theo chính sách lưu giữ 90 ngày.',
  confirmText: 'Xóa tenant', onConfirm: () => deleteTenant.mutateAsync(t.id) });
```

### 7.4. CMP-ReasonDialog

`CMP-ReasonDialog` xin xác nhận kèm lý do bắt buộc cho thao tác ảnh hưởng vận hành theo vế thứ hai của FR-00-050: tạm dừng dịch vụ, thu hồi đăng ký, khóa HTTT thành viên, hoàn tiền, truy cập liên tenant (FR-00-012), xem dữ liệu Nhạy cảm đầy đủ (FR-00-034). Lý do được gửi cùng yêu cầu và ghi vào nhật ký kiểm toán (FR-00-041 trường "lý do"). ReasonDialog cũng là hộp từ chối trong `CMP-ApprovalPanel` (FR-00-072).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Modal` cỡ `md` biến thể nội bộ `reason`; gọi qua `useDhReason()` trả về `Promise<{ reason: string; code?: string } | null>`. |
| Giải phẫu | (1) Tiêu đề hành động; (2) trong giếng: mô tả hậu quả và đối tượng bị ảnh hưởng; (3) `CMP-Select` "Nhóm lý do" (tùy chọn, danh mục lý do chuẩn do phân hệ cấu hình, ví dụ "Bảo trì theo kế hoạch", "Vi phạm điều khoản", "Yêu cầu của chủ quản dữ liệu"); (4) `CMP-TextArea` "Lý do" bắt buộc, tối thiểu 10 ký tự, tối đa 1.000 ký tự, có bộ đếm; (5) tùy chọn bổ sung theo nghiệp vụ (ví dụ "Thông báo cho HTTT bị ảnh hưởng"); (6) ghi chú "Lý do được lưu vào nhật ký kiểm toán và không sửa được."; (7) footer "Hủy" và nút chính. |
| Vật liệu | Như Modal. |
| Biến thể | `operational` (nút chính màu nhấn hoặc phá hủy theo thao tác), `reject` (từ chối yêu cầu, nút chính "Từ chối" kiểu phá hủy viền), `sensitive-access` (xem dữ liệu nhạy cảm, có thêm thời hạn truy cập). |
| Kích thước | `size-modal-md`; ô lý do cao 4 dòng, tự giãn tới 10 dòng. |
| Trạng thái | Chưa nhập đủ (nút chính vẫn bấm được; khi bấm, hiện lỗi tại trường "Vui lòng nêu lý do, tối thiểu 10 ký tự."), đang gửi, lỗi, thành công (đóng và Toast). |
| Token | Như Modal, thêm `font-footnote` + `color-text-tertiary` (ghi chú kiểm toán). |
| Bàn phím, ARIA | Focus ban đầu vào ô lý do; Ctrl/⌘+Enter gửi; ô lý do `aria-required="true"`, `aria-describedby` trỏ bộ đếm và ghi chú kiểm toán. |
| Nội dung | Tiêu đề "Tạm dừng dịch vụ “Tra cứu hộ tịch”"; mô tả "Các HTTT đang gọi dịch vụ sẽ nhận lỗi 503 cho tới khi dịch vụ được kích hoạt lại." |
| Điều cấm | Không cho gửi lý do toàn khoảng trắng hoặc ký tự lặp vô nghĩa dưới 10 ký tự; không điền sẵn lý do; không dùng ReasonDialog cho xóa thông thường không ảnh hưởng vận hành. |

: CMP-ReasonDialog

```ts
export interface DhReasonOptions {
  variant?: 'operational' | 'reject' | 'sensitive-access';
  title: string; consequence: React.ReactNode; confirmText: string; danger?: boolean;
  reasonCodes?: Array<{ value: string; label: string }>;
  minLength?: number;                  // mặc định 10
  extraFields?: React.ReactNode;
  onSubmit: (input: { reason: string; code?: string; extra?: Record<string, unknown> }) => Promise<void>;
}
export function useDhReason(): (opts: DhReasonOptions) => Promise<{ reason: string; code?: string } | null>;
```

```tsx
const askReason = useDhReason();
await askReason({ title: `Tạm dừng dịch vụ “${s.name}”`, confirmText: 'Tạm dừng', danger: true,
  consequence: 'Các HTTT đang gọi dịch vụ sẽ nhận lỗi 503 cho tới khi dịch vụ được kích hoạt lại.',
  reasonCodes: suspendReasons, onSubmit: ({ reason, code }) => suspend.mutateAsync({ id: s.id, reason, code }) });
```

### 7.5. CMP-Popover

`CMP-Popover` là lớp nổi không chặn, mở từ một phần tử kích hoạt để hiển thị nội dung phụ có thể tương tác: giải thích chi tiết một chỉ số, bộ chọn nhỏ, thẻ xem nhanh người dùng. Không dùng Popover cho nội dung chỉ đọc một dòng (dùng `CMP-Tooltip`), cho danh sách lệnh (dùng `CMP-DropdownMenu`) hoặc cho biểu mẫu nhiều trường (dùng Drawer).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Popover` của antd, `trigger="click"` (không dùng `hover` cho nội dung tương tác), `arrow={false}`, `classNames={{ root: 'dh-glass--overlay' }}`; token `Popover.popoverBg` = tint `glass-overlay` (D03-05-02 §13.3). |
| Giải phẫu | (1) Tiêu đề tùy chọn `font-body-strong`; (2) nội dung; (3) hàng hành động tùy chọn. |
| Vật liệu | `glass-overlay`, nội dung trực tiếp lên glass; được phép mở từ trong Modal/Drawer. |
| Biến thể | `default`, `info` (giải thích có liên kết "Tìm hiểu thêm"). |
| Kích thước | Rộng 240–360px; đệm `space-3`; bo `radius-lg`; cách phần tử kích hoạt `space-1`. |
| Trạng thái | Đóng, mở (phóng từ phía phần tử kích hoạt, `motion-duration-base`, `motion-ease-emphasized`), đang tải nội dung (Skeleton). |
| Token | `glass-overlay`, `radius-lg`, `shadow-3`, `space-3`, `z-popover`, `motion-duration-base`. |
| Bàn phím, ARIA | Phần tử kích hoạt có `aria-expanded`, `aria-controls`, `aria-haspopup="dialog"`; Popover `role="dialog"` không modal; Esc đóng và trả focus; Tab đi vào nội dung; bấm ra ngoài đóng. |
| Nội dung | Ngắn, tối đa 3 đoạn. |
| Điều cấm | Không mở Popover chồng Popover; không đặt Popover chứa nội dung bắt buộc phải đọc mới làm tiếp được. |

: CMP-Popover

```ts
export interface DhPopoverProps { title?: string; content: React.ReactNode; actions?: React.ReactNode; children: React.ReactElement; placement?: 'top' | 'bottom' | 'left' | 'right' | 'bottomLeft' | 'bottomRight' }
```

```tsx
<DhPopover title="Hạn mức là gì?" content="Số lượt gọi tối đa trong một tháng theo gói sử dụng. Vượt hạn mức sẽ nhận lỗi 429.">
  <DhIconButton icon="CircleHelp" label="Giải thích hạn mức" />
</DhPopover>
```

### 7.6. CMP-DropdownMenu

`CMP-DropdownMenu` là danh sách lệnh mở từ một nút: "Thao tác khác" trên PageHeader, menu "⋯" trên dòng bảng, menu xuất dữ liệu, menu bộ lọc đã lưu. Không dùng DropdownMenu để chọn giá trị cho biểu mẫu (dùng `CMP-Select`) hoặc điều hướng chính (dùng Sidebar).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Dropdown` của antd với `menu={{ items }}`, `trigger={['click']}`, `classNames={{ root: 'dh-glass--overlay' }}`; token `Menu.popupBg` = `colorBgElevated`. |
| Giải phẫu | (1) Nhóm có tiêu đề `font-caption` đậm 600; (2) mục: biểu tượng, nhãn, phím tắt `CMP-Kbd`, mô tả phụ tùy chọn; (3) đường phân cách; (4) mục phá hủy ở cuối, chữ `color-error-text`, tách bằng đường phân cách; (5) mục con (tối đa một cấp). |
| Vật liệu | `glass-overlay`. |
| Biến thể | `actions`, `export` (Excel, CSV, kèm số dòng ước tính), `selectable` (có dấu chọn, cho bộ lọc đã lưu). |
| Kích thước | Rộng tối thiểu 180px; mục cao `size-control-md`; bo `radius-lg`, mục bo `radius-md`; đệm `space-1`. |
| Trạng thái | Mục thường, hover/focus (`color-fill-hover`), vô hiệu (kèm Tooltip lý do nếu có `disabledReason`), đang tải danh sách mục. |
| Token | `glass-overlay`, `radius-lg`, `radius-md`, `shadow-3`, `color-fill-hover`, `color-error-text`, `font-body`, `font-caption`, `z-popover`. |
| Bàn phím, ARIA | Mẫu ARIA Menu Button: nút `aria-haspopup="menu"`, `aria-expanded`; menu `role="menu"`, mục `role="menuitem"`; Enter/Space/mũi tên xuống mở và focus mục đầu, mũi tên lên/xuống di chuyển, Home/End, ký tự đầu nhảy mục, Esc đóng và trả focus. |
| Nội dung | Nhãn động từ ("Sao chép", "Tạm dừng…"); dấu "…" cuối nhãn khi lệnh mở hộp thoại tiếp theo. |
| Điều cấm | Không quá 10 mục; không lồng quá một cấp; không chứa hành động duy nhất của màn hình (nút chính phải hiện ra ngoài). |

: CMP-DropdownMenu

```ts
export type DhMenuItem =
  | { type?: 'item'; key: string; label: string; icon?: string; shortcut?: string; danger?: boolean; disabledReason?: string; onClick: () => void }
  | { type: 'group'; key: string; label: string; children: DhMenuItem[] }
  | { type: 'divider'; key: string };
export interface DhDropdownMenuProps { items: DhMenuItem[]; trigger: React.ReactElement; variant?: 'actions' | 'export' | 'selectable' }
```

```tsx
<DhDropdownMenu trigger={<DhIconButton icon="Ellipsis" label="Thao tác khác" />} items={[
  { key: 'copy', label: 'Sao chép mã', icon: 'Copy', onClick: copyCode },
  { type: 'divider', key: 'd' },
  { key: 'delete', label: 'Xóa…', icon: 'Trash2', danger: true, onClick: onDelete },
]} />
```

### 7.7. CMP-SessionTimeoutDialog

`CMP-SessionTimeoutDialog` hiện thực FR-00-003: sau thời gian không thao tác (mặc định 30 phút, tenant cấu hình 5–120 phút), hệ thống tự đăng xuất, và **trước 2 phút** hiển thị hộp thoại cảnh báo có đếm ngược để người dùng chọn tiếp tục. Hộp thoại do `CMP-AppShell` gắn một lần, không phân hệ nào tự dựng.

Cơ chế hoạt động như sau. Bộ đếm không thao tác lắng nghe `pointerdown`, `keydown`, `wheel`, `touchstart` (đã điều tiết 1 lần mỗi 30 giây) và đồng bộ giữa các thẻ trình duyệt cùng phiên qua `BroadcastChannel('dh-session')`: thao tác ở thẻ nào cũng đặt lại bộ đếm ở mọi thẻ, và quyết định "Tiếp tục" hay "Đăng xuất" ở một thẻ đóng hộp thoại ở mọi thẻ. Thời điểm hết hạn tính theo đồng hồ tuyệt đối (`Date.now()` so với mốc lưu), không theo `setTimeout` cộng dồn, để đúng cả khi thẻ bị trình duyệt làm chậm ở nền. Khi còn 2 phút, hộp thoại mở; "Tiếp tục làm việc" gọi làm mới token với Keycloak và đặt lại bộ đếm; hết giờ thì giao diện xóa bộ nhớ đệm TanStack Query, gọi đăng xuất OIDC và chuyển tới trang đăng nhập với tham số quay về đúng trang (FR-00-001). Thời lượng không thao tác lấy từ cấu hình tenant, không mã hóa cứng, để kiểm thử với đồng hồ giả lập.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Modal` cỡ `sm`, `zIndex` = `z-session-dialog` (1200) để nằm trên mọi Modal, Drawer, Toast; `keyboard={false}` (Esc không được hiểu là "tiếp tục" ngầm); `mask={{ closable: false }}`. Đây là ngoại lệ duy nhất được hiển thị khi đang có Modal khác mở, vì là hộp thoại hệ thống; Modal phía dưới bị `inert` trong lúc này. |
| Giải phẫu | (1) Biểu tượng `Clock` trên khung; (2) tiêu đề; (3) trong giếng: đồng hồ đếm ngược `mm:ss` cỡ `font-title-1` chữ số đều độ rộng, thanh `CMP-ProgressBar` giảm dần, câu giải thích; (4) footer: "Đăng xuất" (phụ) và "Tiếp tục làm việc" (chính). |
| Vật liệu | Khung `glass-modal`, giếng đặc. |
| Biến thể | `warning` (còn 2 phút), `expired` (đã đăng xuất do hết giờ ở thẻ khác hoặc máy ngủ: thông báo và nút "Đăng nhập lại"). |
| Kích thước | `size-modal-sm`. |
| Trạng thái | Đếm ngược, đang làm mới phiên (nút chính loading), làm mới thất bại (Alert lỗi theo FR-00-080 và nút "Đăng nhập lại"), hết giờ. |
| Token | Như Modal, thêm `z-session-dialog`, `font-title-1`, `font-feature-tabular`, `color-warning-text`. |
| Bàn phím, ARIA | `role="alertdialog"`, focus ban đầu vào "Tiếp tục làm việc"; đồng hồ không đọc mỗi giây: vùng `aria-live="polite"` chỉ thông báo khi mở ("Phiên làm việc sẽ hết sau 2 phút"), khi còn 60 giây và 15 giây (đáp ứng WCAG 2.2.1 về điều chỉnh thời hạn: người dùng được cảnh báo và gia hạn bằng một thao tác đơn). |
| Nội dung | Tiêu đề "Phiên làm việc sắp hết"; mô tả "Bạn đã không thao tác trong 28 phút. Để bảo vệ dữ liệu, hệ thống sẽ tự đăng xuất sau 01:59. Các thay đổi chưa lưu sẽ bị mất." |
| Điều cấm | Không tự gia hạn khi chỉ có yêu cầu nền (thăm dò, SSE) mà người dùng không thao tác; không ẩn hộp thoại sau Modal khác; không dùng Toast cho cảnh báo này. |

: CMP-SessionTimeoutDialog

```ts
export interface DhSessionTimeoutConfig {
  idleMinutes: number;          // từ cấu hình tenant, 5–120
  warnBeforeSeconds?: number;   // mặc định 120
  onRefresh: () => Promise<void>;
  onLogout: (reason: 'idle' | 'user') => Promise<void>;
}
export function DhSessionTimeoutDialog(props: DhSessionTimeoutConfig): JSX.Element;
```

```tsx
<DhSessionTimeoutDialog idleMinutes={tenant.sessionIdleMinutes}
  onRefresh={() => auth.refreshToken()} onLogout={(r) => auth.logout({ reason: r, returnTo: location.href })} />
```

## 8. Bảng dữ liệu

### 8.1. CMP-DataTable

`CMP-DataTable` là thành phần quan trọng nhất của `dh-console`: mọi màn danh sách (PTN-01), bảng con trên trang chi tiết (PTN-02), cột phải của PTN-08 và hộp việc (PTN-10) đều dùng nó. Thành phần hiện thực một lần toàn bộ yêu cầu danh sách dùng chung: phân trang máy chủ (FR-00-021), sắp xếp và trạng thái trên URL (FR-00-022), lọc (FR-00-020, FR-00-023, phối hợp `CMP-FilterBar`), xuất (FR-00-030, FR-00-031, FR-00-034), hành động theo `allowedActions` (FR-00-053), cùng các quy tắc CRUD-TBL, CRUD-SEL, CRUD-PAG kế thừa từ docs/ui_ux_rule.md. Không dùng DataTable cho dữ liệu dạng cặp nhãn–giá trị (dùng `CMP-DescriptionList`), cho log thời gian thực (dùng `CMP-LogViewer`) hoặc cho bảng nhập liệu có sửa từng ô (SDD phân hệ đặc tả riêng dựa trên `EditableProTable`).

#### 8.1.1. Nền thư viện và thuộc tính cố định

DataTable dựa trên `ProTable` của `@ant-design/pro-components` (phiên bản tương thích antd 6, cố định trong `package.json` của `@datahub/ui`). Bảng dưới đây liệt kê thuộc tính cố định mà `DhDataTable` đặt sẵn; màn hình nghiệp vụ không được ghi đè các thuộc tính này.

| Thuộc tính ProTable | Giá trị cố định | Lý do |
|---|---|---|
| `search` | `false` | Dùng `CMP-FilterBar` để bố cục và đồng bộ URL thống nhất |
| `request` | Hàm bọc TanStack Query, đọc tham số từ URL, khóa truy vấn `['t', tenantId, resource, params]` | Phân trang, sắp xếp, lọc ở máy chủ (CRUD-TBL-02, CRUD-FLT-08) |
| `params` | Đối tượng tham số đã giải mã từ URL | Bảng tải lại khi URL đổi, kể cả khi người dùng bấm quay lại |
| `pagination` | `{ defaultPageSize: 20, pageSizeOptions: [10, 20, 50, 100], showSizeChanger: true, showQuickJumper: totalPages > 5, showTotal }`, `current` và `pageSize` lấy từ URL | FR-00-021, CRUD-PAG-01…07 |
| `sticky` | `{ offsetHeader: size-topbar }` | Tiêu đề dính dưới Topbar khi cuộn trang (CRUD-TBL-10) |
| `scroll` | `{ x: 'max-content' }` | Cuộn ngang khi hẹp, kết hợp cột thao tác cố định phải |
| `rowKey` | `'id'` | Khóa ổn định cho chọn nhiều qua trang |
| `options` | `{ density: true, setting: { draggable: true, checkable: true }, reload: true, fullScreen: false }` | Mật độ, cài đặt cột, tải lại |
| `columnsState` | `{ value, onChange }` nối với API tùy chọn người dùng (khóa `tableKey`), không dùng `localStorage` | Cài đặt cột lưu theo người dùng, theo dõi được trên mọi máy |
| `tableAlertRender`, `tableAlertOptionRender` | `false` | Thay bằng `CMP-BulkActionBar` |
| `rowSelection` | `{ preserveSelectedRowKeys: true, getCheckboxProps }` khi có hành động hàng loạt | CRUD-SEL-01, 02, 06, 07 |
| `columnEmptyText` | `'—'` | CRUD-R-05 |
| `dateFormatter` | Hàm định dạng theo `CMP-Timestamp` | DD/MM/YYYY HH:mm (CRUD-TBL-08) |
| `cardBordered` | `true` | Bảng là một thẻ đặc bo `radius-lg` |
| `locale.emptyText` | `CMP-EmptyState` theo nguyên nhân | CRUD-TBL-12 |
| `showSorterTooltip` | `{ target: 'sorter-icon' }` | Tooltip giải thích chiều sắp xếp (CRUD-TBL-04) |

: Nền thư viện và thuộc tính cố định

#### 8.1.2. Giải phẫu và vật liệu

Bảng dữ liệu là **nền đặc tuyệt đối**: không phần con nào của DataTable dùng glass, kể cả khi tiêu đề dính trượt dưới Topbar. Lý do là bảng chứa chữ cỡ nhỏ mật độ cao, cần tương phản tối đa và ổn định khi cuộn; glass ở đây chỉ làm giảm khả năng đọc và tăng chi phí kết xuất trên máy văn phòng.

| Phần con | Mô tả | Vật liệu, token |
|---|---|---|
| Khung thẻ | Bao FilterBar (nếu đi kèm), thanh công cụ, bảng, phân trang | `color-surface-solid`, `color-border-subtle`, `radius-lg`, `shadow-1` |
| Thanh công cụ | Trái: tiêu đề bảng con hoặc số bản ghi đã chọn; phải: nút "Xuất" (`CMP-DropdownMenu` biến thể `export`), "Tải lại", "Mật độ", "Cài đặt cột", nút chính bổ sung tùy chọn | Nền đặc; nút `CMP-IconButton` có Tooltip (CRUD-UI-06, 07) |
| Hàng tiêu đề | Tiêu đề cột `font-body-strong` `color-text-secondary`, biểu tượng sắp xếp, biểu tượng lọc cột (nếu có), Checkbox ba trạng thái | `color-surface-solid-2` (`Table.headerBg`), dính với `z-sticky` |
| Cột chọn | Checkbox căn giữa, rộng 48px, cố định trái | Vùng chạm ≥ 24×24 |
| Cột STT | Số thứ tự theo toàn tập, căn phải, `font-feature-tabular`, rộng 64px, cố định trái | Xem 8.1.4 |
| Cột dữ liệu | Theo `valueType` chuẩn (mục 8.1.3) | `font-body`, `color-text-primary` |
| Cột thao tác | Cố định phải (CRUD-TBL-11), căn giữa, tối đa hai `CMP-IconButton` hiện trực tiếp và menu "⋯" chứa phần còn lại | Nền đặc `color-surface-solid` có bóng tách nhẹ khi bảng cuộn ngang |
| Hàng | Cao `size-table-row` (48px chuẩn, 36px gọn) | Hover `Table.rowHoverBg` (`color-surface-solid-2`), chọn `color-fill-selected`, chọn + hover `color-fill-selected-hover` |
| Thanh tiến độ làm mới | Dải 2px ở mép trên thân bảng khi `isFetching` | `color-accent` |
| Phân trang | `CMP-Pagination` ở chân thẻ, căn phải; tổng số bản ghi bên trái | Nền đặc |
| `CMP-BulkActionBar` | Xuất hiện khi có bản ghi được chọn (mục 8.2) | Nền đặc |

: Giải phẫu và vật liệu

#### 8.1.3. Cột và kiểu giá trị

Mỗi cột khai báo `valueType` chuẩn của Datahub; DataTable tự chọn thành phần nguyên tử, căn chỉnh và độ rộng tối thiểu theo bảng dưới đây (kế thừa chuẩn căn chỉnh của docs/ui_ux_rule.md §2.3).

| `dhType` | Hiển thị | Căn chỉnh | Sắp xếp mặc định |
|---|---|---|---|
| `text` | Cắt một dòng bằng `…`, Tooltip đầy đủ khi bị cắt (CRUD-TBL-07); tối đa 2 dòng khi `wrap: 2` | Trái | Có nếu máy chủ hỗ trợ |
| `link` | Tên đối tượng là liên kết tới trang chi tiết (CRUD-R-02); Ctrl/⌘+bấm mở thẻ mới | Trái | Có |
| `code` | `CMP-Identifier` (mono, nút sao chép khi rê) | Trái | Có |
| `status` | `CMP-StatusTag` (màu kèm chữ, CRUD-TBL-09, FR-00-053) | Trái | Có |
| `datetime`, `date` | `CMP-Timestamp` DD/MM/YYYY HH:mm hoặc DD/MM/YYYY | Trái, chữ số đều độ rộng | Có; mặc định toàn bảng `createdAt,desc` (CRUD-TBL-03) |
| `number`, `percent` | `1.234.567`, `12,5%` | Phải | Có |
| `money` | `CMP-Money` "1.250.000 ₫" | Phải | Có |
| `masked` | `CMP-MaskedValue`; "Hiện" chỉ khi có quyền và qua `CMP-ReasonDialog` (FR-00-034) | Trái | Không |
| `user` | `CMP-Avatar` cỡ nhỏ và tên | Trái | Có |
| `tags` | Tối đa 2 `CMP-Tag`, "+3" có Tooltip | Trái | Không |
| `actions` | Theo `allowedActions` của dòng | Giữa | Không |

: Cột và kiểu giá trị

Quy tắc sắp xếp: chỉ cột khai báo `sortable` mới có biểu tượng; mỗi thời điểm một tiêu chí chính (CRUD-TBL-05), bấm lần lượt tăng → giảm → bỏ; trạng thái ghi vào tham số `sap-xep` trên URL. Khi người dùng bỏ sắp xếp, bảng trở về thứ tự mặc định do máy chủ quy định và hiển thị biểu tượng mặc định trên cột tương ứng.

#### 8.1.4. Cột STT theo toàn tập

Cột STT tính theo vị trí trong toàn bộ tập kết quả, không bắt đầu lại từ 1 ở mỗi trang (CRUD-TBL-06). Công thức là `(page − 1) × size + index + 1`. Không dùng `valueType: 'indexBorder'` của ProTable vì nó đánh số theo trang. Cột STT chỉ có nghĩa khi thứ tự ổn định, vì vậy máy chủ luôn thêm `id` làm tiêu chí sắp xếp phụ.

#### 8.1.5. Trạng thái trên URL và phối hợp với FilterBar

DataTable và FilterBar dùng chung hook `useDhListParams(screenKey)` đọc và ghi tham số theo bảng ở mục 3.4. Đổi trang hoặc số dòng ghi `trang`, `co`; đổi sắp xếp ghi `sap-xep` và giữ trang; đổi bộ lọc đưa `trang` về 1 và **xóa lựa chọn** (khuyến nghị mặc định của CRUD-SEL-06). Khi người dùng mở chi tiết rồi quay lại, URL còn nguyên nên danh sách hiện đúng trang, bộ lọc, sắp xếp (CRUD-FLT-07, CRUD-C-07). Sau khi xóa bản ghi cuối cùng của trang cuối, bảng tự lùi về trang trước (CRUD-D-08) và cập nhật URL bằng `replace`.

#### 8.1.6. Chọn nhiều và hành động hàng loạt

Checkbox tiêu đề chọn hoặc bỏ toàn bộ bản ghi **trên trang hiện tại**, có ba trạng thái chưa chọn, chọn một phần, chọn toàn bộ (CRUD-SEL-01, 02). Lựa chọn được giữ khi đổi trang (`preserveSelectedRowKeys`) và bị xóa khi đổi bộ lọc. Dòng không đủ điều kiện cho bất kỳ hành động hàng loạt nào có Checkbox vô hiệu kèm Tooltip lý do (CRUD-SEL-07). Khi có ít nhất một dòng được chọn, `CMP-BulkActionBar` xuất hiện (CRUD-SEL-03) với số bản ghi chính xác (CRUD-SEL-04); dòng được chọn có nền `color-fill-selected` (CRUD-SEL-05). Kết quả hành động hàng loạt luôn trả theo từng bản ghi (CRUD-SEL-08, CRUD-D-09).

#### 8.1.7. Hành động theo allowedActions

Mỗi dòng dữ liệu từ máy chủ có `allowedActions`. Màn hình khai báo danh mục hành động một lần (`actions` prop) với khóa trùng giá trị trong `allowedActions`; DataTable chỉ hiển thị hành động có trong mảng của dòng đó. Hai hành động có `inline: true` đầu tiên hiện thành `CMP-IconButton` có Tooltip; phần còn lại vào menu "⋯". Hành động phá hủy luôn nằm cuối menu và tự đi qua `CMP-ConfirmDialog` hoặc `CMP-ReasonDialog` theo `confirm` khai báo. Nếu một dòng không có hành động nào, ô thao tác hiển thị trống (không hiện "—" để tránh hiểu nhầm là thiếu dữ liệu) và cột vẫn giữ độ rộng.

#### 8.1.8. Xuất dữ liệu

Nút "Xuất" mở menu "Xuất Excel (.xlsx)" và "Xuất CSV (UTF-8)". Yêu cầu xuất gửi **toàn bộ tham số lọc và sắp xếp hiện tại trên URL** (không gửi `trang`, `co`) cùng danh sách cột đang hiển thị theo cài đặt cột, để tệp khớp đúng những gì người dùng thấy (FR-00-030). Hệ thống phân nhánh theo số dòng ước tính trả về từ API đếm:

1. Tối đa 10.000 dòng: xuất đồng bộ, nút "Xuất" ở trạng thái loading, tệp tải về ngay, Toast "Đã xuất 1.234 dòng".
2. Trên 10.000 dòng: tạo tác vụ nền (FR-00-031). DataTable hiện `CMP-JobProgress` dạng gọn ngay dưới thanh công cụ, người dùng được rời màn hình; khi xong, `CMP-Notification` và mục trong `CMP-NotificationCenter` chứa liên kết tải có hạn 24 giờ.
3. Bảng có cột `masked`: tệp mặc định che giá trị (FR-00-034); nếu người dùng có quyền xem đầy đủ, menu có thêm mục "Xuất kèm dữ liệu nhạy cảm…" mở `CMP-ReasonDialog` biến thể `sensitive-access`.

Mục xuất chỉ hiển thị khi màn hình có nghiệp vụ xuất và phản hồi danh sách có `listActions` chứa `EXPORT`. Mỗi lần xuất sinh bản ghi kiểm toán ở máy chủ (FR-00-040).

#### 8.1.9. Mật độ và cài đặt cột

Mật độ có hai giá trị "Chuẩn" (hàng 48px) và "Gọn" (hàng 36px), mặc định theo `data-density` toàn ứng dụng; nút "Mật độ" trên thanh công cụ cho ghi đè theo bảng và được lưu theo người dùng cùng cài đặt cột. Cài đặt cột cho phép ẩn hiện, sắp lại thứ tự (kéo thả, với phương án bàn phím là nút "Lên"/"Xuống" trên từng mục, đáp ứng WCAG 2.5.7), cố định trái hoặc phải và nút "Khôi phục mặc định". Cột STT, cột chọn, cột thao tác và cột tên đối tượng không ẩn được. Cài đặt lưu qua API tùy chọn người dùng với khóa `{tableKey}`, phạm vi theo tenant.

#### 8.1.10. Trạng thái

Bảng dưới đây liệt kê trạng thái hiển thị của DataTable và điều kiện chuyển; nó là danh sách kiểm thử bắt buộc cho mọi màn PTN-01 (docs/ui_ux_rule.md §5).

| Trạng thái | Điều kiện | Hiển thị |
|---|---|---|
| Đang tải lần đầu | Chưa có dữ liệu | Hàng tiêu đề thật và 5 hàng `CMP-Skeleton` theo độ rộng cột; phân trang ẩn |
| Đang làm mới | Đổi trang, sắp xếp, lọc, tải lại | Giữ dữ liệu cũ, dải tiến độ 2px, `aria-busy="true"`; không nhấp nháy về Skeleton |
| Rỗng | `total = 0` và không có `q`, tham số lọc | `CMP-EmptyState` `no-data`, nút tạo nếu có quyền |
| Không có kết quả | `total = 0` và có bộ lọc | `CMP-EmptyState` `no-result`, nút "Đặt lại bộ lọc" |
| Lỗi | Truy vấn lỗi | `CMP-Alert` `error` trong thân bảng với mã lỗi, mã truy vết, nút "Thử lại"; giữ FilterBar để người dùng sửa điều kiện |
| Mất kết nối | Lỗi mạng | Như lỗi, kèm `CMP-Banner` toàn ứng dụng |
| Không có quyền | 403 | `CMP-EmptyState` `no-permission`; ẩn thanh công cụ |
| Đang xử lý hàng loạt | Đã gửi hành động hàng loạt | BulkActionBar loading, các dòng được chọn khóa Checkbox |
| Bản ghi đã thay đổi | Hành động trên dòng trả 404 hoặc 412 | Toast cảnh báo "Bản ghi đã bị xóa hoặc thay đổi. Danh sách đã được tải lại." và tự làm mới |

: Trạng thái: Trạng thái, Điều kiện

| Khía cạnh | Đặc tả |
|---|---|
| Biến thể | `list` (PTN-01, kèm FilterBar), `embedded` (bảng con trong tab chi tiết, phân trang `simple` nếu ít dòng, không xuất), `selector` (trong Modal `select`, chọn một hoặc nhiều, không có cột thao tác). |
| Kích thước | Hàng `size-table-row`; đệm ô theo `Table.cellPaddingBlock`/`cellPaddingInline` (D03-05-02 §13.3); chiều rộng theo vùng nội dung, không giới hạn `size-page-max` với danh sách. |
| Token | `color-surface-solid`, `color-surface-solid-2`, `color-border-subtle`, `color-fill-selected`, `color-fill-selected-hover`, `color-text-primary`, `color-text-secondary`, `font-body`, `font-body-strong`, `font-feature-tabular`, `size-table-row`, `size-topbar` (độ lệch dính), `radius-lg`, `shadow-1`, `z-sticky`. |
| Bàn phím, ARIA | Bảng là `<table>` ngữ nghĩa có `<caption>` ẩn trực quan nêu tên danh sách và tổng số bản ghi; tiêu đề cột sắp xếp được là `<button>` trong `<th>` với `aria-sort`; Tab đi qua phần tử tương tác theo thứ tự hàng (liên kết tên, Checkbox, nút thao tác), không bẫy focus trong bảng; sau khi đổi trang, focus về `<caption>`/đầu bảng và vùng `aria-live="polite"` đọc "Trang 3 trên 12, hiển thị 41 đến 60 trong 234 bản ghi". Bấm vào dòng không mở chi tiết (tránh xung đột với Checkbox và nút, docs/ui_ux_rule.md §11 điểm 11); chỉ liên kết tên mở chi tiết. |
| Nội dung | Tiêu đề cột là thuật ngữ nghiệp vụ thống nhất (CRUD-TBL-01), danh từ ngắn, không viết tắt khó hiểu; tooltip biểu tượng: "Xuất dữ liệu", "Tải lại", "Mật độ hiển thị", "Cài đặt cột". |
| Điều cấm | Không phân trang hoặc lọc ở trình duyệt; không dùng glass cho bất kỳ phần nào; không tự suy luận hành động từ vai trò; không bắt đầu lại STT mỗi trang; không mở chi tiết khi bấm cả dòng; không lưu cài đặt cột chỉ ở `localStorage`. |

: Trạng thái: Khía cạnh, Đặc tả

```ts
export interface DhColumn<T> {
  key: keyof T & string; title: string; dhType: 'text' | 'link' | 'code' | 'status' | 'datetime' | 'date' | 'number' | 'percent' | 'money' | 'masked' | 'user' | 'tags';
  sortable?: boolean; width?: number; minWidth?: number; wrap?: 1 | 2;
  hideable?: boolean; defaultHidden?: boolean; fixed?: 'left' | 'right';
  href?: (row: T) => string; render?: (row: T) => React.ReactNode; // chỉ khi dhType không đủ
}
export interface DhRowAction<T> {
  key: string;                           // khớp giá trị trong row.allowedActions
  label: string; icon?: string; inline?: boolean; danger?: boolean;
  confirm?: Omit<DhConfirmOptions, 'onConfirm'> | ({ reason: true } & Omit<DhReasonOptions, 'onSubmit'>);
  run: (row: T, input?: { reason?: string }) => Promise<void>;
}
export interface DhBulkAction<T> {
  key: string; label: string; icon?: string; danger?: boolean;
  eligible: (row: T) => boolean;        // thường dựa trên row.allowedActions
  confirm?: DhRowAction<T>['confirm'];
  run: (ids: string[], input?: { reason?: string }) => Promise<DhBulkResult>;
}
export interface DhListResponse<T> { items: T[]; page: number; size: number; totalElements: number; totalPages: number; listActions?: string[] }
export interface DhDataTableProps<T extends { id: string; allowedActions?: string[] }> {
  tableKey: string;                      // khóa lưu cài đặt cột, ví dụ 'ph02.services'
  resource: string;                      // khóa truy vấn
  fetcher: (params: DhListParams) => Promise<DhListResponse<T>>;
  columns: DhColumn<T>[];
  showIndex?: boolean;                   // mặc định true với variant list
  actions?: DhRowAction<T>[];
  bulkActions?: DhBulkAction<T>[];
  export?: { formats: Array<'xlsx' | 'csv'>; fileBaseName: string; start: (params: DhListParams, fmt: 'xlsx' | 'csv', columns: string[]) => Promise<{ jobId?: string; fileUrl?: string }> };
  variant?: 'list' | 'embedded' | 'selector';
  emptyAction?: React.ReactNode;         // nút tạo trong trạng thái rỗng
  caption: string;                       // tên bảng cho trình đọc màn hình
}
```

```tsx
<DhFilterBar screenKey="ph02.services" searchPlaceholder="Tìm theo mã hoặc tên dịch vụ" filters={serviceFilters} />
<DhDataTable<ServiceRow> tableKey="ph02.services" resource="services" caption="Danh sách dịch vụ"
  fetcher={api.services.list}
  columns={[
    { key: 'name', title: 'Tên dịch vụ', dhType: 'link', sortable: true, hideable: false, href: (r) => `/services/${r.id}` },
    { key: 'code', title: 'Mã dịch vụ', dhType: 'code', sortable: true },
    { key: 'status', title: 'Trạng thái', dhType: 'status', sortable: true },
    { key: 'ownerName', title: 'Cơ quan chủ quản', dhType: 'text' },
    { key: 'callsMonth', title: 'Lượt gọi tháng', dhType: 'number', sortable: true },
    { key: 'createdAt', title: 'Ngày tạo', dhType: 'datetime', sortable: true },
  ]}
  actions={[
    { key: 'EDIT', label: 'Sửa', icon: 'Pencil', inline: true, run: (r) => navigate(`/services/${r.id}/edit`) },
    { key: 'SUSPEND', label: 'Tạm dừng…', icon: 'Pause', confirm: { reason: true, title: 'Tạm dừng dịch vụ', confirmText: 'Tạm dừng', consequence: 'HTTT đang gọi sẽ nhận lỗi 503.' }, run: (r, i) => api.services.suspend(r.id, i!.reason!) },
    { key: 'DELETE', label: 'Xóa…', icon: 'Trash2', danger: true, confirm: { severity: 'destructive', title: 'Xóa dịch vụ?', confirmText: 'Xóa dịch vụ', consequence: 'Quản trị tỉnh có thể khôi phục trong 30 ngày.' }, run: (r) => api.services.remove(r.id) },
  ]}
  bulkActions={[{ key: 'DELETE', label: 'Xóa', icon: 'Trash2', danger: true, eligible: (r) => !!r.allowedActions?.includes('DELETE'), run: api.services.bulkDelete }]}
  export={{ formats: ['xlsx', 'csv'], fileBaseName: 'danh-sach-dich-vu', start: api.services.export }}
  emptyAction={<DhButton type="primary" href="/services/new">Thêm dịch vụ</DhButton>} />
```

### 8.2. CMP-BulkActionBar

`CMP-BulkActionBar` là thanh thao tác hàng loạt hiện khi người dùng chọn ít nhất một dòng trong DataTable. Thanh thay thế vùng cảnh báo mặc định của ProTable để thống nhất hành vi và hiển thị kết quả từng bản ghi. Không dùng ngoài DataTable.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Thành phần tự viết bằng `Flex`, gắn vào DataTable qua ngữ cảnh lựa chọn. |
| Giải phẫu | (1) Số bản ghi đã chọn "Đã chọn 12 bản ghi" kèm ghi chú "(trên nhiều trang)" khi lựa chọn vượt trang hiện tại; (2) liên kết "Bỏ chọn"; (3) các hành động hàng loạt, mỗi nút ghi số bản ghi đủ điều kiện khi khác tổng ("Xóa (9)"); (4) Tooltip trên nút giải thích bản ghi không đủ điều kiện. |
| Vật liệu | Nền đặc `color-fill-selected` với chữ `color-accent-on-subtle` cho số đếm; dính ở đầu thân bảng (`position: sticky`, `z-sticky`) ngay dưới hàng tiêu đề, không glass. |
| Biến thể | `default`; `result` sau khi chạy: tóm tắt "Đã xóa 9 bản ghi. 3 bản ghi không xóa được." kèm nút "Xem chi tiết" mở bảng kết quả từng bản ghi (mã, tên, lý do) trong `CMP-Modal` `md`. | `floating` (từ bản 0.2): thanh nổi giữa đáy `CMP-FlowCanvas` khi chọn nhiều nút, vật liệu `glass-overlay`, cùng giải phẫu và hành vi (tên cũ trong D03-06-PH04 là `CMP-SelectionBar`).
| Kích thước | Cao `size-control-lg`; đệm ngang `space-4`. |
| Trạng thái | Ẩn (0 dòng, CRUD-SEL-03), hiện, đang chạy (nút loading, khóa lựa chọn), kết quả một phần, lỗi toàn bộ. |
| Token | `color-fill-selected`, `color-accent-on-subtle`, `font-body-strong`, `space-4`, `size-control-lg`, `z-sticky`, `motion-duration-base`. |
| Bàn phím, ARIA | `role="toolbar"` `aria-label="Thao tác hàng loạt"`; số đếm nằm trong vùng `aria-live="polite"`; khi thanh xuất hiện, focus không bị chuyển (người dùng vẫn ở Checkbox) nhưng phím tắt Alt+B đưa focus tới thanh. |
| Nội dung | Số đếm chính xác, định dạng Việt Nam (CRUD-SEL-04). |
| Điều cấm | Không hiện khi chưa chọn gì; không cho chạy hành động trên bản ghi không đủ quyền; không chỉ báo "Thành công" khi có bản ghi thất bại. |

: CMP-BulkActionBar

```ts
export interface DhBulkActionBarProps { selectedCount: number; acrossPages: boolean; actions: Array<{ key: string; label: string; eligibleCount: number; danger?: boolean; onRun: () => void }>; onClear: () => void; result?: DhBulkResult; running?: boolean }
```

```tsx
// Được DhDataTable dựng tự động từ bulkActions; dùng trực tiếp chỉ trong Storybook.
<DhBulkActionBar selectedCount={12} acrossPages actions={[{ key: 'DELETE', label: 'Xóa', eligibleCount: 9, danger: true, onRun }]} onClear={clear} />
```

## 9. Mã, log, so sánh

Nhóm này hiển thị nội dung kỹ thuật dày đặc nên luôn dùng nền đặc và font `font-family-mono`. Monaco được tải từ gói cục bộ qua `loader.config({ monaco })` của `@monaco-editor/react`, không tải từ CDN, vì `dh-console` chạy trong trung tâm dữ liệu tỉnh có thể không ra Internet. Theme Monaco `datahub-light`/`datahub-dark` được sinh từ token bằng `monaco.editor.defineTheme`.

### 9.1. CMP-CodeEditor

`CMP-CodeEditor` là trình soạn mã cho YAML Camel DSL (PH-04), JSON Schema và AsyncAPI (PH-10), biểu thức ánh xạ, chính sách OPA Rego (PH-12), mẫu thông báo. Không dùng cho xem mã chỉ đọc ngắn (dùng `CMP-CodeText` hoặc `CMP-JsonViewer`).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Editor` của `@monaco-editor/react`. Options cố định: `minimap: { enabled: false }` (bật khi trên 500 dòng), `fontFamily` = `font-family-mono`, `fontSize: 13`, `lineHeight: 20` (`font-mono`), `wordWrap: 'on'` với YAML/Markdown, `accessibilitySupport: 'auto'`, `renderLineHighlight: 'line'`, `scrollBeyondLastLine: false`, `tabSize: 2`, `automaticLayout: true`. Kiểm tra cú pháp bằng JSON Schema cấp từ máy chủ (`monaco-yaml`, chẩn đoán JSON tích hợp). |
| Giải phẫu | (1) Thanh công cụ: ngôn ngữ, "Định dạng", "Sao chép", "Toàn màn hình", gợi ý "Ctrl+M: chuyển chế độ Tab"; (2) vùng soạn có số dòng; (3) thanh trạng thái: vị trí con trỏ, số lỗi/cảnh báo bấm được để nhảy tới; (4) bảng lỗi thu gọn liệt kê chẩn đoán. |
| Vật liệu | Nền đặc `color-surface-solid`; thanh công cụ và thanh trạng thái `color-surface-solid-2`; viền `color-border-subtle`, bo `radius-lg`. |
| Biến thể | `edit`, `readonly` (`readOnly: true`, ẩn "Định dạng"), `inline` (một vùng nhỏ 3–10 dòng trong biểu mẫu, không thanh công cụ). |
| Kích thước | Cao mặc định 360px, kéo giãn theo chiều dọc; `inline` tự giãn theo nội dung tới 10 dòng. |
| Trạng thái | Đang tải trình soạn (Skeleton khối mã), sẵn sàng, có lỗi cú pháp (gạch dưới `color-error-text` và biểu tượng ở lề kèm thông điệp tiếng Việt), chỉ đọc, vô hiệu, bẩn. |
| Token | `font-mono`, `font-family-mono`, `color-surface-solid`, `color-surface-solid-2`, `color-border-subtle`, `color-error-text`, `color-warning-text`, `color-fill-selected` (dòng chọn), `radius-lg`. |
| Bàn phím, ARIA | Monaco giữ Tab để thụt lề, nên thành phần phải công bố cách thoát: Ctrl+M bật chế độ Tab di chuyển focus (WCAG 2.1.2, không bẫy bàn phím); thông báo này đặt ở thanh công cụ và trong `aria-describedby`. Có nhãn `aria-label` theo trường ("Nội dung YAML của luồng"). F8 nhảy tới lỗi kế tiếp. |
| Nội dung | Thông điệp chẩn đoán dịch sang tiếng Việt cho lỗi phổ biến; giữ thông điệp gốc trong Tooltip phụ. |
| Điều cấm | Không tải Monaco từ CDN; không hiển thị bí mật trong trình soạn (bí mật luôn là `T-SECRET-REF`); không dùng Monaco cho trường văn bản thường. |

: CMP-CodeEditor

```ts
export interface DhCodeEditorProps { language: 'yaml' | 'json' | 'xml' | 'sql' | 'rego' | 'markdown' | 'javascript'; value: string; onChange?: (v: string) => void; schemaUri?: string; variant?: 'edit' | 'readonly' | 'inline'; ariaLabel: string; height?: number; onValidate?: (markers: Array<{ line: number; message: string; severity: 'error' | 'warning' }>) => void }
```

```tsx
<DhCodeEditor language="yaml" ariaLabel="Nội dung YAML của luồng" schemaUri="/api/integration/v1/schemas/camel-yaml"
  value={flow.yaml} onChange={setYaml} onValidate={setMarkers} />
```

### 9.2. CMP-JsonViewer

`CMP-JsonViewer` hiển thị JSON chỉ đọc dạng cây thu gọn được: thân yêu cầu và phản hồi trong truy vết lượt gọi (PH-13), thông điệp DLQ (PH-18), giá trị trước/sau trong `CMP-AuditTrail`. Không dùng khi cần sửa (dùng CodeEditor) hoặc so sánh (dùng DiffViewer).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Thành phần tự viết dựng cây từ đối tượng JSON, ảo hóa bằng `@tanstack/react-virtual` khi trên 1.000 nút; chế độ "Văn bản thô" chuyển sang `CMP-CodeEditor` `readonly`. |
| Giải phẫu | (1) Thanh công cụ: "Mở tất cả", "Đóng tất cả", ô tìm khóa/giá trị, "Sao chép JSON", chuyển "Cây / Văn bản thô"; (2) dòng nút: nút mở, khóa, giá trị tô theo kiểu (chuỗi, số, logic, null) kèm nhãn kiểu khi rê; (3) số phần tử của mảng/đối tượng khi thu gọn; (4) giá trị đã che hiển thị "••••" với nhãn "Đã che". |
| Vật liệu | Nền đặc `color-surface-solid-2`, bo `radius-md`. |
| Biến thể | `tree`, `raw`, `compact` (không thanh công cụ, cho ô bảng và Popover). |
| Kích thước | Chữ `font-mono-sm`; thụt cấp 16px; cao tối đa 480px rồi cuộn. |
| Trạng thái | Sẵn sàng, rỗng ("Không có nội dung"), JSON không hợp lệ (hiển thị văn bản thô kèm Alert `warning` "Nội dung không phải JSON hợp lệ"), quá lớn trên 5 MB (chỉ hiển thị 1.000 dòng đầu và nút "Tải tệp"). |
| Token | `font-mono-sm`, `color-surface-solid-2`, `color-text-primary`, `color-text-secondary` (khóa), `color-success-text` (chuỗi), `color-info-text` (số), `color-warning-text` (logic, null), `radius-md`. |
| Bàn phím, ARIA | Cây theo mẫu ARIA Tree như `CMP-Tree`; màu kiểu luôn kèm cách viết phân biệt (chuỗi trong ngoặc kép, `null` viết chữ) nên không dựa vào màu. |
| Nội dung | Khóa giữ nguyên; không dịch. |
| Điều cấm | Không hiển thị giá trị trường mức Nhạy cảm chưa che (che từ máy chủ, NFR-00-029). |

: CMP-JsonViewer

```ts
export interface DhJsonViewerProps { value: unknown; variant?: 'tree' | 'raw' | 'compact'; defaultExpandDepth?: number; maskedPaths?: string[] }
```

```tsx
<DhJsonViewer value={trace.responseBody} defaultExpandDepth={2} />
```

### 9.3. CMP-LogViewer

`CMP-LogViewer` hiển thị log vận hành và log thực thi luồng theo thời gian thực hoặc theo truy vấn: log `dh-runtime` của một luồng (PH-04), log lượt gọi (PH-13), log tác vụ nền (PH-18). Đây là thành phần lõi của PTN-11. Không dùng cho nhật ký kiểm toán (dùng `CMP-AuditTrail`, vì kiểm toán có cấu trúc và có hiệu lực pháp lý).

#### 9.3.1. Hành vi

Log có thể lên tới hàng trăm nghìn dòng, vì vậy danh sách luôn **ảo hóa** bằng `@tanstack/react-virtual`: chỉ các dòng trong khung nhìn cộng vùng đệm được dựng DOM, chiều cao dòng cố định 18px (`font-mono-sm`) để tính vị trí chính xác, dòng xuống hàng được bật theo lựa chọn và khi đó đo chiều cao động. Bộ đệm phía giao diện giữ tối đa 50.000 dòng gần nhất; vượt quá thì bỏ dòng cũ và hiện chú thích "Đã ẩn 12.345 dòng cũ hơn. Dùng bộ lọc thời gian để xem lại." Ở chế độ trực tiếp, dữ liệu đến qua SSE; khi người dùng cuộn lên khỏi đáy, chế độ "Bám đuôi" tự tạm dừng và nút "Có 128 dòng mới, cuộn xuống" xuất hiện, để dòng mới không đẩy mất chỗ người dùng đang đọc. **Che dữ liệu cá nhân (PII)** được thực hiện ở máy chủ trước khi gửi (NFR-00-029); giao diện thêm một lớp bảo vệ thứ hai bằng bộ mẫu nhận diện (số CCCD 12 chữ số, số điện thoại, thư điện tử) và hiển thị giá trị khớp dưới dạng `CMP-MaskedValue` không có nút "Hiện".

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Thành phần tự viết; ảo hóa `@tanstack/react-virtual`; nguồn dữ liệu là `EventSource` (trực tiếp) hoặc truy vấn phân trang theo con trỏ (lịch sử). |
| Giải phẫu | (1) Thanh lọc: mức log (chọn nhiều), ô tìm (tô sáng kết quả, nút trước/sau), khoảng thời gian, lọc theo `trace_id`; (2) thanh điều khiển: "Bám đuôi" (Switch), "Tạm dừng luồng", "Xuống hàng", "Sao chép", "Tải tệp"; (3) danh sách dòng: thời điểm `HH:mm:ss.SSS`, nhãn mức, nguồn, thông điệp, `trace_id` bấm được để mở truy vết; (4) dòng mở rộng hiển thị trường có cấu trúc bằng `CMP-JsonViewer` `compact`; (5) chỉ báo kết nối trực tiếp. |
| Vật liệu | Nền đặc `color-surface-solid` (sáng) hoặc `color-surface-solid` tối theo chế độ; không glass, không nền đen cố định. |
| Biến thể | `live`, `history`, `embedded` (trong Drawer của một tác vụ, không thanh lọc). |
| Kích thước | Dòng 18px (`font-mono-sm`); cao mặc định chiếm phần còn lại của khung nhìn, tối thiểu 320px. |
| Trạng thái | Đang kết nối, đang nhận (chấm `CMP-StatusDot` xanh kèm chữ "Đang nhận"), tạm dừng, mất kết nối (chữ "Mất kết nối, đang thử lại sau 5 giây" và nút "Kết nối lại"), rỗng ("Chưa có dòng log nào khớp bộ lọc"), lỗi truy vấn (Alert). |
| Token | `font-mono-sm`, `font-family-mono`, `color-surface-solid`, `color-fill-hover` (dòng rê), `color-fill-selected` (dòng chọn, kết quả tìm), `color-error-on-bg` + `color-error-bg` (ERROR), `color-warning-on-bg` + `color-warning-bg` (WARN), `color-info-on-bg` + `color-info-bg` (INFO), `color-neutral-on-bg` + `color-neutral-bg` (DEBUG, TRACE), `color-text-tertiary` (thời điểm). |
| Bàn phím, ARIA | Danh sách `role="log"` với `aria-live="off"` khi bám đuôi (không đọc liên tục) và vùng tóm tắt riêng `aria-live="polite"` báo "Có 3 lỗi mới" tối đa mỗi 10 giây; mũi tên lên/xuống di chuyển dòng đang chọn, Enter mở rộng, Ctrl/⌘+F focus ô tìm của thành phần (không chặn tìm của trình duyệt khi focus ở ngoài), End bật lại bám đuôi. |
| Nội dung | Nhãn mức là chữ đầy đủ in hoa ngắn "ERROR", "WARN", "INFO", "DEBUG" đặt trong nhãn nền nhẹ, nên mức log được nhận ra bằng chữ chứ không chỉ bằng màu. |
| Điều cấm | Không dựng toàn bộ dòng vào DOM; không hiển thị PII chưa che; không tô màu cả dòng chỉ bằng màu chữ mà không có nhãn mức. |

: Hành vi

```ts
export interface DhLogLine { ts: string; level: 'ERROR' | 'WARN' | 'INFO' | 'DEBUG' | 'TRACE'; source?: string; message: string; traceId?: string; fields?: Record<string, unknown> }
export interface DhLogViewerProps { variant?: 'live' | 'history' | 'embedded'; streamUrl?: string; query?: (cursor?: string) => Promise<{ lines: DhLogLine[]; next?: string }>; maxBuffer?: number; onTraceClick?: (traceId: string) => void; ariaLabel: string }
```

```tsx
<DhLogViewer variant="live" ariaLabel="Log thực thi luồng Đồng bộ hộ tịch"
  streamUrl={`/api/integration/v1/flows/${flowId}/logs/stream`} onTraceClick={(id) => navigate(`/monitoring/traces/${id}`)} />
```

### 9.4. CMP-DiffViewer

`CMP-DiffViewer` so sánh hai phiên bản: phiên bản luồng trước khi phát hành (PH-04), phiên bản API và schema (PH-02, PH-10), giá trị trước/sau trong nhật ký kiểm toán, và đặc biệt là **giải quyết xung đột khi lưu** theo FR-00-052. Không dùng để hiển thị một phiên bản đơn.

#### 9.4.1. Chế độ xung đột ETag

Khi `CMP-Form` nhận 412 Precondition Failed (ETag không khớp `If-Match`), DiffViewer mở trong `CMP-Modal` cỡ `lg` ở chế độ `conflict`. Đầu giếng nội dung là `CMP-Alert` `warning`: "Dịch vụ này vừa được Nguyễn Văn A cập nhật lúc 14:05 ngày 22/11/2026, sau khi bạn mở biểu mẫu." Thân so sánh hai cột "Phiên bản hiện tại trên hệ thống" (trái) và "Thay đổi của bạn" (phải); với biểu mẫu có cấu trúc, so sánh theo trường (bảng ba cột Trường / Hiện tại / Của bạn, chỉ liệt kê trường khác nhau, đánh dấu trường cả hai cùng sửa là "Xung đột"); với nội dung văn bản (YAML, JSON) dùng `DiffEditor` của Monaco. Footer có ba nút: "Hủy" (quay lại biểu mẫu, giữ dữ liệu đang nhập), "Tải lại phiên bản mới" (bỏ thay đổi của mình, nạp bản hiện tại và ETag mới) và "Ghi đè" (gửi lại với ETag mới; nút kiểu phá hủy viền, mở `CMP-ConfirmDialog` `destructive` "Ghi đè thay đổi của Nguyễn Văn A?"). Mỗi lần ghi đè được ghi kiểm toán với ghi chú "ghi đè sau xung đột".

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `DiffEditor` của `@monaco-editor/react` cho văn bản (`renderSideBySide` khi rộng hơn `bp-lg`, gộp khi hẹp; `readOnly: true`; `originalEditable: false`); thành phần tự viết cho so sánh theo trường. |
| Giải phẫu | (1) Tiêu đề hai cột kèm phiên bản, người sửa, thời điểm; (2) thanh điều khiển: "Cạnh nhau / Gộp", "Chỉ hiện khác biệt", nút khác biệt trước/sau, số khác biệt; (3) vùng so sánh; (4) chú giải ký hiệu: dòng thêm có dấu "+", dòng xóa có dấu "−". |
| Vật liệu | Nền đặc; dòng thêm `color-success-bg`, dòng xóa `color-error-bg`, phần chữ thay đổi đậm hơn bằng gạch chân; khi nằm trong Modal thì nằm trong giếng đặc. |
| Biến thể | `text`, `fields`, `conflict` (kèm ba hành động ở trên). |
| Kích thước | Cao mặc định 480px; trong Modal `lg` chiếm phần giếng còn lại. |
| Trạng thái | Đang tải hai phiên bản, sẵn sàng, không có khác biệt ("Hai phiên bản giống nhau"), lỗi tải, đang ghi đè/tải lại. |
| Token | `color-success-bg`, `color-success-on-bg`, `color-error-bg`, `color-error-on-bg`, `color-warning-bg` (trường xung đột), `font-mono`, `color-surface-solid`, `radius-lg`. |
| Bàn phím, ARIA | F7 / Shift+F7 tới khác biệt kế tiếp/trước (theo Monaco) và nút tương đương trên thanh điều khiển; mỗi khác biệt được đọc dạng "Dòng 12, đã thêm: …"; bảng so sánh theo trường là `<table>` có tiêu đề cột. Thêm/xóa luôn có ký hiệu "+"/"−" nên không dựa vào màu. |
| Nội dung | Nhãn cột dùng ngôn ngữ người dùng, không dùng "original/modified". |
| Điều cấm | Không tự hợp nhất thay đổi ngầm; không bỏ dữ liệu người dùng đang nhập khi họ bấm "Hủy". |

: Chế độ xung đột ETag

```ts
export interface DhDiffViewerProps {
  variant: 'text' | 'fields' | 'conflict';
  language?: string;
  left: { label: string; author?: string; at?: string; value: string | Record<string, unknown> };
  right: { label: string; author?: string; at?: string; value: string | Record<string, unknown> };
  fieldLabels?: Record<string, string>;
  onOverwrite?: () => Promise<void>; onReload?: () => void; onCancel?: () => void;
}
```

```tsx
<DhDiffViewer variant="conflict" fieldLabels={serviceFieldLabels}
  left={{ label: 'Phiên bản hiện tại trên hệ thống', author: latest.updatedByName, at: latest.updatedAt, value: latest }}
  right={{ label: 'Thay đổi của bạn', value: draft }}
  onOverwrite={() => save(draft, latestEtag)} onReload={() => form.reset(latest)} onCancel={closeConflict} />
```

## 10. Quy trình

### 10.1. CMP-Steps

`CMP-Steps` hiển thị tiến trình của quy trình nhiều bước: wizard tạo đối tượng (PTN-05, ví dụ khởi tạo tenant, đăng ký HTTT), vòng đời của yêu cầu (Nháp → Chờ duyệt → Đã duyệt → Đã công bố). Không dùng Steps cho các phần ngang hàng (dùng Tabs) hoặc cho lịch sử sự kiện (dùng Timeline).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Steps` của antd v6 với `items` gồm `title`, `content` (thuộc tính `description` đã lỗi thời), `status`; `orientation="horizontal"` (dọc khi hẹp hơn `bp-md` hoặc trên 5 bước); `size="small"` ở chế độ gọn. |
| Giải phẫu | (1) Chỉ báo bước: số thứ tự, dấu tích khi xong, biểu tượng lỗi khi lỗi; (2) tiêu đề bước; (3) mô tả ngắn hoặc người/thời điểm hoàn tất; (4) đường nối. |
| Vật liệu | Không nền riêng; đặt trên nền đặc của thẻ wizard hoặc trên canvas. |
| Biến thể | `wizard` (bước đã xong bấm được để quay lại sửa), `status` (chỉ đọc, thể hiện vòng đời). |
| Kích thước | Chỉ báo 24px (gọn 20px); tiêu đề `font-body-strong`; mô tả `font-footnote`. |
| Trạng thái từng bước | Chờ (`wait`), đang làm (`process`), xong (`finish`), lỗi (`error`, kèm chữ "Có lỗi" và số lỗi), vô hiệu. |
| Token | `color-accent` (bước đang làm), `color-success-text` (xong), `color-error-text` (lỗi), `color-text-tertiary` (chờ), `color-border-subtle` (đường nối). |
| Bàn phím, ARIA | Danh sách có thứ tự `<ol>` với `aria-label="Các bước"`; bước hiện tại `aria-current="step"`; bước bấm được là nút. Wizard đặt focus vào tiêu đề nội dung bước mới khi chuyển bước. |
| Nội dung | Tiêu đề bước là danh từ ("Thông tin chung", "Kết nối", "Xác nhận"); nút chuyển "Tiếp tục", "Quay lại", nút cuối nêu hành động ("Tạo tenant"). |
| Điều cấm | Không quá 7 bước; không cho nhảy tới bước chưa đủ điều kiện; không chỉ dùng màu để báo trạng thái bước. |

: CMP-Steps

```ts
export interface DhStepsProps { variant?: 'wizard' | 'status'; current: number; items: Array<{ key: string; title: string; content?: string; status?: 'wait' | 'process' | 'finish' | 'error'; errorCount?: number }>; onStepClick?: (index: number) => void }
```

```tsx
<DhSteps variant="wizard" current={step} onStepClick={goTo} items={[
  { key: 'info', title: 'Thông tin chung' }, { key: 'conn', title: 'Kết nối' }, { key: 'review', title: 'Xác nhận' },
]} />
```

### 10.2. CMP-ApprovalPanel

`CMP-ApprovalPanel` là khối duyệt dùng chung cho mọi yêu cầu cần phê duyệt từ mọi phân hệ (kết nạp HTTT, công bố dịch vụ, đăng ký sử dụng, khai thác dữ liệu, phát hành luồng, hoàn tiền), hiển thị trong trang chi tiết yêu cầu và trong hộp "Việc của tôi" (PTN-10, FR-00-070). Thành phần hiện thực nguyên tắc bốn mắt (FR-00-071) và yêu cầu ý kiến khi duyệt, lý do bắt buộc khi từ chối (FR-00-072).

Hành vi bốn mắt được bảo đảm ở hai lớp. Máy chủ là lớp quyết định: phản hồi yêu cầu có `allowedActions` không chứa `APPROVE`, `REJECT` khi người xem là người tạo yêu cầu với loại duyệt được đánh dấu, và từ chối mọi lệnh duyệt như vậy. Giao diện là lớp giải thích: khi người xem là người tạo, panel không hiện nút duyệt mà hiện `CMP-Alert` `info` "Bạn là người tạo yêu cầu này nên không thể tự duyệt. Yêu cầu đang chờ một cán bộ khác có quyền duyệt." Ý kiến khi duyệt là trường bắt buộc tối thiểu 1 ký tự có giá trị gợi ý sẵn có thể sửa ("Đồng ý"); lý do khi từ chối đi qua `CMP-ReasonDialog` biến thể `reject` với tối thiểu 10 ký tự. Duyệt nhiều cấp hiển thị cấp hiện tại và các cấp còn lại.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Thành phần tự viết trong `CMP-Card`; danh sách cấp duyệt dùng `CMP-Steps` `status` dọc; lịch sử ý kiến dùng `CMP-Timeline`. |
| Giải phẫu | (1) Tiêu đề "Phê duyệt" và `CMP-StatusTag` trạng thái yêu cầu; (2) tóm tắt yêu cầu: người gửi, thời điểm gửi, hạn xử lý (đếm ngược, chữ `color-warning-text` khi còn dưới 24 giờ, `color-error-text` khi quá hạn kèm chữ "Quá hạn"); (3) các cấp duyệt và người duyệt; (4) ô "Ý kiến" (`CMP-TextArea`); (5) nút "Duyệt" (chính), "Từ chối" (phá hủy viền), "Yêu cầu bổ sung" (phụ, nếu quy trình hỗ trợ); (6) lịch sử ý kiến các lần trước. |
| Vật liệu | Nền đặc `color-surface-solid`; khi đặt trong Drawer xem nhanh của PTN-10 thì nằm trong giếng đặc. |
| Biến thể | `full` (trang chi tiết), `compact` (cột phải của PTN-10, ẩn lịch sử), `readonly` (yêu cầu đã kết thúc: hiện kết quả và ý kiến cuối). |
| Kích thước | Rộng 360–420px khi là cột phải; toàn chiều rộng khi ở dưới nội dung trên màn hẹp. |
| Trạng thái | Đang tải, chờ bạn duyệt, bạn là người tạo (không được tự duyệt), chờ người khác, đang gửi quyết định, đã duyệt, đã từ chối, đã bị thu hồi bởi người gửi, quá hạn, xung đột (người khác vừa quyết định trước: Alert "Yêu cầu đã được Trần Thị B duyệt lúc 09:12. Trang đã được tải lại." và tự làm mới). |
| Token | `color-surface-solid`, `color-warning-text`, `color-error-text`, `color-success-text`, `font-title-3`, `space-4`, `radius-lg`. |
| Bàn phím, ARIA | `<section aria-labelledby>`; sau khi quyết định thành công, focus chuyển tới thông báo kết quả `role="status"`; trong PTN-10, phím J/K chuyển yêu cầu kế tiếp/trước chỉ khi người dùng bật phím tắt ký tự trong cài đặt (WCAG 2.1.4). |
| Nội dung | Nút "Duyệt", "Từ chối…", "Yêu cầu bổ sung…"; Toast "Đã duyệt yêu cầu đăng ký sử dụng của Sở Tư pháp". |
| Điều cấm | Không cho từ chối không có lý do; không hiện nút duyệt cho người tạo khi loại duyệt yêu cầu bốn mắt; không cho duyệt hàng loạt các loại duyệt được đánh dấu bốn mắt mà không có ý kiến chung. |

: CMP-ApprovalPanel

```ts
export interface DhApprovalPanelProps {
  request: { id: string; type: string; status: string; submittedBy: { id: string; name: string }; submittedAt: string; dueAt?: string; allowedActions: string[]; levels: Array<{ name: string; approver?: string; decidedAt?: string; decision?: 'APPROVED' | 'REJECTED' }>; history: Array<{ at: string; actor: string; decision: string; comment: string }>; fourEyes: boolean };
  currentUserId: string; variant?: 'full' | 'compact' | 'readonly';
  onApprove: (comment: string) => Promise<void>;
  onReject: (reason: string, code?: string) => Promise<void>;
  onRequestChanges?: (comment: string) => Promise<void>;
}
```

```tsx
<DhApprovalPanel request={req} currentUserId={me.id} variant="compact"
  onApprove={(comment) => decide.mutateAsync({ id: req.id, decision: 'APPROVE', comment })}
  onReject={(reason) => decide.mutateAsync({ id: req.id, decision: 'REJECT', comment: reason })} />
```

### 10.3. CMP-JobProgress

`CMP-JobProgress` hiển thị tiến độ của tác vụ chạy lâu chạy nền theo FR-00-054: xuất dữ liệu lớn (FR-00-031), nhập danh mục (FR-00-032, NFR-00-008), xử lý lại DLQ, di trú, đồng bộ danh mục quốc gia. Người dùng được rời màn hình; tác vụ tiếp tục và kết quả đến qua `CMP-Notification`. Không dùng cho thao tác dưới 3 giây (dùng trạng thái loading của nút).

Tiến độ được lấy bằng SSE từ API tác vụ (`/api/platform/v1/jobs/{id}/events`), dự phòng thăm dò mỗi 3 giây khi SSE không khả dụng. Danh sách tác vụ của người dùng được giữ ở `CMP-NotificationCenter` (nhóm "Tác vụ nền"), nên khi quay lại màn hình hoặc mở thẻ mới, JobProgress khôi phục đúng trạng thái theo `jobId`.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Progress` của antd (`type="line"`) bọc trong thành phần tự viết; dạng không xác định khi chưa biết tổng. |
| Giải phẫu | (1) Tên tác vụ; (2) thanh tiến độ và phần trăm; (3) số đã xử lý / tổng ("4.500 / 12.345 dòng"); (4) thời gian còn lại ước tính; (5) số lỗi (bấm để xem); (6) hành động: "Hủy tác vụ" (khi `allowedActions` có `CANCEL`, đi qua ConfirmDialog), "Chạy nền và tiếp tục làm việc", khi xong "Tải tệp" (kèm hạn "Tải được đến 14:30 ngày 23/11/2026") hoặc "Xem báo cáo lỗi". |
| Vật liệu | Nền đặc; dạng `inline` dùng `color-surface-solid-2` trong thẻ; dạng trong NotificationCenter kế thừa `glass-overlay` (thanh tiến độ có nền đặc riêng). |
| Biến thể | `inline` (dưới thanh công cụ DataTable), `card` (trang kết quả nhập, PTN-09), `list-item` (trong NotificationCenter). |
| Kích thước | Thanh cao 6px (`inline`), 8px (`card`); bo `radius-xs`. |
| Trạng thái | Đang xếp hàng, đang chạy, đang hủy, hoàn tất, hoàn tất có lỗi (một phần), thất bại (Alert theo FR-00-080 và "Thử lại"), đã hủy, đã hết hạn tải (nút "Tải tệp" ẩn, ghi "Tệp đã hết hạn tải"). |
| Token | `color-accent` (đang chạy), `color-success-text` (xong), `color-warning-text` (có lỗi), `color-error-text` (thất bại), `color-fill-control` (rãnh), `radius-xs`, `font-feature-tabular`. |
| Bàn phím, ARIA | Thanh `role="progressbar"` với `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, `aria-valuetext="4.500 trên 12.345 dòng"`; vùng `aria-live="polite"` chỉ đọc mốc 25/50/75/100% và trạng thái kết thúc. |
| Nội dung | Tên tác vụ gồm động từ và đối tượng ("Xuất danh sách dịch vụ"); thời gian còn lại dạng "khoảng 2 phút". |
| Điều cấm | Không chặn màn hình trong khi chạy; không hiện phần trăm giả khi chưa biết tổng. |

: CMP-JobProgress

```ts
export interface DhJobProgressProps { jobId: string; variant?: 'inline' | 'card' | 'list-item'; title?: string; onDone?: (job: { status: 'SUCCEEDED' | 'PARTIAL' | 'FAILED' | 'CANCELLED'; fileUrl?: string; expiresAt?: string }) => void }
```

```tsx
{exportJobId && <DhJobProgress jobId={exportJobId} variant="inline" title="Xuất danh sách dịch vụ" />}
```

### 10.4. CMP-AuditTrail

`CMP-AuditTrail` là nội dung của tab "Lịch sử" bắt buộc trên mọi màn chi tiết đối tượng (FR-00-043), hiển thị nhật ký kiểm toán của đối tượng đó. Dữ liệu là bản ghi kiểm toán theo FR-00-041 (thời điểm, chủ thể, địa chỉ nguồn, hành động, giá trị trước và sau đã che, kết quả, lý do, `trace_id`) và là chỉ đọc tuyệt đối (FR-00-042): thành phần không có bất kỳ thao tác sửa hay xóa nào. Màn tra cứu kiểm toán toàn hệ thống của PH-13 dùng `CMP-DataTable` với cùng kiểu dữ liệu; AuditTrail là dạng xem theo một đối tượng.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Timeline` cho dòng thời gian và `CMP-DiffViewer` biến thể `fields` cho chi tiết thay đổi; phân trang theo con trỏ với nút "Tải thêm" (không phân trang số vì dữ liệu chỉ thêm). |
| Giải phẫu | (1) Thanh lọc: loại hành động (chọn nhiều), người thực hiện, khoảng thời gian; (2) mỗi mục: thời điểm, `CMP-Avatar` và tên chủ thể (hoặc nhãn "Hệ thống" / tên ứng dụng khi là máy), động từ hành động ("đã cập nhật", "đã tạm dừng"), `CMP-StatusTag` kết quả nếu thất bại, lý do (khi có); (3) phần mở rộng: bảng các trường thay đổi Trước / Sau (đã che), địa chỉ nguồn, `trace_id` với `CMP-CopyButton` và liên kết mở truy vết; (4) chỉ báo toàn vẹn chuỗi băm "Nhật ký toàn vẹn" (biểu tượng `ShieldCheck` kèm chữ) khi máy chủ xác nhận. |
| Vật liệu | Nền đặc của nội dung tab. |
| Biến thể | `object` (theo đối tượng), `compact` (5 mục gần nhất trong Drawer xem nhanh, liên kết "Xem toàn bộ lịch sử"). |
| Kích thước | Mục thu gọn cao tối thiểu 48px; chữ `font-body`, thời điểm `font-footnote`. |
| Trạng thái | Đang tải, rỗng ("Chưa có hoạt động nào được ghi nhận"), đang tải thêm, lỗi, không có quyền xem kiểm toán (EmptyState `no-permission`), cảnh báo toàn vẹn (Alert `error` "Phát hiện bất thường trong chuỗi nhật ký. Đã thông báo cho quản trị." khi máy chủ báo chuỗi băm không khớp). |
| Token | `font-body`, `font-footnote`, `color-text-secondary`, `color-border-subtle`, `color-success-text`, `color-error-text`, `font-mono-sm` (`trace_id`). |
| Bàn phím, ARIA | Danh sách `<ol>` theo thứ tự thời gian giảm dần, mỗi mục có nút mở rộng `aria-expanded`; "Tải thêm" giữ focus ở vị trí mục mới đầu tiên. |
| Nội dung | Câu dạng "Nguyễn Văn A đã tạm dừng dịch vụ. Lý do: Bảo trì máy chủ nguồn." Giá trị trước/sau dùng nhãn trường như biểu mẫu. |
| Điều cấm | Không có hành động sửa, xóa, ẩn mục; không hiển thị giá trị nhạy cảm chưa che; không sắp xếp tăng dần mặc định. |

: CMP-AuditTrail

```ts
export interface DhAuditTrailProps { objectType: string; objectId: string; variant?: 'object' | 'compact'; fullHistoryHref?: string }
```

```tsx
<DhAuditTrail objectType="SERVICE" objectId={service.id} />
```

### 10.5. CMP-Timeline

`CMP-Timeline` hiển thị chuỗi sự kiện theo thời gian: lịch sử ý kiến duyệt, các mốc của một giao dịch thanh toán (PH-19), các bước thực thi của một lượt gọi. Là nền của `CMP-AuditTrail` và lịch sử trong `CMP-ApprovalPanel`. Không dùng cho tiến trình có bước dự kiến (dùng Steps).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Timeline` của antd v6 với `items` gồm `title` (thời điểm), `content` (nội dung), `icon` (thuộc tính `label`, `children`, `dot` đã lỗi thời); `mode="start"`. |
| Giải phẫu | (1) Chấm hoặc biểu tượng sự kiện; (2) đường nối; (3) thời điểm; (4) nội dung; (5) nhóm theo ngày ("Hôm nay", "Hôm qua", "20/11/2026"). |
| Vật liệu | Không nền riêng; kế thừa nền đặc. |
| Biến thể | `default`, `compact` (một dòng mỗi sự kiện), `status` (biểu tượng theo kết quả: thành công, lỗi, cảnh báo, kèm chữ). |
| Kích thước | Chấm 10px; khoảng giữa mục `space-4` (gọn `space-3`). |
| Trạng thái | Đang tải, rỗng, mục đang diễn ra (`loading` trên mục cuối). |
| Token | `color-border-subtle`, `color-icon-secondary`, `color-success-text`, `color-error-text`, `color-warning-text`, `font-footnote`, `space-3`, `space-4`. |
| Bàn phím, ARIA | `<ol>`; mỗi mục có thời điểm trong `<time datetime>`; biểu tượng kết quả có chữ thay thế. |
| Nội dung | Thời điểm qua `CMP-Timestamp`; trong ngày hiện tại hiển thị "14:05", ngày khác "20/11/2026 14:05". |
| Điều cấm | Không chỉ dùng màu chấm để phân biệt kết quả. |

: CMP-Timeline

```ts
export interface DhTimelineProps { variant?: 'default' | 'compact' | 'status'; groupByDay?: boolean; items: Array<{ key: string; at: string; content: React.ReactNode; result?: 'success' | 'error' | 'warning' | 'info'; icon?: string; pending?: boolean }> }
```

```tsx
<DhTimeline variant="status" groupByDay items={payment.events.map((e) => ({ key: e.id, at: e.at, result: e.result, content: e.description }))} />
```

## 11. Canvas thiết kế

Nhóm này là bộ khung của mẫu PTN-07 (D03-06-00 §4.10) và được dùng ở ba nơi: trình thiết kế luồng tích hợp PH-04 (UI-04-04, nặng nhất), sơ đồ kết nối topic PH-10 (chế độ xem) và trình soạn mô hình quy trình PH-11. Thành phần ở đây là **khung trung lập về nghiệp vụ**: chúng biết vẽ nút, nhóm, cạnh, cổng, lớp phủ và xử lý chọn, kéo thả, hoàn tác, bàn phím; còn loại chặng, tham số, quy tắc hợp lệ là của phân hệ, truyền vào qua "bộ mô tả loại nút" (node type descriptor). Chi tiết riêng của Camel (chín chặng chuẩn, YAML, catalog) nằm ở D03-06-PH04 §10 và không lặp lại ở đây.

### 11.0. Quy tắc chung của canvas

**Thư viện.** Canvas dùng `@xyflow/react` (XYFlow, React Flow 12) vì repo đã dùng ở `apps/console` và có giấy phép MIT. Bố cục tự động dùng `dagre` chạy trong Web Worker để không chặn luồng giao diện với sơ đồ trên 200 nút. Không dùng thư viện vẽ sơ đồ thứ hai ở bất kỳ phân hệ nào.

**Vật liệu.** Bề mặt canvas, nút, nhóm, bảng thành phần, Inspector, thanh công cụ trình thiết kế và bảng dưới là **nền đặc**, vì đây là nội dung dày cần tương phản ổn định và là vùng có nhiều thao tác kéo (một lớp `backdrop-filter` dưới nút đang kéo làm tụt khung hình dưới 30 khung/giây ở máy văn phòng). Chỉ các điều khiển **nổi trên** canvas (thu phóng, minimap, thanh chọn nhiều, dải kết quả chạy thử, ô tìm nổi, bảng chọn nhanh) dùng `glass-overlay`. Như vậy một màn trình thiết kế có tối đa hai phần tử kính lớn (sidebar, thanh trên của khung khi không ở chế độ toàn màn hình) cộng hai lớp nổi nhỏ, nằm trong giới hạn bốn lớp `backdrop-filter` của D03-05-01 §3.2.

**Hai lớp dữ liệu.** Mọi canvas tách *cấu trúc* (đem triển khai hoặc thực thi, ví dụ YAML Camel, BPMN XML) khỏi *bố cục* (tọa độ, ghim, thu gọn, ghi chú dán). Canvas chỉ sửa bố cục trực tiếp; mọi thay đổi cấu trúc đi qua hàm `onStructureChange` của phân hệ, phân hệ trả cấu trúc mới, canvas vẽ lại. Cạnh luôn được suy ra từ cấu trúc, nên không bao giờ vẽ được một sơ đồ mà máy thực thi không chạy được.

**Hoàn tác.** Ngăn hoàn tác chung cho cấu trúc và bố cục, tối thiểu 100 bước mỗi phiên soạn, mỗi bước có nhãn tiếng Việt ("Xóa chặng Ghi nhật ký") để tooltip nút hoàn tác đọc được. Thao tác kéo liên tục gộp thành một bước.

**Truy cập không dùng chuột (WCAG 2.1.1, 2.5.7).** Mọi thao tác kéo có phương án không kéo: chọn mục trong bảng thành phần rồi `Enter` để chèn sau nút đang chọn; `Alt+↑`/`Alt+↓` di chuyển nút trong chuỗi; menu ngữ cảnh mở bằng `Shift+F10` có đủ lệnh. Canvas có **chế độ danh sách** thay thế (`CMP-TreeGrid` biến thể `structure`, mục 13.5) với đủ thao tác của canvas; đây là đường chính cho người dùng trình đọc màn hình.

**Hiệu năng.** Mục tiêu 60 khung/giây khi kéo và thu phóng với 300 nút trên máy chuẩn 4 nhân, 8 GB (NFR-00-005). Dưới 50% thu phóng, nút chuyển sang hiển thị tối giản (dải màu, biểu tượng, huy hiệu lỗi) và không vẽ chữ phụ. Chỉ vẽ nút trong khung nhìn (`onlyRenderVisibleElements`).

### 11.1. CMP-FlowCanvas

`CMP-FlowCanvas` là bề mặt vẽ sơ đồ: nút, nhóm, cạnh, cổng, lưới, lớp phủ, chọn, kéo thả, thu phóng, menu ngữ cảnh. Không dùng cho sơ đồ chỉ để minh họa trong tài liệu hay trang chi tiết (dùng `CMP-DependencyGraph` ở mục 13.8, nhẹ hơn và chỉ đọc).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `ReactFlow` của `@xyflow/react` với `nodeTypes` đăng ký `CMP-FlowNode`, `CMP-GroupNode`, `CMP-StickyNote`; `proOptions={{ hideAttribution: true }}` chỉ khi đã có giấy phép phù hợp, nếu không giữ ghi công; `deleteKeyCode={null}` (xóa đi qua lệnh có hoàn tác, không để thư viện tự xóa). |
| Giải phẫu | (1) Bề mặt có lưới chấm; (2) nút và nhóm; (3) cạnh có mũi tên và nhãn; (4) nút ⊕ trên cạnh và cuối nhánh; (5) lớp phủ (kết quả chạy thử, số liệu chạy thật, khác biệt, tìm kiếm); (6) điều khiển nổi `CMP-CanvasControls`, `CMP-Minimap`, `CMP-BulkActionBar` biến thể `floating`; (7) vùng thông báo `aria-live`. |
| Vật liệu | Nền đặc `color-surface-solid-2`, lưới chấm 1px `color-border-subtle` cách 16px (ẩn dưới 40% thu phóng). Cạnh 1,5px `color-border-control`. |
| Biến thể | `edit` (mặc định), `readonly` (xem phiên bản đã phát hành, sơ đồ PH-10: không kéo, không chèn, vẫn chọn, tìm, thu phóng), `diff` (so sánh hai phiên bản, tô trạng thái khác biệt), `run-overlay` (phủ kết quả một lần chạy). |
| Hướng | Trái sang phải (mặc định) hoặc trên xuống dưới; người dùng đổi ở menu Xem, lưu theo người dùng. |
| Thu phóng | 10–400%; bước theo nút: 25, 50, 75, 100, 150, 200, 400%; con lăn chuột kèm `Ctrl` thu phóng, không kèm thì cuộn khung nhìn. |
| Trạng thái | Đang tải (khung xương ba nút nối nhau), rỗng (chỉ có điểm vào và lời mời "Kéo thành phần từ bảng bên trái hoặc nhấn ⊕ để thêm chặng"), lỗi tải (`CMP-Alert` giữa canvas có nút "Thử lại"), sơ đồ quá lớn (trên 500 nút: tự gợi ý chế độ danh sách), có lớp phủ cũ (lớp phủ mờ đi kèm dải "Cũ: nội dung đã đổi sau lần chạy này"). |
| Token | `color-surface-solid-2`, `color-border-subtle`, `color-border-control`, `color-accent`, `color-focus-ring`, `color-success-text`, `color-error-text`, `motion-duration-base`. |
| Bàn phím, ARIA | Canvas là `role="application"` có `aria-roledescription="sơ đồ"` và `aria-label` ("Sơ đồ route nhan-khai-sinh, 12 chặng"); `Tab` vào canvas focus nút đang chọn hoặc nút đầu; mũi tên di chuyển focus giữa các nút theo thứ tự cấu trúc (không theo tọa độ); `Enter` mở Inspector; `Delete` xóa có hoàn tác; `Ctrl+A` chọn tất cả; `Esc` bỏ chọn; `Shift+F10` mở menu ngữ cảnh; `+`/`−`/`0` thu phóng. Mỗi thay đổi cấu trúc đọc một câu qua `aria-live="polite"` ("Đã chèn chặng Ánh xạ dữ liệu sau Kiểm lược đồ"). |
| Nội dung | Lời mời ở trạng thái rỗng nêu cả cách kéo và cách không kéo. |
| Điều cấm | Không vẽ cạnh tự do không suy ra từ cấu trúc; không đặt kính dưới nút; không lưu tọa độ vào cấu trúc đem triển khai; không chỉ hỗ trợ kéo thả. |

: CMP-FlowCanvas

```ts
export interface DhFlowNodeTypeDescriptor {
  type: string;                                  // 'to', 'choice', 'userTask'…
  kind: 'node' | 'group';
  label: (data: unknown) => string;              // tên hiển thị
  subtitle?: (data: unknown) => string;          // dòng phụ
  icon: string | React.ReactNode;
  categoryColor?: `color-chart-${1|2|3|4|5|6|7|8}` | 'color-accent';
  canBeEntry?: boolean; canHaveNext?: boolean;   // ràng buộc cổng
}

export interface DhFlowCanvasProps {
  structure: DhFlowGraph;                        // nút, nhóm, quan hệ suy ra cạnh (do phân hệ dựng)
  layout: DhFlowLayout;                          // tọa độ, ghim, thu gọn, ghi chú
  nodeTypes: DhFlowNodeTypeDescriptor[];
  mode?: 'edit' | 'readonly' | 'diff' | 'run-overlay';
  direction?: 'LR' | 'TB';
  issues?: Record<string, { errors: number; warnings: number }>;
  overlay?: DhFlowOverlay;                       // kết quả chạy thử, số liệu, khác biệt
  selection?: string[]; onSelectionChange?: (ids: string[]) => void;
  onStructureChange?: (cmd: DhStructureCommand) => void;   // chèn, xóa, di chuyển, bọc
  onLayoutChange?: (layout: DhFlowLayout) => void;
  onOpenInspector?: (id: string) => void;
  contextMenu?: (target: { kind: 'node' | 'edge' | 'pane'; id?: string }) => DhMenuItem[];
  'aria-label': string;
  testId?: string;
}
```

```tsx
<FlowCanvas aria-label={`Sơ đồ route ${route.id}, ${count} chặng`} structure={graph} layout={layout}
  nodeTypes={camelNodeTypes} issues={issuesByStep} selection={sel} onSelectionChange={setSel}
  onStructureChange={designer.apply} onLayoutChange={designer.setLayout} onOpenInspector={openInspector} />
```

### 11.2. CMP-FlowNode

`CMP-FlowNode` là một nút (chặng) trên canvas. Giải phẫu và bảng trạng thái chi tiết của chặng Camel ở D03-06-PH04 §10.7.2–10.7.3 là cách dùng chuẩn; bảng dưới đây là hợp đồng chung mà mọi phân hệ phải theo.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Nút tùy biến của XYFlow (`NodeProps`) với `Handle` cho cổng vào, cổng ra. |
| Giải phẫu | (1) Dải màu nhóm 4px cạnh trái; (2) biểu tượng 20px; (3) tên một dòng; (4) dòng phụ (loại · thành phần · tham số chính); (5) huy hiệu vấn đề (✕n lỗi, ⚠n cảnh báo); (6) huy hiệu chạy (✓, ✕, ⊘ và `CMP-Duration`); (7) huy hiệu phụ (khóa, tắt, ghim, có mô tả, gọi luồng con); (8) nút ⋯ menu ngữ cảnh; (9) cổng vào, cổng ra 8px, vùng nhận 24×24. |
| Vật liệu | Nền đặc `color-surface-solid`, viền 1px `color-border-control`, bóng `shadow-1`, bo `radius-md`. |
| Kích thước | 240×56px (mật độ Chuẩn), 200×40px (Gọn); tối giản dưới 50% thu phóng. |
| Trạng thái | Bình thường; rê (`color-fill-hover`, hiện ⋯ và cổng); focus bàn phím (vòng focus kép cách 2px); đang chọn (viền 2px `color-accent`, nền `color-accent-subtle`); chọn nhiều (viền 2px nét đứt `color-accent`); có lỗi (viền 2px `color-error-text` + ✕n); có cảnh báo (viền 2px `color-warning-text` + ⚠n); bị tắt (viền nét đứt, nền sọc chéo `color-fill-control`, chữ "Đã tắt"); đang bị kéo (mờ 40%); chặng khóa (viền 1px `color-accent` + `lock`); chạy đạt, chạy lỗi, không đi qua; khác biệt thêm, sửa, xóa, di chuyển; không biểu diễn được (nét đứt, "Chỉ sửa trong mã nguồn"). Vừa lỗi vừa chọn: hai vòng viền (chọn ngoài, lỗi trong). |
| Token | `color-surface-solid`, `color-border-control`, `color-fill-hover`, `color-fill-control`, `color-accent`, `color-accent-subtle`, `color-error-text`, `color-error-bg`, `color-warning-text`, `color-success-text`, `color-info-text`, `color-text-secondary`, `color-chart-1…8` (dải nhóm), `shadow-1`, `radius-md`, `font-callout`, `font-caption`. |
| Bàn phím, ARIA | `role="group"` với `aria-roledescription="chặng"`, `aria-label` gồm tên, loại và tình trạng ("Gọi hộ tịch, gọi HTTP, 2 lỗi"); `aria-selected`; cổng là nút có nhãn ("Cổng ra của Gọi hộ tịch"). |
| Nội dung | Tên ưu tiên mô tả do người dùng đặt; không có thì tiêu đề tiếng Việt của loại nút. Tham số chứa biểu thức hiện dạng thẻ nhỏ. |
| Điều cấm | Không chỉ dùng màu viền để báo lỗi (luôn có huy hiệu và chữ trong `aria-label`); không cổng nhỏ hơn vùng nhận 24×24; không chữ dưới 12px. |

: CMP-FlowNode

```ts
export interface DhFlowNodeData {
  type: string; label: string; subtitle?: string;
  issues?: { errors: number; warnings: number };
  run?: { result: 'passed' | 'failed' | 'skipped'; durationMs?: number; error?: string };
  diff?: 'added' | 'changed' | 'removed' | 'moved';
  flags?: Array<'locked' | 'disabled' | 'pinned' | 'described' | 'subflow' | 'not-allowed' | 'source-only'>;
}
```

### 11.3. CMP-GroupNode

`CMP-GroupNode` là khung chứa các nút con của một mẫu có nhánh hoặc thân (rẽ nhánh, thử bắt lỗi, lặp, tách, gộp trong Camel; cổng song song, tiến trình con trong BPMN; khối chặng chuẩn Datahub).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Nút nhóm của XYFlow (`parentId`, `extent: 'parent'`), kích thước do bố cục tự động tính theo nội dung. |
| Giải phẫu | (1) Tiêu đề: biểu tượng, tên mẫu, biểu thức rút gọn; (2) nút thu gọn ⌃; (3) huy hiệu lỗi tổng; (4) các làn nhánh, mỗi làn có nhãn (điều kiện, tên ngoại lệ, "otherwise"); (5) nút "＋ Thêm nhánh" do bộ mô tả loại cho phép. |
| Vật liệu | Nền đặc `color-surface-solid` nhạt hơn nền canvas một bậc nhờ viền 1px `color-border-subtle`, bo `radius-lg`; nhóm lồng nhau xen kẽ `color-surface-solid` và `color-surface-solid-2` để thấy tầng. |
| Trạng thái | Mở, thu gọn ("◆ Rẽ nhánh · 3 nhánh · 7 chặng", giữ huy hiệu lỗi tổng), đang chọn, có lỗi, khác biệt. Lồng sâu quá 6 cấp: gợi ý tách thành luồng con (phân hệ quyết định câu chữ). |
| Bàn phím, ARIA | `role="group"` với `aria-roledescription="nhóm"`, `aria-expanded`; `→` mở và vào nút đầu, `←` thu hoặc ra nhóm cha. |
| Điều cấm | Không cho kéo nút con ra ngoài nhóm bằng thao tác bố cục (ra ngoài là thay đổi cấu trúc, đi qua lệnh có xác nhận ở vùng thả). |

: CMP-GroupNode

### 11.4. CMP-StickyNote

`CMP-StickyNote` là ghi chú dán trên canvas để kỹ sư ghi chú thiết kế. Ghi chú thuộc lớp bố cục, không vào cấu trúc triển khai.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Nút XYFlow tùy biến; trình soạn Markdown giới hạn (đậm, nghiêng, danh sách, liên kết `https`) dựa trên `CMP-TextArea` có thanh định dạng nhỏ. |
| Vật liệu | Nền đặc `color-warning-bg`, chữ `color-warning-on-bg` (đạt 5,41:1), viền 1px `color-border-subtle`, bo `radius-sm`. |
| Kích thước | Rộng 160–480px, kéo đổi được; tối đa 2.000 ký tự. |
| Trạng thái | Xem, đang sửa (nhấp đúp hoặc `Enter`, `Esc` thoát), đang chọn. |
| Bàn phím, ARIA | `role="note"`; trong chế độ danh sách hiện như mục "Ghi chú" theo thứ tự đặt. Liên kết mở thẻ mới, chỉ nhận `https`. |
| Điều cấm | Không cho HTML thô; không cho ảnh nhúng; không đặt dữ liệu cá nhân (nhắc trong chữ giữ chỗ "Ghi chú thiết kế, không ghi dữ liệu cá nhân"). |

: CMP-StickyNote

### 11.5. CMP-NodePalette

`CMP-NodePalette` là bảng thành phần bên trái canvas: tìm, lọc theo vị trí chèn, nhóm theo nghiệp vụ, kéo vào canvas hoặc chèn bằng bàn phím. Cấu trúc và các cách xem riêng của PH-04 ở D03-06-PH04 §10.6.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-SearchField` + `CMP-Select` gọn (cách xem) + danh sách ảo hóa (`rc-virtual-list`) có nhóm `Collapse`; chế độ lưới biểu tượng tùy chọn. |
| Giải phẫu | (1) Ô tìm (`Ctrl+P` hoặc `/`); (2) cách xem; (3) chuyển danh sách/lưới; (4) nhóm "Dùng nhiều" và ghim cá nhân; (5) nhóm có số lượng; (6) mục: dải màu nhóm, biểu tượng, tên, dòng phụ, ⓘ, ☆, thẻ mức hỗ trợ ("Thử nghiệm", "Lỗi thời", "JVM"); (7) chú thích bộ lọc vị trí đang áp; (8) chân: số mục được phép, phiên bản catalog, liên kết danh mục. |
| Vật liệu | Nền đặc `color-surface-solid`, viền phải `color-border-subtle`. (Bản 0.1 của tài liệu này cho phép `glass-chrome` khi gắn mép canvas; bản 0.2 bỏ ngoại lệ đó cho thống nhất với D03-06-00 PTN-07 và D03-06-PH04 §2.1.) |
| Kích thước | Rộng 280px (220–420), thu thành dải 48px chỉ biểu tượng nhóm (`Ctrl+B`); mục cao 32px (danh sách) hoặc 72×72px (lưới). |
| Trạng thái | Đang tải catalog (khung xương 8 dòng), sẵn sàng, không có kết quả tìm ("Không có thành phần phù hợp" và, nếu tên khớp mục bị cấm, dòng "{tên} không được phép ở tỉnh · Đề xuất cho phép"), mục không hợp lệ ở vị trí đang chọn (mờ 50%, `⊘`, tooltip lý do), lỗi tải catalog. |
| Token | `color-surface-solid`, `color-border-subtle`, `color-fill-hover`, `color-focus-ring`, `color-text-secondary`, `color-chart-1…8`, `font-callout`, `font-caption`. |
| Bàn phím, ARIA | Danh sách là `role="listbox"` có nhóm (`role="group"` có nhãn); mũi tên di chuyển, `Enter` chèn mục vào sau nút đang chọn trên canvas và đọc kết quả qua `aria-live`; mục kéo được có `aria-roledescription="thành phần kéo được"` và gợi ý "Nhấn Enter để chèn". |
| Điều cấm | Không hiện mục mà chính sách tenant cấm; không chỉ cho kéo; không tải toàn bộ tài liệu thành phần vào bảng (chỉ chỉ mục tìm kiếm dựng sẵn). |

: CMP-NodePalette

### 11.6. CMP-Inspector

`CMP-Inspector` là ngăn bên phải hiện và sửa thuộc tính của nút đang chọn. Nó là `CMP-Form` (mục 3.2) sinh động từ bộ mô tả tham số của loại nút, chia tab, có kiểm tra trực tiếp.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Form` `layout="vertical"` cỡ `sm`, `CMP-Tabs` gọn, các trường chọn theo kiểu tham số (bảng dưới). |
| Giải phẫu | (1) Đầu: biểu tượng, tên nút sửa tại chỗ, loại, liên kết "Tài liệu ↗", nút ⤢ "Mở rộng" (mở `CMP-Modal` `lg` cùng nội dung); (2) tab "Cơ bản", "Nâng cao", "Lỗi", "Mô tả" (phân hệ thêm bớt); (3) trường; (4) vùng vấn đề của nút (lỗi, cảnh báo có liên kết nhảy tới trường); (5) "Khôi phục mặc định" từng trường. |
| Vật liệu | Nền đặc `color-surface-solid`, viền trái `color-border-subtle`. |
| Kích thước | Rộng 360px (300–560); ẩn khi không chọn nút (khi đó hiện thông tin của toàn sơ đồ); `Ctrl+I` bật tắt. |
| Ánh xạ kiểu tham số | `string` → `CMP-Input`; chuỗi dài → `CMP-TextArea`; `boolean` → `CMP-Switch` chỉ khi có hiệu lực ngay, còn lại `CMP-Checkbox`; số → `CMP-NumberInput` có đơn vị; `enum` → `CMP-Select` (dưới 6 lựa chọn: `CMP-Radio`); biểu thức → `CMP-ExpressionField`; bí mật → `CMP-SecretRefField`; kết nối, lược đồ, bảng mã → biến thể `CMP-ResourceSelect`; danh sách cặp → `CMP-KeyValueEditor`; thời lượng → `CMP-NumberInput` đơn vị ms/s/phút; lịch → `CMP-CronPicker`. |
| Kiểm tra | Trường bắt buộc và định dạng kiểm ở giao diện ngay khi rời trường; kiểm tra ngữ nghĩa (biên dịch biểu thức, kết nối hợp lệ) ở máy chủ sau 400ms; lỗi hiện tại trường và tổng hợp ở (4). Giá trị khác mặc định có chấm nhỏ cạnh nhãn và tooltip "Đã đổi so với mặc định {giá trị}". |
| Trạng thái | Không chọn nút, một nút, nhiều nút (chỉ hiện trường chung, giá trị khác nhau hiển thị "Nhiều giá trị"), chỉ đọc (biểu mẫu dạng mô tả), đang lưu, lỗi. |
| Token | `color-surface-solid`, `color-border-subtle`, `color-accent`, `font-callout`, `space-3`. |
| Bàn phím, ARIA | `<aside role="complementary" aria-label="Thuộc tính chặng">`; `Enter` trên nút canvas đưa focus vào trường đầu của Inspector; `Esc` trong Inspector đưa focus về nút trên canvas. |
| Điều cấm | Không là Modal che canvas; không lưu từng phím gõ lên máy chủ (gộp và tự lưu theo phiên soạn); không có ô nhập tự do cho tham số bí mật. |

: CMP-Inspector

### 11.7. CMP-CanvasControls

`CMP-CanvasControls` là cụm điều khiển nổi góc dưới trái canvas: thu, mức thu phóng, phóng, vừa khung, vừa vùng chọn, khóa bố cục, bật minimap, chú giải.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Flex` chứa `CMP-IconButton` cỡ `sm` và `CMP-DropdownMenu` cho mức thu phóng. |
| Vật liệu | `glass-overlay`, bo `radius-lg`, bóng `shadow-2`. |
| Phím | `Ctrl+-` thu, `Ctrl+=` phóng, `0` vừa khung, `Shift+2` vừa vùng chọn; mọi nút có tooltip ghi phím. |
| Bàn phím, ARIA | `role="toolbar"` `aria-label="Điều khiển sơ đồ"`, mũi tên trái phải giữa các nút (roving tabindex). Mức thu phóng là nút có nhãn "Mức thu phóng 85%". |
| Điều cấm | Không đặt cụm này trên nền đặc tự vẽ (phải là `glass-overlay` để phân biệt lớp nổi với nội dung). |

: CMP-CanvasControls

### 11.8. CMP-Minimap

`CMP-Minimap` là bản đồ thu nhỏ góc dưới phải canvas, tự hiện khi sơ đồ có trên 20 nút.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `MiniMap` của XYFlow, `pannable`, `zoomable`; nút có lỗi vẽ màu `color-error-solid` có viền để vẫn nhận ra khi mù màu đỏ xanh (hình chấm to hơn nút thường). |
| Vật liệu | Khung `glass-overlay`; bên trong vẽ nền đặc `color-surface-solid-2` để nút nhỏ đọc được. Kích thước 200×140px. |
| Bàn phím, ARIA | `aria-hidden="true"` (thông tin đã có ở chế độ danh sách và bảng vấn đề); nút ✕ ẩn minimap focus được. |

: CMP-Minimap

### 11.9. CMP-QuickInsert

`CMP-QuickInsert` là bảng chọn nhanh mở từ nút ⊕ trên cạnh, cuối nhánh, hoặc khi thả dây nối ra vùng trống: ô tìm có focus sẵn, tối đa 6 gợi ý theo ngữ cảnh, danh sách kết quả, `Enter` chèn tại vị trí.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Popover` neo tại điểm chèn, chứa `CMP-SearchField` và danh sách `role="listbox"`. |
| Vật liệu | `glass-overlay`, rộng 360px. |
| Nội dung | Gợi ý do phân hệ tính (PH-04: theo nút trước; PH-11: theo loại phần tử BPMN); nhóm "Gợi ý" trên, "Kết quả" dưới. |
| Bàn phím, ARIA | Mẫu combobox; `Esc` đóng và trả focus về nút ⊕; sau khi chèn, focus chuyển tới nút mới trên canvas. |
| Điều cấm | Không chèn khi lựa chọn không hợp lệ ở vị trí (mục bị ẩn khỏi danh sách, không hiện vô hiệu). |

: CMP-QuickInsert

### 11.10. CMP-DesignerToolbar

`CMP-DesignerToolbar` là thanh công cụ đầu trình thiết kế: quay lại, tên đối tượng sửa tại chỗ, phiên bản và trạng thái, `CMP-SaveIndicator`, menu Tệp/Sửa/Xem, hoàn tác/làm lại, chuyển chế độ (Sơ đồ/Mã/Chia đôi), bộ đếm vấn đề, hành động chạy thử và gửi duyệt, `CMP-AvatarGroup` người đang mở, nút toàn màn hình. Danh sách điều khiển của PH-04 ở D03-06-PH04 §10.4.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Flex` ba vùng (trái: điều hướng và định danh; giữa: soạn; phải: hành động), menu là `CMP-DropdownMenu`, chế độ là `CMP-SegmentedControl`. |
| Vật liệu | **Nền đặc** `color-surface-solid` có viền dưới `color-border-subtle`. Không dùng glass vì thanh chứa chỉ báo trạng thái lưu, bộ đếm lỗi màu trạng thái và nhiều nút nhỏ phải đọc chắc chắn. |
| Kích thước | Cao 48px; điều khiển `size-control-sm`. Dưới 1280px, menu gộp vào "☰", nút chính chỉ còn biểu tượng có `aria-label`. |
| Trạng thái | Bình thường, chỉ đọc (ẩn nút soạn, `CMP-SaveIndicator` "Chỉ đọc"), có vấn đề (bộ đếm "✕ 1 ⚠ 2"), hợp lệ ("✓ Hợp lệ" `color-success-text`), toàn màn hình (vẫn hiện). |
| Bàn phím, ARIA | `role="toolbar"` có `aria-label="Thanh công cụ trình thiết kế"`; phím tắt ghi trong tooltip và trong `CMP-ShortcutSheet`. |
| Điều cấm | Không quá một nút chính (thường là "Gửi duyệt" hoặc "Lưu"); không ẩn hành động bị vô hiệu do trạng thái (hiện vô hiệu kèm lý do, D03-05-04 §2.3). |

: CMP-DesignerToolbar

### 11.11. CMP-EntityRail

`CMP-EntityRail` là dải tab ngang dưới thanh công cụ, liệt kê các thực thể trong cùng một tệp hoặc mô hình (route, cấu hình, bean, REST trong PH-04; tiến trình, tiến trình con trong PH-11). Mỗi mục là một `CMP-EntityTab`.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Tabs` của antd `type="editable-card"` cỡ `small` với `tabBarExtraContent` "＋ Thêm ▾"; kéo đổi thứ tự bằng `@dnd-kit/sortable` có phương án bàn phím. |
| Giải phẫu `CMP-EntityTab` | Biểu tượng loại, nhãn "{loại}: {mã}", huy hiệu số lỗi `CMP-Badge`, nút ✕ (xóa thực thể, có xác nhận; ẩn khi chỉ còn một thực thể). |
| Vật liệu | Nền đặc `color-surface-solid`, cao 36px. |
| Trạng thái | Một thực thể (dải tự ẩn khi phân hệ cho phép), nhiều thực thể, tab có lỗi, tab đang đổi tên (nhấp đúp), tràn (cuộn ngang có nút mũi tên và menu "…"). |
| Bàn phím, ARIA | Mẫu tab của ARIA APG; `Delete` trên tab mở xác nhận xóa; `Ctrl+Shift+←/→` đổi thứ tự. |
| Điều cấm | Không xóa thực thể không xác nhận; không đổi thứ tự chỉ bằng kéo. |

: CMP-EntityRail

### 11.12. CMP-BottomPanel

`CMP-BottomPanel` là ngăn dưới thu gọn được của trình thiết kế, chứa các tab công cụ: "Vấn đề", "Kết quả chạy", "Nhật ký", "Lịch sử sửa", "Bình luận duyệt" (phân hệ chọn).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Tabs` gọn + nội dung theo tab (`CMP-DataTable` gọn cho vấn đề, `CMP-LogViewer` cho nhật ký, `CMP-Timeline` cho lịch sử, `CMP-CommentThread` cho bình luận). |
| Vật liệu | Nền đặc `color-surface-solid`, viền trên `color-border-subtle`. |
| Kích thước | Cao 220px (120 tới 60% chiều cao), thu thành thanh 32px hiện số vấn đề; `Ctrl+J` bật tắt; kích thước và tab lưu theo người dùng. |
| Tab "Vấn đề" | Mỗi dòng: biểu tượng mức (`error`, `warning`, `info`), mã (`CMP-Identifier`), vị trí ("Gọi hộ tịch · Kết nối"), thông điệp, nút "Đi tới" chọn nút và focus trường lỗi. `F8`/`Shift+F8` đi tới vấn đề kế, trước. |
| Bàn phím, ARIA | `<section aria-label="Bảng dưới">`; số vấn đề thay đổi đọc qua `aria-live="polite"` tối đa một lần mỗi 2 giây. |
| Điều cấm | Không tự mở bảng dưới mỗi khi có cảnh báo mới (chỉ tự mở khi người dùng bấm chạy thử hoặc gửi duyệt mà có lỗi chặn). |

: CMP-BottomPanel

### 11.13. CMP-Splitter

`CMP-Splitter` là tay nắm đổi kích thước giữa hai ngăn (bảng thành phần, canvas, Inspector, bảng dưới; cũng dùng ở PTN-08 cây + bảng và PTN-11 tra log).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Splitter` của antd v6 (`Splitter.Panel` có `min`, `max`, `collapsible`). |
| Vật liệu | Đường 1px `color-border-subtle`; khi rê hoặc focus, dải 4px `color-accent`. Vùng nhận 8px. |
| Bàn phím, ARIA | `role="separator"` `aria-orientation`, `aria-valuenow/min/max` theo px; mũi tên đổi 16px, `Shift`+mũi tên 64px, `Enter` thu gọn hoặc mở, nhấp đúp trả về mặc định. |
| Điều cấm | Không có tay nắm chỉ kéo được bằng chuột. |

: CMP-Splitter

## 12. Khung ứng dụng

Nhóm này dựng khung chung của `dh-console`: lớp điều hướng Liquid Glass (sidebar, thanh trên) và các điểm vào toàn cục (tenant, tìm kiếm, thông báo, tác vụ nền, tài khoản). Bố cục, kích thước, quy tắc URL, menu và hành vi theo quyền đã được quy định ở D03-06-00 §2 và §3; tài liệu này đặc tả hợp đồng thành phần để hiện thực đúng một lần.

### 12.1. CMP-AppShell

`CMP-AppShell` là thành phần gốc của mọi trang sau đăng nhập. Nó dựng năm lớp (canvas, sidebar, thanh trên, vùng nội dung, lớp phủ), cung cấp ngữ cảnh khung (tenant hiện tại, quyền, trạng thái thu gọn sidebar, chế độ toàn màn hình, chế độ liên tenant) và các vùng `aria-live` toàn cục.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Layout` của antd chỉ dùng cho bố cục lưới; sidebar và thanh trên là `CMP-Sidebar`, `CMP-Topbar` (không dùng `Layout.Sider`, `Layout.Header` trực tiếp vì cần vật liệu kính và sidebar nổi cách mép, D03-06-00 §3.3). Bọc trong `CMP-ThemeProvider` (D03-05-01 §9.2) và `App` của antd. |
| Giải phẫu | (1) Liên kết "Bỏ qua tới nội dung"; (2) dải liên tenant và dải thông báo hệ thống (khi có, `CMP-Banner`); (3) `CMP-Sidebar`; (4) `CMP-Topbar`; (5) `<main id="noi-dung">` cuộn độc lập; (6) bảng bên tùy chọn (Trợ lý AI); (7) vùng lớp phủ (portal của Modal, Drawer, Toast); (8) hai vùng `aria-live` (`polite`, `assertive`). |
| Vật liệu | Canvas `color-canvas` + `color-canvas-wash`; sidebar `glass-chrome`; thanh trên `glass-chrome` → `glass-chrome-scrolled` + `glass-scroll-edge` khi `main` cuộn (D03-05-01 §5); vùng nội dung trong suốt, các khối bên trong nền đặc. |
| Biến thể | `default`; `fullscreen` (ẩn sidebar và thanh trên, hiện `CMP-FullscreenBar`); `cross-tenant` (dải cảnh báo, viền trên 2px `color-warning-solid`, tiền tố tiêu đề tab); `kiosk` (dashboard trực ca chỉ đọc, PH-12 cấu hình). |
| Responsive | Từ `bp-xl`: sidebar mở rộng; 1200–1365px: sidebar thu gọn mặc định; dưới `bp-lg`: sidebar thành `CMP-Drawer` mở bằng nút ≡ (D03-06-00 §3.4). |
| Trạng thái | Đang khởi động (khung xương sidebar và thanh trên, không có màn trắng), sẵn sàng, mất kết nối (`CMP-Banner` ST-06), bảo trì (chuyển PTN-13), phiên sắp hết (`CMP-SessionTimeoutDialog`). |
| Token | `color-canvas`, `color-canvas-wash`, `size-sidebar`, `size-sidebar-collapsed`, `size-topbar`, `space-2`, `space-6`, `z-sidebar`, `z-topbar`. |
| Bàn phím, ARIA | Landmark theo D03-06-00 §3.6: `<nav aria-label="Điều hướng chính">`, `<header>`, `<main>`, `<aside>`; thứ tự focus: bỏ qua → thanh trên → sidebar → nội dung. Đổi route: focus chuyển về `<h1>` của trang mới và vùng `polite` đọc tiêu đề trang. |
| Điều cấm | Không có màn hình nào dựng khung riêng; không đặt nội dung nghiệp vụ trực tiếp lên kính; không giữ dữ liệu tenant cũ sau khi đổi tenant. |

: CMP-AppShell

```ts
export interface DhAppShellProps {
  menu: DhMenuNode[];                    // cây menu đã lọc theo quyền (D03-06-00 §2.3)
  tenant: { id: string; shortName: string; code: string };
  crossTenant?: { tenantName: string; expiresAt: string; onEnd: () => void };
  systemBanners?: DhBannerMessage[];
  assistantEnabled?: boolean;
  children: React.ReactNode;
}
```

### 12.2. CMP-Topbar

`CMP-Topbar` là thanh trên: nút ≡ (dưới `bp-lg`), `CMP-TenantSwitcher`, ô mở `CMP-CommandPalette`, nút Trợ lý AI (khi bật), nút Trợ giúp, `CMP-BackgroundTaskTray`, chuông `CMP-NotificationCenter`, `CMP-UserMenu`.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `<header>` tự dựng với `Flex`; các nút là `CMP-IconButton` biến thể `text` (đặt được trên kính, D03-05-03 §3.2). |
| Vật liệu | `glass-chrome` khi `main` ở đầu; `glass-chrome-scrolled` + `glass-scroll-edge` khi cuộn. Chuyển vật liệu do `IntersectionObserver` trên mốc đầu `main` (không lắng nghe sự kiện cuộn), chuyển tiếp `motion-duration-base`, tức thì khi giảm chuyển động. |
| Kích thước | Cao `size-topbar` (56px, Gọn 48px); ô tìm rộng 320–480px, co lại thành nút biểu tượng dưới 1280px. |
| Nội dung trên kính | Chỉ chữ `color-text-primary`, `color-text-secondary` và biểu tượng; không đặt chữ liên kết, chữ màu trạng thái trên `glass-chrome-scrolled` (D03-05-01 §3.2). Huy hiệu số dùng `CMP-Badge` nền đặc. |
| Bàn phím, ARIA | `<header role="banner">`; ô tìm là `<button>` có nhãn "Tìm kiếm (Ctrl+K)" và mở bảng lệnh; mọi nút có tên truy cập. |
| Điều cấm | Không thêm hành động nghiệp vụ của phân hệ lên thanh trên (đặt trong `CMP-PageHeader`); không quá 7 điều khiển ở vùng phải. |

: CMP-Topbar

### 12.3. CMP-Sidebar

`CMP-Sidebar` là thanh điều hướng chính hai cấp, tấm kính nổi cách mép `space-2`, bo `radius-xl`, bóng `shadow-2` (D03-06-00 §3.3).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Menu` của antd `mode="inline"` (mở rộng) và `mode="vertical"` với popover cấp 2 (thu gọn); `inlineIndent` 12; mục chọn `itemSelectedBg` = `color-fill-selected`, chữ `color-accent-on-subtle`. |
| Giải phẫu | (1) Logo và tên hệ thống; (2) nhóm menu cấp 1 có biểu tượng `size-icon-lg`; (3) mục cấp 2; (4) `CMP-Badge` số việc ở "Hộp việc"; (5) nút "Thu gọn" ở chân. |
| Vật liệu | `glass-chrome` trên canvas; ở dưới `bp-lg` là khung `glass-modal` của Drawer với nội dung menu trong giếng đặc. Chế độ kính "Tắt": nền `color-surface-solid`, giữ bo góc và bóng. |
| Kích thước | `size-sidebar` (256px; Gọn 232px), thu gọn `size-sidebar-collapsed` (64px; Gọn 56px). Lựa chọn thu gọn ghi nhớ theo người dùng. |
| Trạng thái | Mở rộng, thu gọn (popover `glass-overlay` cho cấp 2, mở bằng rê, focus, `Enter` hoặc `→`), mục đang chọn, nhóm mở, đang tải menu (khung xương 8 mục). |
| Bàn phím, ARIA | `<nav aria-label="Điều hướng chính">`; mũi tên lên xuống giữa mục, `→`/`←` mở thu nhóm, `Home`/`End`; mục hiện tại có `aria-current="page"`. |
| Điều cấm | Không quá hai cấp; không hiện mục người dùng không có quyền (D03-06-00 §2.6); không đặt nội dung động ngoài số đếm lên sidebar. |

: CMP-Sidebar

### 12.4. CMP-TenantSwitcher

`CMP-TenantSwitcher` hiển thị tenant hiện tại và cho đổi tenant hoặc bước vào chế độ liên tenant (FR-00-004, FR-00-011, FR-00-012). Hành vi đầy đủ ở D03-06-00 §2.11.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Nút trên thanh trên mở `CMP-Popover` chứa `CMP-SearchField` và danh sách có nhóm "Gần đây", "Tỉnh của tôi", "Truy cập liên tenant" (chỉ vai trò nền tảng). |
| Hiển thị | Tên ngắn tỉnh + mã tenant `CMP-Identifier` biến thể `badge`; người dùng một tenant: chữ tĩnh không mũi tên. |
| Vật liệu | Nút trên `glass-chrome`; popup `glass-overlay`. |
| Hành vi | Đổi tenant: hỏi nếu có thay đổi chưa lưu → về `/tong-quan` của tenant mới → `queryClient.clear()` → nạp lại quyền và menu. Chọn tenant nhóm liên tenant: mở `CMP-ReasonDialog` (loại lý do, mô tả ≥ 20 ký tự, mã phiếu hỗ trợ tùy chọn) trước khi chuyển. |
| Bàn phím, ARIA | Nút có `aria-haspopup="dialog"` và nhãn "Tenant hiện tại: Tỉnh Mẫu A. Đổi tenant"; danh sách theo mẫu listbox. |
| Điều cấm | Không đổi tenant mà giữ route cũ; không để yêu cầu mạng nào mang ngữ cảnh tenant cũ sau khi đổi. |

: CMP-TenantSwitcher

### 12.5. CMP-UserMenu

`CMP-UserMenu` là menu tài khoản ở góc phải thanh trên (D03-06-00 §2.10).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Avatar` cỡ `md` mở `CMP-DropdownMenu` có khối thông tin tùy biến ở đầu. |
| Mục | Khối thông tin (họ tên, thư điện tử, đơn vị, vai trò trong tenant); "Cài đặt cá nhân"; "Phiên đăng nhập"; "Bộ lọc đã lưu"; chế độ giao diện Sáng/Tối/Theo hệ thống (`CMP-SegmentedControl`); "Hiển thị" (kính Đầy đủ/Giảm/Tắt, mật độ, giảm chuyển động; mở trang cài đặt); "Phím tắt" (mở `CMP-ShortcutSheet`, cũng bằng `?`); "Đăng xuất". |
| Vật liệu | Popup `glass-overlay`. |
| Hành vi | Đăng xuất gọi đăng xuất phía Keycloak và xóa bộ nhớ đệm truy vấn, `sessionStorage`, bản nháp cục bộ có dữ liệu của người dùng. |
| Điều cấm | Không hiển thị mã định danh cá nhân, số điện thoại trong khối thông tin. |

: CMP-UserMenu

### 12.6. CMP-CommandPalette

`CMP-CommandPalette` là bảng lệnh mở bằng `Ctrl+K`: tìm màn hình, đối tượng, lệnh và hỏi trợ lý AI (D03-06-00 §2.7).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Modal` không có tiêu đề và chân, rộng `size-modal-md`, cách mép trên 12% chiều cao; ô `Input` lớn; danh sách nhóm ảo hóa. |
| Vật liệu | Khung `glass-modal`; danh sách kết quả trong giếng `color-surface-solid`. |
| Nguồn kết quả | Màn hình (cây menu đã lọc quyền, lọc tại chỗ), Đối tượng (API tìm hợp nhất, sau 250ms, tối thiểu 2 ký tự), Lệnh (đăng ký bởi màn và toàn cục qua `useRegisterCommand`), Hỏi trợ lý AI (khi bật). Mỗi nhóm tối đa 5 mục và "Xem tất cả". Khi trống: 5 mục gần đây. |
| Tìm kiếm | Bỏ dấu, không phân biệt hoa thường (`matchVi`), khớp tiền tố từ và khớp mã chính xác (FR-00-020). |
| Bàn phím, ARIA | `role="dialog"` `aria-modal="true"`; ô nhập `role="combobox"` `aria-controls` trỏ `role="listbox"`; mũi tên, `Enter`, `Tab` chuyển nhóm, `Esc` đóng và trả focus. |
| Điều cấm | Không trả đối tượng ngoài tenant hiện tại hoặc ngoài quyền xem; không thực thi lệnh phá hủy trực tiếp từ bảng lệnh (lệnh mở màn hoặc hộp xác nhận). |

: CMP-CommandPalette

```ts
export function useRegisterCommand(cmd: { id: string; title: string; keywords?: string[]; shortcut?: string; run: () => void; when?: () => boolean }): void;
```

### 12.7. CMP-NotificationCenter

`CMP-NotificationCenter` là trung tâm thông báo mở từ chuông (FR-00-060, D03-06-00 §2.9).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Badge` trên `CMP-IconButton` chuông mở `CMP-Popover` rộng 400px chứa `CMP-Tabs` "Tất cả", "Việc cần làm", "Tác vụ nền" và danh sách ảo hóa. |
| Vật liệu | Popup `glass-overlay` (vật liệu này đạt ngưỡng chữ mọi nấc nên danh sách đặt trực tiếp). |
| Mục thông báo | Biểu tượng loại; tiêu đề một dòng; mô tả tối đa hai dòng; `CMP-Timestamp` biến thể `relative`; nút hành động trực tiếp ("Tải tệp", "Xem báo cáo lỗi"); chấm chưa đọc kèm chữ ẩn "Chưa đọc". |
| Mức | Thông tin (chỉ tăng huy hiệu); cần chú ý (thêm `CMP-Notification` 6 giây); khẩn (`CMP-Notification` không tự đóng tới khi xác nhận). |
| Nguồn | SSE khi có, thăm dò 60 giây khi không; số đếm giới hạn "99+". |
| Bàn phím, ARIA | Nút chuông có nhãn "Thông báo, 3 chưa đọc"; tăng số đếm không đọc `assertive`. |
| Điều cấm | Không đưa dữ liệu Hạn chế hoặc Nhạy cảm vào nội dung thông báo (chỉ mã và liên kết). |

: CMP-NotificationCenter

### 12.8. CMP-BackgroundTaskTray

`CMP-BackgroundTaskTray` là khay tác vụ nền trên thanh trên: xuất tệp lớn (FR-00-031), nhập dữ liệu, chạy thử, phát hành, đồng bộ (FR-00-054). Nó cho người dùng rời màn mà vẫn theo dõi được tác vụ do chính mình khởi chạy.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-IconButton` biểu tượng `tasks` mang `CMP-Badge` số tác vụ đang chạy, mở `CMP-Popover` rộng 360px liệt kê tác vụ, mỗi tác vụ là `CMP-JobProgress` biến thể `list-item` (mục 10.3). |
| Vật liệu | Nút trên `glass-chrome`; popup `glass-overlay`. |
| Hiển thị trên nút | Có tác vụ đang chạy: vòng tiến độ mảnh quanh biểu tượng (tắt khi giảm chuyển động, thay bằng chấm); có tác vụ xong chưa xem: chấm `color-success-solid`; có tác vụ lỗi chưa xem: chấm `color-error-solid` kèm chữ ẩn "Có tác vụ lỗi". |
| Danh sách | Nhóm "Đang chạy", "Xong gần đây (24 giờ)"; mỗi mục: tên tác vụ, phân hệ, tiến độ hoặc kết quả, hành động ("Tải tệp", "Xem kết quả", "Hủy" khi API cho phép), liên kết tới đối tượng. "Xem tất cả" mở `/viec-cua-toi/tac-vu-nen` (PTN-01). |
| Nguồn | Danh sách tác vụ của người dùng trong tenant hiện tại từ API tác vụ nền dùng chung, cập nhật theo SSE hoặc thăm dò 5 giây khi có tác vụ đang chạy, 60 giây khi không. |
| Bàn phím, ARIA | Nút có nhãn "Tác vụ nền, 2 đang chạy"; khi tác vụ xong, vùng `polite` đọc một câu ("Xuất danh sách giao dịch đã xong") và trung tâm thông báo nhận thông báo. |
| Điều cấm | Không hiện tác vụ của người khác; không giữ liên kết tải tệp quá thời hạn của máy chủ (liên kết ký hết hạn thì hiện "Tạo lại liên kết"). |

: CMP-BackgroundTaskTray

### 12.9. CMP-ShortcutSheet

`CMP-ShortcutSheet` là bảng tra phím tắt mở bằng `?` (khi focus không ở ô nhập) hoặc từ `CMP-UserMenu`.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Modal` `md` chứa danh sách nhóm ("Toàn cục", "Danh sách", "Trình thiết kế"…) với phím hiển thị bằng `CMP-Kbd`; nhóm theo ngữ cảnh hiện tại đứng đầu. |
| Nguồn | Đăng ký qua `useRegisterShortcut` cùng nơi đăng ký phím, nên bảng luôn khớp hành vi thật. |
| Cài đặt | Công tắc "Bật phím tắt một ký tự" (mặc định bật) để đáp ứng WCAG 2.1.4; tắt thì chỉ còn phím có `Ctrl`/`Alt`. |
| Điều cấm | Không ghi đè phím chuẩn của trình duyệt và trình đọc màn hình (`Ctrl+L`, `Ctrl+T`, phím đơn khi trình đọc màn hình ở chế độ duyệt). |

: CMP-ShortcutSheet

### 12.10. CMP-FullscreenBar

`CMP-FullscreenBar` là thanh nổi nhỏ góc trên phải khi khung ở chế độ toàn màn hình (D03-06-00 §3.9): tên màn, đồng hồ (dashboard), nút "Thoát toàn màn hình".

| Khía cạnh | Đặc tả |
|---|---|
| Vật liệu | `glass-overlay`, bo `radius-pill`. |
| Hành vi | Tự mờ sau 3 giây không di chuột, hiện lại khi di chuột hoặc focus; `Esc` thoát. Dải liên tenant và dải hệ thống mức lỗi vẫn hiển thị. |
| Bàn phím, ARIA | `role="toolbar"` `aria-label="Thanh toàn màn hình"`; không bao giờ ẩn khỏi cây truy cập. |

: CMP-FullscreenBar

### 12.11. CMP-StatusBar

`CMP-StatusBar` là chân trạng thái của màn soạn dữ liệu lớn (lưới sửa danh mục PH-07 UI-07-05, nhập có xem trước PTN-09): số bản ghi, số đã đổi chưa lưu, số lỗi, vùng chọn, trạng thái lưu.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Flex` một dòng dính đáy khối nội dung, chứa `CMP-Text` cỡ `footnote`, `CMP-Badge`, `CMP-SaveIndicator`. |
| Vật liệu | Nền đặc `color-surface-solid-2`, viền trên `color-border-subtle`; cao 28px. |
| Nội dung | "1.248 bản ghi · 12 đã sửa · 3 lỗi · Đang chọn 4 ô"; số lỗi là nút đi tới lỗi đầu tiên. |
| Bàn phím, ARIA | `role="status"`; không đọc mỗi thay đổi (chỉ số lỗi đổi mới đọc, tối đa một lần mỗi 2 giây). |
| Điều cấm | Không đặt hành động chính ở chân trạng thái. |

: CMP-StatusBar

## 13. Thành phần dữ liệu chuyên dụng

Nhóm này gồm các thành phần mà tập màn hình PH-04 và PH-07 đề nghị đưa vào design system (D03-06-PH04 §27.3, D03-06-PH07 Phụ lục A-05) và các phân hệ khác chắc chắn dùng lại: lưới sửa được, biểu mẫu sinh từ lược đồ, cây lược đồ, bảng khác biệt, dải hiệu lực phiên bản, đồ thị phụ thuộc, bình luận, ngăn quyết định, thẻ môi trường, bảng điều khiển nhúng và trình hướng dẫn nhiều bước. Đưa chúng vào `@datahub/ui` thay vì để trong thư mục của phân hệ có hai lợi ích: hành vi truy cập (lưới, cây) chỉ phải làm đúng một lần, và phân hệ sau (PH-06, PH-08, PH-19) không phải viết lại.

### 13.1. CMP-EditableTable

`CMP-EditableTable` là lưới sửa được trực tiếp trên ô: sửa bản ghi danh mục hàng loạt (PH-07 UI-07-05), bảng ánh xạ mã (UI-07-10), bảng tham số Kamelet (PH-04), danh sách giá trị liệt kê. Không dùng thay `CMP-DataTable` cho danh sách chỉ xem; không dùng cho biểu mẫu dưới 5 dòng cố định (dùng `CMP-Form` với `Form.List`).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `EditableProTable` của `@ant-design/pro-components` cho lưới nhỏ (dưới 500 dòng, ví dụ tham số Kamelet); lưới lớn (bản ghi danh mục, hàng chục nghìn dòng) dùng lưới ảo hóa hai chiều tự viết trên `@tanstack/react-virtual` vì ProTable không ảo hóa cột. Hai nền cùng một API. |
| Giải phẫu | (1) Thanh công cụ: thêm dòng, xóa dòng chọn, hoàn tác, tìm trong lưới, lọc "Chỉ dòng lỗi"/"Chỉ dòng đã sửa"; (2) tiêu đề cột dính, cột khóa trái (mã); (3) ô: chế độ xem và chế độ sửa; (4) dấu dòng: thêm (＋), sửa (~), xóa (−, chữ gạch ngang), lỗi (✕); (5) `CMP-StatusBar` (mục 12.11). |
| Vật liệu | Nền đặc `color-surface-solid`; ô đang sửa viền 2px `color-accent`; ô lỗi viền 2px `color-error-text` và biểu tượng `error`; dòng đã sửa có dải trái 3px `color-warning-solid` cùng dấu "~". |
| Điều khiển trong ô | Theo kiểu dữ liệu: `CMP-Input`, `CMP-NumberInput`, `CMP-Select`, `CMP-DatePicker`, `CMP-Checkbox`, biến thể `CMP-ResourceSelect`; ánh xạ `data_type` → điều khiển do phân hệ khai báo (PH-07 ở D03-06-PH07 §11). |
| Kiểm tra | Kiểm tra theo JSON Schema do máy chủ cung cấp, biên dịch bằng Ajv trong Web Worker, chạy khi xác nhận ô; lỗi máy chủ (`errors[].pointer`) gắn về đúng ô (D03-06-PH07 §11.6). |
| Lưu | Hai chế độ: `row` (lưu mỗi dòng khi rời dòng, `If-Match` theo dòng) và `batch` (nút "Lưu {n} thay đổi" gửi lô, kết quả từng dòng). Xung đột ETag theo dòng hiện dấu trên dòng và mở `CMP-DiffViewer` `conflict` khi bấm. |
| Kích thước | Dòng `size-table-row` (Gọn 36px); ảo hóa dòng và cột; tối thiểu 60 khung/giây khi cuộn 50.000 dòng × 30 cột. |
| Trạng thái | Đang tải, rỗng ("Chưa có bản ghi. Thêm dòng hoặc nhập từ tệp"), đang sửa ô, có lỗi, đang lưu, lưu một phần, chỉ đọc. |
| Token | `color-surface-solid`, `color-surface-solid-2`, `color-accent`, `color-error-text`, `color-warning-solid`, `color-diff-added-bg`, `color-diff-changed-bg`, `color-diff-removed-bg` (D03-05-02 §4.6), `size-table-row`, `font-callout`. |
| Bàn phím, ARIA | `role="grid"` với `aria-rowcount`/`aria-colcount` theo tổng thật; ô `role="gridcell"` có `aria-rowindex`/`aria-colindex`; roving tabindex; mũi tên, Home/End, Ctrl+Home/End, PageUp/PageDown; Enter hoặc F2 sửa, Esc hủy, Tab xác nhận sang ô kế; Ctrl+Z hoàn tác; ô lỗi `aria-invalid` và `aria-describedby` (kế thừa D03-06-PH07 §20.1). Dán vùng từ Excel (`Ctrl+V`) dán vào nhiều ô, có hoàn tác. |
| Điều cấm | Không lưu từng phím gõ; không mất thay đổi chưa lưu khi đổi trang (hỏi trước, D03-06-00 §4.3); không chỉ dùng màu nền để báo dòng đã sửa. |

: CMP-EditableTable

```ts
export interface DhEditableColumn<Row> {
  key: keyof Row & string; title: string; width?: number; frozen?: boolean;
  editor: 'text' | 'number' | 'select' | 'date' | 'checkbox' | 'resource' | ((props: DhCellEditorProps<Row>) => React.ReactNode);
  required?: boolean; options?: DhSelectOption[];
}

export interface DhEditableTableProps<Row extends { key: string }> {
  columns: DhEditableColumn<Row>[];
  rows: Row[]; totalRows?: number; loadMore?: (offset: number) => Promise<Row[]>;
  validate?: (row: Row) => Promise<Array<{ field: string; message: string }>>;
  saveMode: 'row' | 'batch';
  onSaveRow?: (row: Row, etag?: string) => Promise<void>;
  onSaveBatch?: (changes: Array<{ op: 'add' | 'update' | 'remove'; row: Row; etag?: string }>) => Promise<DhBatchResult>;
  readOnly?: boolean; reorderable?: boolean; 'aria-label': string; testId?: string;
}
```

**Biến thể có mã riêng.** `CMP-EnumEditor` là EditableTable nhỏ cấu hình sẵn ba cột Giá trị, Nhãn, Thứ tự, cho kéo đổi thứ tự (`reorderable`, có phương án `Alt+↑/↓`), giới hạn 1–200 dòng, kiểm tra giá trị theo `^[A-Z0-9_]{1,64}$` và không trùng (PH-07 UI-07-04). Tên `CMP-EditableGrid` trong D03-06-PH07 là cùng thành phần này.

### 13.2. CMP-KeyValueEditor

`CMP-KeyValueEditor` sửa danh sách cặp khóa – giá trị: nhãn của luồng (PH-04), header tĩnh, thuộc tính tệp, tham số kiểu `object` đơn giản. Khác `CMP-EditableTable` ở chỗ chỉ có hai cột, không ảo hóa, nằm trong biểu mẫu.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Form.List` của antd với mỗi dòng là `Space.Compact` gồm `CMP-Input` (khóa), `CMP-Input` hoặc `CMP-ExpressionField` (giá trị), `CMP-IconButton` xóa. |
| Hành vi | Nút "＋ Thêm cặp"; khóa không trùng (lỗi tại dòng trùng); giới hạn số cặp và mẫu khóa do màn truyền (ví dụ tối đa 20, `^[a-z0-9.\-/]{1,63}$`); dán nhiều dòng dạng `khóa=giá trị` tách thành nhiều cặp. Giá trị bí mật không đi qua thành phần này (dùng `CMP-SecretRefField`). |
| Vật liệu | Nền đặc. |
| Bàn phím, ARIA | Mỗi dòng là `role="group"` có nhãn "Cặp 3"; nút xóa có nhãn "Xóa cặp linh-vuc"; sau khi thêm, focus vào ô khóa mới. |
| Điều cấm | Không cho khóa rỗng; không âm thầm gộp khóa trùng. |

: CMP-KeyValueEditor

```ts
export interface DhKeyValueEditorProps {
  value?: Array<{ key: string; value: string }>; onChange?: (v: Array<{ key: string; value: string }>) => void;
  keyPattern?: RegExp; maxPairs?: number; valueEditor?: 'text' | 'expression';
  keyPlaceholder?: string; valuePlaceholder?: string; disabled?: boolean; readOnly?: boolean; testId?: string;
}
```

### 13.3. CMP-DynamicForm

`CMP-DynamicForm` sinh biểu mẫu từ JSON Schema (2020-12) do máy chủ cung cấp kèm gợi ý giao diện: biểu mẫu bản ghi danh mục theo thuộc tính động (PH-07, LGC "thuộc tính động" của Aita), cấu hình bộ điều hợp (PH-05), tham số Kamelet (PH-04 Inspector), biểu mẫu nhiệm vụ người dùng BPMN (PH-11).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Form` + bộ dựng trường tự viết (không dùng thư viện biểu mẫu JSON Schema bên thứ ba vì cần đúng điều khiển của `@datahub/ui` và quy tắc truy cập). Kiểm tra bằng Ajv 8 trong Web Worker. |
| Ánh xạ kiểu | `string` → `CMP-Input` (`maxLength` > 200 → `CMP-TextArea`); `string` `format: date` → `CMP-DatePicker`; `date-time` → `CMP-DatePicker` có giờ; `email`, `uri` → `CMP-Input` có kiểm tra; `integer`, `number` → `CMP-NumberInput`; `boolean` → `CMP-Checkbox`; `enum` → `CMP-Select` (dưới 6 → `CMP-Radio`); `x-dh-codeList` → `CMP-CodeListSelect`; `x-dh-secret: true` → `CMP-SecretRefField`; `object` → nhóm trường có tiêu đề; `array` của đối tượng → `CMP-EditableTable` nhỏ; `array` của chuỗi → `CMP-Select` `multiple` có `allowCreate`. |
| Gợi ý giao diện | Khóa mở rộng `x-dh-ui`: `order`, `group`, `widget`, `help`, `placeholder`, `readOnly`, `hidden`, `span` (độ rộng cột trong lưới 2 cột), `sensitivity` (Công khai, Nội bộ, Hạn chế, Nhạy cảm; trường Nhạy cảm hiển thị bằng `CMP-MaskedValue` ở chế độ xem). Khóa lạ bị bỏ qua và ghi cảnh báo ở môi trường phát triển. |
| Nhãn | `title` tiếng Việt của lược đồ là nhãn; thiếu `title` thì hiện mã trường kèm cảnh báo phát triển (không tự "dịch"). `description` là chữ trợ giúp. |
| Thông điệp lỗi | Ánh xạ từ khóa Ajv sang tiếng Việt một lần ở `@datahub/ui/forms/ajv-vi.ts` (`required` → "Bắt buộc nhập {nhãn}.", `maxLength` → "{nhãn} tối đa {limit} ký tự.", `pattern` → "{nhãn} không đúng định dạng."…). |
| Chế độ | `edit`, `view` (dạng `CMP-DescriptionList`), `diff` (đánh dấu trường khác so với giá trị gốc). |
| Trạng thái | Đang tải lược đồ, lược đồ lỗi (`CMP-Alert` "Không đọc được lược đồ biểu mẫu" kèm mã truy vết), sẵn sàng, lược đồ đổi trong khi sửa (Alert "Lược đồ thuộc tính vừa được thay đổi. Tải lại lược đồ"), như `CMP-Form`. |
| Bàn phím, ARIA | Như `CMP-Form` (mục 3.2); nhóm `object` là `<fieldset>` có `<legend>`. |
| Điều cấm | Không tự viết lại quy tắc kiểm tra song song với lược đồ máy chủ; không hiển thị trường `hidden`; không sinh trường bí mật dạng ô nhập. |

: CMP-DynamicForm

```ts
export interface DhDynamicFormProps {
  schema: JSONSchema2020; uiSchemaVersion?: 1;
  value?: Record<string, unknown>; onChange?: (v: Record<string, unknown>) => void;
  mode?: 'edit' | 'view' | 'diff'; baseline?: Record<string, unknown>;
  serverErrors?: Array<{ pointer: string; message: string }>;
  columns?: 1 | 2; disabled?: boolean; testId?: string;
}
```

### 13.4. CMP-SchemaTree

`CMP-SchemaTree` hiển thị cấu trúc một lược đồ dữ liệu (JSON Schema, XSD đã chuyển đổi, Avro) dạng cây có biểu tượng kiểu, dùng ở trình ánh xạ dữ liệu PH-04 (UI-04-07), xem lược đồ PH-06, chọn trường cho quy tắc chất lượng PH-08.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Tree` (mục 6.4) ảo hóa với nút tùy biến. |
| Nút | Biểu tượng kiểu (`{}` đối tượng, `[]` mảng, `Aa` chuỗi, `#` số, lịch ngày, ✓ boolean, `≡` liệt kê) có chữ thay thế; tên trường `font-mono`; kiểu dạng chữ phụ; dấu `*` bắt buộc; huy hiệu tùy vai trò (`target`: ✓ đã ánh xạ; `source`: số lần dùng); mức nhạy cảm (`lock` khi Nhạy cảm). |
| Biến thể | `browse` (xem), `source`, `target` (hai phía của trình ánh xạ, kéo từ nguồn thả vào đích có phương án bàn phím "Chọn nguồn, rồi Enter trên đích"), `pick` (chọn một hoặc nhiều trường). |
| Tìm | Ô lọc theo tên trường, giữ đường dẫn cha của nút khớp. |
| Vật liệu | Nền đặc. |
| Bàn phím, ARIA | Mẫu `tree` (D03-06-PH07 §20.2); nút có `aria-label` "khaiSinh.nguoiMe.hoTen, chuỗi, bắt buộc, đã ánh xạ". |
| Điều cấm | Không tải lược đồ trên 5 MB về trình duyệt (máy chủ trả dạng nạp lười theo nhánh). |

: CMP-SchemaTree

### 13.5. CMP-TreeGrid

`CMP-TreeGrid` là bảng có cột mà dòng phân cấp mở được. Hai cách dùng chính: chế độ danh sách thay thế canvas cho người dùng bàn phím và trình đọc màn hình (PH-04 §10.18, biến thể `structure`), và bảng dữ liệu phân cấp có nhiều cột (bản ghi danh mục có cha con xem kèm thuộc tính, cây ĐVHC kèm mã).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `Table` của antd với `expandable` cây (`childrenColumnName`), ảo hóa khi trên 500 dòng; biến thể `structure` thêm thao tác cấu trúc. |
| Biến thể `structure` | Mỗi dòng một nút của canvas: Tên, Loại, Thành phần, Tham số chính, Vấn đề. Thao tác: thêm trước, thêm sau, di chuyển lên xuống (`Alt+↑/↓`), thụt vào hoặc ra (chuyển vào nhánh, `Alt+→/←`), xóa, mở Inspector (`Enter`). Mọi thao tác đi qua cùng lệnh cấu trúc của `CMP-FlowCanvas`, cùng ngăn hoàn tác. |
| Vật liệu | Nền đặc. |
| Bàn phím, ARIA | `role="treegrid"`; dòng có `aria-level`, `aria-expanded`, `aria-posinset`, `aria-setsize`; mũi tên phải trái mở thu dòng khi focus ở dòng, di chuyển ô khi focus ở ô. Mỗi thao tác cấu trúc đọc một câu qua `aria-live`. |
| Điều cấm | Không có thao tác nào chỉ làm được trên canvas mà không làm được trên TreeGrid `structure`. |

: CMP-TreeGrid

### 13.6. CMP-DiffTable

`CMP-DiffTable` là bảng khác biệt theo bản ghi giữa hai phiên bản của một tập dữ liệu: bản nháp so với phiên bản đang hiệu lực của danh mục (PH-07 UI-07-07), kết quả một lần đồng bộ quốc gia (UI-07-09), xem trước nhập tệp (UI-07-06, PTN-09), khác biệt thuộc tính lược đồ. Khác `CMP-DiffViewer` (so hai văn bản hoặc hai đối tượng) ở chỗ so hàng nghìn bản ghi có phân trang máy chủ.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-DataTable` ảo hóa, dữ liệu khác biệt do máy chủ tính và phân trang. |
| Cột | Loại khác biệt (chữ + biểu tượng: "Thêm mới" ＋, "Đã sửa" ~, "Ngừng dùng" −, "Phá vỡ" ⚠), mã, trường thay đổi, giá trị cũ (`<del>`), giá trị mới (`<ins>`); với "Đã sửa" nhiều trường, dòng mở rộng liệt kê từng trường. Gộp nhóm theo mã. |
| Bộ lọc | `CMP-SegmentedControl` theo loại khác biệt kèm số lượng ("Thêm 12 · Sửa 40 · Ngừng 3 · Phá vỡ 1"); tìm theo mã. |
| Vật liệu | Nền đặc; ô giá trị dùng token `color-diff-*` (D03-05-02 §4.6) đạt 4,5:1 trên nền đặc. |
| Bàn phím, ARIA | `<table>` ngữ nghĩa; giá trị cũ, mới có văn bản ẩn "Giá trị cũ:", "Giá trị mới:" (nhiều trình đọc không đọc ngữ nghĩa `del`, `ins`, D03-06-PH07 §20.3). |
| Điều cấm | Không chỉ tô màu nền để báo loại khác biệt; không tính khác biệt ở trình duyệt với tập trên 1.000 bản ghi. |

: CMP-DiffTable

### 13.7. CMP-VersionTimeline

`CMP-VersionTimeline` là dải thời gian hiệu lực của các phiên bản: mỗi phiên bản đã phát hành là một đoạn `[hiệu lực từ, hiệu lực đến)` trên trục ngày, đoạn đang hiệu lực tô đậm, phiên bản tương lai nét đứt (danh mục PH-07, phiên bản API PH-02, phiên bản luồng PH-04 theo môi trường).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | SVG tự vẽ (nhẹ hơn ECharts cho một dải), đặt trên bảng phiên bản và liên kết hai chiều với bảng: bấm đoạn chọn dòng, chọn dòng tô đoạn. |
| Vật liệu | Nền đặc; đoạn hiệu lực `color-accent`, đoạn đã hết hiệu lực `color-neutral-solid`, đoạn tương lai viền nét đứt `color-accent`; nhãn số phiên bản trên đoạn. |
| Bảng thay thế | Thông tin của dải luôn có trong bảng phiên bản (cột Hiệu lực); dải có `aria-hidden="true"` và nút "Bỏ qua dải thời gian". |
| Điều cấm | Không dùng dải làm nơi duy nhất thể hiện hiệu lực. |

: CMP-VersionTimeline

Tên `CMP-LineageTimeline` trong D03-06-PH07 (dòng lịch sử một bản ghi qua các phiên bản) là `CMP-Timeline` biến thể `status` có nhóm theo phiên bản; không phải thành phần riêng.

### 13.8. CMP-DependencyGraph

`CMP-DependencyGraph` là đồ thị phụ thuộc chỉ đọc quanh một đối tượng: luồng con, Kamelet, kết nối, topic, lược đồ, bảng mã, API dùng luồng làm backend (PH-04 UI-04-02); API nào dùng danh mục nào (PH-07); hệ thống nào đăng ký API nào (PH-02).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | XYFlow ở chế độ chỉ đọc với bố cục tỏa tròn hai tầng, cùng thư viện với `CMP-FlowCanvas` nhưng không có Inspector, palette, hoàn tác. |
| Biến thể | `compact` (trong thẻ của trang chi tiết, cao 240px, tối đa 1 tầng), `full` (trang riêng hoặc Drawer `lg`, 2 tầng, lọc theo loại). |
| Nút | Biểu tượng loại, tên, `CMP-StatusDot`; bấm mở trang chi tiết của đối tượng (cùng tab nếu cùng phân hệ). Đối tượng không có quyền xem hiện "Đối tượng hạn chế" không có tên. |
| Vật liệu | Nền đặc `color-surface-solid-2`. |
| Bảng thay thế | Nút "Xem dạng danh sách" chuyển sang bảng (Loại, Tên, Quan hệ, Trạng thái); đồ thị `role="img"` có `aria-label` tóm tắt ("Phụ thuộc vào 2 kết nối, 1 topic, 3 bảng mã; được dùng bởi 1 API"). |
| Điều cấm | Không cho sửa quan hệ trên đồ thị; không hiện tên đối tượng người dùng không có quyền xem. |

: CMP-DependencyGraph

### 13.9. CMP-CommentThread

`CMP-CommentThread` là luồng bình luận gắn với một phần tử: chặng trên canvas hoặc dòng YAML khi duyệt luồng (PH-04), bản ghi danh mục khi duyệt công bố (PH-07), trường trong hồ sơ kết nạp (PH-01).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Danh sách `CMP-Timeline` biến thể `compact` + `CMP-TextArea` có nút "Gửi" (`Ctrl+Enter`). |
| Giải phẫu | Mỗi bình luận: `CMP-Avatar`, tên, `CMP-Timestamp` `smart`, nội dung (văn bản thuần, liên kết `https` tự nhận), trạng thái "Đã giải quyết"; nút "Trả lời", "Đánh dấu đã giải quyết" (người duyệt hoặc tác giả). |
| Neo | Bình luận có `anchor` (mã chặng, đường dẫn trường, dòng YAML kèm băm nội dung để phát hiện neo lệch). Neo không còn tồn tại hiện "Phần tử đã thay đổi" và vẫn giữ bình luận. Phần tử có bình luận mở mang huy hiệu `comment` có số. |
| Vật liệu | Nền đặc (trong Inspector, bảng dưới hoặc `CMP-Drawer`). |
| Bàn phím, ARIA | Danh sách `role="feed"`; mỗi bình luận `role="article"` có `aria-labelledby` (tên, thời điểm). |
| Điều cấm | Không cho sửa bình luận của người khác; không xóa bình luận đã gắn với một quyết định duyệt (chỉ ẩn, giữ kiểm toán); không nhận HTML. |

: CMP-CommentThread

### 13.10. CMP-DecisionPanel

`CMP-DecisionPanel` là ngăn quyết định theo trạng thái: hiển thị trạng thái hiện tại của đối tượng có vòng đời và các hành động hợp lệ tiếp theo lấy từ `allowedActions` / `disabledReasons`, mỗi hành động có thể yêu cầu xác nhận, lý do hoặc tùy chọn (PH-07 UI-07-07 duyệt phiên bản, UI-07-09 xác nhận đồng bộ với "Bỏ qua bản ghi lỗi", "Loại trừ mã", "Phát hành ngay"). `CMP-ApprovalPanel` (mục 10.2) là cấu hình sẵn của DecisionPanel cho phê duyệt bốn mắt.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Card` chứa `CMP-StatusTag`, mô tả bước tiếp theo, các `CMP-Button`, tùy chọn dạng `CMP-Checkbox`; hành động cần lý do mở `CMP-ReasonDialog`, hành động phá hủy mở `CMP-ConfirmDialog`. |
| Quy tắc nút | Tối đa một nút chính (hành động "đi tiếp" của quy trình); hành động có quyền nhưng chưa thỏa điều kiện hiện vô hiệu kèm lý do bằng chữ dưới nút (không chỉ tooltip); hành động không có quyền bị ẩn. |
| Vật liệu | Nền đặc. |
| Trạng thái | Đang tải, sẵn sàng, đang gửi quyết định, xung đột (người khác vừa quyết định: Alert và tự làm mới), chỉ đọc (đối tượng đã kết thúc). |
| Bàn phím, ARIA | `<section aria-labelledby>`; sau quyết định, focus tới thông báo kết quả `role="status"`. |
| Điều cấm | Không suy diễn hành động từ vai trò ở giao diện; không gửi quyết định không kèm `If-Match`. |

: CMP-DecisionPanel

```ts
export interface DhDecisionAction {
  key: string; label: string; kind: 'primary' | 'default' | 'danger';
  needs?: 'confirm' | 'reason' | 'none'; options?: Array<{ key: string; label: string; default?: boolean }>;
  disabledReason?: string;
}
export interface DhDecisionPanelProps {
  status: string; nextStepText?: string;
  actions: DhDecisionAction[];                    // đã lọc theo allowedActions
  onDecide: (key: string, input: { reason?: string; options?: Record<string, boolean> }) => Promise<void>;
  readOnly?: boolean; testId?: string;
}
```

### 13.11. CMP-EnvCard

`CMP-EnvCard` là thẻ trạng thái một môi trường triển khai (TEST, STAGING, PROD) của một đối tượng chạy được: phiên bản đang chạy, sức khỏe, số bản sao, lần triển khai cuối, hành động thăng cấp hoặc quay lui (PH-04 UI-04-02; về sau PH-02 cho phiên bản API trên gateway, PH-05 cho bộ điều hợp).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Card` biến thể gọn; số thẻ theo tham số môi trường của tenant (mặc định TEST, PROD), xếp ngang theo thứ tự thăng cấp có mũi tên giữa các thẻ. |
| Giải phẫu | (1) Tên môi trường và nhãn PROD nổi bật (chữ đậm, viền trên 3px `color-warning-solid` để nhắc thận trọng, kèm chữ "Sản xuất"); (2) phiên bản đang chạy và `CMP-StatusTag`; (3) sức khỏe `CMP-StatusDot` + chữ ("Khỏe", "Suy giảm", "Lỗi") và số bản sao "2/2"; (4) `CMP-Timestamp` lần triển khai cuối, người triển khai; (5) chỉ số nhanh 24 giờ (lượng bản tin, tỷ lệ lỗi, p95 `CMP-Duration`); (6) hành động theo `allowedActions` ("Thăng cấp lên PROD", "Quay lui", "Tạm dừng"). |
| Vật liệu | Nền đặc. |
| Trạng thái | Chưa triển khai ("Chưa có phiên bản nào ở PROD"), đang triển khai (`CMP-JobProgress` trong thẻ, theo SSE), khỏe, suy giảm, lỗi, tạm dừng, dừng khẩn. |
| Bàn phím, ARIA | Thẻ là `<article aria-labelledby>`; nhóm thẻ là `role="list"`. |
| Điều cấm | Không hiện nút thăng cấp lên PROD cho người không có quyền `promote`; không chỉ dùng màu chấm cho sức khỏe. |

: CMP-EnvCard

### 13.12. CMP-EmbeddedDashboard

`CMP-EmbeddedDashboard` nhúng một bảng điều khiển giám sát của PH-13 vào trang chi tiết của phân hệ khác, đã lọc theo đối tượng (lượng bản tin theo giây, lỗi, độ trễ, tài nguyên của một luồng; lượt gọi của một API).

| Khía cạnh | Đặc tả |
|---|---|
| Nền | Lưới `CMP-Card` chứa `CMP-Chart` dựng từ định nghĩa bảng điều khiển do PH-13 cung cấp (JSON: danh sách biểu đồ, truy vấn, đơn vị); không nhúng iframe của công cụ giám sát bên thứ ba. |
| Điều khiển | Khoảng thời gian `CMP-SegmentedControl` (1 giờ, 24 giờ, 7 ngày), môi trường, nút "Mở trong Giám sát" tới PH-13 với bộ lọc tương ứng. |
| Vật liệu | Nền đặc. |
| Trạng thái | Đang tải từng biểu đồ (Skeleton riêng), không có dữ liệu, lỗi một biểu đồ (không làm lỗi cả bảng), không có quyền xem giám sát (ẩn khối, hiện chữ "Bạn không có quyền xem số liệu giám sát"). |
| Truy cập | Mỗi biểu đồ có bảng dữ liệu thay thế theo `CMP-Chart` (mục 6.6). |
| Điều cấm | Không dùng iframe; không truy vấn quá 7 ngày mỗi lần từ trang nhúng. |

: CMP-EmbeddedDashboard

### 13.13. CMP-Wizard

`CMP-Wizard` là khung của mẫu PTN-05 (D03-06-00 §4.8): `CMP-Steps` + nội dung bước + thanh hành động dính đáy + bước rà soát. Mọi wizard của các phân hệ (kết nạp HTTT, đăng ký API từ OpenAPI, tạo luồng, tạo danh mục, nhập dữ liệu) dùng thành phần này để có cùng hành vi kiểm tra bước, quay lại, lưu nháp và rời trang.

| Khía cạnh | Đặc tả |
|---|---|
| Nền | `CMP-Steps` (mục 10.1) + `CMP-Form` dùng chung một kho giá trị cho mọi bước + thanh đặc dính đáy chứa "Quay lại", "Lưu nháp" (khi đối tượng hỗ trợ), "Tiếp tục"/"Gửi". |
| Hành vi | Kiểm tra bước khi bấm "Tiếp tục", không sang bước sau khi lỗi; quay lại bước đã qua bằng nút hoặc bấm bước trên Steps; không nhảy tới bước chưa tới; bước đã qua mà dữ liệu bước trước thay đổi làm mất hiệu lực thì Steps đánh dấu "Cần xem lại"; bước rà soát dùng `CMP-DescriptionList` có liên kết "Sửa" về bước; bước chạy lâu dùng `CMP-JobProgress`; bước hiện tại phản ánh trên URL (`?buoc=2`); rời trang khi có dữ liệu thì hỏi (D03-06-00 §4.3). |
| Vật liệu | Steps trên canvas; nội dung bước trong `CMP-Card` đặc; thanh hành động đặc `color-surface-solid` có bóng `shadow-2` khi nội dung cuộn dưới nó. |
| Bàn phím, ARIA | Khi chuyển bước, focus tới tiêu đề bước và vùng `polite` đọc "Bước 2 trên 4, Đầu mối"; `Ctrl+Enter` tương đương "Tiếp tục". |
| Điều cấm | Không dùng Modal cho wizard trên 3 bước; không mất dữ liệu bước khi quay lại; không gửi khi chưa qua bước rà soát. |

: CMP-Wizard

```ts
export interface DhWizardStep<V> { key: string; title: string; description?: string; fields?: Array<keyof V & string>; render: () => React.ReactNode; validate?: (v: V) => Promise<void>; longRunning?: boolean }
export interface DhWizardProps<V> { steps: DhWizardStep<V>[]; initialValues?: Partial<V>; onSubmit: (v: V) => Promise<void>; onSaveDraft?: (v: Partial<V>) => Promise<void>; reviewStep?: boolean; testId?: string }
```

## 14. Bảng tổng hợp, tên gọi khác và nghiệm thu

### 14.1. Bảng tổng hợp thành phần phức hợp và tổ chức

Bảng dưới là danh mục chính thức để đối chiếu Storybook khi nghiệm thu (D03-05 §6). Cột "Mức" theo MoSCoW cho đợt MVP (M: trước khi phát triển phân hệ; S: trước phân hệ đầu tiên dùng nó). Cột "Phân hệ dùng đầu tiên" chỉ nơi thành phần được kiểm chứng trước.

| Mục | Mã | Nền | Vật liệu | Mức | Phân hệ dùng đầu tiên |
|---|---|---|---|---|---|
| 3.1 | `CMP-FormField` | `Form.Item` | Đặc | M | Mọi phân hệ |
| 3.2 | `CMP-Form` | `Form` | Đặc | M | Mọi phân hệ |
| 3.3 | `CMP-SearchField` | `Input.Search` | Đặc, trên glass ở thanh trên | M | Mọi phân hệ |
| 3.4 | `CMP-FilterBar` | `Form` inline | Đặc | M | PH-07, PH-04 |
| 4.1 | `CMP-Breadcrumb` | `Breadcrumb` | Trên canvas | M | Mọi phân hệ |
| 4.2 | `CMP-PageHeader` | tự dựng | Trên canvas | M | Mọi phân hệ |
| 4.3 | `CMP-Tabs` | `Tabs` | Đặc | M | Mọi phân hệ |
| 4.4 | `CMP-Pagination` | `Pagination` | Đặc | M | Mọi phân hệ |
| 5.1 | `CMP-Alert` | `Alert` | Đặc | M | Mọi phân hệ |
| 5.2 | `CMP-Banner` | `Alert banner` | Đặc | M | Khung ứng dụng |
| 5.3 | `CMP-Toast` | `message` | Nền đảo | M | Mọi phân hệ |
| 5.4 | `CMP-Notification` | `notification` | `glass-overlay` | M | Khung ứng dụng |
| 5.5 | `CMP-EmptyState` | `Empty` | Đặc | M | Mọi phân hệ |
| 5.6 | `CMP-ResultPage` | `Result` | Trên canvas | M | Mọi phân hệ |
| 6.1 | `CMP-Card` | `Card` | Đặc | M | Mọi phân hệ |
| 6.2 | `CMP-KpiCard` | `Statistic` | Đặc | M | PH-13, PH-07 |
| 6.3 | `CMP-DescriptionList` | `Descriptions` | Đặc | M | Mọi phân hệ |
| 6.4 | `CMP-Tree` | `Tree` | Đặc | M | PH-07 |
| 6.5 | `CMP-Transfer` | `Transfer` | Đặc | S | PH-12 |
| 6.6 | `CMP-Chart` | ECharts | Đặc | M | PH-13 |
| 7.1 | `CMP-Modal` | `Modal` | `glass-modal` + giếng đặc | M | Mọi phân hệ |
| 7.2 | `CMP-Drawer` | `Drawer` | `glass-modal` + giếng đặc | M | Mọi phân hệ |
| 7.3 | `CMP-ConfirmDialog` | `Modal` | `glass-modal` + giếng đặc | M | Mọi phân hệ |
| 7.4 | `CMP-ReasonDialog` | `Modal` | `glass-modal` + giếng đặc | M | Mọi phân hệ |
| 7.5 | `CMP-Popover` | `Popover` | `glass-overlay` | M | Mọi phân hệ |
| 7.6 | `CMP-DropdownMenu` | `Dropdown` | `glass-overlay` | M | Mọi phân hệ |
| 7.7 | `CMP-SessionTimeoutDialog` | `Modal` | `glass-modal` + giếng đặc | M | Khung ứng dụng |
| 8.1 | `CMP-DataTable` | `ProTable` | Đặc | M | Mọi phân hệ |
| 8.2 | `CMP-BulkActionBar` | tự dựng | Đặc (dính), `glass-overlay` (`floating`) | M | PH-07, PH-04 |
| 9.1 | `CMP-CodeEditor` | Monaco | Đặc | M | PH-04, PH-07 |
| 9.2 | `CMP-JsonViewer` | tự dựng | Đặc | M | PH-04, PH-13 |
| 9.3 | `CMP-LogViewer` | ảo hóa | Đặc | M | PH-13, PH-04 |
| 9.4 | `CMP-DiffViewer` | Monaco DiffEditor | Đặc | M | PH-04, PH-07 |
| 10.1 | `CMP-Steps` | `Steps` | Trên canvas | M | PH-01, PH-04 |
| 10.2 | `CMP-ApprovalPanel` | dựng trên `CMP-DecisionPanel` | Đặc | M | Hộp việc |
| 10.3 | `CMP-JobProgress` | `Progress` | Đặc, `glass-overlay` trong khay | M | PH-07, PH-04 |
| 10.4 | `CMP-AuditTrail` | `CMP-Timeline` | Đặc | M | Mọi phân hệ |
| 10.5 | `CMP-Timeline` | `Timeline` | Đặc | M | Mọi phân hệ |
| 11.1 | `CMP-FlowCanvas` | XYFlow | Đặc | M | PH-04 |
| 11.2 | `CMP-FlowNode` | XYFlow | Đặc | M | PH-04 |
| 11.3 | `CMP-GroupNode` | XYFlow | Đặc | M | PH-04 |
| 11.4 | `CMP-StickyNote` | XYFlow | Đặc (nền cảnh báo nhẹ) | S | PH-04 |
| 11.5 | `CMP-NodePalette` | danh sách ảo hóa | Đặc | M | PH-04 |
| 11.6 | `CMP-Inspector` | `CMP-Form` | Đặc | M | PH-04 |
| 11.7 | `CMP-CanvasControls` | tự dựng | `glass-overlay` | M | PH-04 |
| 11.8 | `CMP-Minimap` | XYFlow `MiniMap` | `glass-overlay` + nền đặc | S | PH-04 |
| 11.9 | `CMP-QuickInsert` | `Popover` | `glass-overlay` | M | PH-04 |
| 11.10 | `CMP-DesignerToolbar` | tự dựng | Đặc | M | PH-04 |
| 11.11 | `CMP-EntityRail` (`CMP-EntityTab`) | `Tabs` | Đặc | M | PH-04 |
| 11.12 | `CMP-BottomPanel` | `Tabs` | Đặc | M | PH-04 |
| 11.13 | `CMP-Splitter` | `Splitter` | Đặc | M | PH-04, PH-07 |
| 12.1 | `CMP-AppShell` | `Layout` | Canvas + glass | M | Khung ứng dụng |
| 12.2 | `CMP-Topbar` | tự dựng | `glass-chrome` / `-scrolled` | M | Khung ứng dụng |
| 12.3 | `CMP-Sidebar` | `Menu` | `glass-chrome` | M | Khung ứng dụng |
| 12.4 | `CMP-TenantSwitcher` | `Popover` | `glass-overlay` | M | Khung ứng dụng |
| 12.5 | `CMP-UserMenu` | `Dropdown` | `glass-overlay` | M | Khung ứng dụng |
| 12.6 | `CMP-CommandPalette` | `Modal` | `glass-modal` + giếng đặc | M | Khung ứng dụng |
| 12.7 | `CMP-NotificationCenter` | `Popover` | `glass-overlay` | M | Khung ứng dụng |
| 12.8 | `CMP-BackgroundTaskTray` | `Popover` | `glass-overlay` | M | PH-07, PH-04 |
| 12.9 | `CMP-ShortcutSheet` | `Modal` | `glass-modal` + giếng đặc | S | PH-04 |
| 12.10 | `CMP-FullscreenBar` | tự dựng | `glass-overlay` | S | PH-04, PH-13 |
| 12.11 | `CMP-StatusBar` | tự dựng | Đặc | S | PH-07 |
| 13.1 | `CMP-EditableTable` (`CMP-EnumEditor`) | EditableProTable / ảo hóa | Đặc | M | PH-07 |
| 13.2 | `CMP-KeyValueEditor` | `Form.List` | Đặc | M | PH-04 |
| 13.3 | `CMP-DynamicForm` | `CMP-Form` + Ajv | Đặc | M | PH-07, PH-04 |
| 13.4 | `CMP-SchemaTree` | `CMP-Tree` | Đặc | M | PH-04 |
| 13.5 | `CMP-TreeGrid` | `Table` cây | Đặc | M | PH-04 |
| 13.6 | `CMP-DiffTable` | `CMP-DataTable` | Đặc | M | PH-07 |
| 13.7 | `CMP-VersionTimeline` | SVG | Đặc | S | PH-07 |
| 13.8 | `CMP-DependencyGraph` | XYFlow chỉ đọc | Đặc | S | PH-04 |
| 13.9 | `CMP-CommentThread` | `CMP-Timeline` | Đặc | S | PH-04 |
| 13.10 | `CMP-DecisionPanel` | `CMP-Card` | Đặc | M | PH-07 |
| 13.11 | `CMP-EnvCard` | `CMP-Card` | Đặc | M | PH-04 |
| 13.12 | `CMP-EmbeddedDashboard` | `CMP-Chart` | Đặc | S | PH-04 |
| 13.13 | `CMP-Wizard` | `CMP-Steps` + `CMP-Form` | Đặc | M | PH-01, PH-04, PH-07 |

: Bảng tổng hợp thành phần phức hợp và tổ chức

Tổng cộng 75 thành phần phức hợp và tổ chức (77 mã kể cả `CMP-EntityTab`, `CMP-EnumEditor`). Cộng 44 thành phần nguyên tử ở D03-05-03 và hai thành phần nền tảng ở D03-05-01 (`CMP-GlassSurface`, `CMP-ThemeProvider`), design system có 121 thành phần.

### 14.2. Tên gọi khác đã gặp trong tài liệu phân hệ

| Tên đã dùng | Tên chuẩn | Ghi chú |
|---|---|---|
| `CMP-EditableGrid` | `CMP-EditableTable` | PH-07 |
| `CMP-TreeView` | `CMP-Tree` | PH-07 |
| `CMP-StatCard` | `CMP-KpiCard` biến thể `filter` | Thẻ đếm bấm để lọc: `aria-pressed`, không có sparkline |
| `CMP-Descriptions` | `CMP-DescriptionList` | PH-04 |
| `CMP-JsonTree` | `CMP-JsonViewer` (hiển thị cây là mặc định) | PH-04 |
| `CMP-AuditTimeline` | `CMP-AuditTrail` | PH-04 |
| `CMP-LineageTimeline` | `CMP-Timeline` biến thể `status`, nhóm theo phiên bản | PH-07 |
| `CMP-SelectionBar` | `CMP-BulkActionBar` biến thể `floating` | Thanh chọn nhiều nổi trên canvas, `glass-overlay` |
| `CMP-FilterChips` | `CMP-FilterBar` phần (7) hàng nhãn bộ lọc | PH-04 |
| `CMP-FilterDrawer` | `CMP-FilterBar` biến thể `embedded` trong `CMP-Drawer` | PH-04 |
| `CMP-ConflictDialog` | `CMP-DiffViewer` biến thể `conflict` trong `CMP-Modal` `lg` (mục 9.4.1) | PH-07 |
| `CMP-DecisionPanel` | Đã thành thành phần chính thức (13.10) | |

: Tên gọi khác đã gặp trong tài liệu phân hệ

`CMP-KpiCard` có thêm biến thể `filter` từ bản 0.2: cả thẻ là nút bật tắt (`aria-pressed`) dùng làm bộ lọc nhanh trên danh sách (PH-07 UI-07-01, UI-07-06); thẻ đang bật có viền 2px `color-accent` và nền `color-accent-subtle`; không có sparkline và liên kết.

### 14.3. Checklist nghiệm thu thành phần phức hợp

- [ ] Có story cho mọi trạng thái ghi ở bảng đặc tả, ở sáng, tối, kính `full` và `off`; với nhóm 11 có thêm story mật độ Gọn và thu phóng 25%, 100%, 400%.
- [ ] axe-core 0 vi phạm A/AA; thử thủ công với NVDA cho `CMP-DataTable`, `CMP-EditableTable`, `CMP-Form`, `CMP-Modal`, `CMP-FlowCanvas` + `CMP-TreeGrid` `structure`, `CMP-AppShell`.
- [ ] Vật liệu khớp bảng mục 2.1 và mục 14.1; không có kính chồng kính ngoài ngoại lệ đã nêu; không quá bốn lớp `backdrop-filter` đồng thời trên story màn đầy đủ.
- [ ] Mọi thao tác kéo có phương án bàn phím (WCAG 2.5.7) và có kiểm thử Playwright chỉ dùng bàn phím.
- [ ] Thành phần dữ liệu hiển thị đủ năm trạng thái mục 2.2 và nhận lỗi dạng `DhApiError` (mục 2.4).
- [ ] Hành động hiển thị theo `allowedActions` và `disabledReasons` (mục 2.3).
- [ ] Khóa truy vấn bắt đầu bằng mã tenant; đổi tenant không để lại dữ liệu cũ.
- [ ] Hiệu năng: `CMP-DataTable` 10.000 dòng, `CMP-EditableTable` 50.000 × 30, `CMP-FlowCanvas` 300 nút, `CMP-LogViewer` 1 triệu dòng đạt 60 khung/giây khi cuộn hoặc kéo trên máy chuẩn.
- [ ] Không có tên `CMP-*` ngoài danh mục mục 14.1 và D03-05-03 §9 trong mã và tài liệu (công cụ `check-cmp.py`, D03-05-03 §12).

### 14.4. Truy vết

| Yêu cầu | Đáp ứng tại |
|---|---|
| RB-03 React + antd v6, Liquid Glass | Toàn bộ; vật liệu mục 2.1, cột Vật liệu mục 14.1 |
| NFR-00-005 hiệu năng giao diện | Mục 11.0, 13.1, 14.3 |
| NFR-00-040…045 | Mục 2, cột "Bàn phím, ARIA" từng thành phần, 14.3 |
| FR-00-003 hết phiên | `CMP-SessionTimeoutDialog` (7.7) |
| FR-00-004, FR-00-011, FR-00-012 tenant và liên tenant | `CMP-AppShell` (12.1), `CMP-TenantSwitcher` (12.4) |
| FR-00-020…023 tìm kiếm và lọc | `CMP-SearchField`, `CMP-FilterBar` (3.3, 3.4), `CMP-CommandPalette` (12.6) |
| FR-00-031, FR-00-054 xuất lớn, tác vụ nền | `CMP-DataTable` (8.1.8), `CMP-JobProgress` (10.3), `CMP-BackgroundTaskTray` (12.8) |
| FR-00-050…052 xác nhận, xóa mềm, xung đột | `CMP-ConfirmDialog`, `CMP-ReasonDialog` (7.3, 7.4), `CMP-DiffViewer` (9.4.1), `CMP-EditableTable` (13.1) |
| FR-00-060…062 thông báo | `CMP-NotificationCenter` (12.7), `CMP-Notification` (5.4) |
| FR-00-070…072 duyệt | `CMP-ApprovalPanel` (10.2), `CMP-DecisionPanel` (13.10) |
| FR-00-080, FR-00-081 lỗi | Mục 2.4, `CMP-Alert`, `CMP-Form` |
| FR-04-010, 013, 016, 017, 026 (trình thiết kế PH-04) | Mục 11, `CMP-TreeGrid` (13.5), `CMP-CommentThread` (13.9) |
| D03-06-PH04 §27.3 | Mục 11, 12.9, 12.10, 13.2, 13.4, 13.5, 13.11; phần nguyên tử ở D03-05-03 |
| D03-06-PH07 Phụ lục A-05 | 13.1, 13.6, 13.10, 12.8, 9.1; `CMP-CronPicker` ở D03-05-03 |

: Truy vết

### 14.5. Đề xuất bổ sung

1. D03-04 bổ sung hợp đồng dùng chung "tác vụ nền của người dùng" (danh sách, SSE, hủy) cho `CMP-BackgroundTaskTray` và "bình luận có neo" cho `CMP-CommentThread`, để các phân hệ không tự định nghĩa.
2. D03-04 bổ sung định nghĩa bảng điều khiển nhúng của PH-13 (JSON) cho `CMP-EmbeddedDashboard`.
3. D03-06-PH04 và D03-06-PH07 đổi tên thành phần theo bảng 14.2 ở lần cập nhật kế tiếp (bản 0.2 của tập này đã đổi sẵn các tên trùng nghĩa trực tiếp).
