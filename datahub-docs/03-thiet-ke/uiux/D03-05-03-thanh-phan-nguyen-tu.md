---
ma_tai_lieu: D03-05-03
ten: Thành phần nguyên tử
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Kỹ sư giao diện, Nhà thiết kế, Kiểm thử viên, AI agent sinh mã
nguoi_lap: Luồng giao diện
---

# D03-05-03 · Thành phần nguyên tử

## 1. Mục đích, cách đọc và quy ước chung

### 1.1. Mục đích

Tài liệu này đặc tả 36 **thành phần nguyên tử (atomic component)** của gói `@datahub/ui`. Thành phần nguyên tử là đơn vị giao diện nhỏ nhất có ý nghĩa độc lập: một nút, một ô nhập, một nhãn trạng thái, một giá trị thời gian. Chúng không chứa thành phần nguyên tử khác ngoại trừ `CMP-Icon`, `CMP-Spinner` và `CMP-Tooltip` (ba thành phần này được phép lồng vào nguyên tử khác vì đóng vai trò trang trí hoặc phụ trợ). Thành phần phức hợp như `CMP-FormField`, `CMP-DataTable`, `CMP-Modal` được ghép từ các nguyên tử ở đây và được đặc tả ở D03-05-04.

Mục tiêu của tài liệu là để kỹ sư giao diện và AI agent sinh mã có thể hiện thực từng thành phần mà không phải tự quyết định thêm về hành vi, màu sắc hay nội dung. Mọi giá trị thị giác đều đến từ token định nghĩa ở D03-05-02; tài liệu này chỉ ghi tên token (dạng `TKN-…` hoặc tên token ngắn trong dấu `` ` ``), không ghi giá trị màu thô. Quy tắc vật liệu Liquid Glass (ADR-020) và thành phần nguyên thủy `CMP-GlassSurface`, `CMP-ThemeProvider` được đặc tả ở D03-05-01; tài liệu này chỉ nêu thành phần nào được phép đặt trên glass.

Ba yêu cầu chi phối toàn bộ tài liệu là NFR-00-045 (100% màn hình dùng thành phần của `@datahub/ui`, không CSS tùy biến ngoài token), NFR-00-040 đến NFR-00-043 (WCAG 2.2 AA, tương phản, bàn phím, giảm chuyển động) và FR-00-053 (nhãn trạng thái vòng đời thống nhất). Ngoài ra một số thành phần hiện thực trực tiếp yêu cầu bảo vệ dữ liệu cá nhân của nguyên tắc NT-10 (D03-01) và FR-00-034, FR-00-040.

### 1.2. Cách đọc

Tài liệu được chia theo nhóm chức năng để người đọc tìm nhanh. Mục 2 nêu quy tắc chung về trạng thái tương tác áp dụng cho mọi thành phần tương tác, nên phải đọc trước khi đọc từng thành phần. Mục 3 đến mục 8 đặc tả từng thành phần, theo thứ tự: hành động (mục 3), chữ và biểu tượng (mục 4), chỉ báo và nhãn (mục 5), phản hồi tiến trình và gợi ý (mục 6), nhập liệu (mục 7), hiển thị dữ liệu nghiệp vụ (mục 8). Mục 9 là bảng tổng hợp, mục 10 là checklist nghiệm thu, sau đó là Truy vết và Đề xuất bổ sung D00-01.

Từ "phải" diễn đạt quy tắc bắt buộc, kiểm tra được trong review mã hoặc kiểm thử tự động. Từ "nên" diễn đạt khuyến nghị, được phép làm khác khi có lý do ghi trong mô tả PR. Từ "cấm" diễn đạt hành vi mà lint, test hoặc reviewer phải chặn.

### 1.3. Khung đặc tả của một thành phần

Mỗi thành phần ở mục 3 đến mục 8 có cùng một khung để người đọc biết chỗ tìm thông tin. Bảng dưới đây giải thích từng mục trong khung. Thành phần đơn giản (ví dụ `CMP-Divider`) có thể gộp vài mục vào một đoạn, nhưng không được bỏ mục "Điều cấm" và "API".

| Mục | Nội dung | Vì sao cần |
|---|---|---|
| Mã và mục đích | Mã `CMP-…`, một đoạn nói thành phần giải quyết việc gì | Truy vết từ màn hình `UI-{PH}-{nn}` tới thành phần |
| Khi dùng / không dùng | Tình huống đúng và tình huống phải chọn thành phần khác | Tránh hai thành phần cùng làm một việc trên các màn hình khác nhau |
| Nền antd | Thành phần antd v6 được bọc và các prop bị cố định | Kỹ sư biết prop nào không được truyền từ ngoài vào |
| Biến thể | Các dạng thị giác hợp lệ và quy tắc chọn | Giữ danh sách biến thể nhỏ, có kiểm soát |
| Kích thước | `sm` / `md` / `lg` ánh xạ sang `size-control-*` | Thống nhất chiều cao giữa các điều khiển đặt cạnh nhau |
| Trạng thái | Trạng thái nào thành phần hỗ trợ, biểu hiện ra sao | Nguồn của danh sách story bắt buộc |
| Token | Tên token D03-05-02 thành phần dùng | Kiểm tra lint "không giá trị thô" (D03-05-02 §15) |
| Nền đặt | Chỉ trên nền đặc, hay đặt được trên glass | Bảo đảm tương phản NFR-00-041 |
| Bàn phím và ARIA | Phím, vai trò, thuộc tính ARIA | NFR-00-042, kiểm thử với NVDA |
| Nội dung tiếng Việt | Quy tắc viết nhãn, thông báo | Văn phong thống nhất toàn hệ thống |
| API | Interface TypeScript và ví dụ TSX | Hợp đồng lập trình, AI agent sinh mã dựa vào đây |
| Điều cấm | Những cách dùng sai đã biết | Danh sách để reviewer kiểm |

### 1.4. Quy ước API chung của `@datahub/ui`

Phần này quy định cách mọi thành phần nguyên tử phơi bày API. Quy ước được kiểm tra bằng lint (`eslint-plugin-datahub-ui`, đề xuất bổ sung ở cuối tài liệu) và bằng test kiểu (`tsd`).

**Bọc antd, không tái xuất nguyên trạng.** Mỗi thành phần có nền antd là một hàm bọc mỏng, không phải `export { Button } from 'antd'`. Hàm bọc làm ba việc: cố định các prop antd không được phép đổi (ví dụ `Button` luôn có `autoInsertSpace={false}` vì antd tự chèn khoảng trắng giữa hai chữ Hán, không hợp với tiếng Việt), ánh xạ prop ngữ nghĩa của Datahub sang prop antd (ví dụ `variant="tinted"` thành `color="primary" variant="filled"`), và gắn lớp CSS vật liệu khi cần. Ứng dụng `dh-console` và `dh-portal` bị lint cấm import trực tiếp từ `antd` cho các thành phần đã có trong `@datahub/ui` (quy tắc `no-restricted-imports`). Ngoại lệ duy nhất là kiểu dữ liệu (`import type`) và các tiện ích không hiển thị như `Grid.useBreakpoint`.

**Tên prop.** Prop dùng camelCase tiếng Anh, trùng tên với antd khi cùng nghĩa (`disabled`, `loading`, `size`, `placeholder`, `value`, `onChange`) để kỹ sư quen antd không phải học lại. Prop có nghĩa riêng của Datahub dùng tên mô tả vai trò, không mô tả hình thức: `tone="error"` chứ không `color="red"`; `status="PUBLISHED"` chứ không `label="Đã công bố"`. Kích thước luôn là `size?: 'sm' | 'md' | 'lg'`, mặc định `'md'`, và được ánh xạ sang `small` / `middle` / `large` của antd trong hàm bọc. Prop boolean mặc định là `false` và đặt tên khẳng định (`readOnly`, `required`, `block`), không đặt tên phủ định (`notEditable`).

**Chuyển tiếp ref (ref forwarding).** Với React 19, `ref` là một prop thường; mọi thành phần nguyên tử nhận `ref` và gắn vào phần tử DOM tương tác chính (nút `<button>`, ô `<input>`), hoặc vào đối tượng ref của antd khi antd phơi bày phương thức (ví dụ `InputRef` có `focus()`). Kiểu ref được khai báo tường minh trong interface, ví dụ `ref?: React.Ref<HTMLButtonElement>`. Lý do là `CMP-FormField` cần focus vào trường lỗi đầu tiên khi gửi biểu mẫu (FR-00-081), và `CMP-Modal` cần đặt focus ban đầu.

**`data-testid`.** Mọi thành phần nhận prop `testId?: string` và hiển thị thành `data-testid` trên phần tử gốc. Với thành phần có phần tử con cần kiểm thử riêng (ví dụ nút "Hiện" trong `CMP-MaskedValue`), thành phần tự sinh `data-testid` theo mẫu `{testId}__{phần}` (ví dụ `api-key__reveal`). Kiểm thử Playwright ưu tiên truy vấn theo vai trò và tên truy cập (`getByRole('button', { name: 'Lưu' })`), chỉ dùng `data-testid` khi không có tên truy cập ổn định.

**Không spread prop antd tùy tiện.** Cấm khai báo `interface DhButtonProps extends ButtonProps` rồi `{...rest}` xuống antd, vì làm vậy mở toàn bộ bề mặt antd (gồm `style`, `color` preset, `ghost`) và phá vỡ tính thống nhất. Interface của Datahub liệt kê tường minh từng prop được phép, có thể dùng `Pick<ButtonProps, 'htmlType' | 'href'>` cho prop lấy nguyên từ antd. Thuộc tính HTML chung được phép chuyển tiếp qua một tập kiểm soát: `id`, `aria-*`, `data-*` (trừ `data-testid` đã có prop riêng), `tabIndex`, `title` cấm (dùng `CMP-Tooltip`). Prop `style` bị cấm trên mọi nguyên tử; `className` được phép nhưng lint cảnh báo khi lớp không thuộc tiền tố `dh-` (lớp tiện ích bố cục như khoảng cách được cấp qua thành phần bố cục, không qua nguyên tử).

**Chuỗi hiển thị và i18n.** Giao diện hiện chỉ có tiếng Việt, nhưng mọi chuỗi cố định bên trong thành phần (ví dụ "Sao chép", "Đã sao chép", "Hiện", "Ẩn", "Đang tải") đến từ một từ điển `dhMessages` trong `@datahub/ui/i18n`, khóa dạng `ui.copyButton.copied`. Thành phần không chứa chuỗi tiếng Việt viết cứng trong JSX. Chuỗi nghiệp vụ (nhãn nút, tiêu đề) do màn hình truyền vào. Locale antd được đặt `vi_VN` trong `CMP-ThemeProvider`, và dayjs dùng locale `vi` cùng plugin `utc`, `timezone` với múi giờ mặc định `Asia/Ho_Chi_Minh`. Định dạng số, tiền, ngày luôn đi qua các hàm `formatNumber`, `formatMoney`, `formatDate`, `formatDateTime` của `@datahub/ui/format` để không có hai cách định dạng khác nhau.

**Mật độ.** Thành phần không nhận prop mật độ. Mật độ "Gọn" được áp toàn cục qua `data-density` và `theme.compactAlgorithm` (D03-05-02 §12.4); token `size-control-md`, `size-control-lg` tự đổi giá trị.

**Điều khiển và không điều khiển.** Thành phần nhập liệu hỗ trợ cả hai chế độ: có `value` + `onChange` là điều khiển (controlled), có `defaultValue` là không điều khiển. `CMP-Form` (D03-05-04) dùng chế độ điều khiển qua `Form.Item` của antd, nên mọi thành phần nhập liệu phải chấp nhận cặp `value` / `onChange(value)` theo đúng chữ ký mà `Form.Item` truyền vào.

Ví dụ khung hàm bọc theo đúng các quy ước trên:

```tsx
// packages/ui/src/atoms/Button/Button.tsx
import { Button as AntButton } from 'antd';
import type { ButtonProps as AntButtonProps } from 'antd';
import { useDhPress } from '../../hooks/useDhPress';
import { toAntSize } from '../../utils/size';

export interface DhButtonProps extends Pick<AntButtonProps, 'htmlType' | 'href' | 'target'> {
  variant?: 'primary' | 'default' | 'tinted' | 'text' | 'danger' | 'danger-outline';
  size?: 'sm' | 'md' | 'lg';
  icon?: React.ReactNode;
  iconPlacement?: 'start' | 'end';
  loading?: boolean;
  disabled?: boolean;
  block?: boolean;
  onClick?: (e: React.MouseEvent<HTMLElement>) => void | Promise<unknown>;
  children: React.ReactNode;
  testId?: string;
  className?: string;
  ref?: React.Ref<HTMLButtonElement>;
  id?: string;
  'aria-describedby'?: string;
}
```

## 2. Quy tắc chung về trạng thái tương tác

### 2.1. Tám trạng thái

Mọi thành phần tương tác (nút, liên kết, điều khiển nhập liệu, nhãn có thể đóng) có tối đa tám trạng thái. Trạng thái không loại trừ nhau hoàn toàn: một nút có thể vừa focus vừa hover; một ô nhập có thể vừa focus vừa invalid. Bảng dưới đây định nghĩa từng trạng thái, cách kích hoạt và thứ tự ưu tiên khi chồng nhau (số nhỏ thắng khi hai trạng thái cùng muốn đổi một thuộc tính thị giác).

| Ưu tiên | Trạng thái | Kích hoạt | Ý nghĩa với người dùng |
|---|---|---|---|
| 1 | `disabled` | Prop `disabled` | Không tương tác được lúc này; nên kèm lý do qua `CMP-Tooltip` hoặc chữ mô tả |
| 2 | `loading` | Prop `loading` | Đang xử lý; chặn thao tác lặp |
| 3 | `invalid` | Prop `status="error"` hoặc `aria-invalid` từ `CMP-FormField` | Giá trị không hợp lệ, có thông báo lỗi tại trường |
| 4 | `readonly` | Prop `readOnly` | Xem được, chọn và sao chép được, không sửa được (CRUD-U-03) |
| 5 | `pressed` | `:active` hoặc phím Space/Enter đang giữ | Phản hồi nhấn tức thì |
| 6 | `focus-visible` | `:focus-visible` (focus bằng bàn phím) | Vị trí focus hiện tại |
| 7 | `hover` | `:hover` trên thiết bị có con trỏ (`@media (hover: hover)`) | Báo phần tử tương tác được |
| 8 | `default` | | Trạng thái nghỉ |

Vòng focus là ngoại lệ của thứ tự ưu tiên: nó luôn hiển thị khi phần tử có `:focus-visible`, kể cả khi phần tử đang `invalid` hoặc `pressed`, vì nó vẽ bằng `outline` bên ngoài và không tranh chấp thuộc tính với các trạng thái khác. Phần tử `disabled` không nhận focus (trừ ngoại lệ ở §2.4).

### 2.2. Bảng token theo trạng thái

Bảng dưới đây cho biết token mà mỗi trạng thái dùng, theo ba họ thành phần: điều khiển trung tính (nút default, ô nhập, Select), điều khiển nhấn (nút primary, Switch bật, Checkbox đã chọn) và mục trong danh sách (mục menu, option của Select, hàng có thể chọn). Hai cột đầu dùng cho nền đặc; với mục trong danh sách đặt trên `glass-overlay`, các lớp phủ `color-fill-*` là bán trong suốt nên tự hòa vào vật liệu.

| Trạng thái | Điều khiển trung tính | Điều khiển nhấn | Mục trong danh sách |
|---|---|---|---|
| `default` | Nền `color-surface-solid`, viền `color-border-control`, chữ `color-text-primary` | Nền `color-accent`, chữ `color-text-on-accent` | Nền trong suốt, chữ `color-text-primary` |
| `hover` | Nền `color-fill-hover` chồng lên nền, viền `color-border-control` giữ nguyên | Nền `color-accent-hover` | Nền `color-fill-hover`; mục đang chọn dùng `color-fill-selected-hover` |
| `pressed` | Nền `color-fill-pressed` + phản hồi nhấn §2.3 | Nền `color-accent-pressed` + phản hồi nhấn §2.3 | Nền `color-fill-pressed` |
| `focus-visible` | `outline: 2px solid color-focus-ring`, `outline-offset: 2px`, và `box-shadow: 0 0 0 2px color-focus-ring-inner` tạo viền kép | Như trung tính | Như trung tính, `outline-offset: -2px` (vẽ vào trong để không bị cắt bởi vùng cuộn) |
| `disabled` | Nền `color-fill-control`, viền `color-border-subtle`, chữ `color-text-disabled`, `cursor: not-allowed` | Nền `color-fill-control`, chữ `color-text-disabled` (không giữ màu nhấn mờ) | Chữ `color-text-disabled` |
| `loading` | Như default, thêm `CMP-Spinner` cỡ `size-icon-sm` hoặc `size-icon-md`, `aria-busy="true"` | Như default, spinner màu `color-text-on-accent` | Không áp dụng |
| `readonly` | Nền `color-surface-solid-2`, viền `color-border-subtle`, chữ `color-text-primary` (không làm mờ chữ vì người dùng vẫn cần đọc) | Không áp dụng | Không áp dụng |
| `invalid` | Viền `color-error-text`, khi focus quầng dùng `color-error-bg`; biểu tượng lỗi `color-error-text` ở hậu tố | Không áp dụng | Không áp dụng |

Thời lượng chuyển trạng thái màu là `motion-duration-instant` với `motion-ease-standard`. Vòng focus xuất hiện tức thì, không chuyển động, để người dùng bàn phím không phải chờ.

Viền kép của vòng focus được hiện thực một lần trong lớp tiện ích `.dh-focus-ring` của `@datahub/ui` và được gắn vào mọi thành phần, không để từng thành phần tự vẽ. Antd v6 có token `lineWidthFocus` và `controlOutline` (D03-05-02 §13.2) tạo quầng focus cho ô nhập; quầng đó được giữ như lớp bổ sung, không thay vòng focus kép, vì quầng `controlOutline` có alpha 0,35 không đạt 3:1 trên mọi nền.

### 2.3. Phản hồi nhấn kiểu Liquid Glass

Antd mặc định tạo hiệu ứng "sóng" (wave) lan ra từ viền khi bấm nút, Checkbox, Radio, Switch. Hiệu ứng này mang ngôn ngữ thiết kế riêng của antd và không hợp với Liquid Glass. Datahub tắt wave toàn cục trong `CMP-ThemeProvider` bằng `ConfigProvider wave={{ disabled: true }}` và thay bằng **phản hồi nhấn (press feedback)** gồm hai hiệu ứng chạy đồng thời:

1. **Sáng bề mặt.** Một lớp giả `::after` phủ toàn bề mặt thành phần, nền là `color-border-glass-highlight`, độ đục chuyển từ 0 lên 0,5 khi nhấn, gợi cảm giác ánh sáng dồn vào điểm ấn trên mặt kính. Với nút primary và danger, lớp sáng chồng lên nền `color-accent-pressed` hoặc `color-error-solid`, nên chữ trắng vẫn đạt tương phản (lớp sáng chỉ tồn tại trong thời gian nhấn, dưới 200ms trong thao tác bình thường, và được tính vào ngoại lệ trạng thái tạm thời giống `color-accent-hover`).
2. **Thu nhỏ.** `transform: scale(0.98)` trên toàn thành phần, thời lượng `motion-duration-instant` khi nhấn xuống và `motion-duration-fast` với `motion-ease-emphasized` khi thả ra, tạo cảm giác vật liệu có đàn hồi.

Phản hồi nhấn được đóng gói trong hook `useDhPress()` và lớp `.dh-press`, được áp cho `CMP-Button`, `CMP-IconButton`, `CMP-CopyButton`, nút trong `CMP-SegmentedControl`, `CMP-Switch` (chỉ áp lên nút gạt), `CMP-Checkbox` và `CMP-Radio` (chỉ áp lên ô chọn). Không áp cho `CMP-Link` (liên kết là chữ, thu nhỏ chữ gây rung khó đọc) và không áp cho ô nhập.

Khi `prefers-reduced-motion: reduce` hoặc công tắc "Giảm chuyển động" bật, hiệu ứng thu nhỏ bị tắt hoàn toàn; hiệu ứng sáng bề mặt vẫn giữ nhưng chuyển tức thì (0ms), vì đó là thay đổi độ đục, thuộc ngoại lệ "mờ dần được giữ" của D03-05-02 §11. Trong chế độ glass "Tắt", lớp sáng bề mặt được thay bằng `color-fill-pressed` để không còn hiệu ứng ánh sáng.

```css
/* packages/ui/src/styles/press.css */
.dh-press { position: relative; transition: transform var(--dh-motion-duration-fast) var(--dh-motion-ease-emphasized); }
.dh-press::after {
  content: ""; position: absolute; inset: 0; border-radius: inherit; pointer-events: none;
  background: var(--dh-color-border-glass-highlight); opacity: 0;
  transition: opacity var(--dh-motion-duration-instant) var(--dh-motion-ease-standard);
}
.dh-press:active:not([aria-disabled="true"]):not([aria-busy="true"]) {
  transform: scale(0.98); transition-duration: var(--dh-motion-duration-instant);
}
.dh-press:active:not([aria-disabled="true"]):not([aria-busy="true"])::after { opacity: 0.5; }
[data-glass="off"] .dh-press::after { background: var(--dh-color-fill-pressed); }
@media (prefers-reduced-motion: reduce) { .dh-press, .dh-press:active { transform: none; } }
[data-motion="reduced"] .dh-press, [data-motion="reduced"] .dh-press:active { transform: none; }
```

Thuộc tính `data-motion` trên `<html>` do `CMP-ThemeProvider` đặt khi người dùng bật công tắc trong cài đặt (D03-05-01). Nếu D03-05-01 chọn tên thuộc tính khác, `press.css` theo tên của D03-05-01.

### 2.4. Vô hiệu hóa và chỉ đọc

Thành phần bị vô hiệu bằng `disabled` không nhận focus và không được trình đọc màn hình đọc là có thể kích hoạt. Điều này gây một vấn đề: người dùng bàn phím không thể focus vào nút để đọc tooltip giải thích vì sao nút bị khóa. Datahub giải quyết như sau. Khi màn hình cần giải thích lý do (ví dụ "Chỉ sửa được khi ở trạng thái Bản nháp"), thành phần nhận prop `disabledReason: string`; khi có prop này, thành phần dùng `aria-disabled="true"` thay vì thuộc tính `disabled` gốc, vẫn nhận focus, chặn sự kiện `onClick` trong hàm bọc, và gắn `CMP-Tooltip` hiển thị lý do khi hover hoặc focus. Khi không có lý do cần nói, dùng `disabled` gốc.

Tuy vậy, nguyên tắc ưu tiên của FR-00-053 là **ẩn hành động không hợp lệ ở trạng thái hiện tại** thay vì hiện rồi khóa. Nút bị vô hiệu chỉ dùng khi hành động sẽ hợp lệ sau một bước người dùng làm được ngay trên màn hình (ví dụ nút "Gửi duyệt" khóa cho tới khi biểu mẫu hợp lệ), hoặc khi ẩn nút gây khó hiểu (ví dụ nút "Lưu" khi chưa có thay đổi).

Trường chỉ đọc (`readOnly`) khác trường vô hiệu: chỉ đọc vẫn nhận focus, cho phép chọn và sao chép chữ, được đọc bởi trình đọc màn hình với `aria-readonly="true"`, và chữ giữ màu `color-text-primary`. CRUD-U-03 yêu cầu trường không sửa được trong biểu mẫu sửa phải ở trạng thái chỉ đọc, nên `readOnly` là cách mặc định cho tình huống này, không dùng `disabled`.

### 2.5. Vùng chạm và kích thước tối thiểu

Mọi phần tử tương tác có vùng chạm tối thiểu 24×24 px (WCAG 2.5.8). Với điều khiển cỡ `sm` (24px), điều này đạt sẵn. Với phần tử nhỏ hơn về thị giác (nút đóng trong `CMP-Tag` 16px, nút sao chép nhỏ trong `CMP-Identifier`), thành phần mở rộng vùng chạm bằng lớp giả `::before` với `inset: -4px` mà không đổi kích thước thị giác. Hai phần tử tương tác cạnh nhau phải cách nhau tối thiểu `space-1` để vùng chạm mở rộng không chồng nhau.

## 3. Nhóm hành động

### 3.1. CMP-Button

**Mục đích.** `CMP-Button` kích hoạt một hành động có nhãn chữ: lưu, gửi duyệt, thêm mới, xác nhận xóa. Đây là thành phần được dùng nhiều nhất và cũng là nơi dễ phá vỡ tính thống nhất nhất, nên được đặc tả chặt.

**Khi dùng.** Dùng cho hành động thay đổi dữ liệu hoặc mở một luồng (Modal, Drawer, trang biểu mẫu). **Khi không dùng.** Điều hướng sang trang khác mà không có hành động đi kèm dùng `CMP-Link`; hành động chỉ có biểu tượng dùng `CMP-IconButton`; hành động sao chép dùng `CMP-CopyButton`; nhóm nhiều hành động phụ dùng `CMP-DropdownMenu` (D03-05-04) với nút kích hoạt "Thêm" có biểu tượng `ellipsis`.

**Nền antd.** `Button` của antd v6. Hàm bọc cố định `autoInsertSpace={false}`, `shape="default"` (bo góc lấy từ token), không dùng `ghost`, không dùng `color` preset (`blue`, `purple`...), không dùng `variant="dashed"` và `variant="link"` (liên kết dùng `CMP-Link`). Prop `iconPlacement` của antd v6 được dùng thay cho `iconPosition` đã cũ.

**Biến thể.** Datahub có sáu biến thể, ánh xạ sang tổ hợp `color` + `variant` của antd v6 như bảng dưới đây. Bảng cũng nêu vai trò để người thiết kế màn hình chọn đúng.

| Biến thể | antd v6 | Vai trò | Ví dụ nhãn |
|---|---|---|---|
| `primary` | `color="primary" variant="solid"` | Hành động chính duy nhất của một vùng | "Lưu", "Thêm mới", "Gửi duyệt", "Công bố" |
| `default` | `color="default" variant="outlined"` | Hành động phụ, hủy | "Hủy", "Xuất Excel", "Xem trước" |
| `tinted` | `color="primary" variant="filled"` | Hành động phụ được nhấn mạnh hơn `default` nhưng không cạnh tranh với `primary`, đặc biệt trên nền glass | "Thêm bước", "Kiểm tra kết nối" |
| `text` | `color="default" variant="text"` | Hành động phụ mật độ cao: trong ô bảng, thanh công cụ, chân thẻ | "Đặt lại", "Bỏ chọn" |
| `danger` | `color="danger" variant="solid"` | Xác nhận hành động phá hủy trong `CMP-ConfirmDialog` (CRUD-D-03) | "Xóa", "Thu hồi khóa", "Hoàn tiền" |
| `danger-outline` | `color="danger" variant="outlined"` | Mở luồng phá hủy từ trang chi tiết hoặc vùng "Nguy hiểm" ở trang cài đặt | "Xóa dịch vụ…", "Tạm dừng tenant…" |

Quy tắc chọn biến thể có bốn điểm. Thứ nhất, **mỗi vùng chỉ có tối đa một nút `primary`**; "vùng" là một trong các khối: thanh tiêu đề trang (`CMP-PageHeader`), chân Modal hoặc Drawer, chân biểu mẫu, một thẻ (`CMP-Card`), một trạng thái rỗng. Lint của Storybook và test hình ảnh kiểm tra quy tắc này bằng cách đếm phần tử `.dh-btn--primary` trong mỗi vùng có `data-dh-region`. Thứ hai, `danger` chỉ xuất hiện ở bước xác nhận cuối cùng, không ở bước mở luồng; bước mở luồng dùng `danger-outline` và nhãn kết thúc bằng dấu ba chấm "…" để báo sẽ có bước tiếp theo. Thứ ba, trên nền glass (topbar, chân Modal nằm ngoài giếng nội dung) dùng `primary`, `tinted` hoặc `text`; không dùng `default` vì viền `color-border-control` trên glass bị nhòe với phông nền. Thứ tư, thứ tự nút trong một nhóm theo chiều đọc: hành động phụ bên trái, hành động chính ngoài cùng bên phải (CRUD-UI-03).

**Kích thước.** `sm` cao `size-control-sm`, đệm ngang `space-2`, biểu tượng `size-icon-sm`, chữ `font-body-strong` 14px (không giảm cỡ chữ ở `sm` để dấu tiếng Việt không bị nén), bo `radius-sm`. `md` cao `size-control-md`, đệm ngang `space-4`, biểu tượng `size-icon-md`, bo `radius-md`. `lg` cao `size-control-lg`, đệm ngang `space-5`, biểu tượng `size-icon-md`, chữ `font-callout` độ đậm 500, bo `radius-md`. Khoảng giữa biểu tượng và nhãn là `space-1` ở `sm` và `space-2` ở `md`, `lg`. Cỡ `lg` chỉ dùng cho hành động chính trong trạng thái rỗng, trang chào và cổng nhà phát triển.

**Trạng thái.** Nút có đủ tám trạng thái trừ `readonly` và `invalid`. Trạng thái `loading` có hành vi bắt buộc sau, hiện thực CRUD-C-04 và CRUD-C-05:

1. Khi `loading` là `true`, nút hiển thị `CMP-Spinner` thay vị trí biểu tượng (nếu có biểu tượng) hoặc trước nhãn (nếu không có), giữ nguyên nhãn và chiều rộng (đặt `min-width` bằng chiều rộng đo được trước khi chuyển để nút không co giật), đặt `aria-busy="true"` và `aria-disabled="true"`, và chặn mọi `onClick` trong hàm bọc.
2. Khi `onClick` trả về một `Promise`, hàm bọc **tự chuyển sang `loading`** cho tới khi promise kết thúc (thành công hay lỗi), kể cả khi màn hình không truyền prop `loading`. Đây là lớp chặn bấm lặp thứ hai, phòng trường hợp màn hình quên quản lý trạng thái.
3. Spinner chỉ hiện sau 150ms kể từ khi bắt đầu chờ để tránh nhấp nháy với thao tác nhanh, nhưng việc chặn bấm có hiệu lực ngay từ mili giây đầu tiên.
4. Trong `CMP-Form`, nút `htmlType="submit"` được nối với trạng thái `isPending` của mutation TanStack Query qua `CMP-Form`; màn hình không tự quản lý.

**Token.** `TKN-color-accent`, `TKN-color-accent-hover`, `TKN-color-accent-pressed`, `TKN-color-text-on-accent` (primary); `TKN-color-accent-subtle`, `TKN-color-accent-on-subtle`, `TKN-color-fill-selected-hover` (tinted và hover của tinted); `TKN-color-surface-solid`, `TKN-color-border-control`, `TKN-color-text-primary`, `TKN-color-fill-hover`, `TKN-color-fill-pressed` (default, text); `TKN-color-error-solid`, `TKN-color-error-text`, `TKN-color-error-bg` (danger, danger-outline; hover của danger-outline dùng nền `color-error-bg`); `TKN-color-fill-control`, `TKN-color-text-disabled` (disabled); `TKN-size-control-sm`, `TKN-size-control-md`, `TKN-size-control-lg`, `TKN-radius-sm`, `TKN-radius-md`, `TKN-font-body-strong`, `TKN-space-1`, `TKN-space-2`, `TKN-space-4`, `TKN-space-5`. Token thành phần antd được đặt ở D03-05-02 §13.3: `Button.primaryShadow`, `Button.defaultShadow`, `Button.dangerShadow` là `none`; `Button.fontWeight` là 500. Hàm bọc đặt thêm `Button.paddingInline` theo `space-4` và `Button.paddingInlineSM` theo `space-2` trong cấu hình theme (bổ sung vào bảng §13.3 của D03-05-02, ghi ở mục Đề xuất).

**Nền đặt.** `primary`, `tinted`, `text`, `danger` đặt được trên nền đặc và trên mọi vật liệu glass. `default` và `danger-outline` chỉ đặt trên nền đặc hoặc `glass-overlay`.

**Bàn phím và ARIA.** Phần tử gốc là `<button type="button">` (mặc định `htmlType="button"` để nút trong biểu mẫu không vô tình gửi biểu mẫu); khi có `href`, antd sinh `<a>` và hàm bọc không cho dùng `loading` cùng `href`. Phím Enter và Space kích hoạt. Tên truy cập là nhãn chữ; nếu nhãn bị rút gọn bằng dấu ba chấm do thiếu chỗ, `aria-label` mang nhãn đầy đủ. Nút mở menu có `aria-haspopup="menu"` và `aria-expanded` (do `CMP-DropdownMenu` gắn). Nút bật tắt (toggle) không dùng `CMP-Button`; dùng `CMP-Switch` hoặc `CMP-SegmentedControl`.

**Nội dung tiếng Việt.** Nhãn nút là **động từ** hoặc cụm động từ ngắn, viết hoa chữ cái đầu, không dấu chấm: "Lưu", "Lưu nháp", "Gửi duyệt", "Thêm dịch vụ", "Xuất Excel". Không dùng "OK", "Đồng ý" chung chung trong hộp xác nhận; nhãn nói đúng hành động sẽ xảy ra ("Xóa 3 bản ghi", "Thu hồi khóa"). Nhãn dài tối đa 3 từ trong vùng hẹp (bảng, thanh công cụ) và 5 từ ở nơi khác. Nút mở luồng có bước tiếp theo kết thúc bằng "…" (dấu ba chấm Unicode U+2026). Nhãn "Thêm mới" là nhãn chuẩn cho nút tạo trên trang danh sách (PTN-01); khi cần rõ đối tượng, dùng "Thêm {đối tượng}".

**API.**

```tsx
export interface DhButtonProps extends Pick<AntButtonProps, 'htmlType' | 'href' | 'target'> {
  /** Mặc định 'default'. Mỗi vùng tối đa một 'primary'. */
  variant?: 'primary' | 'default' | 'tinted' | 'text' | 'danger' | 'danger-outline';
  size?: 'sm' | 'md' | 'lg';
  /** Phần tử CMP-Icon; cỡ biểu tượng do nút quyết định theo size. */
  icon?: React.ReactNode;
  iconPlacement?: 'start' | 'end';
  loading?: boolean;
  disabled?: boolean;
  /** Có giá trị thì dùng aria-disabled, vẫn focus được và hiện tooltip lý do. */
  disabledReason?: string;
  block?: boolean;
  /** Trả về Promise thì nút tự loading tới khi xong. */
  onClick?: (e: React.MouseEvent<HTMLElement>) => void | Promise<unknown>;
  children: React.ReactNode;
  testId?: string;
  className?: string;
  ref?: React.Ref<HTMLButtonElement>;
}
```

```tsx
<Space>
  <Button onClick={onCancel}>Hủy</Button>
  <Button variant="primary" htmlType="submit" icon={<Icon name="save" />}>Lưu</Button>
</Space>

<Button variant="danger-outline" onClick={openDeleteDialog}>Xóa dịch vụ…</Button>

<Button variant="primary" disabledReason="Chỉ gửi duyệt được khi ở trạng thái Bản nháp">
  Gửi duyệt
</Button>
```

**Điều cấm.** Cấm hai nút `primary` trong một vùng. Cấm dùng `danger` cho nút mở luồng. Cấm tự quản lý cờ "đang gửi" bằng `useState` song song với `loading` (dùng promise hoặc `isPending`). Cấm đổi màu nút bằng `className` hay `style`. Cấm nút chỉ có biểu tượng mà không qua `CMP-IconButton`. Cấm nhãn viết hoa toàn bộ ("LƯU"). Cấm dùng `CMP-Button variant="text"` thay cho liên kết điều hướng.

### 3.2. CMP-IconButton

**Mục đích.** `CMP-IconButton` là nút chỉ có biểu tượng, dùng ở nơi chật: thao tác trên hàng bảng, thanh công cụ của trình soạn mã, nút đóng, nút làm mới. Vì không có chữ, thành phần bắt buộc có tên truy cập và tooltip (CRUD-UI-06, CRUD-UI-07).

**Khi dùng.** Hành động có biểu tượng phổ biến trong danh sách chuẩn ở §4.1 (sửa, xóa, làm mới, cài đặt cột, sao chép). **Khi không dùng.** Hành động chính của trang (luôn có chữ); hành động mà biểu tượng không nói rõ nghĩa và không có trong danh sách chuẩn (dùng `CMP-Button` có chữ).

**Nền antd.** `Button` với `icon` và không có `children`, `shape="default"`. Hàm bọc luôn bọc nút trong `CMP-Tooltip` với nội dung bằng `label`.

**Biến thể.** `text` (mặc định, nền trong suốt, hover `color-fill-hover`), `default` (có viền, dùng trong thanh công cụ cạnh `CMP-Button default`), `tinted`, `danger-text` (biểu tượng `color-error-text`, nền trong suốt; dùng cho nút xóa trên hàng bảng, vẫn mở `CMP-ConfirmDialog`). Không có biến thể `primary` vì hành động chính phải có chữ.

**Kích thước.** Nút vuông: `sm` 24×24 với biểu tượng `size-icon-sm`; `md` `size-control-md` vuông với biểu tượng `size-icon-md`; `lg` `size-control-lg` vuông với biểu tượng `size-icon-lg`. Trong ô bảng luôn dùng `sm`.

**Trạng thái.** Như `CMP-Button`, gồm cả `loading` tự động khi `onClick` trả promise (spinner thay biểu tượng). Thêm trạng thái `active` cho nút bật tắt trong thanh công cụ (ví dụ "Bật ngắt dòng" trong `CMP-LogViewer`): nền `color-fill-selected`, biểu tượng `color-accent-on-subtle`, `aria-pressed="true"`.

**Token.** `TKN-color-icon-secondary` (mặc định), `TKN-color-icon-primary` (hover), `TKN-color-fill-hover`, `TKN-color-fill-pressed`, `TKN-color-fill-selected`, `TKN-color-accent-on-subtle`, `TKN-color-error-text`, `TKN-size-control-sm`, `TKN-size-control-md`, `TKN-size-control-lg`, `TKN-size-icon-sm`, `TKN-size-icon-md`, `TKN-size-icon-lg`, `TKN-radius-sm`, `TKN-radius-md`.

**Nền đặt.** Biến thể `text` và `tinted` đặt được trên mọi vật liệu glass (topbar dùng nhiều nhất). `default` chỉ trên nền đặc hoặc `glass-overlay`.

**Bàn phím và ARIA.** `aria-label` bằng `label` là bắt buộc ở mức kiểu (prop `label` không có dấu `?`). Tooltip mở khi hover sau 400ms và khi focus bằng bàn phím ngay lập tức. Biểu tượng bên trong có `aria-hidden="true"`. Nút bật tắt dùng `aria-pressed`.

**Nội dung tiếng Việt.** `label` là cụm động từ đầy đủ, nêu đối tượng khi trên hàng bảng: "Sửa dịch vụ Tra cứu hộ tịch", không chỉ "Sửa", để người dùng trình đọc màn hình phân biệt các hàng. `CMP-DataTable` tự ghép tên đối tượng của hàng vào `label` (D03-05-04); tooltip hiển thị dạng ngắn "Sửa" qua prop `tooltip`.

**API.**

```tsx
export interface DhIconButtonProps {
  icon: React.ReactNode;
  /** Tên truy cập đầy đủ, bắt buộc. */
  label: string;
  /** Nội dung tooltip nếu khác label (thường ngắn hơn). */
  tooltip?: string;
  variant?: 'text' | 'default' | 'tinted' | 'danger-text';
  size?: 'sm' | 'md' | 'lg';
  pressed?: boolean;           // nút bật tắt
  loading?: boolean;
  disabled?: boolean;
  disabledReason?: string;
  onClick?: (e: React.MouseEvent<HTMLElement>) => void | Promise<unknown>;
  testId?: string;
  ref?: React.Ref<HTMLButtonElement>;
}
```

```tsx
<IconButton icon={<Icon name="refresh" />} label="Làm mới danh sách" tooltip="Làm mới" onClick={refetch} />
<IconButton size="sm" variant="danger-text" icon={<Icon name="delete" />}
  label={`Xóa ${row.name}`} tooltip="Xóa" onClick={() => confirmDelete(row)} />
```

**Điều cấm.** Cấm thiếu `label`. Cấm dùng biểu tượng ngoài danh sách chuẩn mà không có tooltip giải nghĩa. Cấm đặt hơn ba `CMP-IconButton` trên một hàng bảng; hành động thứ tư trở đi gộp vào menu "Thêm thao tác".

### 3.3. CMP-Link

**Mục đích.** `CMP-Link` điều hướng tới một địa chỉ: trang khác trong ứng dụng, tài liệu HDSD, trang ngoài. Liên kết là chữ có màu `color-text-link` và gạch chân khi hover.

**Khi dùng.** Tên đối tượng trong ô bảng dẫn tới trang chi tiết; liên kết "Xem tất cả"; liên kết trợ giúp theo ngữ cảnh (FR-00-082). **Khi không dùng.** Hành động thay đổi dữ liệu (dùng `CMP-Button`); mở Modal (dùng `CMP-Button variant="text"`, vì Modal không phải điều hướng).

**Nền antd.** `Typography.Link` cho liên kết ngoài; với liên kết nội bộ, hàm bọc hiển thị `Link` của React Router và áp cùng lớp kiểu, để giữ điều hướng phía client. Prop `to` dùng cho nội bộ, `href` dùng cho ngoài; truyền cả hai là lỗi kiểu.

**Biến thể.** `inline` (mặc định, trong câu chữ, luôn gạch chân để phân biệt không chỉ bằng màu theo WCAG 1.4.1), `standalone` (đứng riêng, ví dụ trong ô bảng, gạch chân chỉ khi hover và focus; được phép vì vị trí và ngữ cảnh đã báo là liên kết), `subtle` (màu `color-text-secondary`, dùng ở chân trang và breadcrumb).

**Kích thước.** Liên kết kế thừa cỡ chữ của ngữ cảnh; không có `size`.

**Trạng thái.** `default`, `hover` (`colorLinkHover` của antd, gạch chân), `focus-visible` (vòng focus kép bo `radius-xs`), `visited` không đổi màu (ứng dụng quản trị, màu đã thăm gây nhiễu), `disabled` (hiển thị chữ thường `color-text-disabled`, không phải phần tử `<a>`).

**Token.** `TKN-color-text-link`, `TKN-color-text-secondary`, `TKN-color-text-disabled`, `TKN-color-focus-ring`, `TKN-color-focus-ring-inner`, `TKN-radius-xs`.

**Nền đặt.** Nền đặc, `glass-overlay` và `glass-chrome` trên canvas. **Cấm** đặt liên kết cỡ chữ thường trực tiếp lên `glass-chrome-scrolled` và `glass-modal` vì tương phản trường hợp xấu nhất dưới 4,5:1 (D03-05-02 §5); liên kết trong Modal luôn nằm trong giếng nội dung đặc.

**Bàn phím và ARIA.** Phần tử `<a href>`. Liên kết ngoài (`external`) có `target="_blank"`, `rel="noopener noreferrer"`, biểu tượng `external-link` cỡ `size-icon-sm` sau chữ, và chữ ẩn cho trình đọc màn hình "(mở trong thẻ mới)" lấy từ `dhMessages`.

**Nội dung tiếng Việt.** Chữ liên kết nói đích đến ("Xem hướng dẫn cấu hình kết nối"), không dùng "Bấm vào đây", "Tại đây".

**API.**

```tsx
type DhLinkProps =
  | { to: string; href?: never; external?: never }
  | { href: string; to?: never; external?: boolean };

export type DhLinkBaseProps = DhLinkProps & {
  variant?: 'inline' | 'standalone' | 'subtle';
  disabled?: boolean;
  children: React.ReactNode;
  testId?: string;
  ref?: React.Ref<HTMLAnchorElement>;
};
```

```tsx
<Link variant="standalone" to={`/services/${row.id}`}>{row.name}</Link>
<Link href="https://docs.datahub.gov.vn/ket-noi" external>Xem hướng dẫn cấu hình kết nối</Link>
```

**Điều cấm.** Cấm `onClick` thay đổi dữ liệu trên `CMP-Link`. Cấm `<a>` không có `href`. Cấm liên kết chỉ phân biệt bằng màu trong đoạn văn.

### 3.4. CMP-CopyButton

**Mục đích.** `CMP-CopyButton` sao chép một chuỗi vào bộ nhớ tạm và báo đã sao chép. Thành phần được `CMP-Identifier`, `CMP-SecretField`, `CMP-CodeText` dùng lại, và được dùng độc lập cạnh khối mã, URL endpoint.

**Nền antd.** `Button` (qua `CMP-IconButton` hoặc `CMP-Button`); không dùng `Typography.copyable` của antd vì không kiểm soát được thông báo và kiểm toán.

**Biến thể.** `icon` (mặc định, `CMP-IconButton` biến thể `text` với biểu tượng `copy`) và `labeled` (`CMP-Button variant="default"` hoặc `"tinted"` có chữ "Sao chép"; dùng trong hộp thoại hiển thị bí mật).

**Kích thước.** `sm`, `md` như `CMP-IconButton` và `CMP-Button`.

**Trạng thái.** Ngoài trạng thái của nút, có trạng thái `copied`: biểu tượng đổi thành `check` màu `color-success-text`, tooltip đổi thành "Đã sao chép", giữ 2 giây rồi trở lại. Trạng thái `error` khi Clipboard API bị từ chối (trình duyệt không cho phép hoặc không phải ngữ cảnh an toàn): tooltip "Không sao chép được. Hãy chọn và sao chép thủ công." và thành phần chọn sẵn chữ nguồn nếu có tham chiếu tới phần tử nguồn.

**Token.** Như `CMP-IconButton`, thêm `TKN-color-success-text`.

**Nền đặt.** Như `CMP-IconButton`.

**Bàn phím và ARIA.** `aria-label` mặc định "Sao chép {mô tả}" (ví dụ "Sao chép mã dịch vụ"). Khi sao chép xong, một vùng `aria-live="polite"` dùng chung của `@datahub/ui` đọc "Đã sao chép"; không dùng `CMP-Toast` cho sự kiện này để tránh làm phiền.

**Nội dung và an toàn.** Thành phần nhận `value` hoặc hàm `getValue` (lấy giá trị tại thời điểm bấm, dùng cho bí mật để giá trị không nằm sẵn trong prop). Khi `sensitive` là `true`, thành phần gọi `onAudit` sau khi sao chép thành công để màn hình ghi kiểm toán hành vi sao chép dữ liệu Nhạy cảm (FR-00-040), và bộ nhớ tạm không bị xóa tự động (trình duyệt không cho phép đáng tin cậy) nhưng tooltip nhắc "Đã sao chép. Không dán vào nơi công khai.".

**API.**

```tsx
export interface DhCopyButtonProps {
  value?: string;
  getValue?: () => string | Promise<string>;
  /** Mô tả đối tượng để ghép vào aria-label: "mã dịch vụ". */
  subject: string;
  variant?: 'icon' | 'labeled';
  size?: 'sm' | 'md';
  sensitive?: boolean;
  onCopied?: () => void;
  onAudit?: () => void;
  testId?: string;
}
```

```tsx
<CopyButton value={endpointUrl} subject="địa chỉ endpoint" />
```

**Điều cấm.** Cấm dùng `document.execCommand('copy')` trừ nhánh dự phòng có kiểm thử. Cấm báo "Đã sao chép" khi chưa chắc chắn promise `navigator.clipboard.writeText` thành công.

## 4. Nhóm chữ và biểu tượng

### 4.1. CMP-Icon

**Mục đích.** `CMP-Icon` hiển thị một biểu tượng từ thư viện Lucide React với nét 1,75 (ADR-022). Mọi biểu tượng trong ứng dụng đi qua thành phần này, không import trực tiếp `lucide-react` trong màn hình, để có một chỗ duy nhất quy định nét, kích thước, màu và danh sách tên chuẩn. Biểu tượng mặc định của antd (`@ant-design/icons`) chỉ còn xuất hiện bên trong thành phần antd mà Datahub không thay được; khi thay được (mũi tên Select, biểu tượng lịch DatePicker, biểu tượng đóng Tag), hàm bọc truyền biểu tượng Lucide qua prop `suffixIcon`, `closeIcon`, `prefix` tương ứng.

**Khi dùng.** Đi kèm chữ trong nút, mục menu, nhãn; đứng riêng trong `CMP-IconButton`; biểu tượng trạng thái trong `CMP-StatusTag`. **Khi không dùng.** Ảnh minh họa trạng thái rỗng (dùng ảnh minh họa của `CMP-EmptyState`); biểu tượng thương hiệu, logo đơn vị (dùng ảnh).

**Nền.** `lucide-react`, mỗi biểu tượng import riêng theo tên để cây bỏ mã thừa (tree-shaking) hoạt động. `CMP-Icon` nhận `name` thuộc kiểu hợp `DhIconName` được sinh từ bảng ánh xạ dưới đây; nhờ vậy màn hình viết `name="delete"` theo nghĩa, không viết `Trash2` theo hình. Khi cần biểu tượng ngoài bảng, kỹ sư thêm vào bảng ánh xạ trong `@datahub/ui/icons/registry.ts` qua PR có review của Luồng giao diện, không dùng biểu tượng Lucide trực tiếp.

**Kích thước.** `sm` = `size-icon-sm` (14px), `md` = `size-icon-md` (16px, mặc định), `lg` = `size-icon-lg` (20px). Nét luôn 1,75 ở mọi kích thước, đặt qua `strokeWidth={1.75}` và `absoluteStrokeWidth` để nét không mảnh đi ở cỡ nhỏ. Biểu tượng đứng cạnh chữ được căn giữa theo chiều cao dòng bằng `vertical-align: -0.125em` (cỡ `md` trong chữ 14px).

**Màu.** Biểu tượng mặc định kế thừa `currentColor` từ chữ chứa nó. Prop `tone` đặt màu riêng: `secondary` dùng `color-icon-secondary`, `success` / `warning` / `error` / `info` dùng `color-{trạng thái}-text` (riêng `warning` trên nền đặc dùng `color-warning-text` chứ không dùng `color-warning-solid`, vì `-solid` của warning chỉ dành cho biểu tượng có viền tối kèm theo như ghi chú D03-05-02 §4.4).

**Trang trí hay mang nghĩa.** Biểu tượng có hai vai trò và thành phần phải biết vai trò nào:

1. **Trang trí** (mặc định): biểu tượng đứng cạnh chữ đã nói đủ nghĩa (nút "Lưu" có biểu tượng đĩa). Thành phần đặt `aria-hidden="true"` và `focusable="false"`.
2. **Mang nghĩa**: biểu tượng là nguồn thông tin duy nhất tại vị trí đó (biểu tượng khóa cạnh tên trường cho biết trường đã mã hóa). Màn hình truyền `label`; thành phần đặt `role="img"` và `aria-label={label}`, đồng thời màn hình phải có `CMP-Tooltip` hiển thị cùng nội dung cho người dùng nhìn thấy.

**Danh sách biểu tượng chuẩn.** Bảng dưới đây là danh sách tên chuẩn cho hành động và khái niệm phổ biến. Mỗi khái niệm chỉ có một biểu tượng trên toàn hệ thống, và mỗi biểu tượng chỉ mang một nghĩa. Cột "Lucide" là tên thành phần trong `lucide-react` tại thời điểm viết; nếu Lucide đổi tên, chỉ bảng ánh xạ thay đổi.

| Tên `DhIconName` | Lucide | Nghĩa và nơi dùng |
|---|---|---|
| `add` | `Plus` | Thêm mới bản ghi, thêm dòng, thêm bước |
| `edit` | `Pencil` | Sửa |
| `delete` | `Trash2` | Xóa (luôn mở xác nhận) |
| `view` | `Eye` | Xem chi tiết; hiện giá trị đã che trong `CMP-MaskedValue` |
| `hide` | `EyeOff` | Ẩn giá trị, che lại |
| `download` | `Download` | Tải xuống tệp, xuất Excel/CSV |
| `upload` | `Upload` | Tải lên tệp, nhập dữ liệu |
| `refresh` | `RefreshCw` | Làm mới dữ liệu đang xem |
| `filter` | `ListFilter` | Mở hoặc thu gọn bộ lọc nâng cao |
| `filter-reset` | `FilterX` | Đặt lại bộ lọc (luôn có tooltip, CRUD-UI-07) |
| `columns` | `Settings2` | Cài đặt cột hiển thị của bảng (luôn có tooltip) |
| `copy` | `Copy` | Sao chép vào bộ nhớ tạm |
| `copied` | `Check` | Đã sao chép, đã chọn |
| `external` | `ExternalLink` | Mở ở thẻ mới, liên kết ra ngoài |
| `search` | `Search` | Tìm kiếm |
| `close` | `X` | Đóng Modal, Drawer, xóa giá trị, đóng nhãn |
| `more` | `Ellipsis` | Menu thêm thao tác |
| `chevron-down` | `ChevronDown` | Mở danh sách chọn, mở rộng |
| `chevron-right` | `ChevronRight` | Mở rộng nút cây, đi tiếp |
| `back` | `ArrowLeft` | Quay lại màn hình cha (CRUD-UI-04) |
| `save` | `Save` | Lưu |
| `send` | `Send` | Gửi duyệt, gửi yêu cầu |
| `approve` | `CircleCheck` | Duyệt |
| `reject` | `CircleX` | Từ chối |
| `publish` | `Rocket` | Công bố, triển khai |
| `pause` | `Pause` | Tạm dừng |
| `resume` | `Play` | Tiếp tục, chạy thử |
| `revoke` | `Ban` | Thu hồi |
| `history` | `History` | Lịch sử, nhật ký kiểm toán |
| `settings` | `Settings` | Cài đặt chung |
| `help` | `CircleHelp` | Trợ giúp theo ngữ cảnh |
| `info` | `Info` | Thông tin |
| `success` | `CircleCheck` | Thành công (trong nhãn trạng thái, thông báo) |
| `warning` | `TriangleAlert` | Cảnh báo |
| `error` | `CircleAlert` | Lỗi |
| `lock` | `Lock` | Dữ liệu được bảo vệ, không có quyền |
| `key` | `KeyRound` | Khóa API, bí mật |
| `calendar` | `Calendar` | Chọn ngày |
| `clock` | `Clock` | Thời điểm, lịch chạy |
| `user` | `User` | Người dùng |
| `tenant` | `Building2` | Tenant, đơn vị |
| `notification` | `Bell` | Thông báo |
| `logout` | `LogOut` | Đăng xuất |
| `drag` | `GripVertical` | Tay cầm kéo (luôn kèm phương án bàn phím, WCAG 2.5.7) |

Ghi chú: `approve` và `success` cùng dùng `CircleCheck` vì cùng một ý "đạt"; đây là ngoại lệ được chấp nhận duy nhất của quy tắc một biểu tượng một nghĩa, vì hai nghĩa không xuất hiện cạnh nhau trong cùng một vị trí.

**Token.** `TKN-size-icon-sm`, `TKN-size-icon-md`, `TKN-size-icon-lg`, `TKN-color-icon-primary`, `TKN-color-icon-secondary`, `TKN-color-success-text`, `TKN-color-warning-text`, `TKN-color-error-text`, `TKN-color-info-text`.

**Nền đặt.** Mọi nền; biểu tượng `tone="secondary"` đạt 3:1 trên mọi nền đặc và trên `glass-overlay`.

**API.**

```tsx
export type DhIconName = keyof typeof iconRegistry; // 'add' | 'edit' | 'delete' | ...

export interface DhIconProps {
  name: DhIconName;
  size?: 'sm' | 'md' | 'lg';
  tone?: 'inherit' | 'secondary' | 'success' | 'warning' | 'error' | 'info';
  /** Có label thì biểu tượng mang nghĩa (role="img"); không có thì aria-hidden. */
  label?: string;
  testId?: string;
}
```

```tsx
<Button icon={<Icon name="download" />}>Xuất Excel</Button>
<Icon name="lock" tone="secondary" label="Trường được mã hóa" />
```

**Điều cấm.** Cấm import `lucide-react` hoặc `@ant-design/icons` trong mã màn hình. Cấm dùng một biểu tượng cho hai nghĩa khác nhau ngoài ngoại lệ đã nêu. Cấm biểu tượng mang nghĩa mà không có `label`. Cấm đổi `strokeWidth`. Cấm dùng biểu tượng làm nguồn thông tin trạng thái duy nhất (luôn kèm chữ, NFR-00-041 và WCAG 1.4.1).

### 4.2. CMP-Text

**Mục đích.** `CMP-Text` hiển thị đoạn chữ hoặc chữ trong dòng với kiểu chữ lấy từ token. Thành phần thay việc viết `<span style={{ color: … }}>`.

**Nền antd.** `Typography.Text` cho chữ trong dòng và `Typography.Paragraph` cho đoạn (`as="p"`). Hàm bọc không mở `copyable`, `editable` của antd (sao chép dùng `CMP-CopyButton`, sửa tại chỗ là thành phần phức hợp).

**Biến thể.** `variant` chọn nấc kiểu chữ: `body` (mặc định, `font-body`), `body-strong` (`font-body-strong`), `footnote`, `caption`, `callout`. `tone` chọn màu: `primary` (mặc định), `secondary`, `tertiary`, `disabled`, `success`, `warning`, `error`. Prop `tabular` bật `font-feature-tabular` cho chữ số. Prop `ellipsis` rút gọn một dòng hoặc `n` dòng; khi bị rút gọn, chữ đầy đủ hiện trong `CMP-Tooltip` khi hover và focus (thành phần tự gắn `tabIndex={0}` khi bị rút gọn để người dùng bàn phím xem được).

**Token.** `TKN-font-body`, `TKN-font-body-strong`, `TKN-font-footnote`, `TKN-font-caption`, `TKN-font-callout`, `TKN-font-feature-tabular`, `TKN-color-text-primary`, `TKN-color-text-secondary`, `TKN-color-text-tertiary`, `TKN-color-text-disabled`, `TKN-color-success-text`, `TKN-color-warning-text`, `TKN-color-error-text`.

**Nền đặt.** `primary`, `secondary` đặt được trên mọi glass. `tertiary` chỉ trên nền đặc và `glass-overlay` (trên `glass-chrome` trường hợp xấu nhất chữ cấp hai đã sát ngưỡng). Chữ màu trạng thái chỉ trên nền đặc và `glass-overlay`.

**Nội dung tiếng Việt.** Chiều cao dòng của mọi nấc ≥ 1,4 đã có trong token. Không dùng `text-transform: uppercase`. Chuỗi dài không có khoảng trắng (URL, mã băm) phải có `overflow-wrap: anywhere` để không tràn khung; với giá trị kỹ thuật dùng `CMP-CodeText` hoặc `CMP-Identifier` thay vì `CMP-Text`.

**API.**

```tsx
export interface DhTextProps {
  as?: 'span' | 'p' | 'div' | 'label';
  variant?: 'body' | 'body-strong' | 'footnote' | 'caption' | 'callout';
  tone?: 'primary' | 'secondary' | 'tertiary' | 'disabled' | 'success' | 'warning' | 'error';
  tabular?: boolean;
  ellipsis?: boolean | { rows: number };
  children: React.ReactNode;
  id?: string;
  testId?: string;
}
```

```tsx
<Text variant="footnote" tone="secondary">Mã dùng để gọi API, không đổi được sau khi tạo.</Text>
```

**Điều cấm.** Cấm truyền màu tùy ý. Cấm cỡ chữ dưới 12px cho thông tin có nghĩa. Cấm dùng màu trạng thái làm cách duy nhất để báo lỗi (luôn kèm biểu tượng hoặc chữ "Lỗi").

### 4.3. CMP-Heading

**Mục đích.** `CMP-Heading` hiển thị tiêu đề có cấp ngữ nghĩa `h1` đến `h4` tách biệt khỏi cỡ chữ thị giác. Tách hai khái niệm này vì cấu trúc tiêu đề phục vụ trình đọc màn hình (WCAG 1.3.1) còn cỡ chữ phục vụ bố cục; ví dụ tiêu đề Drawer là `h2` về ngữ nghĩa nhưng dùng cỡ `font-title-3`.

**Nền antd.** `Typography.Title` với `level` lấy từ `level` của Datahub; hàm bọc ghi đè cỡ chữ bằng lớp tương ứng `variant`.

**Biến thể.** `variant`: `display` (`font-display`, chỉ số KPI lớn trong `CMP-KpiCard`, không dùng cho chữ), `title-1`, `title-2`, `title-3`, `body-strong` (tiêu đề nhóm nhỏ trong biểu mẫu). Mặc định suy từ cấp: `h1` → `title-1`, `h2` → `title-2`, `h3` → `title-3`, `h4` → `body-strong`.

**Quy tắc cấu trúc.** Mỗi trang có đúng một `h1`, do `CMP-PageHeader` hiển thị. Modal và Drawer bắt đầu bằng `h2`. Không nhảy cấp (từ `h2` xuống `h4`).

**Token.** `TKN-font-title-1`, `TKN-font-title-2`, `TKN-font-title-3`, `TKN-font-body-strong`, `TKN-font-display`, `TKN-color-text-primary`.

**Nền đặt.** Mọi nền kể cả glass (chữ chính đạt ngưỡng trên mọi vật liệu).

**Nội dung tiếng Việt.** Tiêu đề viết hoa chữ cái đầu câu, không viết hoa mọi chữ đầu từ ("Danh sách phiên bản", không "Danh Sách Phiên Bản"), dùng tên nghiệp vụ (CRUD-UI-02), không dấu chấm cuối.

**API.**

```tsx
export interface DhHeadingProps {
  level: 1 | 2 | 3 | 4;
  variant?: 'display' | 'title-1' | 'title-2' | 'title-3' | 'body-strong';
  children: React.ReactNode;
  id?: string;
  testId?: string;
}
```

```tsx
<Heading level={2} variant="title-3" id="drawer-title">Sửa thông tin kết nối</Heading>
```

**Điều cấm.** Cấm dùng `CMP-Text variant="body-strong"` thay cho tiêu đề có cấu trúc. Cấm hai `h1` trên một trang. Cấm in hoa toàn bộ.

### 4.4. CMP-Kbd

**Mục đích.** `CMP-Kbd` hiển thị tổ hợp phím tắt, ví dụ trong tooltip của nút ("Lưu  Ctrl S"), trong `CMP-CommandPalette` và trang trợ giúp phím tắt.

**Nền.** Phần tử `<kbd>` tự viết; không dùng `Typography.Keyboard` của antd vì kiểu dáng không khớp.

**Thị giác.** Nền `color-surface-solid-2`, viền `color-border-subtle` dưới dày 1px kèm viền dưới đậm hơn 1px tạo cảm giác phím nổi, chữ `font-mono-sm`, bo `radius-xs`, đệm ngang `space-1`, cao tối thiểu 20px. Trong tooltip (nền đảo), dùng biến thể `inverse`: nền trong suốt, viền `color-text-on-inverse` alpha thấp qua lớp phủ, chữ `color-text-on-inverse`.

**Hệ điều hành.** Prop `keys` nhận mảng tên phím trừu tượng (`'mod'`, `'shift'`, `'alt'`, `'enter'`, ký tự). `'mod'` hiển thị "Ctrl" trên Windows và Linux, "⌘" trên macOS (xác định bằng `navigator.userAgentData.platform` hoặc `navigator.platform`). Các phím được nối bằng khoảng trắng mảnh, không dùng dấu "+".

**Token.** `TKN-color-surface-solid-2`, `TKN-color-border-subtle`, `TKN-color-text-secondary`, `TKN-color-text-on-inverse`, `TKN-font-mono-sm`, `TKN-radius-xs`, `TKN-space-1`.

**Nền đặt.** Nền đặc, `glass-overlay`, nền đảo (biến thể `inverse`).

**ARIA.** Bọc ngoài là `<kbd>` chứa các `<kbd>` con theo khuyến nghị HTML; thêm chữ ẩn "Phím tắt:" trước tổ hợp khi đứng trong tooltip để trình đọc màn hình đọc rõ. Phím "⌘" có `aria-label="Command"`.

**API.**

```tsx
export interface DhKbdProps { keys: Array<'mod' | 'shift' | 'alt' | 'enter' | 'esc' | string>; variant?: 'default' | 'inverse'; }
```

```tsx
<Tooltip title={<>Tìm nhanh <Kbd variant="inverse" keys={['mod', 'K']} /></>}>…</Tooltip>
```

**Điều cấm.** Cấm viết cứng "Ctrl" trong chuỗi. Cấm hiển thị phím tắt chưa được đăng ký trong bộ quản lý phím tắt của ứng dụng.

### 4.5. CMP-CodeText

**Mục đích.** `CMP-CodeText` hiển thị đoạn mã ngắn, tên trường kỹ thuật, đường dẫn, biểu thức trong dòng chữ hoặc khối mã chỉ đọc nhiều dòng ngắn (dưới 20 dòng). Khối mã dài, có tô màu cú pháp hoặc cần sửa dùng `CMP-CodeEditor` (Monaco) ở D03-05-04.

**Nền antd.** `Typography.Text code` cho dạng trong dòng; dạng khối là `<pre><code>` tự viết.

**Biến thể.** `inline` (nền `color-surface-solid-2`, đệm `0 space-1`, bo `radius-xs`, chữ `font-mono` co theo ngữ cảnh 0,92em) và `block` (nền `color-surface-solid-2`, đệm `space-3`, bo `radius-md`, chữ `font-mono`, cuộn ngang khi dòng dài, có `CMP-CopyButton` góc trên phải nếu `copyable`).

**Token.** `TKN-font-family-mono`, `TKN-font-mono`, `TKN-font-mono-sm`, `TKN-color-surface-solid-2`, `TKN-color-text-primary`, `TKN-radius-xs`, `TKN-radius-md`, `TKN-space-1`, `TKN-space-3`.

**Nền đặt.** Chỉ nền đặc và `glass-overlay` (nền `surface-solid-2` là màu đặc nên đặt trong popover vẫn đúng).

**Bàn phím và ARIA.** Khối mã cuộn ngang có `tabIndex={0}` và `role="region"` kèm `aria-label` (ví dụ "Ví dụ yêu cầu cURL") để người dùng bàn phím cuộn được (WCAG 2.1.1).

**Nội dung.** Mã luôn hiển thị nguyên văn, không dịch, không viết hoa lại. Giá trị chứa dữ liệu Nhạy cảm không được đưa vào `CMP-CodeText`; dùng `CMP-MaskedValue`.

**API.**

```tsx
export interface DhCodeTextProps {
  children: string;
  variant?: 'inline' | 'block';
  copyable?: boolean;
  /** Bắt buộc với variant="block" để đặt aria-label cho vùng cuộn. */
  label?: string;
  maxHeight?: number; // px, block cuộn dọc khi vượt
}
```

```tsx
<Text>Đặt biến <CodeText>DH_TENANT</CodeText> trong tệp cấu hình.</Text>
<CodeText variant="block" copyable label="Ví dụ gọi API">{curlSample}</CodeText>
```

**Điều cấm.** Cấm dùng `dangerouslySetInnerHTML` để tô màu. Cấm hiển thị bí mật, token truy cập trong `CMP-CodeText`.

### 4.6. CMP-Divider

**Mục đích.** `CMP-Divider` tạo đường kẻ phân cách giữa các nhóm nội dung. Đường kẻ chỉ trang trí, không mang thông tin.

**Nền antd.** `Divider` với `variant="solid"`, `orientation="horizontal"` hoặc `"vertical"`. Divider có tiêu đề (`children`) được phép cho nhóm trường trong biểu mẫu dài, tiêu đề căn trái (`titlePlacement="start"`), chữ `font-caption` độ đậm 600 màu `color-text-secondary`.

**Khoảng cách.** Ngang: lề trên dưới `space-4` (mặc định) hoặc `space-6` (`spacing="lg"`). Dọc: cao bằng chữ (`1em`), lề hai bên `space-2`, dùng giữa các mục trong thanh công cụ.

**Token.** `TKN-color-border-subtle`, `TKN-space-2`, `TKN-space-4`, `TKN-space-6`, `TKN-font-caption`, `TKN-color-text-secondary`.

**Nền đặt.** Mọi nền. Trên glass, đường kẻ dùng `color-border-subtle` vẫn đúng vì chỉ trang trí.

**ARIA.** Không có tiêu đề: `role="separator"` mặc định của antd; với Divider dọc trong thanh công cụ, `aria-orientation="vertical"`. Divider chỉ trang trí trong danh sách dùng `aria-hidden="true"` (prop `decorative`).

**API.**

```tsx
export interface DhDividerProps { orientation?: 'horizontal' | 'vertical'; spacing?: 'md' | 'lg'; title?: string; decorative?: boolean; }
```

**Điều cấm.** Cấm dùng Divider thay khoảng trắng giữa mọi khối (lạm dụng làm giao diện rối; ưu tiên khoảng cách `space-6`). Cấm Divider nét đứt.

