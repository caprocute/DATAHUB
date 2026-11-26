---
ma_tai_lieu: D03-05-03
ten: Thành phần nguyên tử
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư giao diện, Nhà thiết kế, Kiểm thử viên, AI agent sinh mã
nguoi_lap: Luồng giao diện
---

# D03-05-03 · Thành phần nguyên tử

## 1. Mục đích, cách đọc và quy ước chung

### 1.1. Mục đích

Tài liệu này đặc tả 44 **thành phần nguyên tử (atomic component)** của gói `@datahub/ui`. Thành phần nguyên tử là đơn vị giao diện nhỏ nhất có ý nghĩa độc lập: một nút, một ô nhập, một nhãn trạng thái, một giá trị thời gian. Chúng không chứa thành phần nguyên tử khác ngoại trừ `CMP-Icon`, `CMP-Spinner` và `CMP-Tooltip` (ba thành phần này được phép lồng vào nguyên tử khác vì đóng vai trò trang trí hoặc phụ trợ). Thành phần phức hợp như `CMP-FormField`, `CMP-DataTable`, `CMP-Modal` được ghép từ các nguyên tử ở đây và được đặc tả ở D03-05-04.

Mục tiêu của tài liệu là để kỹ sư giao diện và AI agent sinh mã có thể hiện thực từng thành phần mà không phải tự quyết định thêm về hành vi, màu sắc hay nội dung. Mọi giá trị thị giác đều đến từ token định nghĩa ở D03-05-02; tài liệu này chỉ ghi tên token (dạng `TKN-…` hoặc tên token ngắn trong dấu `` ` ``), không ghi giá trị màu thô. Quy tắc vật liệu Liquid Glass (ADR-020) và thành phần nguyên thủy `CMP-GlassSurface`, `CMP-ThemeProvider` được đặc tả ở D03-05-01; tài liệu này chỉ nêu thành phần nào được phép đặt trên glass.

Ba yêu cầu chi phối toàn bộ tài liệu là NFR-00-045 (100% màn hình dùng thành phần của `@datahub/ui`, không CSS tùy biến ngoài token), NFR-00-040 đến NFR-00-043 (WCAG 2.2 AA, tương phản, bàn phím, giảm chuyển động) và FR-00-053 (nhãn trạng thái vòng đời thống nhất). Ngoài ra một số thành phần hiện thực trực tiếp yêu cầu bảo vệ dữ liệu cá nhân của nguyên tắc NT-10 (D03-01) và FR-00-034, FR-00-040.

### 1.2. Cách đọc

Tài liệu được chia theo nhóm chức năng để người đọc tìm nhanh. Mục 2 nêu quy tắc chung về trạng thái tương tác áp dụng cho mọi thành phần tương tác, nên phải đọc trước khi đọc từng thành phần. Mục 3 đến mục 8 đặc tả từng thành phần, theo thứ tự: hành động (mục 3), chữ và biểu tượng (mục 4), chỉ báo và nhãn (mục 5), phản hồi tiến trình và gợi ý (mục 6), nhập liệu (mục 7), hiển thị dữ liệu nghiệp vụ (mục 8). Mục 9 là bảng tổng hợp kèm bảng tên gọi khác, mục 10 là checklist nghiệm thu, mục 11 là truy vết và mục 12 là các đề xuất bổ sung.

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
| `offline` | `CloudOff` | Mất kết nối, chưa lưu lên máy chủ |
| `expression` | `SquareFunction` | Mở trình soạn biểu thức (ƒx) |
| `connection` | `Plug` | Kết nối PH-05, thành phần cần kết nối |
| `schema` | `Braces` | Lược đồ dữ liệu |
| `undo` | `Undo2` | Hoàn tác |
| `redo` | `Redo2` | Làm lại |
| `zoom-in` | `ZoomIn` | Phóng to |
| `zoom-out` | `ZoomOut` | Thu nhỏ |
| `fit-view` | `Scan` | Vừa khung nhìn |
| `fullscreen` | `Maximize2` | Toàn màn hình |
| `pin` | `Pin` | Ghim vị trí, ghim mục |
| `comment` | `MessageSquare` | Bình luận |
| `diff` | `GitCompare` | So sánh khác biệt |
| `tasks` | `ListChecks` | Khay tác vụ nền |
| `command` | `Command` | Bảng lệnh (CommandPalette) |
| `sticky-note` | `StickyNote` | Ghi chú dán trên canvas |
| `minimap` | `Map` | Bản đồ thu nhỏ |
| `panel` | `PanelLeft` | Thu gọn, mở ngăn bên |

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


## 5. Nhóm chỉ báo và nhãn

### 5.1. CMP-StatusTag

**Mục đích.** `CMP-StatusTag` hiển thị trạng thái vòng đời của một đối tượng nghiệp vụ hoặc trạng thái của một lượt chạy, giao dịch. Đây là thành phần hiện thực FR-00-053: mọi phân hệ hiển thị trạng thái bằng cùng một bộ nhãn, cùng màu, cùng chữ. Bảng ánh xạ trạng thái được định nghĩa **một lần** trong tài liệu này và trong mã nguồn ở `@datahub/ui/status/registry.ts`; màn hình không bao giờ tự chọn màu cho trạng thái.

**Khi dùng.** Cột "Trạng thái" trong bảng, tiêu đề trang chi tiết (cạnh tên đối tượng trong `CMP-PageHeader`), thẻ, kết quả lượt chạy. **Khi không dùng.** Phân loại, thẻ gắn tự do (dùng `CMP-Tag`); số đếm (dùng `CMP-Badge`); chỉ báo sức khỏe nhỏ trong không gian chật như cạnh tên nút trên canvas (dùng `CMP-StatusDot`, nhưng vẫn theo cùng bảng ánh xạ).

**Nền antd.** `Tag` của antd v6 với `variant="filled"`, không dùng prop `color` preset (D03-05-02 §13.2). Màu được gắn qua lớp `dh-status-tag--{tone}` đọc biến `--dh-color-{tone}-bg` và `--dh-color-{tone}-on-bg`. Hàm bọc cố định `closable={false}` (trạng thái không đóng được), `bordered={false}`.

**Năm sắc thái.** Mọi trạng thái được quy về một trong năm sắc thái (tone) có ý nghĩa cố định. Bảng dưới đây nêu ý nghĩa của sắc thái, token, và hình dạng chỉ báo đi kèm chữ. Hình dạng là kênh thông tin thứ hai sau chữ, để người mù màu phân biệt được ngay cả khi không đọc chữ (WCAG 1.4.1).

| Sắc thái | Ý nghĩa | Nền / chữ | Chỉ báo mặc định |
|---|---|---|---|
| `success` | Hoạt động bình thường, đã hoàn tất tốt, đang có hiệu lực | `color-success-bg` / `color-success-on-bg` | Chấm tròn đặc |
| `warning` | Cần chú ý, tạm thời không hoạt động, sắp hết hạn, có thể phục hồi | `color-warning-bg` / `color-warning-on-bg` | Chấm tròn rỗng (vòng) |
| `error` | Thất bại, bị thu hồi, bị từ chối, không phục hồi được nếu không can thiệp | `color-error-bg` / `color-error-on-bg` | Biểu tượng `error` cỡ `size-icon-sm` |
| `info` | Đang trong quy trình, đang chờ một bên xử lý, đang chạy | `color-info-bg` / `color-info-on-bg` | Chấm tròn nửa (hoặc spinner nhỏ với trạng thái "đang chạy") |
| `neutral` | Chưa có hiệu lực, đã kết thúc tự nhiên, không còn hoạt động nhưng không phải lỗi | `color-neutral-bg` / `color-neutral-on-bg` | Chấm tròn viền đứt (vòng nét đứt) |

**Bảng ánh xạ trạng thái dùng chung.** Bảng dưới đây ánh xạ mã trạng thái chuẩn (kiểu `T-ENUM`, D00-01 §5) sang nhãn tiếng Việt và sắc thái. Mỗi phân hệ khi định nghĩa máy trạng thái của đối tượng (D02-03, D03-03) phải dùng mã trong bảng này nếu nghĩa trùng; chỉ khi không có mã phù hợp mới đề xuất mã mới bằng PR vào `registry.ts` kèm cập nhật bảng này. Cột "Nhóm" cho biết loại đối tượng thường dùng, không giới hạn.

| Mã | Nhãn hiển thị | Sắc thái | Nhóm | Ghi chú |
|---|---|---|---|---|
| `DRAFT` | Bản nháp | `neutral` | Vòng đời đối tượng | Đang soạn, chưa gửi |
| `PENDING_APPROVAL` | Chờ duyệt | `info` | Vòng đời, yêu cầu | Đang chờ người duyệt (FR-00-070) |
| `CHANGES_REQUESTED` | Cần chỉnh sửa | `warning` | Yêu cầu | Người duyệt trả lại kèm ý kiến |
| `APPROVED` | Đã duyệt | `success` | Vòng đời, yêu cầu | Được duyệt, có thể chưa công bố |
| `REJECTED` | Từ chối | `error` | Yêu cầu | Bị từ chối, có lý do (FR-00-072) |
| `PUBLISHED` | Đã công bố | `success` | Dịch vụ, API, danh mục, sản phẩm dữ liệu | Đang có hiệu lực với bên dùng |
| `ACTIVE` | Đang hoạt động | `success` | Tenant, tài khoản, kết nối, khóa API | |
| `SUSPENDED` | Tạm dừng | `warning` | Dịch vụ, tenant, tài khoản, đăng ký | Có thể khôi phục |
| `DEPRECATED` | Ngừng cung cấp | `warning` | Phiên bản API, dịch vụ | Vẫn chạy nhưng sắp gỡ; tooltip nêu ngày gỡ dự kiến |
| `RETIRED` | Đã gỡ | `neutral` | Phiên bản API, dịch vụ | Không còn phục vụ |
| `CLOSED` | Đã đóng | `neutral` | Yêu cầu, sự cố, phiên | Kết thúc tự nhiên |
| `REVOKED` | Thu hồi | `error` | Khóa API, chứng thư, quyền, đăng ký | Bị chấm dứt chủ động, không khôi phục |
| `EXPIRED` | Hết hạn | `neutral` | Khóa API, chứng thư, liên kết tải | |
| `EXPIRING` | Sắp hết hạn | `warning` | Khóa API, chứng thư | Còn ≤ 30 ngày (ngưỡng do phân hệ cấu hình) |
| `DISABLED` | Đã vô hiệu | `neutral` | Tài khoản, luồng, lịch chạy | Do người dùng tắt |
| `DELETED` | Đã xóa | `neutral` | Mọi đối tượng xóa mềm (FR-00-051) | Chỉ hiện trong chế độ xem dữ liệu đã xóa |
| `ERROR` | Lỗi | `error` | Kết nối, đồng bộ, cấu hình | Trạng thái lỗi kéo dài |
| `QUEUED` | Đang chờ chạy | `info` | Tác vụ nền, lượt chạy | |
| `RUNNING` | Đang chạy | `info` | Tác vụ nền, lượt chạy luồng (FR-00-054) | Chỉ báo là spinner nhỏ; tắt quay khi giảm chuyển động |
| `SUCCEEDED` | Thành công | `success` | Lượt chạy, lượt gọi, giao dịch | |
| `PARTIALLY_SUCCEEDED` | Thành công một phần | `warning` | Nhập dữ liệu, xử lý hàng loạt (CRUD-D-09) | |
| `FAILED` | Thất bại | `error` | Lượt chạy, lượt gọi, giao dịch | |
| `CANCELLED` | Đã hủy | `neutral` | Lượt chạy, giao dịch, yêu cầu | Do người dùng hoặc hệ thống hủy |
| `TIMED_OUT` | Quá thời gian | `error` | Lượt gọi, lượt chạy | |
| `RETRYING` | Đang thử lại | `warning` | Lượt chuyển sự kiện, lượt gọi | |
| `PENDING_PAYMENT` | Chờ thanh toán | `info` | Giao dịch thanh toán | |
| `PAID` | Đã thanh toán | `success` | Giao dịch thanh toán | |
| `REFUND_PENDING` | Chờ hoàn tiền | `info` | Giao dịch thanh toán | |
| `REFUNDED` | Hoàn tiền | `neutral` | Giao dịch thanh toán | Đã hoàn tất hoàn tiền; không phải lỗi |
| `RECONCILE_PENDING` | Chờ đối soát | `info` | Giao dịch, kỳ đối soát | |
| `RECONCILED` | Đã đối soát | `success` | Giao dịch, kỳ đối soát | |
| `RECONCILE_MISMATCH` | Lệch đối soát | `error` | Giao dịch, kỳ đối soát | Cần xử lý |
| `HEALTHY` | Bình thường | `success` | Sức khỏe dịch vụ, nút hạ tầng | |
| `DEGRADED` | Suy giảm | `warning` | Sức khỏe dịch vụ | |
| `DOWN` | Ngừng hoạt động | `error` | Sức khỏe dịch vụ | |
| `UNKNOWN` | Không xác định | `neutral` | Mọi nhóm | Dự phòng khi nhận mã chưa có trong bảng |

Bốn quy tắc đi kèm bảng. Thứ nhất, sắc thái thể hiện **mức cần chú ý**, không thể hiện "tốt hay xấu" về đạo đức: "Hoàn tiền" là `neutral` vì giao dịch đã kết thúc đúng quy trình; "Ngừng cung cấp" là `warning` vì bên dùng phải hành động trước ngày gỡ. Thứ hai, nhãn hiển thị trong bảng là nhãn chuẩn; nếu một phân hệ cần nhãn khác cho cùng mã (ví dụ PH thanh toán muốn "Đã hoàn tiền"), phải sửa nhãn ở đây cho mọi phân hệ, không ghi đè cục bộ. Thứ ba, mã chưa có trong bảng hiển thị là `UNKNOWN` kèm mã gốc trong tooltip, và thành phần ghi cảnh báo `console.warn` ở môi trường phát triển để phát hiện sớm. Thứ tư, khi phân hệ có máy trạng thái riêng chưa chuẩn hóa, có thể truyền `customStatus={{ label, tone }}` nhưng lint báo cảnh báo và PR phải giải thích.

**Kích thước.** `sm` cao 20px, chữ `font-caption` độ đậm 500, đệm ngang `space-2`, dùng trong bảng chế độ gọn và `CMP-StatusDot` có nhãn. `md` (mặc định) cao `size-control-sm` (24px), chữ `font-footnote` độ đậm 500, đệm ngang `space-2`. Bo góc `radius-pill`. Khoảng giữa chỉ báo và chữ là `space-1`; chỉ báo dạng chấm có đường kính 6px (`sm`) hoặc 8px (`md`).

**Trạng thái.** Nhãn không tương tác, không có hover hay focus. Khi trạng thái có giải thích bổ sung (lý do tạm dừng, ngày gỡ của `DEPRECATED`), thành phần nhận `description` và bọc trong `CMP-Tooltip`, đồng thời trở thành focus được (`tabIndex={0}`) để người dùng bàn phím xem được; nhưng giải thích đó cũng phải có ở trang chi tiết, không chỉ nằm trong tooltip.

**Token.** `TKN-color-success-bg`, `TKN-color-success-on-bg`, `TKN-color-warning-bg`, `TKN-color-warning-on-bg`, `TKN-color-error-bg`, `TKN-color-error-on-bg`, `TKN-color-info-bg`, `TKN-color-info-on-bg`, `TKN-color-neutral-bg`, `TKN-color-neutral-on-bg`, `TKN-radius-pill`, `TKN-font-caption`, `TKN-font-footnote`, `TKN-space-1`, `TKN-space-2`, `TKN-size-control-sm`, `TKN-size-icon-sm`. Chấm chỉ báo dùng `currentColor` (bằng màu chữ `-on-bg`), nên tự đạt 3:1 trên nền nhẹ.

**Nền đặt.** Mọi nền kể cả glass, vì nhãn dùng cặp nền nhẹ + chữ trên nền nhẹ nên tương phản không phụ thuộc lớp dưới (D03-05-02 §4.4).

**ARIA.** Phần tử `<span>`; chỉ báo hình có `aria-hidden="true"` vì chữ đã đủ nghĩa. Trong ô bảng, tiêu đề cột "Trạng thái" cung cấp ngữ cảnh; ngoài bảng, thành phần thêm chữ ẩn "Trạng thái:" trước nhãn khi prop `announcePrefix` bật. Khi trạng thái thay đổi trực tiếp trên màn hình (tác vụ chạy xong), vùng chứa nhãn do màn hình đặt `aria-live="polite"`, không phải thành phần.

**Nội dung tiếng Việt.** Nhãn là cụm danh từ hoặc tính từ ngắn, tối đa 3 từ, viết hoa chữ cái đầu: "Đã công bố", "Chờ duyệt". Không dùng tiếng Anh trong nhãn; thuật ngữ tiếng Anh nếu cần đặt trong tooltip (ví dụ "Ngừng cung cấp (Deprecated)").

**API.**

```tsx
export type DhStatusCode = keyof typeof statusRegistry; // 'DRAFT' | 'PENDING_APPROVAL' | ...
export type DhTone = 'success' | 'warning' | 'error' | 'info' | 'neutral';

export interface DhStatusTagProps {
  status: DhStatusCode | (string & {}); // mã lạ → UNKNOWN
  size?: 'sm' | 'md';
  description?: string;
  announcePrefix?: boolean;
  /** Chỉ dùng khi chưa chuẩn hóa; lint cảnh báo. */
  customStatus?: { label: string; tone: DhTone };
  testId?: string;
}

/** Dùng cho bộ lọc, biểu đồ: lấy nhãn và sắc thái từ cùng nguồn. */
export function getStatusMeta(code: string): { label: string; tone: DhTone; known: boolean };
```

```tsx
<StatusTag status={service.status} />
<StatusTag status="DEPRECATED" description="Gỡ dự kiến ngày 31/03/2027. Hãy chuyển sang phiên bản v2." />
```

Bộ lọc trạng thái trong `CMP-FilterBar` dùng `getStatusMeta` để sinh tùy chọn của `CMP-Select`, nên nhãn trong bộ lọc và trong bảng luôn trùng nhau.

**Điều cấm.** Cấm dùng `Tag color="green"` hay `CMP-Tag` để hiển thị trạng thái. Cấm nhãn trạng thái chỉ có màu, không chữ. Cấm tự định nghĩa nhãn tiếng Việt cho mã đã có trong bảng. Cấm dùng sắc thái `error` cho trạng thái kết thúc bình thường.

### 5.2. CMP-Tag

**Mục đích.** `CMP-Tag` hiển thị nhãn phân loại hoặc giá trị gắn tự do: nhãn của dịch vụ, lĩnh vực, giá trị đã chọn trong bộ lọc, phương thức HTTP. Khác `CMP-StatusTag` ở chỗ không mang nghĩa vòng đời và có thể đóng được.

**Nền antd.** `Tag` với `variant="filled"`. Không dùng `color` preset.

**Biến thể.** `neutral` (mặc định, nền `color-neutral-bg` qua token `Tag.defaultBg` đã đặt ở D03-05-02, chữ `color-text-primary`), `accent` (nền `color-accent-subtle`, chữ `color-accent-on-subtle`; dùng cho giá trị bộ lọc đang áp dụng), `outline` (nền trong suốt, viền `color-border-subtle`; dùng trong vùng đã có nhiều màu). Phương thức HTTP (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) dùng biến thể `neutral` với chữ `font-mono-sm`; không gán màu riêng từng phương thức, vì màu không mang thêm thông tin so với chữ và gây nhầm với trạng thái.

**Kích thước.** `sm` cao 20px, `md` cao `size-control-sm`; bo `radius-sm`; chữ `font-caption` (`sm`) hoặc `font-footnote` (`md`).

**Trạng thái.** Tag tĩnh không có trạng thái tương tác. Tag đóng được (`closable`) có nút đóng là `CMP-IconButton` cỡ thị giác 16px với vùng chạm mở rộng 24px, nhãn truy cập "Bỏ {giá trị}". Tag chọn được (`checkable`, dùng trong bộ lọc nhanh) có trạng thái chọn: nền `color-fill-selected`, chữ `color-accent-on-subtle`, `aria-pressed`.

**Token.** `TKN-color-neutral-bg`, `TKN-color-text-primary`, `TKN-color-accent-subtle`, `TKN-color-accent-on-subtle`, `TKN-color-border-subtle`, `TKN-color-fill-selected`, `TKN-color-fill-hover`, `TKN-radius-sm`, `TKN-font-caption`, `TKN-font-footnote`, `TKN-font-mono-sm`.

**Nền đặt.** Mọi nền.

**Bàn phím và ARIA.** Tag đóng được: Tab tới nút đóng, Enter hoặc Space đóng; sau khi đóng, focus chuyển sang tag kế tiếp hoặc về ô nhập liên quan. Tag chọn được: phần tử `<button aria-pressed>`.

**Nội dung.** Chữ trong tag tối đa 24 ký tự hiển thị; dài hơn thì rút gọn với tooltip chữ đầy đủ.

**API.**

```tsx
export interface DhTagProps {
  children: React.ReactNode;
  variant?: 'neutral' | 'accent' | 'outline';
  size?: 'sm' | 'md';
  mono?: boolean;
  closable?: boolean;
  onClose?: () => void;
  checkable?: boolean;
  checked?: boolean;
  onCheckedChange?: (checked: boolean) => void;
  testId?: string;
}
```

```tsx
<Tag mono>GET</Tag>
<Tag variant="accent" closable onClose={() => removeFilter('domain')}>Lĩnh vực: Hộ tịch</Tag>
```

**Điều cấm.** Cấm dùng `CMP-Tag` cho trạng thái. Cấm gán màu theo giá trị (mỗi nhãn một màu) vì tạo cảm giác mang nghĩa trạng thái.

### 5.3. CMP-Badge

**Mục đích.** `CMP-Badge` hiển thị số đếm nhỏ gắn lên một phần tử khác: số thông báo chưa đọc trên chuông, số việc chờ duyệt cạnh mục menu "Việc của tôi", số bộ lọc đang áp dụng trên nút lọc.

**Nền antd.** `Badge` với `count`, `overflowCount={99}`, `showZero={false}`. Không dùng `Badge.Ribbon`. Chấm không số (`dot`) được phép cho "có mục mới" khi số lượng không quan trọng.

**Biến thể.** `accent` (mặc định, nền `color-accent`, chữ `color-text-on-accent`), `error` (nền `color-error-solid`, chữ `color-text-on-accent`; chỉ cho cảnh báo cần xử lý ngay, ví dụ số sự cố), `neutral` (nền `color-fill-control`, chữ `color-text-secondary`; số đếm thông tin như số bản ghi trong tab). Biến thể `inline` đặt số đứng cạnh chữ (trong tab, mục menu) thay vì chồng lên góc.

**Kích thước.** Cao 18px (token thành phần antd `Badge.indicatorHeight`), chữ 12px độ đậm 600 với `font-feature-tabular`; `Badge.dotSize` 8px. Hai giá trị này đặt trong `theme.components.Badge`.

**Token.** `TKN-color-accent`, `TKN-color-error-solid`, `TKN-color-text-on-accent`, `TKN-color-fill-control`, `TKN-color-text-secondary`, `TKN-font-feature-tabular`, `TKN-radius-pill`. Badge chồng lên phần tử trên glass có viền ngoài 2px màu `color-surface-solid` để tách khỏi biểu tượng (`Badge.badgeShadowColor`).

**Nền đặt.** Mọi nền.

**ARIA.** Số đếm chồng lên nút không được đọc riêng; thành phần cung cấp chữ để ghép vào tên truy cập của nút cha, ví dụ nút chuông có `aria-label="Thông báo, 5 mục chưa đọc"`. Prop `srLabel` của Badge sinh chuỗi này; nút cha dùng nó. Chấm `dot` đi kèm chữ ẩn "có mục mới". Khi số tăng, không tự đọc to (tránh làm phiền); `CMP-NotificationCenter` quyết định thông báo.

**Nội dung.** Số dùng định dạng Việt Nam khi lớn hơn 999 nhưng vì `overflowCount` 99, hiển thị "99+".

**API.**

```tsx
export interface DhBadgeProps {
  count?: number;
  dot?: boolean;
  variant?: 'accent' | 'error' | 'neutral';
  inline?: boolean;
  children?: React.ReactNode;   // phần tử được gắn badge
  /** Danh từ đếm: "mục chưa đọc" → "5 mục chưa đọc". */
  unit: string;
  testId?: string;
}
export function badgeSrLabel(count: number | undefined, unit: string): string;
```

```tsx
<Badge count={unread} unit="mục chưa đọc">
  <IconButton icon={<Icon name="notification" />} label={`Thông báo, ${badgeSrLabel(unread, 'mục chưa đọc')}`} />
</Badge>
```

**Điều cấm.** Cấm dùng Badge để hiển thị trạng thái (dùng `CMP-StatusTag` hoặc `CMP-StatusDot`). Cấm Badge `error` cho số đếm thông thường.

### 5.4. CMP-StatusDot

**Mục đích.** `CMP-StatusDot` là chỉ báo trạng thái thu gọn: một chấm tròn kèm chữ ngắn hoặc kèm tooltip. Dùng ở nơi `CMP-StatusTag` quá to: cạnh tên nút trên `CMP-FlowCanvas`, trong danh sách nút hạ tầng dày đặc, trong mục menu chuyển tenant.

**Nền antd.** `Badge` với `status` không dùng; thành phần tự viết để dùng chung bảng ánh xạ của `CMP-StatusTag` và hình dạng chỉ báo năm sắc thái.

**Biến thể.** `labeled` (mặc định, chấm + chữ `font-footnote` màu `color-text-secondary`), `dot-only` (chỉ chấm; bắt buộc có `CMP-Tooltip` và chữ ẩn cho trình đọc màn hình, chỉ dùng khi ngữ cảnh lặp lại cùng ý nghĩa và có chú giải trên màn hình). Với `RUNNING`, chấm có hiệu ứng nhịp thở (độ đục 1 → 0,4 → 1, chu kỳ 1,6 giây), tắt khi giảm chuyển động.

**Kích thước.** Chấm 8px, khoảng cách tới chữ `space-1`. Hình dạng theo sắc thái như bảng của `CMP-StatusTag` (đặc, vòng, biểu tượng lỗi 12px, nửa, nét đứt). Màu chấm dùng `color-{tone}-text` (không phải `-solid`) để đạt 3:1 trên nền đặc và `glass-overlay`; riêng `warning` dùng `color-warning-text`.

**Token.** `TKN-color-success-text`, `TKN-color-warning-text`, `TKN-color-error-text`, `TKN-color-info-text`, `TKN-color-neutral-text`, `TKN-color-text-secondary`, `TKN-font-footnote`, `TKN-space-1`.

**Nền đặt.** Nền đặc và `glass-overlay`. Không đặt trực tiếp trên `glass-chrome` vì màu trạng thái trên chrome chưa được kiểm tra trường hợp xấu nhất.

**ARIA.** `labeled`: chấm `aria-hidden`. `dot-only`: `role="img"`, `aria-label` bằng nhãn trạng thái.

**API.**

```tsx
export interface DhStatusDotProps {
  status: DhStatusCode | (string & {});
  variant?: 'labeled' | 'dot-only';
  /** Ghi đè chữ hiển thị nhưng giữ sắc thái theo mã, ví dụ "12 ms". */
  label?: string;
  testId?: string;
}
```

```tsx
<StatusDot status="HEALTHY" />
<StatusDot status="DEGRADED" variant="dot-only" />
```

**Điều cấm.** Cấm dùng `dot-only` trong cột bảng mà không có chú giải. Cấm màu chấm khác bảng ánh xạ.

### 5.5. CMP-Avatar

**Mục đích.** `CMP-Avatar` đại diện cho một người dùng, một hệ thống máy hoặc một tenant bằng ảnh hoặc chữ cái đầu. Dùng trong `CMP-UserMenu`, `CMP-AuditTrail` (chủ thể của bản ghi kiểm toán), danh sách người duyệt.

**Nền antd.** `Avatar` với `shape="circle"` (người) hoặc `shape="square"` bo `radius-sm` (hệ thống máy, tenant). `Avatar.Group` với `max={{ count: 3 }}` cho danh sách người.

**Biến thể.** `image` khi có ảnh; `initials` khi không có ảnh: hai ký tự gồm chữ cái đầu của từ đầu tiên (họ) và từ cuối cùng (tên) trong họ tên, theo thứ tự xuất hiện, ví dụ "Nguyễn Văn An" → "NA"; tên chỉ có một từ thì lấy một ký tự. Chữ giữ dấu (ví dụ "Đặng" → "Đ"). Nền chữ cái đầu chọn từ `color-chart-1` đến `color-chart-7` theo băm ổn định của mã người dùng, chữ `color-text-on-accent`. Lưu ý: chỉ các màu có tương phản chữ trắng ≥ 4,5:1 ở chế độ sáng được dùng (`color-chart-1`, `-3`, `-4`, `-5`, `-6`, `-7`); `color-chart-2` và `color-chart-8` bị loại; ở chế độ tối dùng nền `color-neutral-bg` với chữ `color-neutral-on-bg` để không phải kiểm tra thêm tương phản chữ trắng trên các màu biểu đồ tối. `system`: biểu tượng `key` hoặc `tenant` trên nền `color-fill-control`, dùng cho chủ thể máy trong kiểm toán.

**Kích thước.** `sm` 24px (bảng, nhật ký), `md` 32px (menu người dùng), `lg` 40px (trang hồ sơ). Chữ cái đầu dùng `font-caption` độ đậm 600 (`sm`), `font-footnote` 600 (`md`), `font-body-strong` (`lg`).

**Token.** `TKN-color-chart-1`, `TKN-color-chart-3`, `TKN-color-chart-4`, `TKN-color-chart-5`, `TKN-color-chart-6`, `TKN-color-chart-7`, `TKN-color-text-on-accent`, `TKN-color-neutral-bg`, `TKN-color-neutral-on-bg`, `TKN-color-fill-control`, `TKN-radius-pill`, `TKN-radius-sm`, `TKN-size-control-sm`, `TKN-size-control-md`, `TKN-size-control-lg`.

**Nền đặt.** Mọi nền.

**ARIA.** Avatar đứng cạnh tên người: `aria-hidden="true"` (tên đã nói). Avatar đứng riêng (trong `Avatar.Group`): `role="img"` và `aria-label` bằng họ tên; phần "+2" có `aria-label="và 2 người khác"`.

**Bảo vệ dữ liệu.** Ảnh đại diện tải qua URL có ký tên ngắn hạn của kho đối tượng, không nhúng base64 vào phản hồi danh sách. Avatar không hiển thị thông tin cá nhân khác ngoài tên hiển thị.

**API.**

```tsx
export interface DhAvatarProps {
  name: string;
  subjectType?: 'user' | 'system' | 'tenant';
  src?: string;
  size?: 'sm' | 'md' | 'lg';
  /** Mã ổn định để chọn màu nền chữ cái đầu. */
  seed: string;
  decorative?: boolean;
}
```

```tsx
<Space size="small"><Avatar name={actor.name} seed={actor.id} size="sm" decorative /> <Text>{actor.name}</Text></Space>
```

**Điều cấm.** Cấm dùng ảnh mặc định của bên thứ ba (Gravatar) vì gửi thư điện tử băm ra ngoài. Cấm chọn màu ngẫu nhiên mỗi lần hiển thị.

### 5.6. CMP-AvatarGroup

**Mục đích.** `CMP-AvatarGroup` hiển thị một nhóm người cùng liên quan tới một đối tượng ở cùng thời điểm: người đang mở cùng phiên bản luồng (PH-04 UI-04-04, FR-04-010), người được giao một việc duyệt, thành viên một nhóm đầu mối. Đây là cách dùng `Avatar.Group` đã nêu ở mục 5.5, được tách thành mã riêng vì có thêm hai hành vi mà Avatar đơn không có: chỉ báo hiện diện và lời giải thích bằng chữ.

**Khi dùng / không dùng.** Dùng khi số người là thông tin quan trọng và tên từng người xem được khi cần. Không dùng thay cho danh sách người duyệt có trạng thái quyết định (dùng `CMP-ApprovalPanel` hoặc `CMP-Timeline`), không dùng để liệt kê hơn 20 người (dùng `CMP-Popover` chứa danh sách).

**Nền antd.** `Avatar.Group` với `max={{ count, popover: { trigger: 'click' } }}`; phần "+n" mở `CMP-Popover` (`glass-overlay`) liệt kê đủ tên, không mở bằng rê chuột để dùng được với bàn phím.

**Biến thể.** `static` (danh sách cố định) và `presence` (người đang hiện diện, cập nhật theo nhịp máy chủ; mỗi ảnh có chấm hiện diện 8px `color-success-solid` có viền 2px `color-surface-solid` ở góc dưới phải). Ở biến thể `presence`, khi có từ một người khác trở lên, thành phần hiện chữ đi kèm do màn hình truyền vào (ví dụ "Đang có 2 người khác mở luồng này") để thông tin không chỉ nằm ở hình.

**Kích thước.** `sm` 24px (thanh công cụ trình thiết kế, bảng), `md` 32px. Mặc định `count` là 3. Ảnh chồng lên nhau 25% đường kính, viền 2px cùng màu nền đặt để tách ảnh.

**Trạng thái.** Rỗng (không hiển thị gì, không để khoảng trống), có người, đang tải lần đầu (`CMP-Skeleton` hình tròn), lỗi tải (ẩn thành phần; hiện diện là thông tin phụ, không báo lỗi to).

**Token.** Như `CMP-Avatar`, thêm `TKN-color-success-solid`, `TKN-color-surface-solid`, `TKN-space-1`.

**Nền đặt.** Nền đặc, `glass-chrome` (thanh trên), `glass-overlay`.

**Bàn phím và ARIA.** Nhóm là `role="group"` có `aria-label` ("Người đang mở luồng"). Mỗi ảnh có tên truy cập là họ tên kèm thời điểm ("Trần Thị B, mở từ 09:12"); "+n" là nút có `aria-label="Xem thêm n người"` và `aria-expanded`. Thay đổi hiện diện không đọc qua `aria-live` (quá ồn); chỉ chữ đi kèm thay đổi.

**Nội dung.** Tooltip mỗi ảnh: "{tên} mở từ {HH:mm}". Không hiển thị thư điện tử hay đơn vị trong tooltip.

**API.**

```tsx
export interface DhAvatarGroupProps {
  people: Array<{ id: string; name: string; src?: string; since?: string /* T-TS */ }>;
  variant?: 'static' | 'presence';
  max?: number;                    // mặc định 3
  size?: 'sm' | 'md';
  caption?: string;                // chữ đi kèm, bắt buộc với presence khi people.length > 0
  'aria-label': string;
  testId?: string;
}
```

```tsx
<AvatarGroup variant="presence" aria-label="Người đang mở luồng" size="sm"
  people={others} caption={others.length ? `Đang có ${others.length} người khác mở luồng này` : undefined} />
```

**Điều cấm.** Cấm chỉ dùng chấm màu để báo hiện diện. Cấm mở danh sách "+n" bằng rê chuột. Cấm đưa người dùng hiện tại vào nhóm `presence` (người dùng biết mình đang mở).

## 6. Nhóm phản hồi tiến trình và gợi ý

### 6.1. CMP-Spinner

**Mục đích.** `CMP-Spinner` báo một thao tác đang chạy mà không biết trước thời lượng, ở phạm vi nhỏ: trong nút, trong ô, trong vùng nhỏ của thẻ. Với tải dữ liệu lần đầu của một vùng có cấu trúc biết trước (bảng, thẻ, biểu mẫu), dùng `CMP-Skeleton`; với thao tác biết tiến độ, dùng `CMP-ProgressBar`.

**Nền antd.** `Spin` với `indicator` là biểu tượng tự vẽ (vòng cung SVG nét 2px quay 0,8 giây một vòng) thay cho bốn chấm mặc định của antd, để khớp ngôn ngữ Liquid Glass. Đặt toàn cục qua `ConfigProvider spin={{ indicator }}` trong `CMP-ThemeProvider`.

**Kích thước.** `sm` = `size-icon-sm` (trong nút `sm`, ô bảng), `md` = `size-icon-md` (trong nút `md`, `lg`), `lg` = 32px (giữa vùng nội dung). Token thành phần antd `Spin.dotSize`, `Spin.dotSizeSM`, `Spin.dotSizeLG` đặt tương ứng 16, 14, 32.

**Màu.** Kế thừa `currentColor`; mặc định `color-icon-secondary`, trong nút primary là `color-text-on-accent`.

**Chuyển động.** Khi giảm chuyển động, vòng cung không quay mà đổi độ đục nhịp chậm (1 → 0,5, chu kỳ 1,6 giây), vẫn cho biết đang chạy.

**Độ trễ hiển thị.** Prop `delay` mặc định 150ms (antd `Spin.delay`), tránh nhấp nháy với thao tác nhanh.

**Token.** `TKN-color-icon-secondary`, `TKN-color-text-on-accent`, `TKN-size-icon-sm`, `TKN-size-icon-md`.

**Nền đặt.** Mọi nền.

**ARIA.** Spinner đứng riêng có `role="status"` và chữ ẩn từ prop `label` (mặc định "Đang tải"). Spinner trong nút không có `role` riêng; nút đã có `aria-busy`. Vùng đang tải có `aria-busy="true"` do vùng chứa đặt.

**API.**

```tsx
export interface DhSpinnerProps { size?: 'sm' | 'md' | 'lg'; label?: string; delay?: number; testId?: string; }
```

```tsx
<Spinner size="lg" label="Đang tải danh sách lượt chạy" />
```

**Điều cấm.** Cấm dùng spinner toàn trang che cả ứng dụng (dùng Skeleton theo vùng). Cấm spinner quá 3 giây mà không chuyển sang thông báo tiến độ hoặc tác vụ nền (FR-00-054).

### 6.2. CMP-Skeleton

**Mục đích.** `CMP-Skeleton` giữ chỗ cho nội dung đang tải lần đầu bằng các khối xám có hình dạng giống nội dung thật, để bố cục không nhảy khi dữ liệu về (giảm CLS, phục vụ NFR-00-005) và người dùng biết sắp thấy gì.

**Nền antd.** `Skeleton` (đoạn), `Skeleton.Input`, `Skeleton.Button`, `Skeleton.Avatar`, `Skeleton.Node`. Hàm bọc cung cấp các mẫu dựng sẵn khớp thành phần phức hợp: `table` (hàng tiêu đề + n hàng, chiều cao `size-table-row`), `description` (cặp nhãn – giá trị), `form` (nhãn + ô nhập), `card`, `kpi`.

**Thị giác.** Khối nền `color-fill-control`, bo `radius-xs` cho dòng chữ và bo theo thành phần thật cho khối khác. Hiệu ứng ánh sáng lướt (shimmer) bật mặc định với chu kỳ 1,6 giây, dải sáng dùng `color-fill-hover`; token thành phần antd `Skeleton.gradientFromColor` và `Skeleton.gradientToColor` đặt lần lượt theo `color-fill-control` và `color-fill-pressed`. Khi giảm chuyển động, tắt shimmer, giữ khối tĩnh.

**Thời điểm.** Skeleton chỉ cho lần tải đầu. Khi làm mới dữ liệu đã có (đổi trang, lọc lại), giữ dữ liệu cũ hiển thị mờ nhẹ kèm `CMP-Spinner` nhỏ ở góc vùng hoặc thanh tiến trình mảnh trên đầu bảng, không quay về Skeleton (tránh nhấp nháy, TanStack Query `placeholderData: keepPreviousData`). Skeleton chỉ hiện sau 200ms; nếu dữ liệu về trước đó thì không hiện.

**Token.** `TKN-color-fill-control`, `TKN-color-fill-hover`, `TKN-color-fill-pressed`, `TKN-radius-xs`, `TKN-size-table-row`, `TKN-motion-duration-slower`.

**Nền đặt.** Nền đặc. Trong popover glass (danh sách đang tải của Select), dùng `CMP-Spinner` thay vì Skeleton.

**ARIA.** Vùng chứa Skeleton có `aria-busy="true"` và `aria-label` mô tả ("Đang tải bảng dịch vụ"); các khối có `aria-hidden="true"`.

**API.**

```tsx
export interface DhSkeletonProps {
  preset?: 'text' | 'table' | 'description' | 'form' | 'card' | 'kpi';
  rows?: number;
  columns?: number;     // preset table
  label: string;
  active?: boolean;     // shimmer, mặc định true
}
```

```tsx
{isLoading ? <Skeleton preset="description" rows={6} label="Đang tải thông tin dịch vụ" /> : <DescriptionList … />}
```

**Điều cấm.** Cấm Skeleton có hình dạng khác hẳn nội dung thật. Cấm dùng Skeleton cho thao tác gửi biểu mẫu.

### 6.3. CMP-ProgressBar

**Mục đích.** `CMP-ProgressBar` thể hiện tiến độ đã biết của một thao tác (nhập tệp, xuất dữ liệu, tải lên) hoặc mức sử dụng hạn mức (dung lượng, hạn ngạch lượt gọi). Thành phần phức hợp `CMP-JobProgress` (D03-05-04) ghép ProgressBar với trạng thái tác vụ nền.

**Nền antd.** `Progress` với `type="line"`. Không dùng `type="circle"` và `type="dashboard"` trong ứng dụng quản trị (vòng tròn chiếm diện tích, khó so sánh), trừ trong `CMP-KpiCard` nếu D03-05-04 cho phép.

**Biến thể.** `progress` (tiến độ thao tác; màu `color-accent`; khi xong chuyển `color-success-text` và hiện biểu tượng `success`; khi lỗi chuyển `color-error-text` và biểu tượng `error`) và `meter` (mức sử dụng; màu theo ngưỡng: dưới 80% `color-accent`, từ 80% `color-warning-solid` kèm chữ "Sắp đạt hạn mức", từ 100% `color-error-solid` kèm chữ "Đã đạt hạn mức"; ngưỡng cấu hình được). Biến thể `indeterminate` (không biết tiến độ, dải chạy qua lại) chỉ dùng tạm khi máy chủ chưa trả tiến độ, tối đa vài giây.

**Kích thước.** Độ dày 4px (`sm`, trên đầu bảng) hoặc 8px (`md`, mặc định). Bo `radius-xs` (token thành phần antd `Progress.lineBorderRadius`). Rãnh (`Progress.remainingColor`) dùng `color-fill-control`.

**Chữ đi kèm.** Phần trăm hiển thị bên phải bằng `font-footnote` với `font-feature-tabular`, làm tròn số nguyên, định dạng "45%". Với nhập tệp, chữ phụ nêu số tuyệt đối "4.500 / 10.000 dòng". Phần trăm không bao giờ là kênh duy nhất của trạng thái lỗi; luôn kèm chữ "Thất bại" và biểu tượng.

**Token.** `TKN-color-accent`, `TKN-color-success-text`, `TKN-color-error-text`, `TKN-color-warning-solid`, `TKN-color-error-solid`, `TKN-color-fill-control`, `TKN-radius-xs`, `TKN-font-footnote`, `TKN-font-feature-tabular`, `TKN-motion-duration-base`.

**Nền đặt.** Nền đặc và `glass-overlay` (trong `CMP-Notification` báo tiến độ tác vụ nền).

**ARIA.** `role="progressbar"`, `aria-valuenow`, `aria-valuemin="0"`, `aria-valuemax="100"`, `aria-valuetext` dạng "4.500 trên 10.000 dòng, 45%". `indeterminate` không có `aria-valuenow`. Biến thể `meter` dùng `role="meter"`. Thay đổi phần trăm không được đọc liên tục; vùng chứa thông báo `aria-live` ở các mốc 25/50/75/100% hoặc khi xong.

**API.**

```tsx
export interface DhProgressBarProps {
  variant?: 'progress' | 'meter' | 'indeterminate';
  percent?: number;
  status?: 'active' | 'success' | 'error';
  size?: 'sm' | 'md';
  valueText?: string;
  thresholds?: { warning: number; error: number }; // meter, mặc định 80/100
  label: string;
  showPercent?: boolean;
}
```

```tsx
<ProgressBar label="Tiến độ nhập tệp" percent={45} valueText="4.500 / 10.000 dòng" />
<ProgressBar variant="meter" label="Hạn ngạch lượt gọi tháng này" percent={86} />
```

**Điều cấm.** Cấm thanh tiến độ giả (tăng theo thời gian không dựa vào máy chủ). Cấm dùng màu đỏ cho thanh `progress` đang chạy bình thường.

### 6.4. CMP-Tooltip

**Mục đích.** `CMP-Tooltip` hiển thị chữ gợi ý ngắn khi hover hoặc focus vào một phần tử: tên của nút biểu tượng, chữ đầy đủ của nội dung bị rút gọn, lý do nút bị khóa, giờ chính xác của thời điểm tương đối.

**Khi dùng.** Bổ sung thông tin không bắt buộc cho thao tác. **Khi không dùng.** Thông tin người dùng **bắt buộc** phải biết để hoàn thành việc (hướng dẫn nhập, điều kiện, cảnh báo hậu quả) không được chỉ nằm trong tooltip; phải hiển thị thường trực bằng chữ mô tả của `CMP-FormField` hoặc `CMP-Alert`. Nội dung tương tác (liên kết, nút) không được đặt trong tooltip; dùng `CMP-Popover` (D03-05-04).

**Nền antd.** `Tooltip`. Nền là `colorBgSpotlight` = `color-surface-inverse` (nền đảo đặc, **không glass**), chữ `color-text-on-inverse`. Token thành phần antd `Tooltip.maxWidth` 320 đã đặt ở D03-05-02 §13.3. Hàm bọc cố định `mouseEnterDelay={0.4}`, `mouseLeaveDelay={0.1}`, `arrow={false}` (Liquid Glass không dùng mũi tên; tooltip cách phần tử 6px), `trigger={['hover', 'focus']}`, `destroyOnHidden`. Lớp `dh-tooltip` gắn qua `classNames.root`, phần thân qua `classNames.container` (tên phần ngữ nghĩa đã đối chiếu antd 6.7.1).

**Kích thước.** Đệm `space-1` dọc và `space-2` ngang, chữ `font-footnote`, bo `radius-sm`, rộng tối đa 320px, xuống dòng tự nhiên. Không có kích thước khác.

**Chuyển động.** Xuất hiện bằng mờ dần + phóng `motion-scale-enter` trong `motion-duration-fast` với `motion-ease-emphasized`; khi giảm chuyển động chỉ mờ dần.

**Token.** `TKN-color-surface-inverse`, `TKN-color-text-on-inverse`, `TKN-font-footnote`, `TKN-radius-sm`, `TKN-space-1`, `TKN-space-2`, `TKN-motion-duration-fast`, `TKN-motion-ease-emphasized`, `TKN-motion-scale-enter`, `TKN-z-tooltip`.

**Nền đặt.** Tooltip tự có nền đặc nên đặt được trên mọi nền; mở được từ trong Modal, popover glass.

**Bàn phím và ARIA.** Tooltip mở **ngay** khi phần tử nhận focus bằng bàn phím (không chờ 400ms), đóng khi mất focus hoặc khi nhấn Esc (WCAG 1.4.13: có thể bỏ qua). Người dùng di chuột từ phần tử lên tooltip thì tooltip không đóng (có thể rê). Phần tử kích hoạt nhận `aria-describedby` trỏ tới tooltip, trừ trường hợp tooltip là tên duy nhất của nút biểu tượng: khi đó `CMP-IconButton` dùng `aria-label` và tooltip chỉ hiển thị thị giác (`aria-hidden` trên tooltip) để không đọc hai lần. Phần tử không focus được (chữ bị rút gọn) phải được thành phần cha thêm `tabIndex={0}`. Tooltip không mở trên thiết bị cảm ứng khi chạm (chạm là kích hoạt); thông tin vì vậy càng không được là bắt buộc.

**Nội dung tiếng Việt.** Câu ngắn, tối đa khoảng 80 ký tự, không dấu chấm cuối nếu là cụm từ, có dấu chấm nếu là câu đầy đủ. Tooltip của nút biểu tượng là động từ ("Làm mới", "Cài đặt cột"). Có thể kèm `CMP-Kbd` phím tắt.

**API.**

```tsx
export interface DhTooltipProps {
  title: React.ReactNode;
  children: React.ReactElement;         // phần tử nhận ref và focus
  placement?: 'top' | 'bottom' | 'left' | 'right';
  /** true khi tooltip lặp lại aria-label của phần tử, để tránh đọc hai lần. */
  visualOnly?: boolean;
  open?: boolean;                        // điều khiển, dùng cho trạng thái "Đã sao chép"
}
```

```tsx
<Tooltip title="Thời điểm theo giờ Việt Nam (UTC+07:00)">
  <Text tabIndex={0}>2 phút trước</Text>
</Tooltip>
```

**Điều cấm.** Cấm đặt thông tin bắt buộc duy nhất trong tooltip. Cấm liên kết, nút trong tooltip. Cấm dùng thuộc tính HTML `title` thay tooltip. Cấm tooltip glass. Cấm tooltip trên phần tử `disabled` gốc (không nhận sự kiện; dùng `disabledReason`).

### 6.5. CMP-SaveIndicator

**Mục đích.** `CMP-SaveIndicator` cho người dùng biết công việc đang soạn đã an toàn trên máy chủ hay chưa, ở các màn có tự lưu hoặc phiên soạn dài: trình thiết kế luồng (PH-04 UI-04-04), lưới sửa danh mục (PH-07 UI-07-05), trình soạn mô hình quy trình (PH-11). Đây là hiện thực của nguyên tắc 4 "Trung thực về trạng thái" (D03-05 §2) cho thao tác ghi không có nút Lưu rõ ràng.

**Khi dùng / không dùng.** Dùng khi màn có tự lưu hoặc lưu nền. Không dùng cho biểu mẫu thường có nút Lưu (trạng thái đã thể hiện bằng nút `loading` và `CMP-Toast`, ST-09, ST-10 ở D03-06-00 §4.2).

**Nền antd.** Không có thành phần antd tương ứng; dựng từ `CMP-Icon`, `CMP-Text` và `CMP-Button` biến thể `text` cỡ `sm` cho hành động "Thử lại".

**Sáu trạng thái.** Bảng dưới là hợp đồng duy nhất cho mọi phân hệ. Chữ là kênh thông tin chính, biểu tượng là kênh thứ hai, màu là kênh thứ ba.

| Trạng thái | Biểu tượng | Chữ | Màu chữ | Hành động |
|---|---|---|---|---|
| `dirty` | Chấm tròn đặc 6px | "Chưa lưu" | `color-warning-text` | Bấm để lưu ngay (tương đương `Ctrl+S`) |
| `saving` | `CMP-Spinner` cỡ `sm` (đổi độ đục thay vì quay khi giảm chuyển động) | "Đang lưu…" | `color-text-secondary` | Không |
| `saved` | `success` (dấu tích) | "Đã lưu {HH:mm}" | `color-text-secondary` | Tooltip nêu thời điểm đầy đủ `CMP-Timestamp` |
| `error` | `warning` | "Lưu lỗi" + nút "Thử lại" | `color-error-text` | "Thử lại"; tooltip nêu mã lỗi và mã truy vết |
| `offline` | `offline` | "Chưa lưu lên máy chủ (mất kết nối)" | `color-warning-text` | Không; tự lưu lại khi có kết nối, bản nháp giữ cục bộ |
| `readonly` | `lock` | "Chỉ đọc" | `color-text-secondary` | Tooltip nêu lý do (đang duyệt, không có quyền, phiên bản đã phát hành) |

**Quy tắc chuyển trạng thái.** `saving` chỉ hiện sau 300ms để tránh nhấp nháy khi máy chủ trả nhanh; `saved` giữ nguyên tới lần thay đổi tiếp theo; `error` không tự biến mất. Khi chuyển sang `error` hoặc `offline`, thành phần phát một thông báo `aria-live="polite"` một lần ("Lưu không thành công"); các chuyển trạng thái khác không đọc để tránh ồn. Thời điểm trong `saved` lấy từ phản hồi máy chủ (`updatedAt`), không lấy đồng hồ máy trạm.

**Kích thước.** Một dòng, cao `size-control-sm`; chữ `font-footnote`. Dưới 1280px chỉ còn biểu tượng kèm `aria-label` và tooltip đầy đủ chữ.

**Token.** `TKN-color-warning-text`, `TKN-color-error-text`, `TKN-color-text-secondary`, `TKN-font-footnote`, `TKN-size-icon-sm`, `TKN-size-control-sm`, `TKN-space-1`.

**Nền đặt.** Nền đặc (thanh công cụ đặc của trình thiết kế). Không đặt trên `glass-chrome-scrolled` vì chữ màu trạng thái không đạt ngưỡng trên vật liệu đó (D03-05-01 §3.2).

**Bàn phím và ARIA.** Vùng gốc `role="status"`. Ở trạng thái `dirty` và `error`, phần tương tác là `<button>` có tên truy cập đầy đủ ("Lưu ngay", "Thử lưu lại").

**API.**

```tsx
export type DhSaveState = 'dirty' | 'saving' | 'saved' | 'error' | 'offline' | 'readonly';

export interface DhSaveIndicatorProps {
  state: DhSaveState;
  savedAt?: string;                 // T-TS từ máy chủ, bắt buộc khi state = 'saved'
  error?: DhApiError;               // khi state = 'error'
  readonlyReason?: string;          // khi state = 'readonly'
  onSaveNow?: () => void;
  onRetry?: () => void;
  compact?: boolean;
  testId?: string;
}
```

```tsx
<SaveIndicator state={session.saveState} savedAt={version.updatedAt} error={session.lastError}
  onSaveNow={session.flush} onRetry={session.flush} />
```

**Điều cấm.** Cấm báo "Đã lưu" khi dữ liệu mới chỉ nằm ở IndexedDB hay `localStorage`. Cấm tự ẩn trạng thái lỗi. Cấm dùng `CMP-Toast` cho mỗi lần tự lưu thành công.

## 7. Nhóm nhập liệu

### 7.0. Quy tắc chung của điều khiển nhập liệu

Mọi thành phần trong mục này tuân theo năm quy tắc chung, nên các mục con chỉ nêu điểm khác. Thứ nhất, điều khiển nhập liệu **không tự hiển thị nhãn, chữ mô tả và thông báo lỗi**; ba phần này do `CMP-FormField` (D03-05-04) dựng và nối bằng `id`, `aria-labelledby`, `aria-describedby`, `aria-invalid`, `aria-required`. Điều khiển dùng ngoài biểu mẫu (ví dụ ô tìm kiếm trên thanh công cụ) phải có `aria-label`. Thứ hai, biến thể thị giác mặc định là `outlined` (viền `color-border-control` đạt 3:1, WCAG 1.4.11); biến thể `filled` (nền `color-fill-control`, không viền) chỉ dùng trong thanh công cụ và topbar; `borderless` chỉ dùng cho sửa tại chỗ trong ô bảng. Thứ ba, trạng thái `invalid` lấy từ prop `status="error"` của antd, viền `color-error-text`, và token thành phần antd `errorActiveShadow` dùng `color-error-bg`; chữ lỗi do `CMP-FormField` hiển thị ngay dưới trường (FR-00-081). Thứ tư, kích thước `sm` / `md` / `lg` ánh xạ `size-control-sm` / `size-control-md` / `size-control-lg`, bo `radius-sm` (`sm`) hoặc `radius-md`, chữ luôn `font-body` 14px (không giảm cỡ ở `sm` vì chữ nhập là nội dung). Thứ năm, điều khiển nhập liệu luôn đặt trên nền đặc (`color-surface-solid` của trang, thẻ, giếng nội dung Modal); ngoại lệ là ô tìm kiếm biến thể `filled` trên topbar glass do `CMP-Topbar` quy định, và các điều khiển trong popover glass (bộ lọc cột của bảng) dùng `glass-overlay`.

Token dùng chung cho cả nhóm: `TKN-color-surface-solid`, `TKN-color-surface-solid-2` (readonly), `TKN-color-fill-control` (filled, disabled), `TKN-color-border-control`, `TKN-color-border-subtle`, `TKN-color-text-primary`, `TKN-color-text-tertiary` (placeholder), `TKN-color-text-disabled`, `TKN-color-error-text`, `TKN-color-error-bg`, `TKN-color-focus-ring`, `TKN-color-focus-ring-inner`, `TKN-size-control-sm`, `TKN-size-control-md`, `TKN-size-control-lg`, `TKN-radius-sm`, `TKN-radius-md`, `TKN-font-body`, `TKN-motion-duration-instant`. Token thành phần antd `Input.hoverBorderColor` giữ `color-border-control` (không đổi màu viền khi hover để tránh nhầm với focus), `Input.activeBorderColor` là `color-accent`, `Input.activeShadow` dùng `controlOutline`.

Chữ giữ chỗ (placeholder) là ví dụ định dạng ("VD: 0912345678"), không thay nhãn và không chứa hướng dẫn bắt buộc, vì biến mất khi người dùng gõ.

### 7.1. CMP-Input

**Mục đích.** `CMP-Input` nhận chuỗi một dòng: tên, mã, URL, thư điện tử, từ khóa tìm kiếm.

**Nền antd.** `Input` và `Input.Search` (cho biến thể tìm kiếm). Hàm bọc cố định `autoComplete` theo `type` (ví dụ `"off"` cho mã nghiệp vụ, `"email"` cho thư điện tử), `allowClear` bật mặc định với biểu tượng `close` Lucide và nhãn "Xóa nội dung", `count` bật khi có `maxLength` (CRUD-C-02, hiển thị "12/255").

**Biến thể.** `text` (mặc định), `search` (tiền tố biểu tượng `search`, nhấn Enter gọi `onSearch` theo CRUD-FLT-03, không có nút "Tìm" riêng trong ô; nút "Tìm kiếm" của `CMP-FilterBar` nằm ngoài), `code` (chữ `font-family-mono`, tự chuyển chữ hoa theo `T-CODE` khi mất focus, kiểm tra mẫu `^[A-Z0-9][A-Z0-9_.-]{0,63}$`), `url` (`inputMode="url"`), `email` (`type="email"`, `inputMode="email"`). Tiền tố và hậu tố (`prefix`, `suffix`) chỉ chứa `CMP-Icon` hoặc chữ đơn vị ngắn.

**Tìm kiếm không dấu.** FR-00-020 yêu cầu tìm "da nang" ra "Đà Nẵng". Việc so khớp không phân biệt hoa thường và dấu tiếng Việt là **trách nhiệm của backend** (chuẩn hóa `unaccent` + `lower` ở truy vấn PostgreSQL hoặc chỉ mục tìm kiếm). Biến thể `search` chỉ có ba trách nhiệm phía giao diện: gửi nguyên văn chuỗi người dùng gõ sau khi cắt khoảng trắng hai đầu và chuẩn hóa NFC (để "Đà" gõ bằng bộ gõ tổ hợp và bộ gõ dựng sẵn cho cùng chuỗi), không tự bỏ dấu (để backend còn ưu tiên kết quả khớp đúng dấu nếu muốn), và trì hoãn (debounce) 300ms khi dùng chế độ tìm theo gõ (`searchMode="instant"`) cho danh sách nhỏ. Với bộ gõ tiếng Việt (Unikey, EVKey, bộ gõ macOS), thành phần không gửi tìm kiếm khi đang trong phiên soạn ký tự (`compositionstart` → `compositionend`), tránh gửi chuỗi dở dang như "Ða" rồi "Đà".

**Trạng thái.** Đủ tám trạng thái trừ `pressed`. `loading` chỉ có ở biến thể `search` khi đang tìm (spinner ở hậu tố).

**Bàn phím và ARIA.** Biến thể `search` có `role="searchbox"` (antd `Input` với `type="search"`); Esc xóa nội dung khi có nội dung, lần Esc thứ hai không làm gì (để Modal chứa nó không bị đóng ngoài ý muốn, thành phần gọi `stopPropagation` ở lần Esc đầu).

**Nội dung.** Giá trị được cắt khoảng trắng hai đầu trước khi gửi (do `CMP-Form`); thông báo lỗi định dạng theo FR-00-080: nói điều sai và cách sửa ("Mã chỉ gồm chữ in hoa, số, dấu chấm, gạch dưới, gạch ngang; tối đa 64 ký tự").

**API.**

```tsx
export interface DhInputProps {
  variant?: 'text' | 'search' | 'code' | 'url' | 'email';
  appearance?: 'outlined' | 'filled' | 'borderless';
  size?: 'sm' | 'md' | 'lg';
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;          // nhận chuỗi, không nhận event
  onSearch?: (value: string) => void;          // variant="search"
  searchMode?: 'enter' | 'instant';
  placeholder?: string;
  maxLength?: number;
  prefix?: React.ReactNode;
  suffix?: React.ReactNode;
  allowClear?: boolean;
  disabled?: boolean;
  readOnly?: boolean;
  status?: 'error' | 'warning';
  loading?: boolean;
  id?: string;
  'aria-label'?: string;
  'aria-describedby'?: string;
  testId?: string;
  ref?: React.Ref<InputRef>;
}
```

```tsx
<Input variant="search" aria-label="Tìm theo tên hoặc mã dịch vụ" placeholder="Tên hoặc mã dịch vụ"
  onSearch={(q) => setFilter({ q, page: 1 })} />
<Input variant="code" maxLength={64} placeholder="VD: TRA_CUU_HO_TICH" />
```

**Điều cấm.** Cấm bỏ dấu chuỗi tìm kiếm phía giao diện rồi lọc dữ liệu đã tải (CRUD-FLT-08). Cấm dùng placeholder thay nhãn. Cấm `type="number"` (dùng `CMP-NumberInput`). Cấm `type="password"` cho bí mật hệ thống (dùng `CMP-SecretField`).

### 7.2. CMP-SecretField

**Mục đích.** `CMP-SecretField` xử lý giá trị bí mật: khóa API, client secret, mật khẩu kết nối cơ sở dữ liệu, khóa ký webhook. Thành phần có hai chế độ phục vụ hai tình huống khác nhau về bảo mật.

**Chế độ `issue` (hiển thị một lần khi cấp).** Sau khi máy chủ sinh bí mật mới (tạo khóa API, xoay vòng client secret), bí mật được trả về **đúng một lần** trong phản hồi tạo. Thành phần hiển thị bí mật trong giếng nội dung của một Modal với các quy tắc sau:

1. Bí mật hiển thị bằng `font-mono`, đầy đủ (không che), trong ô chỉ đọc nền `color-surface-solid-2`, kèm `CMP-CopyButton variant="labeled"` có `sensitive` và nút "Tải tệp .txt" (tùy chọn theo phân hệ).
2. Một `CMP-Alert` (D03-05-04) sắc thái `warning` thường trực phía trên: "Đây là lần duy nhất bí mật được hiển thị. Hãy sao chép và lưu ở nơi an toàn. Nếu làm mất, bạn phải tạo bí mật mới."
3. Nút đóng Modal có nhãn "Tôi đã lưu bí mật" và chỉ bật sau khi người dùng đã bấm sao chép hoặc tải tệp, hoặc đã tích ô xác nhận "Tôi đã lưu bí mật ở nơi an toàn". Esc và bấm ra ngoài không đóng Modal ở chế độ này.
4. **Không lưu bí mật trong state lâu dài.** Bí mật chỉ được giữ trong `useRef` cục bộ của thành phần, không đưa vào bộ đệm TanStack Query (mutation tạo đặt `gcTime: 0` và thành phần đọc từ `onSuccess` rồi xóa `data` của mutation bằng `reset()`), không vào Redux/Zustand, không vào URL, không vào `localStorage`/`sessionStorage`, không ghi log. Khi Modal đóng hoặc thành phần bị gỡ, ref được gán chuỗi rỗng.
5. Phần tử hiển thị có `autoComplete="off"`, `spellCheck={false}`, `data-1p-ignore`, `data-lpignore="true"` để trình quản lý mật khẩu và trình kiểm tra chính tả không thu thập.

**Chế độ `input` (nhập bí mật).** Người dùng nhập bí mật của hệ thống ngoài (mật khẩu kết nối). Nền là `Input.Password` với nút hiện/ẩn biểu tượng `view` / `hide` (nhãn "Hiện bí mật" / "Ẩn bí mật"). Khi sửa một bản ghi đã có bí mật, máy chủ không bao giờ trả lại bí mật; ô hiển thị giá trị giữ chỗ "Đã đặt • cập nhật 12/11/2026" và nút "Thay bí mật"; chỉ khi bấm, ô nhập mới mở. Biểu mẫu gửi trường bí mật chỉ khi người dùng đã nhập giá trị mới (giá trị `undefined` nghĩa là giữ nguyên). Bí mật tự che lại khi ô mất focus quá 30 giây.

**Kích thước, trạng thái, token.** Như quy tắc chung, thêm `TKN-font-mono`, `TKN-color-warning-bg`, `TKN-color-warning-on-bg`.

**Nền đặt.** Chỉ nền đặc (giếng nội dung Modal hoặc biểu mẫu).

**Bàn phím và ARIA.** Ô hiển thị bí mật ở chế độ `issue` có `aria-label="Bí mật vừa được cấp"` và `aria-describedby` trỏ tới cảnh báo; focus ban đầu của Modal đặt vào nút sao chép. Nút hiện/ẩn ở chế độ `input` có `aria-pressed` và `aria-controls`.

**API.**

```tsx
type DhSecretFieldProps =
  | {
      mode: 'issue';
      /** Hàm lấy bí mật một lần; thành phần giữ trong ref, không trong state. */
      takeSecret: () => string;
      secretLabel: string;              // "Khóa API"
      allowDownload?: boolean;
      onAcknowledge: () => void;        // người dùng đã xác nhận lưu
      onCopyAudit?: () => void;
    }
  | {
      mode: 'input';
      value?: string;
      onChange?: (value: string | undefined) => void;
      hasExistingSecret?: boolean;
      existingUpdatedAt?: string;       // T-TS
      disabled?: boolean;
      status?: 'error';
      id?: string;
      'aria-describedby'?: string;
    };
```

```tsx
<SecretField mode="issue" secretLabel="Khóa API" takeSecret={() => created.current!.secret}
  onAcknowledge={closeModal} onCopyAudit={() => audit('API_KEY_SECRET_COPIED', created.current!.id)} />
```

**Điều cấm.** Cấm lưu bí mật vào bất kỳ kho trạng thái nào ngoài ref cục bộ. Cấm hiển thị lại bí mật đã cấp ở bất kỳ màn hình nào. Cấm gửi bí mật trong tham số URL. Cấm dùng `CMP-MaskedValue` cho bí mật (MaskedValue cho phép mở xem lại, bí mật thì không).

### 7.3. CMP-TextArea

**Mục đích.** `CMP-TextArea` nhận chuỗi nhiều dòng: mô tả, ghi chú, lý do (trong `CMP-ReasonDialog`), ý kiến duyệt (FR-00-072).

**Nền antd.** `Input.TextArea` với `autoSize={{ minRows: 3, maxRows: 12 }}` mặc định, `showCount` bật khi có `maxLength`. Mô tả theo `T-TEXT` có `maxLength={4000}`.

**Biến thể.** `default`; `reason` (tối thiểu 10 ký tự sau khi cắt khoảng trắng, bộ đếm hiển thị "Còn thiếu 6 ký tự" cho đến khi đủ, dùng trong `CMP-ReasonDialog`); `code` không có (dùng `CMP-CodeEditor`).

**Trạng thái, token.** Như quy tắc chung. Vùng kéo đổi kích thước (`resize`) tắt khi `autoSize`; khi bật, chỉ cho kéo dọc và luôn có phương án không kéo là `autoSize` (WCAG 2.5.7).

**Bàn phím.** Enter xuống dòng; Ctrl/⌘ + Enter gửi biểu mẫu chứa nó nếu biểu mẫu khai báo (gợi ý `CMP-Kbd` hiển thị dưới trường).

**API.**

```tsx
export interface DhTextAreaProps {
  variant?: 'default' | 'reason';
  value?: string; defaultValue?: string; onChange?: (value: string) => void;
  minLength?: number; maxLength?: number;
  minRows?: number; maxRows?: number;
  placeholder?: string; disabled?: boolean; readOnly?: boolean; status?: 'error';
  submitOnModEnter?: boolean;
  id?: string; 'aria-describedby'?: string; testId?: string;
  ref?: React.Ref<TextAreaRef>;
}
```

```tsx
<TextArea variant="reason" minLength={10} maxLength={1000} placeholder="VD: Tạm dừng để bảo trì cơ sở dữ liệu nguồn" />
```

**Điều cấm.** Cấm nhận Markdown hoặc HTML rồi hiển thị không qua làm sạch. Cấm TextArea không giới hạn độ dài.

### 7.4. CMP-NumberInput

**Mục đích.** `CMP-NumberInput` nhận số: hạn ngạch, thời gian chờ, số lần thử lại, số tiền (với biến thể `money`).

**Nền antd.** `InputNumber` với `controls={false}` mặc định (nút tăng giảm nhỏ khó bấm và vùng chạm dưới 24px); bật `controls` chỉ khi khoảng giá trị nhỏ (dưới 20 bước). Hàm bọc đặt `decimalSeparator=","` và bộ `formatter` / `parser` định dạng hàng nghìn bằng dấu chấm theo kiểu Việt Nam ("1.234.567"; "12,5"). Chữ số dùng `font-feature-tabular`, căn phải.

**Biến thể.** `number` (mặc định), `integer` (`precision={0}`), `money` (`precision={0}`, hậu tố "₫", giá trị kiểu `T-MONEY`; số tiền lớn hơn `Number.MAX_SAFE_INTEGER` được truyền dạng chuỗi và thành phần dùng chế độ `stringMode` của antd để không mất chính xác), `percent` (hậu tố "%", 0–100), `duration` (hậu tố đơn vị do màn hình truyền: "ms", "giây", "phút").

**Trạng thái.** Ngoài trạng thái chung, giá trị ngoài `min` / `max` được giữ nguyên khi đang gõ và chỉ báo lỗi khi mất focus, không tự kẹp giá trị (tự kẹp làm người dùng mất dữ liệu đã gõ mà không biết).

**Bàn phím và ARIA.** Mũi tên lên/xuống tăng giảm `step`; Shift + mũi tên tăng giảm 10 bước. Thành phần đặt `role="spinbutton"`, `aria-valuemin`, `aria-valuemax`, `aria-valuenow` (antd đã có) và `inputMode="decimal"` hoặc `"numeric"`.

**Token.** Chung, thêm `TKN-font-feature-tabular`.

**API.**

```tsx
export interface DhNumberInputProps {
  variant?: 'number' | 'integer' | 'money' | 'percent' | 'duration';
  unit?: string;                        // duration
  value?: number | string | null;       // string khi money vượt safe integer
  onChange?: (value: number | string | null) => void;
  min?: number; max?: number; step?: number;
  controls?: boolean;
  size?: 'sm' | 'md' | 'lg';
  placeholder?: string; disabled?: boolean; readOnly?: boolean; status?: 'error';
  id?: string; 'aria-describedby'?: string; testId?: string;
  ref?: React.Ref<HTMLInputElement>;
}
```

```tsx
<NumberInput variant="duration" unit="ms" min={100} max={60000} step={100} />
<NumberInput variant="money" min={0} />
```

**Điều cấm.** Cấm dùng số thực cho tiền. Cấm định dạng kiểu Mỹ ("1,234.5"). Cấm tự kẹp giá trị khi đang gõ.

### 7.5. CMP-Select

**Mục đích.** `CMP-Select` chọn một hoặc nhiều giá trị từ danh sách: trạng thái, lĩnh vực, đơn vị, phương thức xác thực, người dùng. Đây là điều khiển chính của `CMP-FilterBar` (FR-00-023).

**Khi dùng / không dùng.** Từ 6 lựa chọn trở lên, hoặc danh sách động. Dưới 6 lựa chọn loại trừ nhau và cần thấy hết: `CMP-Radio` (trong biểu mẫu) hoặc `CMP-SegmentedControl` (chuyển chế độ xem). Dữ liệu phân cấp: `CMP-TreeSelect`. Chuyển nhiều mục giữa hai danh sách lớn: `CMP-Transfer`.

**Nền antd.** `Select`. Hàm bọc cố định: `suffixIcon` là `chevron-down` Lucide; `allowClear` bật khi không bắt buộc; `optionFilterProp="label"`; `notFoundContent` là chữ "Không có lựa chọn phù hợp" (không dùng ảnh trống của antd); `popupMatchSelectWidth` là `true` với độ rộng tối thiểu 200px; `virtual` bật (mặc định antd) cho danh sách dài; `getPopupContainer` để mặc định (gắn vào `body`) trừ khi trong Modal cần cuộn cùng, khi đó `CMP-Modal` cung cấp container qua context.

**Popup dùng glass-overlay.** Danh sách thả xuống là lớp nổi nên dùng vật liệu `glass-overlay`. Hàm bọc gắn lớp `dh-glass--overlay` qua `classNames.popup.root` (tên phần ngữ nghĩa đã đối chiếu antd 6.7.1; không dùng `popupClassName` đã cũ). Nền `colorBgElevated` đã được ánh xạ sang tint của `glass-overlay` ở D03-05-02 §13.2, nên lớp CSS chỉ thêm `backdrop-filter`, viền và bóng `shadow-3`. Option đang được trỏ (`optionActiveBg`) dùng `color-fill-hover`, option đã chọn (`optionSelectedBg`) dùng `color-fill-selected` với chữ `optionSelectedColor` là `color-accent-on-subtle` và `optionSelectedFontWeight` 500, kèm biểu tượng `copied` (dấu tích) ở cuối để không chỉ dựa vào màu. Bo popup `radius-lg`, option bo `radius-sm` có lề trong `space-1`. Chế độ glass "Tắt" làm popup thành nền đặc tự động qua token. Select mở từ trong Modal vẫn dùng `glass-overlay` (ngoại lệ glass chồng glass được phép).

**Biến thể chức năng.** Bốn tính năng có thể kết hợp:

1. **Nhiều giá trị** (`multiple`): giá trị đã chọn hiển thị thành `CMP-Tag` cỡ `sm` đóng được; `maxTagCount="responsive"` để tự gộp thành "+3" khi chật, tooltip của "+3" liệt kê giá trị ẩn. Popup không đóng sau mỗi lần chọn. Có hai mục đặc biệt đầu danh sách khi `selectAll` bật: "Chọn tất cả" và "Bỏ chọn tất cả" (chỉ với danh sách tĩnh dưới 200 mục).
2. **Tìm kiếm** (`showSearch`): bật mặc định khi có từ 10 lựa chọn. Với danh sách tĩnh, lọc phía giao diện bằng hàm so khớp bỏ dấu tiếng Việt `matchVi(label, query)` của `@datahub/ui/format` (chuẩn hóa NFD, bỏ dấu kết hợp, đổi "đ" thành "d", không phân biệt hoa thường); đây là danh sách nhỏ đã nằm trọn trong bộ nhớ nên không vi phạm CRUD-FLT-08.
3. **Tải từ xa** (`remote`): khi danh sách lớn hoặc phụ thuộc quyền (người dùng, đơn vị, dịch vụ), thành phần nhận `fetchOptions(query, page)` trả `{ items, hasMore }`; gọi sau debounce 300ms, hủy yêu cầu cũ bằng `AbortController`, cuộn tới cuối tải trang tiếp (`onPopupScroll`), hiển thị `CMP-Spinner` cỡ `sm` cuối danh sách khi đang tải, và thông báo lỗi "Không tải được danh sách. Thử lại" kèm nút thử lại khi lỗi. Bỏ dấu là việc của backend (FR-00-020). Giá trị đã chọn nhưng không nằm trong trang hiện tại được hiển thị nhờ prop `value` dạng `{ value, label }` (`labelInValue`) để không phải tải lại nhãn.
4. **Nhóm** (`options` có `options` con): tiêu đề nhóm `font-caption` độ đậm 600 màu `color-text-secondary`.

**Kích thước, trạng thái.** Như quy tắc chung; trạng thái `loading` hiện spinner thay mũi tên.

**Token.** Chung, cộng với nhóm token của popup. Tint của popup không gọi trực tiếp mà lấy qua `colorBgElevated` (ánh xạ từ `TKN-glass-overlay`); lớp CSS dùng `TKN-blur-lg`, `TKN-saturate-glass-muted`, `TKN-glass-highlight-top`, `TKN-glass-edge`, `TKN-shadow-3`, `TKN-radius-lg`, `TKN-color-fill-hover`, `TKN-color-fill-selected`, `TKN-color-accent-on-subtle`, `TKN-z-popover`, `TKN-motion-duration-base`, `TKN-motion-ease-emphasized`.

**Bàn phím và ARIA.** Theo mẫu combobox của ARIA APG: `role="combobox"`, `aria-expanded`, `aria-controls`, `aria-activedescendant` (antd cung cấp). Mũi tên xuống mở và di chuyển, Enter chọn, Esc đóng popup (Esc lần hai mới đến Modal), Backspace trong ô trống của chế độ nhiều giá trị xóa tag cuối, gõ ký tự để tìm. Số kết quả được thông báo qua vùng `aria-live` ("12 lựa chọn").

**Nội dung.** Placeholder dạng "Chọn {đối tượng}" ("Chọn trạng thái"); với nhiều giá trị "Chọn một hoặc nhiều {đối tượng}". Nhãn option dùng tên nghiệp vụ; khi trùng tên, thêm mã ở chữ phụ (`font-footnote`, `color-text-secondary`).

**API.**

```tsx
export interface DhSelectOption<V = string> { value: V; label: string; description?: string; disabled?: boolean; }

export interface DhSelectProps<V = string> {
  options?: Array<DhSelectOption<V> | { label: string; options: DhSelectOption<V>[] }>;
  multiple?: boolean;
  value?: V | V[] | DhSelectOption<V> | DhSelectOption<V>[];
  onChange?: (value: any) => void;
  showSearch?: boolean;
  selectAll?: boolean;
  remote?: {
    fetchOptions: (query: string, page: number, signal: AbortSignal) => Promise<{ items: DhSelectOption<V>[]; hasMore: boolean }>;
    debounceMs?: number;            // mặc định 300
  };
  placeholder?: string;
  size?: 'sm' | 'md' | 'lg';
  appearance?: 'outlined' | 'filled' | 'borderless';
  allowClear?: boolean;
  disabled?: boolean; readOnly?: boolean; loading?: boolean; status?: 'error';
  id?: string; 'aria-label'?: string; 'aria-describedby'?: string; testId?: string;
  ref?: React.Ref<RefSelectProps>;
}
```

```tsx
<Select multiple placeholder="Chọn trạng thái"
  options={['DRAFT', 'PENDING_APPROVAL', 'PUBLISHED', 'SUSPENDED'].map((c) => ({ value: c, label: getStatusMeta(c).label }))} />

<Select placeholder="Chọn đơn vị" remote={{ fetchOptions: (q, p, signal) => api.units.search({ q, page: p }, { signal }) }} />
```

**Điều cấm.** Cấm tải toàn bộ danh sách lớn về trình duyệt để lọc. Cấm popup nền đặc tự viết thay vì `glass-overlay`. Cấm dùng `mode="tags"` cho phép nhập giá trị tự do trừ khi đặc tả màn hình ghi rõ (khi đó dùng `CMP-Select` với `allowCreate` có kiểm tra định dạng). Cấm Select cho dưới 3 lựa chọn.

### 7.6. CMP-TreeSelect

**Mục đích.** `CMP-TreeSelect` chọn một hoặc nhiều nút trong dữ liệu phân cấp: đơn vị hành chính (tỉnh → xã), cơ cấu tổ chức, cây danh mục, nhóm dịch vụ.

**Nền antd.** `TreeSelect`. Popup gắn `dh-glass--overlay` qua `classNames.popup.root`; biểu tượng mở rộng `chevron-right`; `treeLine` tắt; `showSearch` bật với `treeNodeFilterProp="title"` và lọc bỏ dấu `matchVi` cho cây tĩnh.

**Biến thể.** Đơn chọn (mặc định); nhiều chọn có hộp kiểm (`treeCheckable`) với `showCheckedStrategy` mặc định `SHOW_PARENT` (chọn cả cha thì chỉ hiện cha) để danh sách tag gọn; tải lười (`loadData`) cho cây lớn như đơn vị hành chính, tải con khi mở nút; tìm kiếm từ xa cho cây lớn (backend trả các nút khớp kèm đường dẫn tổ tiên).

**Trạng thái, token, nền.** Như `CMP-Select`. Nút không chọn được (chỉ để nhóm) có `selectable: false` và chữ `color-text-secondary`, không dùng `color-text-disabled` vì không phải bị vô hiệu.

**Bàn phím và ARIA.** Mũi tên lên/xuống di chuyển, phải mở nút / vào con, trái đóng nút / về cha, Space bật tắt hộp kiểm, Enter chọn. Popup có `role="tree"`, nút có `aria-level`, `aria-expanded`, `aria-selected` hoặc `aria-checked`.

**Nội dung.** Giá trị đã chọn hiển thị nhãn kèm đường dẫn rút gọn khi trùng tên ("Phường 1 · Quận 3").

**API.**

```tsx
export interface DhTreeSelectProps<V = string> {
  treeData: DhTreeNode<V>[];
  multiple?: boolean;                 // dùng treeCheckable
  checkedStrategy?: 'parent' | 'child' | 'all';
  loadChildren?: (node: DhTreeNode<V>) => Promise<DhTreeNode<V>[]>;
  remoteSearch?: (query: string, signal: AbortSignal) => Promise<DhTreeNode<V>[]>;
  value?: V | V[]; onChange?: (value: V | V[]) => void;
  placeholder?: string; size?: 'sm' | 'md' | 'lg';
  disabled?: boolean; readOnly?: boolean; status?: 'error';
  id?: string; 'aria-describedby'?: string; testId?: string;
}
export interface DhTreeNode<V = string> { value: V; title: string; isLeaf?: boolean; selectable?: boolean; children?: DhTreeNode<V>[]; }
```

```tsx
<TreeSelect placeholder="Chọn đơn vị hành chính" treeData={provinces} loadChildren={(n) => api.adminUnits.children(n.value)} />
```

**Điều cấm.** Cấm tải toàn bộ cây hơn 2.000 nút một lần. Cấm cây sâu quá 6 cấp trong TreeSelect (dùng `CMP-Tree` trong trang).

### 7.7. CMP-Checkbox

**Mục đích.** `CMP-Checkbox` bật tắt một lựa chọn độc lập trong biểu mẫu (chấp nhận điều khoản, "Gửi thông báo cho người tạo"), hoặc chọn nhiều mục trong nhóm (`Checkbox.Group`), hoặc chọn hàng trong `CMP-DataTable`.

**Khi dùng / không dùng.** Lựa chọn chỉ có hiệu lực khi bấm Lưu: Checkbox. Thiết lập có hiệu lực ngay khi gạt: `CMP-Switch`.

**Nền antd.** `Checkbox`, `Checkbox.Group`. Wave tắt toàn cục; phản hồi nhấn áp lên ô chọn. Token thành phần antd `Checkbox.checkboxSize` 16 (ô thị giác), vùng chạm mở rộng tới 24×24 bằng nhãn bọc ngoài và lớp giả.

**Trạng thái.** `unchecked` (viền `color-border-control`, nền `color-surface-solid`), `checked` (nền `color-accent`, dấu tích `color-text-on-accent`), `indeterminate` (nền `color-accent`, gạch ngang; dùng cho "chọn tất cả" khi chọn một phần), cộng `hover`, `focus-visible`, `disabled` (nền `color-fill-control`, dấu `color-text-disabled`), `invalid` (viền `color-error-text`). Bo `radius-xs`.

**Token.** `TKN-color-border-control`, `TKN-color-surface-solid`, `TKN-color-accent`, `TKN-color-accent-hover`, `TKN-color-text-on-accent`, `TKN-color-fill-control`, `TKN-color-text-disabled`, `TKN-color-error-text`, `TKN-radius-xs`, `TKN-motion-duration-fast`.

**Nền đặt.** Nền đặc và `glass-overlay` (bộ lọc cột, menu chọn cột hiển thị).

**Bàn phím và ARIA.** Space bật tắt. Nhóm có `role="group"` với `aria-labelledby` trỏ nhãn nhóm (do `CMP-FormField` dựng `fieldset`/`legend`). `indeterminate` đặt `aria-checked="mixed"`.

**Nội dung.** Nhãn là câu khẳng định mô tả điều xảy ra khi chọn ("Gửi thư thông báo cho người tạo"), không phủ định ("Không gửi thư").

**API.**

```tsx
export interface DhCheckboxProps {
  checked?: boolean; defaultChecked?: boolean; indeterminate?: boolean;
  onChange?: (checked: boolean) => void;
  children?: React.ReactNode;     // nhãn
  disabled?: boolean; status?: 'error';
  id?: string; 'aria-label'?: string; 'aria-describedby'?: string; testId?: string;
  ref?: React.Ref<CheckboxRef>;
}
export interface DhCheckboxGroupProps<V = string> {
  options: Array<{ value: V; label: string; disabled?: boolean }>;
  value?: V[]; onChange?: (value: V[]) => void;
  direction?: 'vertical' | 'horizontal';   // mặc định vertical khi > 3 mục
  disabled?: boolean;
}
```

```tsx
<Checkbox>Gửi thư thông báo cho người tạo</Checkbox>
```

**Điều cấm.** Cấm Checkbox có hiệu lực tức thì không cần Lưu (dùng Switch). Cấm Checkbox không nhãn ngoài ô chọn hàng của bảng (ô chọn hàng có `aria-label` "Chọn {tên hàng}").

### 7.8. CMP-Radio

**Mục đích.** `CMP-Radio` chọn đúng một trong 2 đến 5 lựa chọn loại trừ nhau, khi người dùng cần thấy tất cả lựa chọn để so sánh (phương thức xác thực, kiểu lịch chạy).

**Nền antd.** `Radio.Group` với `options`. Không dùng `optionType="button"` (dùng `CMP-SegmentedControl`). Biến thể `card` (mỗi lựa chọn là một khối có tiêu đề và mô tả, viền `color-border-subtle`, chọn thì viền `color-accent` 2px và nền `color-accent-subtle`) dùng khi lựa chọn cần giải thích, ví dụ chọn kiểu kết nối trong wizard PTN-05.

**Trạng thái.** Như Checkbox; ô tròn 16px (`Radio.radioSize`), chấm trong 8px (`Radio.dotSize`) màu `color-text-on-accent` trên nền `color-accent`.

**Token.** Như Checkbox, thêm `TKN-color-accent-subtle`, `TKN-color-border-subtle`, `TKN-radius-lg` (biến thể card), `TKN-space-4`.

**Nền đặt.** Nền đặc.

**Bàn phím và ARIA.** `role="radiogroup"`; Tab vào nhóm focus mục đang chọn (hoặc mục đầu), mũi tên di chuyển và chọn đồng thời, Tab rời nhóm.

**Nội dung.** Lựa chọn sắp theo thứ tự logic hoặc phổ biến nhất trước; luôn có giá trị mặc định hợp lý được chọn sẵn, trừ khi việc chọn sẵn tạo thiên lệch có hậu quả (khi đó để trống và bắt buộc chọn).

**API.**

```tsx
export interface DhRadioGroupProps<V = string> {
  options: Array<{ value: V; label: string; description?: string; disabled?: boolean }>;
  value?: V; onChange?: (value: V) => void;
  variant?: 'default' | 'card';
  direction?: 'vertical' | 'horizontal';
  disabled?: boolean; status?: 'error';
  id?: string; 'aria-labelledby'?: string; testId?: string;
}
```

```tsx
<RadioGroup variant="card" options={[
  { value: 'REST', label: 'REST API', description: 'Gọi dịch vụ HTTP của hệ thống nguồn' },
  { value: 'DB', label: 'Cơ sở dữ liệu', description: 'Đọc trực tiếp bảng hoặc khung nhìn' },
]} />
```

**Điều cấm.** Cấm Radio đơn lẻ. Cấm hơn 5 lựa chọn (dùng Select).

### 7.9. CMP-Switch

**Mục đích.** `CMP-Switch` bật tắt một thiết lập **có hiệu lực ngay**: bật/tắt lịch chạy, bật thông báo theo kênh (FR-00-061), bật chế độ gọn.

**Nền antd.** `Switch`. Token thành phần antd `Switch.trackHeight` 22 và `Switch.handleSize` 18 đã đặt ở D03-05-02 §13.3 (viên nang kiểu iOS thu nhỏ); cỡ `sm` dùng `trackHeightSM` và `handleSizeSM` mặc định của antd. Nút gạt nền `color-surface-solid` (`Switch.handleBg`) với bóng nhẹ.

**Trạng thái.** Tắt: rãnh `color-fill-control` kèm viền trong 1px `color-border-control` để rãnh đạt 3:1 (rãnh `fill-control` một mình không đạt 3:1 trên nền trắng). Bật: rãnh `color-accent`. `loading`: spinner trong nút gạt, chặn thao tác, dùng khi việc bật tắt gọi máy chủ; nếu máy chủ lỗi, Switch quay về giá trị cũ và màn hình hiển thị `CMP-Toast` lỗi. `disabled`: rãnh `color-fill-control`, nút gạt mờ theo `opacity-disabled`.

**Thao tác ảnh hưởng vận hành.** Nếu tắt một thứ đang phục vụ (tắt lịch đồng bộ đang chạy, tạm dừng dịch vụ), Switch không đổi ngay mà mở `CMP-ConfirmDialog` hoặc `CMP-ReasonDialog` theo FR-00-050; chỉ đổi giá trị sau khi xác nhận và máy chủ trả thành công. Prop `confirm` cấu hình việc này.

**Token.** `TKN-color-fill-control`, `TKN-color-border-control`, `TKN-color-accent`, `TKN-color-surface-solid`, `TKN-opacity-disabled`, `TKN-radius-pill`, `TKN-motion-duration-fast`, `TKN-motion-ease-emphasized`.

**Nền đặt.** Nền đặc và `glass-overlay`.

**Bàn phím và ARIA.** `role="switch"`, `aria-checked`; Space và Enter bật tắt. Switch luôn có nhãn chữ bên cạnh (bên trái trong danh sách cài đặt, PTN-12); không dùng chữ bên trong rãnh ("Bật"/"Tắt") vì quá nhỏ.

**Nội dung.** Nhãn nêu thiết lập ở thể khẳng định ("Gửi thông báo qua thư điện tử"); trạng thái hiện tại có thể nhắc bằng chữ phụ khi quan trọng ("Đang bật từ 10/11/2026").

**API.**

```tsx
export interface DhSwitchProps {
  checked?: boolean; onChange?: (checked: boolean) => void | Promise<unknown>;
  size?: 'sm' | 'md';
  loading?: boolean; disabled?: boolean; disabledReason?: string;
  confirm?: { when: 'on' | 'off' | 'both'; kind: 'confirm' | 'reason'; title: string; description?: string };
  id?: string; 'aria-labelledby'?: string; testId?: string;
}
```

```tsx
<Switch checked={schedule.enabled} onChange={(v) => toggleSchedule.mutateAsync(v)}
  confirm={{ when: 'off', kind: 'reason', title: 'Tắt lịch đồng bộ?' }} aria-labelledby="lbl-schedule" />
```

**Điều cấm.** Cấm Switch trong biểu mẫu chỉ có hiệu lực khi bấm Lưu (dùng Checkbox). Cấm Switch không nhãn.

### 7.10. CMP-SegmentedControl

**Mục đích.** `CMP-SegmentedControl` chuyển giữa 2 đến 5 chế độ xem hoặc khoảng giá trị ngắn của cùng một nội dung: "Bảng / Biểu đồ", "1 giờ / 24 giờ / 7 ngày", "JSON / XML". Đây là điều khiển mang dấu ấn Liquid Glass rõ nhất: nút chọn nổi lên như một mảnh kính trượt trên rãnh.

**Khi dùng / không dùng.** Thay đổi cách xem, không thay đổi dữ liệu. Điều hướng giữa các phần nội dung khác nhau dùng `CMP-Tabs`. Lựa chọn giá trị trong biểu mẫu dùng `CMP-Radio`.

**Nền antd.** `Segmented`. Token thành phần antd đã đặt ở D03-05-02 §13.3: `Segmented.trackBg` = `color-fill-control`, `Segmented.itemSelectedBg` = nền nổi của mảnh kính, `Segmented.trackPadding` 2 (bo đồng tâm: rãnh `radius-md` 10px, nút chọn 8px). Thêm `itemHoverBg` = `color-fill-hover`, `itemColor` = `color-text-secondary`, `itemSelectedColor` = `color-text-primary`. Nút chọn có bóng `shadow-1`. Chuyển động trượt `motion-duration-base` với `motion-ease-emphasized`; tắt trượt khi giảm chuyển động (nút chọn đổi chỗ tức thì).

**Kích thước.** `sm` / `md` / `lg` theo `size-control-*` (chiều cao tổng của rãnh). Mục có thể chỉ biểu tượng (bắt buộc `aria-label` và tooltip) hoặc biểu tượng + chữ.

**Token.** `TKN-color-fill-control`, `TKN-color-surface-solid`, `TKN-color-fill-hover`, `TKN-color-text-secondary`, `TKN-color-text-primary`, `TKN-shadow-1`, `TKN-radius-md`, `TKN-radius-sm`, `TKN-size-control-sm`, `TKN-size-control-md`, `TKN-size-control-lg`, `TKN-motion-duration-base`, `TKN-motion-ease-emphasized`.

**Nền đặt.** Nền đặc và mọi vật liệu glass (thường xuất hiện trên thanh công cụ trong `CMP-PageHeader`).

**Bàn phím và ARIA.** Antd v6 hiển thị dạng `radiogroup`; mũi tên trái phải di chuyển và chọn. Đây là hành vi đúng cho chuyển chế độ xem.

**Nội dung.** Nhãn ngắn 1–2 từ, cùng loại từ (cùng là danh từ).

**API.**

```tsx
export interface DhSegmentedControlProps<V extends string = string> {
  options: Array<{ value: V; label?: string; icon?: React.ReactNode; ariaLabel?: string; disabled?: boolean }>;
  value?: V; onChange?: (value: V) => void;
  size?: 'sm' | 'md' | 'lg';
  block?: boolean;
  'aria-label': string;
  testId?: string;
}
```

```tsx
<SegmentedControl aria-label="Khoảng thời gian" value={range} onChange={setRange}
  options={[{ value: '1h', label: '1 giờ' }, { value: '24h', label: '24 giờ' }, { value: '7d', label: '7 ngày' }]} />
```

**Điều cấm.** Cấm dùng thay Tabs cho nội dung khác nhau. Cấm hơn 5 mục. Cấm thay đổi dữ liệu khi đổi mục.

### 7.11. CMP-DatePicker

**Mục đích.** `CMP-DatePicker` chọn một ngày (`T-DATE`) hoặc một thời điểm (`T-TS`): ngày hiệu lực, hạn của khóa API, thời điểm chạy lịch một lần.

**Nền antd.** `DatePicker` với dayjs, locale `vi_VN` từ `ConfigProvider`. Hàm bọc cố định: `format="DD/MM/YYYY"` (ngày) hoặc `"DD/MM/YYYY HH:mm"` (thời điểm, `showTime={{ format: 'HH:mm' }}`, không chọn giây trừ khi `precision="second"`); tuần bắt đầu thứ Hai (locale `vi`); `suffixIcon` là `calendar` Lucide; popup gắn `dh-glass--overlay` qua `classNames.popup.root` (antd 6.7.1 nhận `classNames.popup` dạng chuỗi hoặc đối tượng, Datahub dùng dạng đối tượng); `needConfirm` bật với `showTime` để người dùng chọn xong giờ mới áp dụng.

**Nhập bằng bàn phím.** Người dùng gõ trực tiếp "21/11/2026" vào ô; thành phần chấp nhận thêm các dạng "21-11-2026", "21.11.2026", "21112026" và chuẩn hóa về "21/11/2026" khi mất focus. Giá trị không hợp lệ (31/02) giữ nguyên chữ đã gõ và báo lỗi "Ngày không hợp lệ. Nhập theo dạng DD/MM/YYYY.", không âm thầm xóa.

**Múi giờ.** Giá trị thời điểm hiển thị và nhập theo `Asia/Ho_Chi_Minh`, chuyển sang UTC ISO 8601 khi gửi (`T-TS` lưu UTC). Giá trị ngày (`T-DATE`) không có múi giờ, gửi dạng `YYYY-MM-DD`. Hàm chuyển đổi nằm trong `@datahub/ui/format` (`toApiDate`, `toApiTimestamp`), không viết tay ở màn hình.

**Ràng buộc.** Prop `min`, `max` (ví dụ hạn khóa API không quá 365 ngày, không ở quá khứ) dùng `disabledDate`; ngày bị khóa trong lịch có chữ `color-text-disabled` và `aria-disabled`. Ràng buộc phải kiểm tra lại ở backend (CRUD-C-03).

**Popup.** Ô ngày hôm nay có viền `color-accent` 1px; ngày chọn nền `color-accent` chữ `color-text-on-accent`; hover `color-fill-hover` (token thành phần antd `DatePicker.cellHoverBg`). Ô ngày 32×32 (đạt vùng chạm). Lớp chân popup có nút "Hôm nay" (ngày) hoặc "Bây giờ" (thời điểm).

**Token.** Chung của nhóm nhập liệu, thêm `TKN-color-accent`, `TKN-color-text-on-accent`, `TKN-color-fill-hover`, `TKN-color-fill-selected`, `TKN-blur-lg`, `TKN-shadow-3`, `TKN-radius-lg`, `TKN-z-popover`, `TKN-font-feature-tabular`.

**Nền đặt.** Ô nhập trên nền đặc; popup trên `glass-overlay`.

**Bàn phím và ARIA.** Ô nhập là `combobox` có `aria-haspopup="dialog"`; mũi tên xuống mở lịch; trong lịch, mũi tên di chuyển theo ngày/tuần, PageUp/PageDown đổi tháng, Shift + PageUp/PageDown đổi năm, Enter chọn, Esc đóng và trả focus về ô. Lịch có tiêu đề tháng năm được đọc ("Tháng 11 năm 2026").

**API.**

```tsx
export interface DhDatePickerProps {
  kind?: 'date' | 'datetime';
  precision?: 'minute' | 'second';
  /** 'YYYY-MM-DD' cho date; ISO 8601 UTC cho datetime. */
  value?: string | null;
  onChange?: (value: string | null) => void;
  min?: string; max?: string;
  disabledDate?: (d: Dayjs) => boolean;
  placeholder?: string;          // mặc định "DD/MM/YYYY"
  size?: 'sm' | 'md' | 'lg';
  allowClear?: boolean; disabled?: boolean; readOnly?: boolean; status?: 'error';
  id?: string; 'aria-describedby'?: string; testId?: string;
}
```

```tsx
<DatePicker kind="date" min={todayIso()} max={addDaysIso(365)} placeholder="DD/MM/YYYY" />
```

**Điều cấm.** Cấm truyền đối tượng `Dayjs` ra ngoài thành phần (giá trị là chuỗi chuẩn). Cấm định dạng MM/DD. Cấm hiển thị theo múi giờ của máy người dùng khi khác giờ Việt Nam.

### 7.12. CMP-DateRangePicker

**Mục đích.** `CMP-DateRangePicker` chọn khoảng thời gian "từ – đến": lọc nhật ký, lọc giao dịch, kỳ báo cáo, kỳ đối soát. FR-00-023 yêu cầu bộ lọc khoảng thời gian.

**Nền antd.** `DatePicker.RangePicker` với cùng cố định như `CMP-DatePicker`, thêm `separator` là biểu tượng `chevron-right` có `aria-hidden` và chữ ẩn "đến", `placeholder={['Từ ngày', 'Đến ngày']}`.

**Khoảng đặt sẵn (preset).** Bảng chuẩn bên trái popup (prop `presets` của antd, độ rộng `DatePicker.presetsWidth`): "Hôm nay", "Hôm qua", "7 ngày qua", "30 ngày qua", "Tháng này", "Tháng trước", "Quý này", "Năm nay". Với `kind="datetime"` có thêm "15 phút qua", "1 giờ qua", "24 giờ qua" ở đầu (dùng cho PTN-11 giám sát, tra log). Preset tương đối ("7 ngày qua") được lưu trên URL dưới dạng mã preset (`range=last7d`), không phải hai ngày cụ thể, để liên kết chia sẻ luôn cho dữ liệu mới nhất (FR-00-022); khi người dùng chọn ngày cụ thể thì URL lưu hai ngày. Màn hình có thể truyền tập preset riêng nhưng nhãn phải lấy từ từ điển `dhMessages`.

**Ràng buộc.** "Từ" ≤ "Đến" luôn được bảo đảm: khi người dùng chọn ngày "đến" nhỏ hơn "từ", thành phần đổi chỗ hai giá trị (hành vi `order` mặc định của antd) và thông báo qua vùng `aria-live` "Đã đổi chỗ ngày bắt đầu và ngày kết thúc". Prop `maxSpanDays` giới hạn độ dài khoảng (ví dụ tra log tối đa 31 ngày theo NFR-00-003): ngày ngoài giới hạn so với điểm đã chọn bị khóa trong lịch, và chữ phụ dưới trường nêu giới hạn. Ngày "đến" mặc định là cuối ngày (23:59:59) khi `kind="date"`, chuyển đổi do `toApiRange` xử lý, để khoảng "21/11 – 21/11" bao trọn ngày 21.

**Hiển thị.** Ô hiển thị "01/11/2026 → 21/11/2026" hoặc tên preset ("7 ngày qua") khi đang dùng preset tương đối, kèm tooltip hai ngày cụ thể.

**Token, nền, bàn phím.** Như `CMP-DatePicker`; khoảng giữa hai ngày tô `color-fill-selected` (`DatePicker.cellActiveWithRangeBg`). Tab di chuyển giữa ô "từ" và "đến"; trong popup, preset là danh sách nút đứng trước lịch theo thứ tự Tab.

**API.**

```tsx
export type DhRangePreset = 'today' | 'yesterday' | 'last15m' | 'last1h' | 'last24h' | 'last7d' | 'last30d'
  | 'thisMonth' | 'lastMonth' | 'thisQuarter' | 'thisYear';

export interface DhDateRangeValue { from: string; to: string; preset?: DhRangePreset; }

export interface DhDateRangePickerProps {
  kind?: 'date' | 'datetime';
  value?: DhDateRangeValue | null;
  onChange?: (value: DhDateRangeValue | null) => void;
  presets?: DhRangePreset[] | false;
  maxSpanDays?: number;
  min?: string; max?: string;
  size?: 'sm' | 'md' | 'lg';
  allowClear?: boolean; disabled?: boolean; status?: 'error';
  'aria-label'?: string; testId?: string;
}
```

```tsx
<DateRangePicker kind="datetime" maxSpanDays={31} presets={['last15m', 'last1h', 'last24h', 'last7d']}
  aria-label="Khoảng thời gian" value={range} onChange={setRange} />
```

**Điều cấm.** Cấm hai `CMP-DatePicker` rời nhau thay cho khoảng. Cấm khoảng không giới hạn với dữ liệu lớn. Cấm lưu preset tương đối thành ngày cố định trên URL.

### 7.13. CMP-Upload

**Mục đích.** `CMP-Upload` cho người dùng chọn và tải tệp lên: tệp nhập dữ liệu (FR-00-032, PTN-09), tệp OpenAPI, chứng thư, tài liệu đính kèm hồ sơ duyệt, ảnh đại diện.

**Nền antd.** `Upload` (danh sách tệp) và `Upload.Dragger` (vùng kéo thả). Hàm bọc cố định: `customRequest` dùng hàm tải lên của `@datahub/api-client` (gửi tệp trực tiếp tới kho đối tượng qua URL có ký tên ngắn hạn hoặc qua API, có `X-Request-ID`), `showUploadList` với biểu tượng Lucide, `maxCount` theo prop, `beforeUpload` chạy kiểm tra phía giao diện.

**Biến thể.** `dropzone` (vùng kéo thả, dùng cho tệp chính của trang nhập dữ liệu), `button` (`CMP-Button` "Chọn tệp" kèm danh sách, dùng trong biểu mẫu), `avatar` (ảnh đại diện, xem trước hình tròn).

**Kéo thả có phương án thay thế.** Vùng kéo thả **luôn chứa nút "Chọn tệp"** (`CMP-Button variant="default"`) bên trong, vì kéo thả không dùng được bằng bàn phím và trình đọc màn hình (WCAG 2.5.7, 2.1.1). Cả vùng là một nút lớn focus được mở hộp chọn tệp khi Enter/Space; chữ trong vùng: "Kéo thả tệp vào đây hoặc **Chọn tệp**", dòng phụ nêu ràng buộc. Khi kéo tệp vào, vùng chuyển trạng thái `dragover`: viền nét liền 2px `color-accent`, nền `color-accent-subtle`; bình thường viền 1px nét đứt `color-border-control` (ngoại lệ được phép của quy tắc cấm nét đứt, vì đây là quy ước phổ biến của vùng thả).

**Kiểm tra tệp.** Kiểm tra ba lớp. Lớp một, phía giao diện trong `beforeUpload`: phần mở rộng và kiểu MIME theo `accept` (ví dụ `.xlsx,.csv`), dung lượng tối đa `maxSizeMb`, số tệp tối đa; tệp không đạt bị từ chối ngay với thông báo cụ thể ("Tệp danh-sach.pdf không đúng định dạng. Chỉ nhận .xlsx, .csv." / "Tệp vượt quá 20 MB."). Lớp hai, máy chủ kiểm tra lại kiểu thật bằng chữ ký nội dung (magic bytes), không tin phần mở rộng. Lớp ba, **quét mã độc phía máy chủ**: sau khi tải xong, tệp ở trạng thái "Đang kiểm tra an toàn" (`CMP-StatusDot` `info`), máy chủ quét bằng công cụ chống mã độc (đặc tả ở D03-07) rồi trả "Sẵn sàng" hoặc "Bị chặn: phát hiện mã độc" (`error`). Biểu mẫu chứa tệp chỉ cho gửi khi mọi tệp đã "Sẵn sàng". Giao diện không bao giờ mở hoặc xem trước tệp chưa qua quét.

**Trạng thái của từng tệp.** `uploading` (`CMP-ProgressBar` cỡ `sm` theo phần trăm thật từ sự kiện tiến độ, nút "Hủy tải lên"), `scanning`, `done`, `error` (thông báo lỗi và nút "Thử lại"), `rejected`. Mỗi tệp hiển thị tên (rút gọn giữa nếu dài, tooltip đầy đủ), dung lượng định dạng "1,2 MB", nút "Xóa tệp" (`CMP-IconButton` `delete` với nhãn "Xóa tệp {tên}").

**Token.** `TKN-color-border-control`, `TKN-color-accent`, `TKN-color-accent-subtle`, `TKN-color-surface-solid`, `TKN-color-surface-solid-2`, `TKN-color-text-secondary`, `TKN-color-error-text`, `TKN-radius-lg`, `TKN-space-6`, `TKN-space-12`, `TKN-font-body`, `TKN-font-footnote`, `TKN-size-icon-lg`.

**Nền đặt.** Chỉ nền đặc.

**Bàn phím và ARIA.** Vùng thả là `role="button"` với `aria-describedby` trỏ dòng ràng buộc. Danh sách tệp là `<ul>`; thay đổi trạng thái tệp (xong, lỗi, bị chặn) thông báo qua `aria-live="polite"`. Sau khi xóa tệp, focus chuyển tới tệp kế tiếp hoặc về nút "Chọn tệp".

**Nội dung.** Dòng ràng buộc luôn hiển thị thường trực: "Định dạng .xlsx, .csv · Tối đa 20 MB · 1 tệp". Trang nhập có liên kết "Tải tệp mẫu" cạnh vùng thả (FR-00-033).

**API.**

```tsx
export interface DhUploadFile { uid: string; name: string; size: number; status: 'uploading' | 'scanning' | 'done' | 'error' | 'rejected'; percent?: number; fileId?: string; error?: string; }

export interface DhUploadProps {
  variant?: 'dropzone' | 'button' | 'avatar';
  accept: string[];                 // ['.xlsx', '.csv'] — bắt buộc
  maxSizeMb: number;                // bắt buộc
  maxCount?: number;
  purpose: string;                  // mã mục đích gửi cho máy chủ, vd 'catalog-import'
  value?: DhUploadFile[]; onChange?: (files: DhUploadFile[]) => void;
  /** Gọi khi mọi tệp đã qua quét và sẵn sàng. */
  onReady?: (fileIds: string[]) => void;
  disabled?: boolean; status?: 'error';
  id?: string; 'aria-describedby'?: string; testId?: string;
}
```

```tsx
<Upload variant="dropzone" accept={['.xlsx', '.csv']} maxSizeMb={20} maxCount={1} purpose="catalog-import"
  onReady={([id]) => startPreview(id)} />
```

**Điều cấm.** Cấm vùng kéo thả không có nút chọn tệp. Cấm tin phần mở rộng tệp ở máy chủ. Cấm xem trước, xử lý tệp trước khi quét xong. Cấm đọc toàn bộ tệp lớn vào bộ nhớ trình duyệt để kiểm tra (chỉ kiểm tra siêu dữ liệu). Cấm thanh tiến độ giả.

### 7.14. CMP-RadioCard

**Mục đích.** `CMP-RadioCard` chọn một trong 2 đến 6 phương án loại trừ nhau khi mỗi phương án cần một câu giải thích để người dùng chọn đúng: điểm xuất phát khi tạo luồng ("Trống", "Từ khuôn mẫu", "Từ API", "Nhập YAML", PH-04 UI-04-03), kiểu nguồn danh mục ("Tự quản", "Đồng bộ quốc gia", "Kết hợp", PH-07), chế độ nhập ("Thêm mới", "Ghi đè", "Gộp").

**Khi dùng / không dùng.** Dùng ở bước đầu của wizard hoặc biểu mẫu khi lựa chọn quyết định các trường xuất hiện phía sau. Lựa chọn ngắn không cần giải thích dùng `CMP-Radio`; chuyển chế độ xem dùng `CMP-SegmentedControl`.

**Nền antd.** `Radio.Group` với mỗi mục là `Radio` được bọc trong khung thẻ (thuộc tính ngữ nghĩa `classNames` của antd v6 gắn lớp `dh-radio-card`). Không dùng `Card` của antd làm mục vì `Card` không mang vai trò radio.

**Giải phẫu.** (1) Biểu tượng `CMP-Icon` cỡ `lg` tùy chọn; (2) tiêu đề `font-body-strong`; (3) mô tả tối đa hai dòng `font-footnote` màu `color-text-secondary`; (4) chấm radio ở góc trên phải; (5) thẻ phụ tùy chọn ("Khuyến nghị", "Cần quyền quản trị").

**Biến thể và bố cục.** Lưới 2, 3 hoặc 4 cột theo số phương án; dưới `bp-md` chuyển một cột. Mọi thẻ cùng chiều cao theo thẻ cao nhất.

**Trạng thái.** Mặc định: nền `color-surface-solid`, viền 1px `color-border-control`. Rê: nền `color-fill-hover`. Focus bàn phím: vòng focus kép của thẻ (không chỉ của chấm radio). Đã chọn: viền 2px `color-accent`, nền `color-accent-subtle`, chấm radio đầy; tiêu đề giữ `color-text-primary`. Vô hiệu: chữ `color-text-disabled` kèm `disabledReason` hiện bằng chữ phụ trong thẻ (không chỉ tooltip, vì người dùng cần đọc lý do trước khi chọn phương án khác). Lỗi (bắt buộc mà chưa chọn): viền nhóm `color-error-text` và thông báo của `CMP-FormField`.

**Token.** `TKN-color-surface-solid`, `TKN-color-border-control`, `TKN-color-fill-hover`, `TKN-color-accent`, `TKN-color-accent-subtle`, `TKN-color-text-primary`, `TKN-color-text-secondary`, `TKN-color-text-disabled`, `TKN-color-error-text`, `TKN-radius-lg`, `TKN-space-4`, `TKN-font-body-strong`, `TKN-font-footnote`.

**Nền đặt.** Chỉ nền đặc (biểu mẫu, giếng nội dung của Modal).

**Bàn phím và ARIA.** `role="radiogroup"` có `aria-labelledby` trỏ tới nhãn của `CMP-FormField`; mỗi thẻ là `role="radio"` với `aria-checked` và `aria-describedby` trỏ tới mô tả. Tab vào nhóm focus thẻ đang chọn (hoặc thẻ đầu); mũi tên di chuyển và chọn (đúng mẫu radio của ARIA APG); cả thẻ là vùng bấm.

**Nội dung.** Tiêu đề là danh từ hoặc cụm danh từ ngắn ("Từ khuôn mẫu"); mô tả nói kết quả của lựa chọn ("Bắt đầu từ khuôn có sẵn chín chặng chuẩn, đã gắn xử lý lỗi").

**API.**

```tsx
export interface DhRadioCardOption<V extends string = string> {
  value: V; title: string; description?: string; icon?: DhIconName;
  badge?: string; disabled?: boolean; disabledReason?: string;
}

export interface DhRadioCardProps<V extends string = string> {
  options: DhRadioCardOption<V>[];   // 2–6 mục
  value?: V; onChange?: (value: V) => void;
  columns?: 2 | 3 | 4;
  status?: 'error';
  id?: string; 'aria-labelledby'?: string; testId?: string;
}
```

```tsx
<RadioCard columns={4} value={origin} onChange={setOrigin} aria-labelledby="lbl-origin" options={[
  { value: 'blank', title: 'Trống', icon: 'add', description: 'Luồng chỉ có điểm vào, tự thêm chặng.' },
  { value: 'template', title: 'Từ khuôn mẫu', icon: 'history', badge: 'Khuyến nghị', description: 'Có sẵn chín chặng chuẩn và xử lý lỗi.' },
  { value: 'api', title: 'Từ API', icon: 'external', description: 'Sinh route cho từng thao tác của API PH-02.' },
  { value: 'yaml', title: 'Nhập YAML', icon: 'upload', description: 'Nạp tệp Camel YAML có sẵn.' },
]} />
```

**Điều cấm.** Cấm dùng RadioCard cho lựa chọn nhiều giá trị (dùng `CMP-Checkbox` dạng thẻ chỉ khi D03-05-04 bổ sung). Cấm hơn 6 phương án. Cấm đặt nút hoặc liên kết bên trong thẻ (lồng phần tử tương tác vào radio).

### 7.15. CMP-CronPicker

**Mục đích.** `CMP-CronPicker` cho người dùng đặt lịch chạy định kỳ bằng ngôn ngữ thường thay vì viết biểu thức cron: lịch đồng bộ danh mục quốc gia (PH-07 UI-07-09, UI-07-13), lịch chạy luồng định thời (PH-04, thành phần `timer`/`quartz`), lịch đối soát (PH-19), lịch xuất báo cáo. Kết quả là biểu thức cron 6 trường kiểu Spring (`giây phút giờ ngày tháng thứ`) theo múi giờ `Asia/Ho_Chi_Minh`.

**Khi dùng / không dùng.** Dùng cho lịch lặp lại. Thời điểm chạy một lần dùng `CMP-DatePicker` có giờ. Chu kỳ ngắn kiểu "mỗi 30 giây" của luồng tích hợp dùng `CMP-NumberInput` có đơn vị (tham số `period`), không dùng cron.

**Nền antd.** Ghép `CMP-SegmentedControl` (chọn kiểu lịch), `CMP-Select`, `CMP-Checkbox` (các thứ trong tuần), `TimePicker` của antd và `CMP-Input` (chế độ tùy chỉnh). Không có thành phần antd tương ứng trọn vẹn.

**Năm kiểu lịch.**

| Kiểu | Điều khiển | Ví dụ hiển thị | Cron sinh ra |
|---|---|---|---|
| Hằng giờ | Phút thứ (0–59) | "Hằng giờ vào phút 15" | `0 15 * * * *` |
| Hằng ngày | Giờ phút | "Hằng ngày lúc 01:00" | `0 0 1 * * *` |
| Hằng tuần | Các thứ + giờ phút | "Thứ Hai, Thứ Năm lúc 22:30" | `0 30 22 * * MON,THU` |
| Hằng tháng | Ngày (1–28, "ngày cuối tháng") + giờ phút | "Ngày 1 hằng tháng lúc 02:00" | `0 0 2 1 * *` hoặc `0 0 2 L * *` |
| Tùy chỉnh | Ô nhập cron 6 trường | Diễn giải tiếng Việt sinh tự động | Như người dùng nhập |

Ngày trong tháng giới hạn 1–28 ở chế độ thân thiện để không có tháng bị bỏ lịch; cần ngày 29–31 thì dùng "ngày cuối tháng" hoặc chế độ tùy chỉnh.

**Xem trước và giới hạn.** Dưới điều khiển luôn có dòng "Lần chạy kế tiếp: 26/11/2026 01:00 · 27/11/2026 01:00 · 28/11/2026 01:00" (ba lần, tính ở trình duyệt bằng thư viện phân tích cron và kiểm tra lại ở máy chủ khi lưu). Màn hình truyền `minIntervalMinutes` (ví dụ PH-07 là 60 theo tham số `07.rdm.sync-min-interval`); lịch dày hơn ngưỡng bị báo lỗi "Lịch không được chạy dày hơn 1 giờ một lần". Biểu thức tùy chỉnh sai cú pháp báo lỗi chỉ ra trường sai ("Trường giờ phải trong khoảng 0–23").

**Trạng thái.** Mặc định, đang nhập, lỗi cú pháp, lỗi vượt ngưỡng, vô hiệu, chỉ đọc (chỉ hiện diễn giải và ba lần chạy kế tiếp).

**Token.** Như các điều khiển ghép; dòng xem trước `TKN-font-footnote`, `TKN-color-text-secondary`, `TKN-font-feature-tabular`.

**Nền đặt.** Nền đặc.

**Bàn phím và ARIA.** Nhóm là `role="group"` có nhãn; dòng xem trước có `aria-live="polite"` để người dùng trình đọc màn hình nghe kết quả sau khi đổi; ô cron tùy chỉnh có `aria-describedby` trỏ tới diễn giải.

**Nội dung.** Diễn giải bằng câu đầy đủ, dùng "Thứ Hai … Chủ nhật", giờ 24 giờ. Luôn ghi "(giờ Việt Nam)" khi người dùng mở chế độ tùy chỉnh.

**API.**

```tsx
export interface DhCronPickerProps {
  value?: string;                       // cron 6 trường
  onChange?: (cron: string) => void;
  kinds?: Array<'hourly' | 'daily' | 'weekly' | 'monthly' | 'custom'>;  // mặc định đủ năm
  minIntervalMinutes?: number;
  previewCount?: number;                // mặc định 3
  disabled?: boolean; readOnly?: boolean; status?: 'error';
  id?: string; 'aria-labelledby'?: string; testId?: string;
}
```

```tsx
<CronPicker value={form.scheduleCron} onChange={(v) => form.setFieldValue('scheduleCron', v)}
  minIntervalMinutes={60} aria-labelledby="lbl-schedule" />
```

**Điều cấm.** Cấm cron 5 trường hoặc 7 trường (mỗi hệ một kiểu gây lệch giờ chạy). Cấm hiển thị lịch theo giờ UTC. Cấm lưu khi máy chủ chưa xác nhận biểu thức hợp lệ.

### 7.16. CMP-ExpressionField

**Mục đích.** `CMP-ExpressionField` nhập một biểu thức ngắn có ngôn ngữ: điều kiện rẽ nhánh, biểu thức gán header, đường dẫn trích dữ liệu trong trình thiết kế luồng (PH-04, FR-04-016), quy tắc chất lượng dữ liệu (PH-08), điều kiện cổng trong mô hình quy trình (PH-11).

**Khi dùng / không dùng.** Biểu thức một dòng hoặc vài dòng. Đoạn mã dài, ánh xạ dữ liệu, tệp cấu hình dùng `CMP-CodeEditor` (D03-05-04); ô ƒx của trường này mở `CMP-CodeEditor` trong Modal khi cần soạn dài (PH-04 UI-04-06).

**Nền antd.** `Space.Compact` ghép `CMP-Select` cỡ `sm` (ngôn ngữ) và một ô một dòng có tô cú pháp. Ô tô cú pháp dùng CodeMirror 6 chế độ một dòng (nhẹ hơn Monaco, nạp tức thì), không dùng `Input` của antd vì không tô được. Nút ƒx là `CMP-IconButton`.

**Ngôn ngữ.** Danh sách ngôn ngữ do màn hình truyền vào (PH-04 dùng `simple`, `constant`, `header`, `exchangeProperty`, `jq`, `jsonpath`, `xpath`, `xquery` theo catalog Camel). Mỗi ngôn ngữ có bộ tô cú pháp và bộ gợi ý riêng; ngôn ngữ chưa có bộ tô thì hiện chữ đơn sắc.

**Kiểm tra.** Kiểm tra cú pháp chạy ở máy chủ (PH-04 API-04-032) sau 400ms kể từ lần gõ cuối, hủy yêu cầu cũ bằng `AbortController`. Lỗi hiện dưới ô theo `CMP-FormField`, kèm vị trí ("Lỗi ở ký tự 18: thiếu dấu `}`") và gạch chân sóng tại vị trí lỗi. Đang kiểm tra: biểu tượng `CMP-Spinner` cỡ `sm` ở cuối ô. Hợp lệ: không hiện gì (không làm ồn bằng dấu tích xanh).

**Gợi ý.** `Ctrl+Space` mở danh sách gợi ý (`glass-overlay`): biến có sẵn của ngôn ngữ (`${header.*}`, `${body}`), header và thuộc tính đã khai báo ở các chặng trước, trường của lược đồ đầu vào nếu có. Gõ `${` tự mở gợi ý.

**Trạng thái.** Mặc định, focus, đang kiểm tra, lỗi, vô hiệu, chỉ đọc (vẫn tô cú pháp, cho chọn và sao chép).

**Token.** `TKN-font-mono`, `TKN-color-surface-solid`, `TKN-color-border-control`, `TKN-color-error-text`, `TKN-size-control-sm`, `TKN-size-control-md`; màu tô cú pháp dùng bảng `color-chart-*` có tương phản ≥ 4,5:1 trên `color-surface-solid` (`color-chart-1`, `-3`, `-4`, `-5`, `-6`, `-7`).

**Nền đặt.** Chỉ nền đặc (Inspector, biểu mẫu).

**Bàn phím và ARIA.** Ô có `role="textbox"`, `aria-multiline="false"`, nhãn từ `CMP-FormField`. `Tab` rời ô (không chèn ký tự tab); `Enter` không xuống dòng mà xác nhận; `Shift+Enter` mở Modal soạn dài. Danh sách gợi ý theo mẫu combobox.

**API.**

```tsx
export interface DhExpressionValue { language: string; expression: string }

export interface DhExpressionFieldProps {
  value?: DhExpressionValue; onChange?: (v: DhExpressionValue) => void;
  languages: Array<{ value: string; label: string }>;
  validate?: (v: DhExpressionValue, signal: AbortSignal) => Promise<{ ok: true } | { ok: false; message: string; offset?: number }>;
  suggestions?: (ctx: { language: string; prefix: string }) => Promise<Array<{ label: string; insertText: string; detail?: string }>>;
  onOpenEditor?: () => void;            // nút ƒx
  disabled?: boolean; readOnly?: boolean; status?: 'error';
  id?: string; 'aria-describedby'?: string; testId?: string;
}
```

```tsx
<ExpressionField languages={camelLanguages} value={step.when} onChange={setWhen}
  validate={(v, signal) => api.int.compileExpression(v, { signal })} onOpenEditor={openExpressionModal} />
```

**Điều cấm.** Cấm đánh giá (eval) biểu thức ở trình duyệt. Cấm cho nhập bí mật dạng chữ trong biểu thức (dùng `CMP-SecretRefField`); máy chủ báo lỗi nếu phát hiện chuỗi giống bí mật.

### 7.17. CMP-SecretRefField

**Mục đích.** `CMP-SecretRefField` gán giá trị bí mật cho một tham số **bằng tham chiếu**, không bao giờ bằng giá trị: mật khẩu, khóa, token trong cấu hình luồng (PH-04 tham số có `secret: true`), cấu hình bộ điều hợp (PH-05), kênh thanh toán (PH-19). Đây là đối trọng của `CMP-SecretField` (mục 7.2): SecretField nhận hoặc hiển thị bí mật một lần, SecretRefField chỉ trỏ tới nơi bí mật đã được cất.

**Khi dùng / không dùng.** Dùng ở mọi nơi cấu hình kỹ thuật cần bí mật. Nhập bí mật lần đầu vào kho dùng `CMP-SecretField` ở màn quản lý kết nối PH-05.

**Nền antd.** `CMP-Select` có tải từ xa, hiển thị giá trị đã chọn dạng `CMP-CodeText` có biểu tượng `key`.

**Hai nguồn tham chiếu.** (1) Khóa của kết nối PH-05 được cấp cho không gian làm việc: `{{conn:<mã-kết-nối>.<khóa>}}`, ví dụ `{{conn:ndxp-ho-tich.password}}`. (2) Đường dẫn trong kho bí mật do nền tảng cấp cho tenant: `{{vault:<đường-dẫn>#<khóa>}}`. Danh sách lấy từ máy chủ theo quyền; người dùng không gõ tự do được đường dẫn kho.

**Hiển thị.** Ô chỉ hiện tham chiếu và nhãn nguồn ("Kết nối ndxp-ho-tich · khóa password"), kèm chỉ báo môi trường có giá trị ("TEST ✓ · PROD ✓", thiếu môi trường nào thì ghi "PROD chưa có giá trị" màu `color-warning-text`). Không có nút "Hiện", không có cách nào xem giá trị thật từ giao diện.

**Trạng thái.** Chưa chọn (bắt buộc thì báo lỗi khi gửi), đã chọn, tham chiếu không còn hợp lệ (kết nối bị thu hồi quyền hoặc bị xóa: viền lỗi, chữ "Tham chiếu không còn hợp lệ", PH-04 ERR-04-010), đang tải danh sách, vô hiệu, chỉ đọc.

**Token.** `TKN-font-mono`, `TKN-color-warning-text`, `TKN-color-error-text`, `TKN-color-surface-solid-2`.

**Nền đặt.** Chỉ nền đặc.

**Bàn phím và ARIA.** Như `CMP-Select`; tên truy cập của giá trị đã chọn đọc đầy đủ ("Tham chiếu bí mật: kết nối ndxp-ho-tich, khóa password").

**API.**

```tsx
export interface DhSecretRef { source: 'conn' | 'vault'; ref: string /* chuỗi {{…}} */ }

export interface DhSecretRefFieldProps {
  value?: DhSecretRef; onChange?: (v: DhSecretRef | undefined) => void;
  sources?: Array<'conn' | 'vault'>;     // mặc định cả hai
  fetchRefs: (q: string, signal: AbortSignal) => Promise<Array<DhSecretRef & { label: string; envs: Record<string, boolean>; valid: boolean }>>;
  requiredEnvs?: string[];               // ví dụ ['PROD']
  disabled?: boolean; readOnly?: boolean; status?: 'error';
  id?: string; 'aria-describedby'?: string; testId?: string;
}
```

**Điều cấm.** Cấm ô nhập tự do cho tham số bí mật. Cấm lưu, ghi log hoặc gửi giá trị bí mật thật từ trình duyệt. Cấm hiển thị một phần giá trị (bốn ký tự cuối) của bí mật.

### 7.18. CMP-ResourceSelect và các biến thể theo phân hệ

**Mục đích.** Nhiều màn hình phải chọn một đối tượng do phân hệ khác quản lý: bảng mã của PH-07, kết nối của PH-05, lược đồ của PH-06, API của PH-02, topic của PH-10. Nếu mỗi màn tự dựng một Select, nhãn, cách hiển thị phiên bản và cách báo "không có quyền" sẽ khác nhau. `CMP-ResourceSelect` là `CMP-Select` tải từ xa có thêm ba hành vi chung; các biến thể theo phân hệ là cấu hình sẵn của nó, mỗi biến thể có mã `CMP-` riêng để màn hình truy vết.

**Ba hành vi chung.** Thứ nhất, mỗi lựa chọn hiển thị tên, mã (`CMP-Identifier` nhỏ) và một chỉ báo trạng thái gọn (`CMP-StatusDot`). Thứ hai, khi đối tượng có phiên bản, sau khi chọn đối tượng thì hiện ô chọn phiên bản cạnh bên với mặc định "Phiên bản hiện hành (tự theo)" hoặc một phiên bản cố định; lựa chọn này được lưu tường minh (`version: 'CURRENT' | số`). Thứ ba, giá trị đã lưu trỏ tới đối tượng người dùng không còn quyền xem hoặc đã bị xóa vẫn hiển thị mã gốc kèm chữ "Không xem được (không có quyền hoặc đã xóa)" thay vì để trống, để không mất dữ liệu khi lưu lại.

| Mã | Đối tượng | Nguồn API | Bộ lọc mặc định | Chỉ báo riêng |
|---|---|---|---|---|
| `CMP-CodeListSelect` | Danh mục dùng chung PH-07 | API-07-001 (`scope`, trạng thái `PUBLISHED`) | Danh mục tenant được dùng | Nguồn: địa phương, quốc gia, kết hợp (token `color-source-*`, D03-05-02 §4.6) |
| `CMP-ConnectionSelect` | Kết nối PH-05 | Danh sách kết nối được cấp cho không gian | Đúng loại kết nối mà tham số yêu cầu | Môi trường có giá trị (TEST, STAGING, PROD); "Chưa sẵn sàng cho PROD"; nút "Tạo kết nối mới" mở PH-05 ở thẻ mới |
| `CMP-SchemaSelect` | Lược đồ dữ liệu PH-06 | Danh sách lược đồ đã công bố | Lược đồ tenant được dùng | Định dạng (JSON Schema, XSD, Avro) |
| `CMP-ApiSelect` | API PH-02 | Danh mục API người dùng được xem | `PUBLISHED` | Phiên bản API, trạng thái `DEPRECATED` có cảnh báo |
| `CMP-TopicSelect` | Topic PH-10 | Topic của dự án sự kiện được cấp | Đúng chiều (phát hay nhận) | Quyền phát/nhận |

**Nền antd, token, nền đặt, bàn phím.** Như `CMP-Select` (mục 7.5). Popup `glass-overlay`. Ô nằm trên nền đặc.

**API.**

```tsx
export interface DhResourceRef { id: string; code: string; version?: 'CURRENT' | number }

export interface DhResourceSelectProps {
  kind: 'codeList' | 'connection' | 'schema' | 'api' | 'topic';
  value?: DhResourceRef; onChange?: (v: DhResourceRef | undefined) => void;
  filter?: Record<string, string | string[]>;    // ví dụ { connectionType: 'jdbc-postgresql' }
  versioned?: boolean;                           // hiện ô chọn phiên bản
  allowCreateLink?: boolean;                     // nút "Tạo … mới" mở phân hệ nguồn
  disabled?: boolean; readOnly?: boolean; status?: 'error';
  id?: string; 'aria-describedby'?: string; testId?: string;
}

// Biến thể là hàm bọc cố định `kind`:
export const CodeListSelect = (p: Omit<DhResourceSelectProps, 'kind'>) => <ResourceSelect kind="codeList" versioned {...p} />;
```

```tsx
<ConnectionSelect filter={{ connectionType: param.connectionType }} allowCreateLink
  value={stepConfig.connection} onChange={(v) => setParam('connection', v)} />
```

**Điều cấm.** Cấm tải toàn bộ đối tượng của phân hệ khác về trình duyệt. Cấm lưu nhãn hiển thị thay cho mã. Cấm âm thầm đổi giá trị đã lưu khi đối tượng không còn xem được.

## 8. Nhóm hiển thị dữ liệu nghiệp vụ

Năm thành phần ở mục này hiển thị một **giá trị** có quy tắc định dạng riêng của nghiệp vụ nhà nước: thời điểm, thời lượng, số tiền, mã định danh và dữ liệu cá nhân cần che. Chúng có chung ba quy tắc. Thứ nhất, định dạng chỉ đi qua các hàm của `@datahub/ui/format`; không màn hình nào tự gọi `dayjs().format()` hay `toLocaleString()`. Thứ hai, giá trị rỗng (`null`, `undefined`, chuỗi rỗng) luôn hiển thị "—" màu `color-text-tertiary` kèm `aria-label="Không có giá trị"` (kế thừa CRUD-R-05). Thứ ba, chữ số dùng `font-feature-tabular` để các giá trị trong cột bảng thẳng hàng.

### 8.1. CMP-Timestamp

**Mục đích.** `CMP-Timestamp` hiển thị một thời điểm (`T-TS`) hoặc một ngày (`T-DATE`) theo đúng một quy ước trên toàn hệ thống: múi giờ `Asia/Ho_Chi_Minh`, định dạng ngày `DD/MM/YYYY`, giờ 24 giờ. Máy chủ luôn trả thời điểm theo ISO 8601 có múi giờ (UTC), giao diện quy đổi. D00-01 §5 ghi dạng đầy đủ của `T-TS` là `dd/MM/yyyy HH:mm:ss`; giao diện mặc định rút gọn tới phút ở bảng và chi tiết để dễ đọc, và luôn cho xem dạng đầy đủ qua tooltip.

**Khi dùng / không dùng.** Mọi chỗ hiện thời điểm: cột bảng, mô tả chi tiết, dòng thời gian, thông báo, log. Khoảng thời gian (từ… đến…) dùng hai Timestamp nối bằng " – ". Thời lượng dùng `CMP-Duration`.

**Nền antd.** Không có; là phần tử `<time>` có `dateTime` là chuỗi ISO gốc.

**Biến thể.**

| Biến thể | Định dạng | Ví dụ | Dùng ở |
|---|---|---|---|
| `date` | `DD/MM/YYYY` | 20/11/2026 | Ngày hiệu lực, ngày ban hành |
| `datetime` (mặc định) | `DD/MM/YYYY HH:mm` | 20/11/2026 14:05 | Bảng, chi tiết (CRUD-TBL-08) |
| `datetime-second` | `DD/MM/YYYY HH:mm:ss` | 20/11/2026 14:05:09 | Lịch sử sửa, kết quả chạy thử, giao dịch |
| `datetime-ms` | `DD/MM/YYYY HH:mm:ss.SSS` | 20/11/2026 14:05:09.412 | Log, truy vết (PTN-11) |
| `smart` | Trong ngày: `HH:mm`; hôm qua: "Hôm qua HH:mm"; trong năm: `DD/MM HH:mm`; khác năm: `DD/MM/YYYY HH:mm` | 14:05 · Hôm qua 09:12 | Dòng thời gian, hộp việc, thông báo |
| `relative` | "vừa xong" (dưới 1 phút), "{n} phút trước", "{n} giờ trước", từ 24 giờ chuyển sang `datetime` | 5 phút trước | Thông báo, "cập nhật lần cuối" |

Biến thể `relative` tự cập nhật mỗi 60 giây bằng một bộ đếm chung cho cả trang (không tạo bộ đếm riêng cho mỗi phần tử). Mọi biến thể trừ `date` có `CMP-Tooltip` hiện thời điểm đầy đủ đến giây kèm dòng UTC ("20/11/2026 14:05:09 (giờ Việt Nam) · 2026-11-20T07:05:09Z") để kỹ sư đối chiếu log.

**Quá hạn và sắp hết hạn.** Prop `deadline` biến Timestamp thành mốc hạn: quá hạn hiện thêm chữ "Quá hạn {n} ngày" màu `color-error-text`; còn dưới ngưỡng (mặc định 24 giờ) hiện "Còn {n} giờ" màu `color-warning-text`. Màu luôn kèm chữ.

**Token.** `TKN-font-feature-tabular`, `TKN-color-text-primary`, `TKN-color-text-tertiary`, `TKN-color-error-text`, `TKN-color-warning-text`.

**Nền đặt.** Mọi nền; chữ màu trạng thái (`deadline`) chỉ trên nền đặc và `glass-overlay`.

**ARIA.** `<time dateTime="2026-11-20T07:05:09Z">`. Tên truy cập của biến thể `smart` và `relative` là dạng đầy đủ ("20 tháng 11 năm 2026, 14 giờ 05") để trình đọc màn hình không đọc "Hôm qua" thiếu ngữ cảnh khi nghe lại.

**API.**

```tsx
export interface DhTimestampProps {
  value?: string | null;                // ISO 8601 có múi giờ, hoặc YYYY-MM-DD với variant 'date'
  variant?: 'date' | 'datetime' | 'datetime-second' | 'datetime-ms' | 'smart' | 'relative';
  deadline?: { warnHours?: number };    // coi value là hạn
  showUtcTooltip?: boolean;             // mặc định true, trừ 'date'
  testId?: string;
}
```

```tsx
<Timestamp value={row.updatedAt} />
<Timestamp value={task.dueAt} variant="smart" deadline={{ warnHours: 24 }} />
```

**Điều cấm.** Cấm hiển thị giờ UTC mà không ghi rõ. Cấm định dạng `MM/DD/YYYY` hay `YYYY-MM-DD` trên giao diện người dùng (trừ khối mã, JSON). Cấm lấy đồng hồ máy trạm làm mốc cho dữ liệu nghiệp vụ (chỉ dùng cho biến thể `relative`, đã hiệu chỉnh lệch đồng hồ theo tiêu đề `Date` của máy chủ).

### 8.2. CMP-Duration

**Mục đích.** `CMP-Duration` hiển thị thời lượng: độ trễ lượt gọi, thời gian chạy của một chặng, thời gian xử lý của tác vụ nền, SLA.

**Quy tắc định dạng.** Dưới 1 giây: "{n} ms" (số nguyên, ví dụ "184 ms"). Từ 1 giây đến dưới 1 phút: một chữ số thập phân dấu phẩy, "1,2 s". Từ 1 phút: "2 phút 05 giây"; từ 1 giờ: "1 giờ 04 phút"; từ 1 ngày: "2 ngày 3 giờ". Biến thể `compact` cho cột bảng hẹp dùng "2m05s", "1h04m" với tooltip dạng đầy đủ. Số theo `vi-VN` (dấu chấm phân cách nghìn: "12.480 ms" chỉ xuất hiện khi màn hình ép đơn vị `ms`).

**So với ngưỡng.** Prop `threshold` (ví dụ SLA 5.000 ms) tô chữ `color-warning-text` khi vượt 80% và `color-error-text` khi vượt 100%, kèm biểu tượng `warning`/`error` và tooltip "Vượt SLA 5 s".

**Token, nền đặt, ARIA.** `TKN-font-feature-tabular`, `TKN-color-warning-text`, `TKN-color-error-text`; mọi nền đặc và `glass-overlay`; phần tử `<time dateTime="PT1.2S">` với tên truy cập đầy đủ ("1,2 giây").

**API.**

```tsx
export interface DhDurationProps {
  ms?: number | null;
  variant?: 'default' | 'compact';
  unit?: 'auto' | 'ms';
  threshold?: { warnRatio?: number; limitMs: number };
  testId?: string;
}
```

**Điều cấm.** Cấm tự tính thời lượng bằng hiệu hai thời điểm của đồng hồ máy trạm. Cấm hiển thị "0 ms" cho giá trị chưa đo (dùng "—").

### 8.3. CMP-Money

**Mục đích.** `CMP-Money` hiển thị số tiền: phí dịch vụ công, giao dịch thanh toán, đối soát, hoàn tiền (PH-19), đơn giá gói sử dụng (PH-02). Sai một dấu phân cách trên màn đối soát là sai nghiệp vụ, nên quy tắc là bắt buộc tuyệt đối.

**Quy tắc định dạng.** Máy chủ trả số tiền theo kiểu `T-MONEY` của D00-01 §5: **số nguyên đồng** (`integer` int64 trong OpenAPI, ví dụ `1250000`); kiểu `number` của JavaScript biểu diễn chính xác tới khoảng 9 triệu tỷ đồng nên đủ cho mọi giao dịch. Mã tiền tệ ISO 4217 mặc định `VND`. Giao diện hiển thị "1.250.000 ₫": dấu chấm phân cách nghìn, ký hiệu "₫" sau số cách một khoảng trắng không ngắt. Đồng Việt Nam không có phần thập phân. Ngoại tệ (hiếm, chỉ đối soát quốc tế) hiển thị "1.250,50 USD" với hai chữ số thập phân dấu phẩy. Số âm (hoàn tiền, điều chỉnh) dùng dấu trừ thật "−1.250.000 ₫", không dùng ngoặc.

**Biến thể.** `default`; `signed` (luôn có dấu "+" hoặc "−", tô `color-success-text` cho dương và `color-error-text` cho âm, dùng cho chênh lệch đối soát; màu kèm dấu nên không chỉ dựa vào màu); `compact` cho thẻ KPI ("1,25 tỷ ₫", "350 triệu ₫") với tooltip giá trị đầy đủ. `compact` cấm dùng trong bảng và màn đối soát.

**Căn lề.** Trong bảng, cột tiền căn phải (D03-05-04 §8.1.3), chữ số đều độ rộng.

**Token, nền đặt.** `TKN-font-feature-tabular`, `TKN-color-success-text`, `TKN-color-error-text`; mọi nền.

**ARIA.** Tên truy cập đọc thành chữ số kèm đơn vị: "1.250.000 đồng"; số âm "âm 1.250.000 đồng".

**API.**

```tsx
export interface DhMoneyProps {
  amount?: number | null;               // T-MONEY: số nguyên đồng
  currency?: string;                    // mặc định 'VND'
  variant?: 'default' | 'signed' | 'compact';
  testId?: string;
}
```

```tsx
<Money amount={tx.amount} />
<Money amount={recon.diffAmount} variant="signed" />
```

**Điều cấm.** Cấm nhận số tiền dạng số thực hoặc có phần thập phân với VND. Cấm làm tròn số tiền ở giao diện. Cấm cộng tổng tiền ở giao diện cho màn đối soát (tổng do máy chủ tính).

### 8.4. CMP-Identifier

**Mục đích.** `CMP-Identifier` hiển thị một mã định danh kỹ thuật hoặc nghiệp vụ mà người dùng hay phải đọc, sao chép, đối chiếu: mã HTTT, mã API, mã luồng, mã tenant, mã giao dịch, mã hồ sơ, `trace_id`, mã ĐVQHNS. Nó khác `CMP-CodeText` ở chỗ có hành vi sao chép, rút gọn có kiểm soát và có thể là liên kết.

**Nền antd.** `Typography.Text` với `code={false}` và lớp `dh-identifier`, ghép `CMP-CopyButton` biến thể `icon` cỡ `sm`.

**Biến thể.** `inline` (mặc định, trong câu hoặc ô bảng), `badge` (nền `color-fill-control`, bo `radius-sm`, dùng cạnh tiêu đề trong `CMP-PageHeader`), `link` (là liên kết tới trang chi tiết của đối tượng mang mã; với `trace_id` là liên kết tới trang truy vết PTN-11).

**Rút gọn.** Mã dài (băm, UUID, `trace_id` 32 ký tự) rút gọn giữa với dấu "…" theo `truncate` ("4bf92f35…a3ce929d", giữ 8 ký tự đầu và 8 ký tự cuối); tooltip và nội dung sao chép luôn là mã đầy đủ. Mã nghiệp vụ ngắn (dưới 24 ký tự) không bao giờ rút gọn.

**Sao chép.** Nút sao chép hiện khi rê hoặc focus vào mã (luôn hiện trên thiết bị cảm ứng và ở biến thể `badge`), vùng chạm mở rộng 24×24 (mục 2.5). Sao chép xong, `CMP-CopyButton` đổi biểu tượng `copied` 2 giây và thông báo `aria-live` "Đã sao chép mã".

**Token.** `TKN-font-mono`, `TKN-font-footnote`, `TKN-color-text-primary`, `TKN-color-text-link`, `TKN-color-fill-control`, `TKN-radius-sm`.

**Nền đặt.** Mọi nền; biến thể `link` không đặt trên `glass-chrome-scrolled` và `glass-modal` (D03-05-01 §3.2).

**ARIA.** Tên truy cập của mã rút gọn là mã đầy đủ; có `aria-label` tiền tố loại mã khi màn hình truyền `kind` ("Mã truy vết 4bf92f35…").

**API.**

```tsx
export interface DhIdentifierProps {
  value?: string | null;
  kind?: string;                        // 'Mã truy vết', 'Mã giao dịch'…
  variant?: 'inline' | 'badge' | 'link';
  href?: string;                        // với variant 'link'
  truncate?: 'none' | 'middle';         // mặc định 'middle' khi value dài từ 24 ký tự
  copyable?: boolean;                   // mặc định true
  testId?: string;
}
```

```tsx
<Identifier kind="Mã truy vết" value={error.traceId} variant="link" href={`/giam-sat/truy-vet/${error.traceId}`} />
```

**Điều cấm.** Cấm dùng Identifier cho dữ liệu cá nhân (số CCCD, số điện thoại là dữ liệu cá nhân, dùng `CMP-MaskedValue`). Cấm rút gọn bằng cắt đuôi (người đối chiếu cần cả đầu và cuối). Cấm viết hoa lại hoặc thêm khoảng trắng vào mã.

### 8.5. CMP-MaskedValue

**Mục đích.** `CMP-MaskedValue` hiển thị dữ liệu cá nhân đã được che theo mức phân loại và cho người có quyền mở xem có kiểm soát. Đây là hiện thực trên giao diện của nguyên tắc 5 (D03-05 §2), NT-10 của D03-01, FR-00-034 và FR-00-040, và là một kiểm soát của hồ sơ bảo vệ dữ liệu cá nhân (Luật BVDLCN 91/2025/QH15).

**Nguyên tắc.** Che là việc của **máy chủ**: API trả giá trị đã che (`"0912****78"`) cùng cờ `masked: true` và mã trường. Giao diện không bao giờ nhận giá trị thật rồi che bằng CSS. Mở xem gọi một API riêng (`POST …/reveal` theo mẫu của từng phân hệ) có lý do, máy chủ kiểm quyền `PERM-09-unmask` (D02-08), ghi kiểm toán và trả giá trị thật.

**Mẫu che chuẩn.** Bảng dưới là mẫu máy chủ áp dụng và giao diện mô tả trong tài liệu hướng dẫn; giao diện chỉ hiển thị.

| Loại dữ liệu | Mẫu che | Ví dụ |
|---|---|---|
| Số định danh cá nhân (12 chữ số) | Giữ 3 đầu, 2 cuối | `001*******34` |
| Số điện thoại | Giữ 4 đầu, 2 cuối | `0912****78` |
| Thư điện tử | Giữ ký tự đầu của phần tên và tên miền | `n****@****.gov.vn` |
| Họ tên (khi phân loại Nhạy cảm) | Giữ chữ cái đầu mỗi từ | `N. V. A.` |
| Ngày sinh | Giữ năm | `**/**/1990` |
| Địa chỉ | Giữ cấp tỉnh | `***, Tỉnh Mẫu A` |
| Số tài khoản ngân hàng | Giữ 4 cuối | `********1234` |

**Luồng mở xem.** (1) Người dùng bấm nút "Hiện" (biểu tượng `view`). (2) `CMP-ReasonDialog` (D03-05-04 §7.4) mở với ô lý do bắt buộc tối thiểu 10 ký tự và danh sách lý do thường dùng do phân hệ cấu hình. (3) Sau khi máy chủ trả giá trị, giá trị thật hiển thị tại chỗ, kèm chữ phụ "Đang hiện · tự che sau 30 giây" và nút "Ẩn" (`hide`). (4) Sau 30 giây, khi rời trang, khi đổi tenant hoặc khi cửa sổ mất focus quá 30 giây, giá trị tự che lại và bị xóa khỏi bộ nhớ thành phần. (5) Mở xem lần nữa cần lý do lần nữa (mỗi lần là một bản ghi kiểm toán). Trong một bảng, chỉ mở được từng ô; không có "Hiện tất cả".

**Biến thể.** `revealable` (có nút Hiện khi `canReveal`), `static` (không bao giờ có nút, dùng cho log vận hành và giá trị giao diện tự nhận diện, D03-06-00 PTN-11). Khi người dùng không có quyền, nút không hiện (không hiện vô hiệu), đúng quy ước ẩn khi thiếu quyền (D03-05-04 §2.3).

**Trạng thái.** Che, đang mở (đợi máy chủ: spinner trong nút), đang hiện, lỗi mở (Toast lỗi với mã lỗi, giá trị giữ nguyên che), hết hạn hiện (tự che).

**Token.** `TKN-font-mono` (với giá trị dạng số), `TKN-color-text-secondary` (ký tự che), `TKN-color-warning-text` (chữ "Đang hiện"), `TKN-font-caption`.

**Nền đặt.** Nền đặc. Không đặt dữ liệu cá nhân trên lớp glass.

**Bàn phím và ARIA.** Giá trị che có tên truy cập "Đã che: số điện thoại" (không đọc từng dấu sao). Nút "Hiện" có `aria-label="Hiện số điện thoại"`. Khi giá trị hiện, vùng gốc thông báo `aria-live="polite"` "Đang hiện số điện thoại, tự che sau 30 giây".

**Chống lộ phụ.** Giá trị đã hiện không được đưa vào bộ nhớ đệm TanStack Query (mutation `gcTime: 0`), không vào URL, không vào nội dung xuất Excel (xuất luôn xuất bản che), có `user-select: all` để sao chép có chủ đích nhưng không có nút sao chép riêng. Trang in (`@media print`) luôn in bản che.

**API.**

```tsx
export interface DhMaskedValueProps {
  masked: string;                        // giá trị đã che do máy chủ trả
  fieldLabel: string;                    // 'số điện thoại'
  variant?: 'revealable' | 'static';
  canReveal?: boolean;                   // từ allowedActions/quyền
  reveal?: (reason: string) => Promise<string>;   // gọi API mở xem
  reasonPresets?: string[];
  autoHideSeconds?: number;              // mặc định 30
  testId?: string;
}
```

```tsx
<MaskedValue masked={citizen.phone} fieldLabel="số điện thoại" canReveal={can('unmask')}
  reveal={(reason) => api.privacy.reveal({ subjectId: citizen.id, field: 'phone', reason })} />
```

**Điều cấm.** Cấm che bằng CSS hoặc ở giao diện. Cấm "Hiện tất cả". Cấm giữ giá trị đã hiện quá thời hạn. Cấm dùng MaskedValue cho bí mật (dùng `CMP-SecretField`, `CMP-SecretRefField`).

## 9. Bảng tổng hợp thành phần nguyên tử

Bảng dưới đây là danh mục chính thức các thành phần nguyên tử, dùng để đối chiếu danh mục Storybook khi nghiệm thu design system (D03-05 §6). Cột "Mức" theo MoSCoW cho đợt MVP: M bắt buộc có trước khi phát triển phân hệ, S cần có trước khi làm phân hệ dùng nó. Cột "Story tối thiểu" là số story bắt buộc chưa nhân với hai chế độ sáng/tối và hai chế độ kính `full`/`off`.

| Mục | Mã | Nền antd hoặc thư viện | Mức | Story tối thiểu | Đặt trên glass |
|---|---|---|---|---|---|
| 3.1 | `CMP-Button` | `Button` | M | 6 biến thể × 8 trạng thái | Có |
| 3.2 | `CMP-IconButton` | `Button` `shape` | M | 4 | Có |
| 3.3 | `CMP-Link` | `Typography.Link` | M | 4 | Hạn chế (mục 3.3) |
| 3.4 | `CMP-CopyButton` | `Button` + Clipboard API | M | 3 | Có |
| 4.1 | `CMP-Icon` | Lucide | M | 1 (bảng biểu tượng) | Có |
| 4.2 | `CMP-Text` | `Typography.Text` | M | 5 | Có |
| 4.3 | `CMP-Heading` | `Typography.Title` | M | 4 | Có |
| 4.4 | `CMP-Kbd` | thẻ `kbd` | S | 1 | Có |
| 4.5 | `CMP-CodeText` | `Typography.Text code` | M | 2 | Không |
| 4.6 | `CMP-Divider` | `Divider` | M | 2 | Có |
| 5.1 | `CMP-StatusTag` | `Tag` | M | 5 sắc thái + bảng mã | Có |
| 5.2 | `CMP-Tag` | `Tag` | M | 4 | Có |
| 5.3 | `CMP-Badge` | `Badge` | M | 3 | Có |
| 5.4 | `CMP-StatusDot` | `Badge status` | M | 5 | Có |
| 5.5 | `CMP-Avatar` | `Avatar` | M | 3 | Có |
| 5.6 | `CMP-AvatarGroup` | `Avatar.Group` | S | 3 | Có |
| 6.1 | `CMP-Spinner` | `Spin` | M | 3 | Có |
| 6.2 | `CMP-Skeleton` | `Skeleton` | M | 4 hình dạng | Không |
| 6.3 | `CMP-ProgressBar` | `Progress` | M | 4 | `glass-overlay` |
| 6.4 | `CMP-Tooltip` | `Tooltip` | M | 2 | Có (nền đảo) |
| 6.5 | `CMP-SaveIndicator` | tự dựng | S | 6 trạng thái | Không |
| 7.1 | `CMP-Input` | `Input` | M | 8 trạng thái | `glass-overlay` |
| 7.2 | `CMP-SecretField` | `Input.Password` | M | 2 chế độ × 3 | Không |
| 7.3 | `CMP-TextArea` | `Input.TextArea` | M | 4 | Không |
| 7.4 | `CMP-NumberInput` | `InputNumber` | M | 4 | Không |
| 7.5 | `CMP-Select` | `Select` | M | 4 tính năng × 3 | Popup `glass-overlay` |
| 7.6 | `CMP-TreeSelect` | `TreeSelect` | M | 3 | Popup `glass-overlay` |
| 7.7 | `CMP-Checkbox` | `Checkbox` | M | 4 | Có |
| 7.8 | `CMP-Radio` | `Radio` | M | 3 | Có |
| 7.9 | `CMP-Switch` | `Switch` | M | 4 | `glass-overlay` |
| 7.10 | `CMP-SegmentedControl` | `Segmented` | M | 3 | Có |
| 7.11 | `CMP-DatePicker` | `DatePicker` | M | 4 | Popup `glass-overlay` |
| 7.12 | `CMP-DateRangePicker` | `DatePicker.RangePicker` | M | 4 | Popup `glass-overlay` |
| 7.13 | `CMP-Upload` | `Upload` | M | 3 biến thể × 5 trạng thái tệp | Không |
| 7.14 | `CMP-RadioCard` | `Radio.Group` | S | 4 | Không |
| 7.15 | `CMP-CronPicker` | ghép | S | 5 kiểu lịch + lỗi | Không |
| 7.16 | `CMP-ExpressionField` | CodeMirror 6 + `Select` | S | 5 | Không |
| 7.17 | `CMP-SecretRefField` | `Select` | S | 4 | Không |
| 7.18 | `CMP-ResourceSelect` (`CMP-CodeListSelect`, `CMP-ConnectionSelect`, `CMP-SchemaSelect`, `CMP-ApiSelect`, `CMP-TopicSelect`) | `Select` | S | 3 mỗi biến thể | Popup `glass-overlay` |
| 8.1 | `CMP-Timestamp` | thẻ `time` | M | 6 biến thể | Có |
| 8.2 | `CMP-Duration` | thẻ `time` | M | 3 | Có |
| 8.3 | `CMP-Money` | tự dựng | M | 3 | Có |
| 8.4 | `CMP-Identifier` | `Typography.Text` | M | 3 | Có (trừ `link` trên glass dày) |
| 8.5 | `CMP-MaskedValue` | tự dựng | M | 5 trạng thái | Không |

Tổng cộng 44 thành phần nguyên tử. Tính cả năm biến thể theo phân hệ của `CMP-ResourceSelect` (có mã riêng để truy vết nhưng dùng chung một hiện thực) thì có 49 mã `CMP-`.

**Tên gọi khác đã gặp trong tài liệu phân hệ.** Một số tập D03-06 viết trước khi tập này hoàn thành dùng tên khác cho cùng thành phần. Bảng dưới là ánh xạ chính thức; tập phân hệ được sửa theo tên chuẩn ở lần cập nhật kế tiếp và lint tài liệu (`build/check-cmp.py`, đề xuất ở mục 12) cảnh báo tên không có trong danh mục.

| Tên đã dùng | Tên chuẩn | Ghi chú |
|---|---|---|
| `CMP-Segmented` | `CMP-SegmentedControl` | |
| `CMP-SearchInput` | `CMP-SearchField` (D03-05-04 §3.3) | Ô tìm có bỏ dấu và debounce |
| `CMP-FileDrop`, `CMP-FileDropzone` | `CMP-Upload` biến thể `dropzone` | |
| `CMP-CodeBlock` | `CMP-CodeEditor` chế độ chỉ đọc (D03-05-04 §9.1) hoặc `CMP-JsonViewer` | Khối mã nhiều dòng |

## 10. Checklist nghiệm thu thành phần nguyên tử

Kiểm thử viên và người duyệt PR dùng checklist dưới đây cho mỗi thành phần trước khi phát hành `@datahub/ui`.

- [ ] Có đủ story theo cột "Story tối thiểu" của mục 9, mỗi story ở sáng, tối, kính `full` và `off`.
- [ ] axe-core không có vi phạm A/AA trên mọi story (NFR-00-040).
- [ ] Mọi giá trị thị giác đến từ token; lint "không giá trị thô" không báo lỗi (D03-05-02 §15).
- [ ] Không có `{...rest}` xuống antd; interface liệt kê tường minh prop được phép (mục 1.4).
- [ ] Vòng focus kép hiển thị đúng trên nền đặc, nền nhấn và `glass-overlay`, đạt 3:1.
- [ ] Vùng chạm tối thiểu 24×24 (WCAG 2.5.8), kể cả nút phụ nhỏ (sao chép, đóng nhãn).
- [ ] Không có thông tin chỉ truyền bằng màu (WCAG 1.4.1): trạng thái có chữ hoặc hình dạng đi kèm.
- [ ] Chuỗi cố định lấy từ `dhMessages`, không viết cứng trong JSX.
- [ ] Hành vi bàn phím đúng mục "Bàn phím và ARIA" của thành phần, đã thử với NVDA trên Windows cho nhóm nhập liệu.
- [ ] Ở chế độ giảm chuyển động, không còn chuyển động trượt, quay hay phóng to.
- [ ] Thành phần nhận `ref`, `testId`, `id`, `aria-*` theo mục 1.4.
- [ ] Thành phần nhập liệu chạy đúng trong `Form.Item` (cặp `value`/`onChange`).
- [ ] Thành phần hiển thị dữ liệu (mục 8) hiển thị "—" cho giá trị rỗng và dùng hàm của `@datahub/ui/format`.
- [ ] `CMP-MaskedValue`, `CMP-SecretField`, `CMP-SecretRefField`: kiểm thử bảo mật xác nhận giá trị thật không nằm trong bộ nhớ đệm, URL, `localStorage`, tệp xuất.

## 11. Truy vết

| Yêu cầu | Đáp ứng tại |
|---|---|
| RB-03 React + antd v6, Liquid Glass tới từng thành phần nguyên tử | Toàn bộ tài liệu; vật liệu từng thành phần ở mục "Nền đặt" |
| NFR-00-040…043 WCAG 2.2 AA, tương phản, bàn phím, giảm chuyển động | Mục 2, mục "Bàn phím và ARIA" của mỗi thành phần, mục 10 |
| NFR-00-045 100% màn hình dùng `@datahub/ui` | Mục 1.4, mục 9 |
| FR-00-034, FR-00-040 che và mở xem dữ liệu cá nhân có kiểm toán | `CMP-MaskedValue` (8.5) |
| FR-00-050 xác nhận thao tác ảnh hưởng vận hành | `CMP-Switch` (7.9) prop `confirm` |
| FR-00-053 nhãn trạng thái thống nhất | `CMP-StatusTag` (5.1), `CMP-StatusDot` (5.4) |
| FR-00-054 tác vụ dài và trạng thái lưu | `CMP-ProgressBar` (6.3), `CMP-SaveIndicator` (6.5) |
| FR-00-080, FR-00-081 thông báo lỗi và lỗi theo trường | Mục 7.0, `CMP-ExpressionField` (7.16) |
| CRUD-R-05, CRUD-TBL-08 của `docs/ui_ux_rule.md` | Mục 8 (giá trị rỗng, định dạng ngày giờ) |
| PH-04 D03-06-PH04 §27.3 (thành phần đề nghị bổ sung) | `CMP-AvatarGroup`, `CMP-SaveIndicator`, `CMP-RadioCard`, `CMP-ExpressionField`, `CMP-SecretRefField`, `CMP-ConnectionSelect`, `CMP-SchemaSelect`, `CMP-CodeListSelect`; phần còn lại ở D03-05-04 |
| PH-07 D03-06-PH07 Phụ lục A-05 | `CMP-CronPicker`; `CMP-FileDrop` là `CMP-Upload`; phần còn lại ở D03-05-04 |
| PH-19 BRD (hiển thị số tiền, giao dịch) | `CMP-Money` (8.3), `CMP-Timestamp` biến thể `datetime-second` (8.1) |

## 12. Đề xuất bổ sung

1. **D00-01 §5 (kiểu dữ liệu).** Bổ sung cho `T-MONEY` trường đi kèm `currency` (ISO 4217, mặc định `VND`) dành cho trường hợp đối soát ngoại tệ hiếm gặp, để `CMP-Money` không phải đoán đơn vị.
2. **D00-01 thuật ngữ.** Bổ sung "tham chiếu bí mật" (secret reference): chuỗi `{{conn:…}}` hoặc `{{vault:…}}` trỏ tới bí mật đã cất, không chứa giá trị.
3. **Công cụ kiểm tra tài liệu.** Bổ sung `datahub-docs/build/check-cmp.py`: quét mọi tệp `.md` trong `datahub-docs/`, liệt kê mã `CMP-*` không có trong bảng tổng hợp mục 9 của tài liệu này và của D03-05-04, chạy trong cổng kiểm tra liên kết (DoD "kiểm tra liên kết chạy sạch").
4. **Bộ biểu tượng.** Bổ sung các khóa biểu tượng ở bảng của mục 4.1 (đã thêm ở bản 0.2): `offline`, `expression`, `connection`, `schema`, `undo`, `redo`, `zoom-in`, `zoom-out`, `fit-view`, `fullscreen`, `pin`, `comment`, `diff`, `tasks`, `command`, `sticky-note`, `minimap`, `panel`.
