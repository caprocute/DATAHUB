---
ma_tai_lieu: D03-10
ten: Thiết kế đa tenant
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiến trúc sư, Đội phát triển, Vận hành, Hội đồng thẩm định
mo_ta: Đặc tả tenant, ba chế độ cách ly, cách xác định tenant trong mỗi yêu cầu, cơ chế cách ly ở từng tầng, vòng đời, khởi tạo, hạn mức và sáp nhập tenant, làm ràng buộc chung cho mọi phân hệ của Datahub.
tai_lieu_lien_quan: ADR-003 RLS đa tenant; D00-01 Thuật ngữ và quy ước; D02-02 SRS; D03-01 SAD; D03-07 Thiết kế ATTT; D03-09 Hạ tầng và DR; D04-01 Quy ước viết mã
---

# D03-10 · Thiết kế đa tenant

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Datahub phục vụ nhiều tỉnh trên cùng một nền tảng và một bộ mã. Tài liệu đặc tả cách bảo đảm dữ liệu, cấu hình và người dùng của mỗi tỉnh (một tenant) tách biệt hoàn toàn với tỉnh khác ở mọi tầng, và cách một tenant được khởi tạo, cấu hình hạn mức, tạm ngừng, sáp nhập và chấm dứt. Đây là ràng buộc chung mà mọi phân hệ phải tuân thủ.

**Phạm vi.** Tài liệu gồm khái niệm tenant và ba chế độ cách ly, cách xác định tenant trong mỗi yêu cầu, cơ chế cách ly ở mười hai tầng (CSDL, bộ nhớ đệm, Kafka, kho lược đồ, kho đối tượng, Keycloak, OPA, APISIX, runtime luồng, kho bí mật, quan sát, nhật ký kiểm toán), vòng đời tenant với sáu trạng thái, saga khởi tạo mười bước, hạn mức mặc định, quy trình sáp nhập và sáu quy tắc bắt buộc cho người phát triển.

**Căn cứ pháp lý.** CMP-LAW-06 và CMP-LAW-08 (Nghị định 331/2026/NĐ-CP, TCVN 14423:2026: kiểm soát truy cập, phân tách dữ liệu, nhật ký ở cấp độ 3); CMP-LAW-05 (Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15: dữ liệu cá nhân của tỉnh này không được lộ sang tỉnh khác); CMP-LAW-03 (Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu); CMP-LAW-16 (Luật An ninh mạng 116/2025/QH15: lưu trữ dữ liệu trong nước, bảo vệ hệ thống thông tin).

**Những điểm hội đồng cần lưu ý.** (1) Tenant của một yêu cầu chỉ được lấy từ token đã xác thực, không bao giờ từ tham số do người gọi gửi; người dùng tỉnh này không thể tự khai là tỉnh khác. (2) Cách ly được thực thi ở tầng hạ tầng (RLS của PostgreSQL, ACL Kafka, realm Keycloak, chính sách OpenBao), và mỗi DU tự kiểm tra cấu hình khi khởi động, từ chối chạy nếu cấu hình làm vô hiệu cách ly. (3) Một bộ mã chạy được cho cả nền tảng dùng chung lẫn tỉnh tự vận hành, nhờ ba chế độ cách ly từ dùng chung tới cụm riêng. (4) Việc sắp xếp đơn vị hành chính cấp tỉnh được hỗ trợ bằng quy trình sáp nhập tenant có thời gian chuyển tiếp mặc định 6 tháng, HTTT không phải đổi ngay. (5) Truy cập dữ liệu tỉnh từ tenant quản trị nền tảng phải nêu lý do và được kiểm toán.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Chế độ cách ly | 3 (`SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER`) |
| Tầng có cơ chế cách ly riêng | 12 |
| Trạng thái vòng đời tenant | 6 |
| Bước saga khởi tạo tenant | 10, mục tiêu ≤ 1 giờ ở chế độ `SHARED` (NFR-00-057) |
| Hạn mức mặc định | 500 lượt gọi mỗi giây, 1.000 luồng, 10/20 MB/s Kafka, 500 GB kho đối tượng, 200 GB CSDL, 2.000 người dùng |
| Ngưỡng tách namespace runtime riêng | Trên 50 luồng |
| Thời gian chuyển tiếp khi sáp nhập | 6 tháng (mặc định) |
| Quy tắc bắt buộc cho người phát triển | 6 |

: Con số chính của thiết kế đa tenant

Các con số trên được lấy từ chương 2, 4, 5 và 6 của tài liệu này; hạn mức thực tế của từng tỉnh được điều chỉnh theo hợp đồng.

## 1. Mục đích

Datahub là sản phẩm phục vụ nhiều tỉnh trên cùng một nền tảng (quyết định Q2). Tài liệu này đặc tả **tenant là gì, dữ liệu của mỗi tenant được cách ly ra sao ở từng tầng, tenant được khởi tạo, cấu hình, tạm ngừng, sáp nhập như thế nào**. Đây là ràng buộc chung cho mọi phân hệ; FRS và SDD từng phân hệ phải tuân thủ và không mô tả lại.

### 1.1. Mục đích của tài liệu

Tài liệu là nguồn chuẩn duy nhất về đa tenant cho toàn bộ Datahub. Hội đồng thẩm định dùng tài liệu để đánh giá mức bảo đảm cách ly dữ liệu giữa các tỉnh trên nền tảng dùng chung. Kỹ sư dùng chương 3, 4 và 6 làm ràng buộc khi viết mã, migration và kiểm thử; người viết SDD, CSDL phân hệ dẫn chiếu tài liệu này thay vì mô tả lại. Vận hành dùng chương 5 để khởi tạo, tạm ngừng và sáp nhập tenant.

### 1.2. Phạm vi

Tài liệu đặc tả những gì chung cho mọi phân hệ về tenant. Phần hiện thực cụ thể của từng phân hệ, giao diện quản trị tenant và hạ tầng chạy các cơ chế này nằm ở tài liệu khác, như bảng dưới.

| Thuộc tài liệu này | Nằm ở tài liệu khác |
|---|---|
| Khái niệm tenant, tenant `PLATFORM`, dữ liệu `COMMON`, chế độ cách ly | Quyết định chọn RLS và các phương án khác: ADR-003 |
| Xác định tenant trong yêu cầu, sự kiện, tác vụ nền | Biện pháp ATTT `SEC-80`…`SEC-88`: D03-07 |
| Cơ chế cách ly và cách kiểm chứng ở từng tầng | Namespace, định cỡ, sao lưu theo tenant: D03-09 |
| Vòng đời, saga khởi tạo, hạn mức, sáp nhập | Chức năng, màn hình quản trị tenant: tập phân hệ PH-20 |
| Quy tắc cho người phát triển | Quy tắc viết mã chi tiết: D04-01 |

: Phân định phạm vi giữa D03-10 và các tài liệu khác

### 1.3. Người đọc và cách đọc

Bảng dưới gợi ý phần cần đọc theo vai trò.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 2, 4, 5.4 | Đánh giá mức cách ly và khả năng đáp ứng sáp nhập tỉnh |
| Kiến trúc sư, người viết SDD, CSDL | Chương 2, 3, 4, 6 | Ràng buộc phải tuân thủ trong thiết kế phân hệ |
| Kỹ sư phát triển | Chương 3, 4 (mẫu RLS), 6 | Cách đặt ngữ cảnh tenant, viết migration, tránh lỗi rò rỉ |
| Kiểm thử viên | Chương 4 (cột kiểm chứng), 6 | Ca kiểm thử rò rỉ chéo tenant, kiểm thử ACL, chính sách |
| Vận hành, quản trị nền tảng | Chương 5 | Khởi tạo, tạm ngừng, sáp nhập, theo dõi hạn mức |

: Người đọc D03-10 và phần cần đọc theo vai trò

### 1.4. Thuật ngữ và chữ viết tắt

Bảng dưới chỉ gồm thuật ngữ riêng của thiết kế đa tenant. Thuật ngữ chung (HTTT, DU, RLS, saga…) theo D00-01 §2 và SAD §1.4.

| Thuật ngữ | Giải thích |
|---|---|
| Tenant | Đơn vị khách hàng độc lập về dữ liệu và quản trị, tương ứng một tỉnh hoặc thành phố trực thuộc trung ương (chương 2) |
| Tổ chức | Sở, ngành, xã bên trong một tenant; không phải tenant riêng |
| `PLATFORM` | Tenant đặc biệt cho quản trị nền tảng, không chứa dữ liệu nghiệp vụ của tỉnh |
| `COMMON` | Giá trị `tenant_id` của dữ liệu dùng chung toàn quốc, mọi tenant đọc được, chỉ `PLATFORM` ghi |
| Chế độ cách ly | Mức tách tài nguyên của một tenant: `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER` |
| `TenantContext` | Ngữ cảnh tenant của luồng xử lý trong DU, đặt từ token hoặc tường minh cho tác vụ nền |
| `app.tenant_id` | Biến phiên PostgreSQL mà chính sách RLS đọc, đặt bằng `SET LOCAL` đầu mỗi giao dịch |
| `FORCE ROW LEVEL SECURITY` | Tùy chọn buộc RLS áp dụng cả với chủ sở hữu bảng |
| `BYPASSRLS` | Thuộc tính vai trò PostgreSQL cho phép bỏ qua RLS; vai trò ứng dụng không được có |
| Hàng xóm ồn ào | Tình huống một tenant dùng quá nhiều tài nguyên làm ảnh hưởng tenant khác |
| Tenant nguồn, tenant đích | Tenant bị sáp nhập và tenant nhận dữ liệu trong quy trình sáp nhập |
| Thời gian chuyển tiếp | Khoảng thời gian sau sáp nhập mà lời gọi tới tenant nguồn vẫn được chuyển sang tenant đích |

: Thuật ngữ riêng của thiết kế đa tenant

### 1.5. Tài liệu tham chiếu

Các tài liệu dưới đây được dẫn chiếu trong D03-10.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| CMP-LAW-06, CMP-LAW-08 | Nghị định 331/2026/NĐ-CP, TCVN 14423:2026 | Yêu cầu kiểm soát truy cập, phân tách dữ liệu ở cấp độ 3 |
| CMP-LAW-05 | Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 | Không để lộ dữ liệu cá nhân giữa các tỉnh |
| ADR-003 | PostgreSQL với RLS làm cơ chế cách ly tenant mặc định | Lý do chọn cách ly logic và các phương án nâng cấp |
| D00-01 | Thuật ngữ và quy ước | Kiểu T-TENANT, cột ngữ cảnh bắt buộc |
| D02-02 | Đặc tả yêu cầu phần mềm (SRS) | FR-00-010…012, NFR-00-057, NFR-00-060 |
| D03-01 | Thiết kế kiến trúc tổng thể (SAD) | Nguyên tắc NT-02, đơn vị triển khai |
| D03-07 | Thiết kế an toàn thông tin | Biện pháp `SEC-80`…`SEC-88` về tenant |
| D03-09 | Thiết kế hạ tầng, triển khai, DR | Namespace `dh-rt-{tenant}`, sao lưu và khôi phục theo tenant |
| D04-01 | Quy ước viết mã | Nhắc lại quy tắc chương 6 ở mức mã nguồn |

: Tài liệu tham chiếu của D03-10

### 1.6. Cấu trúc tài liệu

Tài liệu đi từ khái niệm tới cơ chế, rồi tới vận hành và quy tắc. Bảng dưới tóm tắt từng chương.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 2 | Khái niệm tenant, tenant đặc biệt, ba chế độ cách ly | Hội đồng, kiến trúc sư |
| 3 | Xác định tenant trong yêu cầu, sự kiện, tác vụ nền | Kỹ sư |
| 4 | Cơ chế cách ly và cách kiểm chứng theo từng tầng, mẫu RLS, dữ liệu dùng chung | Kỹ sư, kiểm thử viên, hội đồng |
| 5 | Vòng đời tenant, saga khởi tạo, hạn mức, sáp nhập | Vận hành, hội đồng |
| 6 | Sáu quy tắc bắt buộc cho người phát triển | Kỹ sư, kiểm thử viên |
| 7 | Truy vết yêu cầu tới mục của tài liệu | Kiểm thử viên, quản lý chất lượng |

: Cấu trúc chương của D03-10

## 2. Khái niệm

**Tenant** là một đơn vị khách hàng độc lập về dữ liệu và quản trị, tương ứng với **một tỉnh hoặc thành phố trực thuộc trung ương**. Mã tenant theo kiểu T-TENANT (D00-01 §5), ví dụ `T68`. Mọi đơn vị bên trong tỉnh (sở, ngành, xã) là **tổ chức** trong tenant, không phải tenant riêng.

Ngoài các tenant tỉnh có một tenant đặc biệt **`PLATFORM`** dành cho quản trị nền tảng. Tenant này không chứa dữ liệu nghiệp vụ của tỉnh nào; người dùng của nó chỉ truy cập dữ liệu tỉnh qua cơ chế liên tenant có lý do và kiểm toán (FR-00-012).

Mỗi tenant có một **chế độ cách ly**:

| Chế độ | Mô tả | Khi dùng |
|---|---|---|
| `SHARED` (mặc định) | Dùng chung cụm CSDL, Kafka, kho đối tượng với tenant khác; cách ly logic bằng RLS, ACL, tiền tố | Đa số tỉnh trên nền tảng dùng chung |
| `DEDICATED_DB` | Cụm PostgreSQL riêng; các tầng khác dùng chung | Tỉnh có yêu cầu riêng về CSDL hoặc chuẩn bị lên cấp độ 4 |
| `DEDICATED_CLUSTER` | Một cụm Kubernetes riêng, toàn bộ thành phần riêng | Tỉnh tự vận hành on-prem; cấp độ 4 |

: Ba chế độ cách ly tenant và trường hợp áp dụng

Ở chế độ `DEDICATED_CLUSTER`, phần mềm vẫn chạy ở chế độ đa tenant (thường chỉ có một hoặc vài tenant), nhờ đó chỉ có một bộ mã cho mọi hồ sơ triển khai (RB-07).

## 3. Xác định tenant trong mỗi yêu cầu

Nguồn sự thật duy nhất về tenant của một yêu cầu là **token đã xác thực**. Cụ thể:

1. Mỗi tenant có một realm Keycloak tên `dh-{mã tenant viết thường}` (ví dụ `dh-t68`). Token do realm phát hành mang claim `tenant` bằng mã tenant.
2. APISIX xác minh token bằng khóa công khai của realm tương ứng, đối chiếu claim `tenant` với realm phát hành, rồi chuyển tiếp header nội bộ `X-DH-Tenant` (header này bị xóa nếu client tự gửi).
3. Ở mỗi DU, bộ lọc Spring Security đọc tenant từ token (không tin header khi gọi từ ngoài mesh), đặt vào `TenantContext` và vào biến phiên PostgreSQL `app.tenant_id` ở đầu mỗi giao dịch.
4. Sự kiện Kafka mang tenant trong header CloudEvents `dhtenant` và trong tên topic; consumer kiểm tra hai giá trị khớp nhau, không khớp thì chuyển vào DLQ và cảnh báo an ninh.
5. Tác vụ nền (lịch, xử lý lô) chạy lặp theo từng tenant, đặt `TenantContext` tường minh; không có tác vụ nào chạy "không tenant" trừ tác vụ của tenant `PLATFORM`.

```{.mermaid caption="Trình tự xác định tenant từ token tới chính sách RLS"}
sequenceDiagram
  participant C as Client
  participant G as APISIX
  participant D as DU (Spring)
  participant P as PostgreSQL
  C->>G: Bearer token (realm dh-t68)
  G->>G: Xác minh chữ ký, claim tenant = T68
  G->>D: Chuyển tiếp, X-DH-Tenant: T68
  D->>D: TenantContext = T68 (từ token)
  D->>P: BEGIN, rồi SET LOCAL app.tenant_id = 'T68'
  D->>P: SELECT ... (RLS tự lọc)
  P-->>D: Chỉ bản ghi của T68
```

Hình cho thấy tenant đi một chiều từ token xuống CSDL: APISIX xác minh và ghi `X-DH-Tenant`, DU vẫn đọc lại tenant từ token để đặt `TenantContext`, rồi đặt biến phiên `app.tenant_id` bằng `SET LOCAL` trong giao dịch. Từ đó chính sách RLS của PostgreSQL tự lọc mọi truy vấn, nên một câu `SELECT` quên điều kiện tenant cũng không trả về bản ghi của tỉnh khác. Biến phiên đặt bằng `SET LOCAL` chỉ sống trong giao dịch, tương thích với PgBouncer chế độ giao dịch (D03-09 §6.3).

## 4. Cách ly theo từng tầng

Bảng dưới đây là phần cốt lõi của tài liệu: với mỗi tầng, cơ chế cách ly ở chế độ `SHARED` và cách kiểm chứng. Mọi cơ chế đều được thực thi ở tầng hạ tầng chứ không chỉ dựa vào mã ứng dụng.

| Tầng | Cơ chế cách ly | Kiểm chứng |
|---|---|---|
| CSDL PostgreSQL | Cột `tenant_id` trên mọi bảng nghiệp vụ; RLS bật và `FORCE ROW LEVEL SECURITY`; vai trò kết nối của ứng dụng không có `BYPASSRLS` và không là chủ sở hữu bảng | DU tự kiểm tra khi khởi động: từ chối chạy nếu vai trò có `BYPASSRLS` hoặc bảng nào thiếu chính sách. Kiểm thử rò rỉ chéo tenant |
| Bộ nhớ đệm Valkey | Khóa có tiền tố `{tenant}:`; ACL người dùng Valkey theo mẫu khóa với dữ liệu nhạy cảm | Kiểm thử đơn vị lớp bộ nhớ đệm |
| Kafka | Topic tiền tố mã tenant viết thường (`t68.`); ACL theo tiền tố cho principal của từng HTTT; quota sản xuất, tiêu thụ theo tenant | Kiểm thử ACL tự động khi khởi tạo tenant |
| Schema registry | Nhóm (group) Apicurio theo tenant cho schema riêng; schema dùng chung ở nhóm `common` chỉ-đọc | |
| Kho đối tượng | Bucket `dh-{tenant}-{mục đích}`; khóa truy cập theo tenant; mã hóa phía máy chủ | |
| Keycloak | Realm riêng mỗi tenant; quản trị tỉnh chỉ quản trị realm của mình | |
| OPA | Mọi chính sách có điều kiện `input.tenant == data.resource.tenant` | Kiểm thử chính sách Rego |
| APISIX | Route, consumer, plugin config gắn nhãn tenant; host hoặc tiền tố đường dẫn theo tenant cho API công bố | |
| Runtime luồng | Luồng thuộc một tenant; triển khai trong namespace `dh-rt-{tenant}` khi tenant có trên 50 luồng hoặc yêu cầu, còn lại dùng namespace chung với nhãn tenant | |
| Kho bí mật | Đường dẫn `kv/dh/{tenant}/...`; chính sách OpenBao theo tenant | |
| Quan sát | Nhãn `tenant` bắt buộc trên metric, log, trace; Grafana tách tổ chức (organization) theo tenant cho quản trị tỉnh | Quản trị tỉnh chỉ thấy dữ liệu tỉnh mình trên Grafana |
| Nhật ký kiểm toán | Cột `tenant_id`, RLS như CSDL; kho WORM tách tiền tố theo tenant | |

: Cơ chế cách ly tenant và cách kiểm chứng ở mười hai tầng

**Chính sách RLS mẫu.** Mọi bảng nghiệp vụ dùng cùng mẫu dưới đây. Migration Liquibase của mỗi phân hệ phải có changeset tạo chính sách ngay sau khi tạo bảng; công cụ lint migration chặn bảng không có chính sách.

```sql
ALTER TABLE ph07_rdm.category ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.category FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON ph07_rdm.category
  USING (tenant_id = current_setting('app.tenant_id', false))
  WITH CHECK (tenant_id = current_setting('app.tenant_id', false));
```

Tham số `false` ở `current_setting` làm truy vấn **lỗi** (thay vì trả rỗng) khi quên đặt biến phiên, giúp phát hiện sớm lỗi lập trình.

**Dữ liệu dùng chung giữa các tenant.** Một số dữ liệu là chung cho cả nước: danh mục quốc gia, danh mục đơn vị hành chính, định nghĩa Kamelet được duyệt. Dữ liệu này lưu với `tenant_id = 'COMMON'` và chính sách RLS cho phép đọc `tenant_id IN (current_setting('app.tenant_id'), 'COMMON')`; chỉ tenant `PLATFORM` được ghi.

## 5. Vòng đời tenant

Chương này đặc tả tenant đi qua những trạng thái nào từ khi khai báo tới khi chấm dứt, cách khởi tạo tự động bằng saga, hạn mức bảo vệ các tenant khỏi ảnh hưởng lẫn nhau và quy trình sáp nhập khi sắp xếp đơn vị hành chính cấp tỉnh.

### 5.1. Máy trạng thái

Một tenant có sáu trạng thái. Sơ đồ dưới cho thấy các chuyển trạng thái được phép; bảng tiếp theo nêu hành vi của data plane và giao diện ở từng trạng thái.

```{.mermaid caption="Vòng đời tenant từ khai báo tới chấm dứt"}
stateDiagram-v2
  [*] --> PROVISIONING: Khai báo
  PROVISIONING --> ACTIVE: Khởi tạo thành công
  PROVISIONING --> FAILED: Lỗi khởi tạo
  FAILED --> PROVISIONING: Thử lại
  ACTIVE --> SUSPENDED: Tạm ngừng (có lý do)
  SUSPENDED --> ACTIVE: Khôi phục
  ACTIVE --> MERGING: Bắt đầu sáp nhập vào tenant khác
  MERGING --> MERGED: Hoàn tất
  SUSPENDED --> DECOMMISSIONED: Chấm dứt
  MERGED --> DECOMMISSIONED: Hết thời hạn lưu giữ
  DECOMMISSIONED --> [*]
```

Người đọc cần thấy rằng chỉ có hai đường tới `DECOMMISSIONED`: từ `SUSPENDED` khi chấm dứt có quyết định, và từ `MERGED` khi hết thời hạn lưu giữ sau sáp nhập; tenant đang `ACTIVE` không thể bị chấm dứt trực tiếp mà phải qua tạm ngừng trước. Khởi tạo lỗi không làm mất tenant: `FAILED` cho phép thử lại từ bước lỗi của saga (mục 5.2).

| Trạng thái | Ý nghĩa | Data plane | Giao diện |
|---|---|---|---|
| `PROVISIONING` | Đang khởi tạo tài nguyên | Không phục vụ | Chỉ quản trị nền tảng thấy |
| `ACTIVE` | Hoạt động | Phục vụ | Đầy đủ |
| `SUSPENDED` | Tạm ngừng do quyết định quản lý hoặc sự cố an ninh | Từ chối với `ERR-20-001`, trừ API được đánh dấu thiết yếu nếu quyết định tạm ngừng cho phép | Chỉ-đọc cho quản trị tỉnh |
| `MERGING` | Đang chuyển dữ liệu sang tenant đích | Phục vụ, có cầu nối chuyển tiếp | Cảnh báo trên thanh trên |
| `MERGED` | Đã sáp nhập; mọi yêu cầu được định tuyến sang tenant đích trong thời gian chuyển tiếp | Chuyển tiếp | Chỉ-đọc, phục vụ tra cứu lịch sử |
| `DECOMMISSIONED` | Đã chấm dứt; dữ liệu đã được xuất bàn giao và xóa theo chính sách | Không | Không |

: Sáu trạng thái tenant và hành vi của data plane, giao diện

### 5.2. Khởi tạo tenant

Khởi tạo tenant là một saga do PH-20 điều phối. Mỗi bước idempotent và có thao tác bù trừ; nếu một bước lỗi, saga dừng ở `FAILED` và cho phép thử lại từ bước lỗi.

| Bước | Hành động | Bù trừ |
|---|---|---|
| 1 | Ghi bản ghi tenant, cấu hình mặc định, hạn mức | Xóa bản ghi |
| 2 | Tạo realm Keycloak từ mẫu, client của `dh-console`, `dh-portal`, vai trò chuẩn (D02-08), tài khoản quản trị tỉnh đầu tiên với yêu cầu đổi mật khẩu và đăng ký MFA | Xóa realm |
| 3 | Tạo đường dẫn và chính sách trong OpenBao | Xóa |
| 4 | Tạo bucket kho đối tượng | Xóa bucket rỗng |
| 5 | Tạo ACL và quota Kafka theo tiền tố; nhóm Apicurio | Xóa |
| 6 | Với `DEDICATED_DB`: tạo cụm CloudNativePG từ mẫu, chạy migration; ghi chuỗi kết nối tham chiếu vào bảng định tuyến | Xóa cụm |
| 7 | Tạo tổ chức Grafana, nguồn dữ liệu lọc theo tenant | Xóa |
| 8 | Nạp dữ liệu nền: tổ chức cấp tỉnh, đơn vị hành chính thuộc tỉnh (từ danh mục `COMMON`), danh mục bắt buộc | Xóa |
| 9 | Chạy kiểm tra khói: đăng nhập tài khoản quản trị, gọi API mẫu, phát và nhận một sự kiện mẫu | — |
| 10 | Chuyển `ACTIVE`, gửi thông báo cho đầu mối | — |

: Mười bước saga khởi tạo tenant và thao tác bù trừ

Mục tiêu thời gian của saga ở chế độ `SHARED` là ≤ 1 giờ (NFR-00-057).

Sơ đồ trình tự dưới đây vẽ lại mười bước của bảng trên theo thứ tự gọi giữa PH-20 và các thành phần hạ tầng, để người vận hành thấy saga chạm những hệ nào và dừng ở đâu khi lỗi.

```{.mermaid caption="Trình tự saga khởi tạo tenant do PH-20 điều phối"}
sequenceDiagram
  actor PA as Quản trị nền tảng
  participant P20 as PH-20 (dh-platform)
  participant KC as Keycloak
  participant BAO as OpenBao
  participant S3 as Kho đối tượng
  participant KF as Kafka và Apicurio
  participant PG as CloudNativePG
  participant GF as Grafana
  PA->>P20: Khai báo tenant T68, chế độ cách ly
  P20->>P20: Bước 1, bản ghi tenant PROVISIONING, cấu hình, hạn mức
  P20->>KC: Bước 2, tạo realm dh-t68, client, vai trò, quản trị tỉnh đầu tiên
  P20->>BAO: Bước 3, đường dẫn kv/dh/t68 và chính sách
  P20->>S3: Bước 4, bucket dh-t68-*
  P20->>KF: Bước 5, ACL, quota theo tiền tố t68., nhóm Apicurio
  opt Chế độ DEDICATED_DB
    P20->>PG: Bước 6, tạo cụm từ mẫu, chạy migration, ghi bảng định tuyến
  end
  P20->>GF: Bước 7, tổ chức Grafana, nguồn dữ liệu lọc theo tenant
  P20->>P20: Bước 8, nạp dữ liệu nền từ COMMON
  P20->>P20: Bước 9, kiểm tra khói đăng nhập, gọi API, phát và nhận sự kiện
  P20-->>PA: Bước 10, tenant ACTIVE, thông báo đầu mối
```

Hình cho thấy mọi bước đều do PH-20 gọi tuần tự và mỗi bước là một lệnh tới đúng một hệ, nên khi bước nào lỗi, saga dừng ở `FAILED` và biết chính xác hệ nào cần bù trừ hoặc thử lại. Bước 6 chỉ chạy với chế độ `DEDICATED_DB`. Kiểm tra khói ở bước 9 là điều kiện để chuyển `ACTIVE`; tenant chưa qua kiểm tra khói không bao giờ phục vụ data plane.

### 5.3. Hạn mức theo tenant

Hạn mức bảo vệ các tenant khỏi ảnh hưởng lẫn nhau trên nền tảng dùng chung (vấn đề "hàng xóm ồn ào"). Giá trị mặc định dưới đây được điều chỉnh theo hợp đồng của từng tỉnh.

| Hạn mức | Mặc định | Thực thi tại |
|---|---|---|
| Lượt gọi API tối đa mỗi giây cho toàn tenant | 500 | APISIX (`limit-count` theo nhãn tenant) |
| Số luồng đang hoạt động | 1.000 | PH-04 khi phát hành |
| Thông lượng Kafka sản xuất / tiêu thụ | 10 MB/s / 20 MB/s | Quota Kafka |
| Dung lượng kho đối tượng | 500 GB | Kiểm tra khi tải lên; cảnh báo ở 80% |
| Dung lượng CSDL | 200 GB | Giám sát, cảnh báo ở 80% |
| Số người dùng | 2.000 | PH-12 |

: Hạn mức mặc định theo tenant và nơi thực thi

### 5.4. Sáp nhập tenant

Sáp nhập đáp ứng thực tế sắp xếp đơn vị hành chính cấp tỉnh. Khi tỉnh A và tỉnh B hợp thành tỉnh C (hoặc A sáp nhập vào B), quy trình như sau:

1. **Chuẩn bị.** Tạo tenant đích (hoặc dùng tenant hiện có). Lập bảng ánh xạ: tổ chức, HTTT thành viên, mã danh mục địa phương trùng nhau.
2. **Chuyển dữ liệu.** PH-18 chạy công cụ chuyển dữ liệu theo từng phân hệ: sao chép bản ghi sang tenant đích với `tenant_id` mới, giữ `id` gốc (UUID v7 không trùng), ghi trường `origin_tenant_id` để truy vết. Danh mục địa phương trùng mã được đánh dấu xung đột để cán bộ nghiệp vụ xử lý.
3. **Chuyển định danh.** Người dùng được tạo lại ở realm đích, giữ liên kết LDAP nếu có; thông tin xác thực ứng dụng của HTTT được cấp mới, cấp song song có thời hạn để HTTT chuyển dần.
4. **Chuyển tiếp.** Tenant nguồn sang `MERGED`; APISIX định tuyến lời gọi tới API của tenant nguồn sang API tương ứng của tenant đích trong thời gian chuyển tiếp (mặc định 6 tháng), kèm header cảnh báo `Deprecation`.
5. **Kết thúc.** Hết thời gian chuyển tiếp, tenant nguồn chuyển `DECOMMISSIONED`; dữ liệu và nhật ký kiểm toán của tenant nguồn được lưu trữ theo thời hạn quy định.

Sơ đồ dưới đây tóm tắt năm bước sáp nhập và trạng thái của tenant nguồn ở mỗi bước.

```{.mermaid caption="Các bước sáp nhập tenant nguồn vào tenant đích"}
flowchart TB
  A["1. Chuẩn bị: tạo hoặc chọn tenant đích, lập bảng ánh xạ tổ chức, HTTT, mã danh mục"] --> B["2. Chuyển dữ liệu theo phân hệ (PH-18), giữ id gốc, ghi origin_tenant_id"]
  B --> C{"Danh mục địa phương trùng mã?"}
  C -->|Có| D[Đánh dấu xung đột, cán bộ nghiệp vụ xử lý]
  C -->|Không| E
  D --> E["3. Chuyển định danh: tạo lại người dùng ở realm đích, cấp song song thông tin xác thực HTTT"]
  E --> F["4. Chuyển tiếp: tenant nguồn MERGED, APISIX định tuyến sang tenant đích, header Deprecation"]
  F --> G["5. Kết thúc sau thời gian chuyển tiếp (mặc định 6 tháng): tenant nguồn DECOMMISSIONED"]
```

Người đọc cần thấy rằng tenant nguồn vẫn phục vụ trong suốt bước 1 đến bước 3 (trạng thái `MERGING`), và sau khi sang `MERGED` thì HTTT cũ vẫn gọi được nhờ APISIX chuyển tiếp. Điểm duy nhất cần người can thiệp là xung đột mã danh mục địa phương ở bước 2. HTTT có thời gian chuyển tiếp để đổi sang thông tin xác thực và địa chỉ mới mà không gián đoạn dịch vụ.

Danh mục đơn vị hành chính (`COMMON`) lưu lịch sử hiệu lực: mỗi đơn vị có khoảng thời gian hiệu lực và liên kết tới đơn vị kế thừa, nhờ đó dữ liệu cũ vẫn tra được theo tên đơn vị tại thời điểm phát sinh.

## 6. Quy tắc cho người phát triển

Các quy tắc sau được kiểm tra tự động trong CI hoặc bằng kiểm thử bắt buộc. Coding convention (D04-01) nhắc lại chúng.

1. Không đọc tenant từ tham số đường dẫn, query hay thân yêu cầu.
2. Không dùng `@Query` native vượt qua RLS; không tạo kết nối CSDL ngoài `DataSource` được quản lý.
3. Mọi bảng mới phải có `tenant_id NOT NULL` và chính sách RLS trong cùng changeset.
4. Mọi khóa bộ nhớ đệm, tên topic, khóa đối tượng phải dùng hàm tạo tên có tenant của thư viện dùng chung, không ghép chuỗi tay.
5. Mọi tác vụ nền phải được bọc trong `TenantContext.runAs(tenant, …)`.
6. Mỗi API mới phải có ít nhất một ca kiểm thử rò rỉ chéo tenant: tạo dữ liệu ở tenant A, truy cập bằng token tenant B, kỳ vọng `404` (không phải `403`, để không lộ sự tồn tại).

## 7. Truy vết

Bảng dưới nối các yêu cầu, chỉ tiêu và quyết định kiến trúc với mục của tài liệu này đáp ứng chúng, làm căn cứ cho kiểm thử viên lập ca kiểm thử.

| Yêu cầu | Đáp ứng tại |
|---|---|
| REQ-20, BO-06, KPI-12 | Mục 5.2 |
| FR-00-010, FR-00-011, FR-00-012 | Mục 3, 4, 6 |
| NFR-00-057, NFR-00-060 | Mục 5.2, 5.3 |
| ADR-003 | Mục 2, 4 |

: Truy vết yêu cầu, chỉ tiêu và ADR tới mục của D03-10

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: khái niệm, xác định tenant, cách ly theo tầng, vòng đời, khởi tạo, hạn mức, sáp nhập, quy tắc cho người phát triển, truy vết |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp, giữ nguyên nội dung kỹ thuật 0.1: thêm Tóm tắt cho hội đồng thẩm định; bổ sung chương 1 các mục 1.1–1.6 (mục đích, phạm vi, người đọc, thuật ngữ, tài liệu tham chiếu, cấu trúc); thêm thuyết minh cho sơ đồ xác định tenant (đã kiểm không còn dấu ";" trong thông điệp) và sơ đồ vòng đời tenant; thêm sơ đồ trình tự saga khởi tạo tenant (mục 5.2) và sơ đồ các bước sáp nhập (mục 5.4); thêm đoạn mở cho chương 5, 7 và mục 5.1; viết lại chú thích bảng, hình cho cụ thể, bỏ chú thích trùng |
