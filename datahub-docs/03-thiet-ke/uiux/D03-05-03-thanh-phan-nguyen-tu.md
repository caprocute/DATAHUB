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

