---
ma_tai_lieu: D03-05-04
ten: Thành phần phức hợp và tổ chức
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Kỹ sư giao diện, Nhà thiết kế, Kiểm thử viên, AI agent sinh mã
nguoi_lap: Luồng giao diện
---

# D03-05-04 · Thành phần phức hợp và tổ chức

## 1. Mục đích, phạm vi và cách đọc

Tài liệu này đặc tả 49 thành phần phức hợp (composite) và thành phần tổ chức (organism) của design system Datahub, đóng gói trong `@datahub/ui`. Thành phần phức hợp là tổ hợp của các thành phần nguyên tử ở D03-05-03 (ví dụ `CMP-FormField` ghép nhãn, điều khiển, mô tả và thông báo lỗi); thành phần tổ chức là khối giao diện lớn mang nghiệp vụ dùng chung (ví dụ `CMP-DataTable`, `CMP-ApprovalPanel`) hoặc khung ứng dụng (`CMP-AppShell`, `CMP-Topbar`, `CMP-Sidebar`). Mẫu màn hình PTN-01…14 ở D03-06-00 được lắp hoàn toàn từ các thành phần trong tài liệu này, nên mọi hành vi dùng chung của FR-00 (danh sách, lọc, xuất, xác nhận, xung đột, lịch sử, duyệt, thông báo, lỗi) được hiện thực đúng một lần ở đây và mọi phân hệ kế thừa.

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
| 11 | Canvas thiết kế | `CMP-FlowCanvas`, `CMP-FlowNode`, `CMP-NodePalette`, `CMP-Inspector` |
| 12 | Khung ứng dụng | `CMP-AppShell`, `CMP-Topbar`, `CMP-Sidebar`, `CMP-TenantSwitcher`, `CMP-UserMenu`, `CMP-CommandPalette`, `CMP-NotificationCenter` |

## 2. Quy tắc chung cho mọi thành phần phức hợp

### 2.1. Quy tắc vật liệu

Vật liệu là quyết định thiết kế quan trọng nhất của mỗi thành phần, vì đặt sai glass sẽ làm hỏng tương phản (NFR-00-041) và hiệu năng (NFR-00-005). Quy tắc dưới đây áp dụng cho toàn bộ tài liệu; cột "Vật liệu" trong bảng đặc tả từng thành phần chỉ được chọn trong năm giá trị của bảng.

| Vật liệu | Lớp CSS | Được dùng cho | Điều kiện bắt buộc |
|---|---|---|---|
| `glass-chrome` | `.dh-glass--chrome` | Sidebar; topbar khi chưa có nội dung cuộn dưới nó; NodePalette và Inspector khi gắn mép bên cạnh vùng canvas | Chỉ đặt trên `color-canvas` (kèm `color-canvas-wash`), nơi phông nền do hệ thống kiểm soát; không đặt trên nội dung có thể cuộn hoặc di chuyển bên dưới |
| `glass-chrome-scrolled` | `.dh-glass--chrome-scrolled` | Topbar khi nội dung đang cuộn bên dưới | Chuyển tự động khi `scrollTop > 0` của vùng nội dung; kèm dải `glass-scroll-edge` |
| `glass-modal` | `.dh-glass--modal` | Khung Modal, Drawer, CommandPalette, khung Drawer của sidebar dưới `bp-lg` | Nội dung đặt trong giếng nội dung (content well) nền `color-surface-solid`, bo góc đồng tâm; không đặt chữ liên kết cỡ thường trực tiếp trên khung |
| `glass-overlay` | `.dh-glass--overlay` | Popover, DropdownMenu, popup của Select/DatePicker/TreeSelect, Notification, NotificationCenter, popup của TenantSwitcher và UserMenu | Nội dung đặt trực tiếp lên glass vì vật liệu đạt ngưỡng mọi nấc chữ ở trường hợp xấu nhất |
| Nền đặc | không lớp glass | Bảng, biểu mẫu, thẻ, log, mã, so sánh, biểu đồ, nút trên canvas, minimap, BulkActionBar, giếng nội dung | `color-surface-solid` hoặc `color-surface-solid-2`; Tooltip và Toast dùng nền đảo `color-surface-inverse` |

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

**Hành vi chi tiết.** Thứ nhất, FilterBar giữ một bản nháp điều kiện trong trạng thái cục bộ; chỉ khi người dùng bấm "Tìm kiếm" hoặc Enter, bản nháp mới được ghi lên URL bằng `setSearchParams` (thay `replace` cho lần ghi đầu, `push` cho các lần sau để nút quay lại của trình duyệt hoạt động) và trang về 1. Bộ lọc dạng Select đơn hoặc Segmented có thể áp dụng ngay khi đổi nếu SDD phân hệ quy định, nhưng mặc định là áp dụng khi bấm tìm. Thứ hai, quy ước tham số URL thống nhất cho mọi danh sách được nêu ở bảng dưới, nhờ đó backend và frontend không hiểu khác nhau (bài học của docs/ui_ux_rule.md §2.2).

| Tham số URL | Ý nghĩa | Ví dụ |
|---|---|---|
| `q` | Từ khóa, đã trim | `q=da%20nang` |
| `page` | Trang, bắt đầu từ 1 trên URL (API dùng `page-1`) | `page=3` |
| `size` | Số dòng mỗi trang, thuộc 10/20/50/100 | `size=50` |
| `sort` | `{trường},{asc|desc}`; nhiều tiêu chí cách nhau bằng `;` khi bảng hỗ trợ | `sort=createdAt,desc` |
| `f.{trường}` | Giá trị lọc; nhiều giá trị cách nhau bằng dấu phẩy (FR-00-023) | `f.status=PUBLISHED,SUSPENDED` |
| `f.{trường}From`, `f.{trường}To` | Khoảng thời gian, dạng `yyyy-MM-dd`, bao gồm hai đầu | `f.createdFrom=2026-11-01` |
| `adv` | Vùng nâng cao đang mở (`1`) | `adv=1` |

Thứ ba, "Đặt lại" xóa toàn bộ tham số `q`, `f.*`, giữ `size` và đưa `page` về 1 (CRUD-FLT-05). Thứ tư, "Bộ lọc đã lưu" (FR-00-024) lưu một tên do người dùng đặt cùng chuỗi tham số URL (trừ `page`) qua API tùy chọn người dùng, phạm vi theo tenant và theo màn hình; menu liệt kê bộ lọc đã lưu, cho đặt một bộ lọc làm mặc định khi mở màn hình, đổi tên và xóa. Lưu bộ lọc mở `CMP-Modal` cỡ `sm` với một trường "Tên bộ lọc" (tối đa 64 ký tự, không trùng trong phạm vi màn hình).

```ts
export interface DhFilterDef {
  name: string;                         // khóa sau tiền tố f.
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
    { name: 'status', label: 'Trạng thái', kind: 'multiSelect', basic: true, options: serviceStatusOptions },
    { name: 'owner', label: 'Cơ quan chủ quản', kind: 'treeSelect', basic: true, options: loadAgencies },
    { name: 'created', label: 'Ngày tạo', kind: 'dateRange' },
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

