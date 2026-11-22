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
| Biến thể | `default`, `with-spark`, `status` (giá trị là trạng thái sức khỏe, dùng `CMP-StatusTag`). |
| Kích thước | Giá trị `font-display`; nhãn `font-footnote`; cao tối thiểu 120px; lưới 4 cột từ `bp-xxl`, 2 cột dưới `bp-xl`. |
| Trạng thái | Đang tải (Skeleton giá trị), sẵn sàng, không có dữ liệu kỳ trước (ẩn chỉ báo thay đổi, ghi "Chưa đủ dữ liệu so sánh"), lỗi (giá trị "—" kèm biểu tượng cảnh báo và Tooltip lỗi). |
| Token | `font-display`, `font-feature-tabular`, `font-footnote`, `color-success-text`, `color-error-text`, `color-text-secondary`. |
| Bàn phím, ARIA | Toàn thẻ có nhãn đọc liền mạch: "Lượt gọi API hôm nay: 1.234.567, tăng 12,5% so với 7 ngày trước"; sparkline `aria-hidden="true"` vì giá trị đã có ở chữ. |
| Nội dung | Chiều tăng không mặc định là tốt: thành phần nhận `goodDirection` để tô `color-success-text` hay `color-error-text` (ví dụ tỷ lệ lỗi tăng là xấu); màu luôn kèm mũi tên và chữ "tăng"/"giảm". |
| Điều cấm | Không làm tròn mất nghĩa (dùng "1,2 triệu" chỉ khi có Tooltip giá trị đầy đủ); không chỉ dùng màu để báo tăng giảm. |

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

