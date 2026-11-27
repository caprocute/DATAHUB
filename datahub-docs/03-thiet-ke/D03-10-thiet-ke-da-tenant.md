---
ma_tai_lieu: D03-10
ten: Thiết kế đa tenant
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiến trúc sư, Đội phát triển, Vận hành, Hội đồng thẩm định
mo_ta: Đặc tả tenant, ba chế độ cách ly, cách xác định tenant trong mỗi yêu cầu, cơ chế cách ly ở từng tầng, vòng đời, khởi tạo, hạn mức và sáp nhập tenant, làm ràng buộc chung cho mọi phân hệ của Datahub.
tai_lieu_lien_quan: ADR-003 RLS đa tenant; D00-01 Thuật ngữ và quy ước; D02-02 SRS; D03-01 SAD; D03-07 Thiết kế ATTT; D03-09 Hạ tầng và DR; D04-01 Quy ước viết mã
---

# D03-10 · Thiết kế đa tenant

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Datahub phục vụ nhiều tỉnh trên cùng một nền tảng và một bộ mã. Tài liệu đặc tả cách bảo đảm dữ liệu, cấu hình và người dùng của mỗi tỉnh (một tenant) tách biệt hoàn toàn với tỉnh khác ở mọi tầng, và cách một tenant được khởi tạo, cấu hình hạn mức, tạm ngừng, sáp nhập và chấm dứt. Đây là ràng buộc chung mà mọi phân hệ phải tuân thủ.

**Phạm vi.** Tài liệu gồm khái niệm tenant và ba chế độ cách ly, cách xác định tenant trong mỗi yêu cầu, cơ chế cách ly ở mười hai tầng (CSDL, bộ nhớ đệm, Kafka, kho lược đồ, kho đối tượng, Keycloak, OPA, APISIX, runtime luồng, kho bí mật, quan sát, nhật ký kiểm toán), vòng đời tenant với sáu trạng thái, saga khởi tạo mười bảy bước, hạn mức mặc định, quy trình sáp nhập và bảy quy tắc bắt buộc cho người phát triển.

**Căn cứ pháp lý.** CMP-LAW-06 và CMP-LAW-08 (Nghị định 331/2026/NĐ-CP, TCVN 14423:2026: kiểm soát truy cập, phân tách dữ liệu, nhật ký ở cấp độ 3); CMP-LAW-05 (Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15: dữ liệu cá nhân của tỉnh này không được lộ sang tỉnh khác); CMP-LAW-03 (Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu); CMP-LAW-16 (Luật An ninh mạng 116/2025/QH15: lưu trữ dữ liệu trong nước, bảo vệ hệ thống thông tin).

**Những điểm hội đồng cần lưu ý.** (1) Tenant của một yêu cầu chỉ được lấy từ token đã xác thực, không bao giờ từ tham số do người gọi gửi; người dùng tỉnh này không thể tự khai là tỉnh khác. (2) Cách ly được thực thi ở tầng hạ tầng (RLS của PostgreSQL, ACL Kafka, realm Keycloak, chính sách OpenBao), và mỗi DU tự kiểm tra cấu hình khi khởi động, từ chối chạy nếu cấu hình làm vô hiệu cách ly. (3) Một bộ mã chạy được cho cả nền tảng dùng chung lẫn tỉnh tự vận hành, nhờ ba chế độ cách ly từ dùng chung tới cụm riêng. (4) Việc sắp xếp đơn vị hành chính cấp tỉnh được hỗ trợ bằng quy trình sáp nhập tenant có thời gian chuyển tiếp mặc định 6 tháng, HTTT không phải đổi ngay. (5) Truy cập dữ liệu tỉnh từ tenant quản trị nền tảng phải nêu lý do và được kiểm toán.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Chế độ cách ly | 3 (`SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER`) |
| Tầng có cơ chế cách ly riêng | 12 |
| Trạng thái vòng đời tenant | 6, cộng `FAILED` của saga khởi tạo |
| Bước saga khởi tạo tenant | 17, mục tiêu ≤ 1 giờ ở chế độ `SHARED` (NFR-00-057) |
| Hạn mức mặc định | 500 lượt gọi mỗi giây, 1.000 luồng, 10/20 MB/s Kafka, 500 GB kho đối tượng, 200 GB CSDL, 2.000 người dùng |
| Ngưỡng tách namespace runtime riêng | Trên 50 luồng |
| Thời gian chuyển tiếp khi sáp nhập | 6 tháng (mặc định) |
| Quy tắc bắt buộc cho người phát triển | 7 |

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
| 6 | Bảy quy tắc bắt buộc cho người phát triển | Kỹ sư, kiểm thử viên |
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
6. Người dùng thuộc nhiều tenant không mang một token chung: mỗi lần đổi tenant, BFF xin token mới ở realm của tenant đích (FR-12-027, FR-00-004). Nhân sự nền tảng đi qua nhà môi giới định danh nền tảng của realm đích và chỉ vào được khi có quyền có thời hạn còn hiệu lực; nhà thầu phục vụ nhiều tỉnh có tài khoản riêng ở từng realm và đăng nhập lại, kèm yếu tố thứ hai nếu thuộc nhóm bắt buộc. Token cấp ra luôn mang đúng một claim `tenant`, nên một yêu cầu không bao giờ thuộc hai tenant.

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

**Biến phiên rỗng coi là thiếu tenant.** Trên PostgreSQL 18, một kết nối của pool đã từng chạy `SET LOCAL app.tenant_id` thì ở giao dịch sau `current_setting('app.tenant_id')` trả về chuỗi rỗng và không báo lỗi `unrecognized configuration parameter`. Vì vậy mọi chỗ đọc tenant (hàm lấy tenant của thư viện dùng chung, bộ kiểm tra khi lấy kết nối từ pool, kiểm thử RLS) phải coi chuỗi rỗng, hoặc chuỗi chỉ gồm khoảng trắng, là thiếu tenant và từ chối thực thi; không được dựa vào việc truy vấn báo lỗi để phát hiện lỗi quên đặt biến. Chuỗi rỗng không bao giờ là mã tenant hợp lệ, và chỉ các dòng dùng chung (`COMMON`) của bảng mẫu S mới còn đọc được khi biến rỗng, nên kiểm thử RLS của mỗi phân hệ có thêm ca đặt biến thành chuỗi rỗng và kỳ vọng DU từ chối hoặc truy vấn không trả dòng nào của tenant.

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
| Nhật ký kiểm toán | Cột `tenant_id`, RLS như CSDL; kho WORM tách tiền tố theo tenant. Chuỗi băm riêng theo từng tenant, kể cả tenant `PLATFORM` có chuỗi riêng của nền tảng; PH-13 dùng mẫu P cho mọi bảng chuỗi và bản ghi, riêng khóa công khai ký neo dùng mẫu S (mục 4, biến thể mẫu RLS) | |

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

**Danh mục schema được DU tự kiểm khi khởi động.** Phép kiểm "mọi bảng có chính sách RLS, vai trò kết nối không `BYPASSRLS`" áp cho mọi schema `ph{nn}_*` mà DU sở hữu trên cụm (danh mục ở SAD §8.4), gồm cả `ph02_catalog`, `ph08_dq`, `ph16_kpi`, `ph20_tenant`. Bảng phân vùng chỉ được cấp quyền và gắn chính sách ở bảng cha; phân vùng con không cấp quyền riêng. Bảng không có `tenant_id` (ví dụ bảng khóa tác vụ `shedlock`) phải nằm trong danh sách ngoại lệ có chủ đích của phân hệ và không chứa dữ liệu tenant.

**Các biến thể của mẫu RLS.** Mẫu cơ bản ở trên là mẫu P. Các phân hệ cần thêm một số biến thể; mọi biến thể đều dùng `FORCE ROW LEVEL SECURITY`, `current_setting('app.tenant_id', false)` và không cho vai kết nối `BYPASSRLS`. Quy ước dữ liệu của chính nền tảng: dòng thuộc nền tảng (nhân sự nền tảng, chính sách gốc, realm, chuỗi kiểm toán của nền tảng) mang `tenant_id = 'PLATFORM'`, và phiên `PLATFORM` thao tác chúng mà không phải đổi `app.tenant_id` sang từng tỉnh.

| Mẫu | Đọc | Ghi | Dùng ở |
|---|---|---|---|
| P | Dòng có `tenant_id` bằng tenant của phiên | Như đọc | Mặc định cho mọi bảng nghiệp vụ; PH-13 dùng cho cả tenant `PLATFORM` |
| S (dùng chung) | Dòng của tenant phiên và dòng dùng chung (`COMMON`, hoặc `PLATFORM` khi dữ liệu thuộc chính nền tảng, ví dụ `audit_signing_key` của PH-13) | Dòng dùng chung chỉ phiên `PLATFORM` ghi | Bảng mẫu và bảng định nghĩa: `lint_rule` của PH-02 (bảng mẫu S duy nhất của PH-02), `dq_rule_template` của PH-08, bảy bảng định nghĩa của PH-16, `national_platform`, `national_service`, `service_spec` của PH-14 |
| G | Dòng của tenant phiên và dòng có `target_tenant` bằng tenant phiên | Chỉ ở tenant của người nhận quyền, do phiên `PLATFORM` ghi | `privileged_grant` của PH-12: quản trị tỉnh bị truy cập đọc được quyền có thời hạn đang mở vào tỉnh mình mà không sửa được |
| PLAT, PLATR | PLAT: chỉ phiên `PLATFORM` thấy; PLATR: thêm quyền đọc cho mọi tenant | Chỉ phiên `PLATFORM` | Dữ liệu nền tảng của PH-20 (`platform_module`, `product_release` thuộc PLATR) |
| OWN, CTL, TECH | OWN: tenant tự quản đọc ghi dòng của mình; CTL: tenant chỉ đọc dòng của mình; TECH: bảng kỹ thuật ghi cùng giao dịch | OWN, TECH: phiên tenant; CTL: chỉ phiên `PLATFORM` của vai `ph20_platform_app` | PH-20: ba bể kết nối `ph20_app`, `ph20_platform_app`, `ph20_ro` (D03-03-PH20 mục 2.1) |
| P kèm `origin_tenant_id` | Như P; bản sao danh mục liên tỉnh thuộc tenant của cổng đang phục vụ, `origin_tenant_id` là tenant sở hữu API | Tác vụ đồng bộ, theo tenant của cổng | PH-15: không chính sách nào cho đọc chéo tenant |

: Các mẫu RLS dùng chung và biến thể, kèm nơi áp dụng

Với bảng mẫu S, phiên `PLATFORM` ghi dòng `COMMON` (hoặc `PLATFORM`) là quy ước chung; phiên của tenant tỉnh chỉ đọc. Bảng mẫu P của PH-14 cho phép dòng `COMMON` (chứng thư, hạn mức, sổ giao dịch của cổng `COMMON`) nhưng chỉ phiên `PLATFORM` thấy.

**Ngoại lệ đọc liên tenant bằng khung nhìn.** Cách ly ở mục này không cho một vai kết nối của tỉnh đọc dòng của tỉnh khác. Hai phân hệ có nhu cầu so sánh liên tenant ở dạng thống kê và đã thiết kế ngoại lệ ở tập CSDL riêng: vai `ph08_benchmark` của PH-08 chỉ đọc điểm chiều của ảnh chụp chính thức qua khung nhìn `v_benchmark_dimension` (FR-08-061), và vai `ph16_compare` của PH-16 chỉ đọc khung nhìn `v_compare_value` gồm sáu cột giá trị chỉ tiêu hiện hành, ẩn danh tenant và áp nhóm tối thiểu `16.compare.min-tenants` trước khi trả (FR-16-041). Quy tắc chung cho mọi ngoại lệ loại này: chỉ qua khung nhìn chỉ-đọc với số cột tối thiểu, vai riêng không dùng cho yêu cầu của người dùng, không có dữ liệu cá nhân hay dữ liệu Nhạy cảm, dữ liệu trả về đã ẩn danh và tổng hợp (khớp SEC-85 ở D03-07 mục 9, thống kê toàn nền tảng chỉ dùng dữ liệu tổng hợp), và mỗi ngoại lệ mới phải được kiến trúc sư ATTT duyệt và ghi vào đây trước khi cấp vai.

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
  FAILED --> DECOMMISSIONED: Bù trừ xong, hủy khởi tạo
  ACTIVE --> SUSPENDED: Tạm ngừng (có lý do)
  SUSPENDED --> ACTIVE: Khôi phục
  ACTIVE --> MERGING: Bắt đầu sáp nhập vào tenant khác
  MERGING --> ACTIVE: Hủy kế hoạch trước cutover
  MERGING --> MERGED: Hoàn tất
  SUSPENDED --> DECOMMISSIONED: Chấm dứt
  MERGED --> DECOMMISSIONED: Hết thời hạn lưu giữ
  DECOMMISSIONED --> [*]
```

Người đọc cần thấy rằng có ba đường tới `DECOMMISSIONED`: từ `SUSPENDED` khi chấm dứt có quyết định, từ `MERGED` khi hết thời hạn lưu giữ sau sáp nhập, và từ `FAILED` khi khởi tạo lỗi mà người có thẩm quyền chọn hủy và saga đã bù trừ xong (FR-20-011); tenant đang `ACTIVE` không thể bị chấm dứt trực tiếp mà phải qua tạm ngừng trước. Khởi tạo lỗi không tự làm mất tenant: `FAILED` cho phép thử lại từ bước lỗi của saga (mục 5.2). Kế hoạch sáp nhập bị hủy trước thời điểm chuyển đổi (cutover) đưa tenant nguồn từ `MERGING` về `ACTIVE`; sau khi đã sang `MERGED` thì không còn đường quay về. `FAILED` là trạng thái của saga khởi tạo, thêm vào sáu trạng thái bền của bảng dưới (D02-03-PH20 mục 4.3); ở `FAILED` data plane trả `ERR-20-101` như ở `PROVISIONING`.

| Trạng thái | Ý nghĩa | Data plane | Giao diện |
|---|---|---|---|
| `PROVISIONING` | Đang khởi tạo tài nguyên | Không phục vụ | Chỉ quản trị nền tảng thấy |
| `ACTIVE` | Hoạt động | Phục vụ | Đầy đủ |
| `SUSPENDED` | Tạm ngừng do quyết định quản lý hoặc sự cố an ninh | Từ chối với `ERR-20-001`, trừ API được đánh dấu thiết yếu nếu quyết định tạm ngừng cho phép | Chỉ-đọc cho quản trị tỉnh |
| `MERGING` | Đang chuyển dữ liệu sang tenant đích; còn hủy được trước cutover | Phục vụ, có cầu nối chuyển tiếp | Cảnh báo trên thanh trên |
| `MERGED` | Đã sáp nhập; mọi yêu cầu được định tuyến sang tenant đích trong thời gian chuyển tiếp | Chuyển tiếp | Chỉ-đọc, phục vụ tra cứu lịch sử |
| `DECOMMISSIONED` | Đã chấm dứt; dữ liệu đã được xuất bàn giao và xóa theo chính sách | Không | Không |

: Sáu trạng thái tenant và hành vi của data plane, giao diện

### 5.2. Khởi tạo tenant

Khởi tạo tenant là một saga do PH-20 điều phối. Mỗi bước idempotent và có thao tác bù trừ; nếu một bước lỗi, saga dừng ở `FAILED` và cho phép thử lại từ bước lỗi. Bảng dưới là nguồn chuẩn mã bước `S01`…`S17` đã đặc tả ở D02-03-PH20 mục 4.4; các tập FRS, SDD, CSDL, API và ca kiểm thử dùng chung mã này. Thứ tự bù trừ ngược thứ tự thực hiện.

| Bước | Hành động và bên thực hiện | Bù trừ |
|---|---|---|
| `S01_RECORD` | PH-20 ghi bản ghi tenant `PROVISIONING`, cấu hình mặc định, hạn mức từ mẫu; đồng thời ghi bảng định tuyến tenant tới ô CSDL (cho mọi chế độ, xem bước `S07`) | Xóa bản ghi, chỉ khi chưa có bước nào khác xong |
| `S02_CONFIG_REPO` | PH-20 tạo thư mục `tenants/{ma}/` trong kho `dh-tenant-config` và commit cấu hình | Revert commit |
| `S03_REALM` | PH-12 (API-12-080) tạo realm `dh-{mã viết thường}` từ mẫu, client `dh-console`, `dh-portal`, vai trò chuẩn, vai trò tùy biến `realm-user-admin` cho quản trị tỉnh (không có `manage-realm`), nhà môi giới định danh nền tảng ở trạng thái ẩn, tài khoản quản trị tỉnh đầu tiên với yêu cầu đổi mật khẩu và đăng ký MFA | Xóa realm còn `PROVISIONING` |
| `S04_SECRETS` | PH-20 qua OpenBao tạo đường dẫn `kv/dh/{ma}/...`, chính sách theo tenant, KEK `dh-{ma}-pii` (SEC-88) | Xóa đường dẫn, xóa KEK chưa dùng |
| `S05_BUCKETS` | PH-20 qua Ceph RGW tạo bucket `dh-{ma}-{mục đích}` (`files`, `exports`, `backup`, `audit`) | Xóa bucket rỗng |
| `S06_EVENTING` | PH-10 đặt hạn mức Kafka, principal nội bộ, ACL tiền tố `{ma}.`, topic hệ thống, nhóm Apicurio (bất đồng bộ, báo tiến độ) | PH-10 gỡ khi nhận `EVT-20-04` `DECOMMISSIONED` |
| `S07_DATABASE` | Chỉ `DEDICATED_DB`: PH-20 tạo cụm CloudNativePG từ mẫu, chạy migration. Bảng định tuyến tenant dùng cho cả ô CSDL dùng chung (`SHARED`) lẫn cụm riêng, nên bước này cập nhật chuỗi kết nối tham chiếu khi tenant có cụm riêng | Xóa cụm |
| `S08_OBSERVABILITY` | PH-13 (API-13-072) khởi tạo chuỗi kiểm toán theo tenant (FR-13-059), tổ chức Grafana, nguồn dữ liệu lọc theo tenant, luật cảnh báo | Đóng chuỗi bằng API-13-073 (FR-13-060) |
| `S09_GATEWAY` | PH-03 (bất đồng bộ) tạo host, tiền tố, hạn mức hợp đồng ở APISIX; dữ liệu mặc định PH-03 tạo theo D03-03-PH03 mục 5, quy ước đặt tên host theo tenant còn mở (Q03-53 của D03-03-PH03) | PH-03 gỡ |
| `S10_INTEGRATION` | PH-04 (bất đồng bộ) tạo không gian `DEFAULT`, kho `dh-flows-{ma}`, kho `dh-config-{ma}` (ADR-068), ApplicationSet runtime, và với tenant dùng chúng thì tài nguyên `dh-probe` và `dh-cdc` theo tenant | PH-04 gỡ |
| `S11_SEED_RDM` | PH-07 (API-07-073) nạp gói danh mục nền | PH-07 xóa danh mục nền |
| `S12_SEED_MDM` | PH-06 nạp gói dữ liệu chủ nền, nếu bật theo mẫu (bất đồng bộ) | Không |
| `S13_ORG_SEED` | PH-20 nạp tổ chức cấp tỉnh và đơn vị hành chính thuộc tỉnh từ danh mục `COMMON` | Xóa |
| `S14_KPI` | PH-16 kế thừa bộ chỉ tiêu mẫu, nếu bật (FR-16-008) | Không |
| `S15_MODULES` | Các phân hệ bật theo mẫu (PH-19, PH-17…) nhận `EVT-20-07` (`platform.tenant.module-enabled.v1`) và báo xong (bất đồng bộ) | Phát `EVT-20-08` |
| `S16_SMOKE` | PH-20 chạy kiểm tra khói: đăng nhập quản trị, gọi API mẫu, phát và nhận một sự kiện mẫu, một ca rò rỉ chéo tenant | Không |
| `S17_ACTIVATE` | PH-20 chuyển `ACTIVE`, thông báo đầu mối (PH-18), đẩy KPI-12 sang PH-16 (API-16-030) | Không |

: Mười bảy bước saga khởi tạo tenant, bên thực hiện và thao tác bù trừ

Bước bất đồng bộ chờ phân hệ báo tiến độ qua API-20-166; hết thời hạn `20.provision.step-timeout-minutes` thì bước chuyển `FAILED` với `ERR-20-106`. Bước không áp dụng (phân hệ chưa bật, `S07` ở chế độ `SHARED`) có trạng thái `SKIPPED`. Các bước `S06`, `S09`, `S10`, `S12` khởi động cùng lúc sau `S05` và cùng phải xong trước `S11`; các bước còn lại chạy tuần tự.

Mục tiêu thời gian của saga ở chế độ `SHARED` là ≤ 1 giờ (NFR-00-057).

Sơ đồ trình tự dưới đây vẽ lại mười bảy bước của bảng trên theo thứ tự gọi giữa PH-20 và các phân hệ, hệ hạ tầng, để người vận hành thấy saga chạm những hệ nào và dừng ở đâu khi lỗi.

```{.mermaid caption="Trình tự saga khởi tạo tenant do PH-20 điều phối"}
sequenceDiagram
  actor PA as Quản trị nền tảng
  participant P20 as PH-20 (dh-platform)
  participant P12 as PH-12 (Keycloak)
  participant BAO as OpenBao
  participant S3 as Kho đối tượng
  participant PG as CloudNativePG
  participant P13 as PH-13 (kiểm toán, Grafana)
  participant PHX as PH-10, 03, 04, 06 (bất đồng bộ)
  participant P07 as PH-07, PH-16
  PA->>P20: Khai báo tenant T68, chế độ cách ly
  P20->>P20: S01 bản ghi tenant PROVISIONING, hạn mức, bảng định tuyến
  P20->>P20: S02 thư mục cấu hình trong kho dh-tenant-config
  P20->>P12: S03 realm dh-t68, client, vai trò, quản trị tỉnh đầu tiên
  P20->>BAO: S04 đường dẫn kv/dh/t68, chính sách, KEK
  P20->>S3: S05 bucket dh-t68-*
  P20-)PHX: S06, S09, S10, S12 khởi động cùng lúc qua EVT-20-01
  opt Chế độ DEDICATED_DB
    P20->>PG: S07 tạo cụm từ mẫu, chạy migration
  end
  P20->>P13: S08 chuỗi kiểm toán, tổ chức Grafana, luật cảnh báo
  PHX--)P20: Báo tiến độ qua API-20-166
  P20->>P07: S11 danh mục nền, S14 chỉ tiêu mẫu
  P20->>P20: S13 tổ chức cấp tỉnh từ COMMON
  P20-)PHX: S15 EVT-20-07 cho từng phân hệ bật theo mẫu
  P20->>P20: S16 kiểm tra khói, một ca rò rỉ chéo
  P20-->>PA: S17 tenant ACTIVE, thông báo đầu mối
```

Hình cho thấy PH-20 gọi tuần tự các bước đồng bộ và phát lệnh cho các bước bất đồng bộ rồi chờ báo tiến độ, nên khi một bước lỗi, saga dừng ở `FAILED` và biết chính xác hệ nào cần bù trừ hoặc thử lại. Bước `S07` chỉ chạy với chế độ `DEDICATED_DB`. Kiểm tra khói ở bước `S16` là điều kiện để chuyển `ACTIVE`; tenant chưa qua kiểm tra khói không bao giờ phục vụ data plane.

### 5.3. Hạn mức theo tenant

Hạn mức bảo vệ các tenant khỏi ảnh hưởng lẫn nhau trên nền tảng dùng chung (vấn đề "hàng xóm ồn ào"). Giá trị mặc định dưới đây được điều chỉnh theo hợp đồng của từng tỉnh. Hạn mức của phân hệ có khóa tham số riêng (ví dụ `02.*` của PH-02) chỉ được tăng tới trần nền tảng trong bảng, không vượt trần bằng cấu hình của tỉnh.

| Hạn mức | Mặc định | Thực thi tại |
|---|---|---|
| Lượt gọi API tối đa mỗi giây cho toàn tenant | 500 | APISIX (`limit-count` theo nhãn tenant) |
| Số luồng đang hoạt động | 1.000 | PH-04 khi phát hành |
| Thông lượng Kafka sản xuất / tiêu thụ | 10 MB/s / 20 MB/s | Quota Kafka |
| Dung lượng kho đối tượng | 500 GB | Kiểm tra khi tải lên; cảnh báo ở 80% |
| Dung lượng CSDL | 200 GB | Giám sát, cảnh báo ở 80% |
| Số người dùng | 2.000 | PH-12 |
| Quy mô danh mục dịch vụ (PH-02): số API, số phiên bản mỗi API, số đăng ký sử dụng | 2.000 API, 50 phiên bản mỗi API, 20.000 đăng ký (NFR-02-010) | PH-02 khi đăng ký, tạo phiên bản, đăng ký sử dụng |

: Hạn mức mặc định theo tenant và nơi thực thi

**Nhóm ưu tiên không miễn hạn mức toàn tenant.** Consumer thuộc nhóm `ESSENTIAL` ở PH-03 chỉ được hệ số nới và mức vượt hạn ngạch riêng của mình; hạn mức toàn tenant 500 lượt gọi mỗi giây vẫn áp cho cả nhóm này, vì mục đích của hạn mức là bảo vệ tenant khác khỏi hàng xóm ồn ào.

**Chia hạn mức Kafka theo principal.** Kafka chỉ có hạn mức theo principal, nên thông lượng sản xuất và tiêu thụ của tenant (10 MB/s và 20 MB/s mặc định) được PH-10 chia thành hạn mức từng `KafkaUser` theo `quotaBytesPerSecond` khai báo (tối thiểu 256 KiB/s), tổng không vượt trần của tenant (BR-10-029); principal nội bộ giữ phần dự trữ `10.quota.internal-reserve-ratio`.

### 5.4. Sáp nhập tenant

Sáp nhập đáp ứng thực tế sắp xếp đơn vị hành chính cấp tỉnh. Khi tỉnh A và tỉnh B hợp thành tỉnh C (hoặc A sáp nhập vào B), quy trình như sau:

1. **Chuẩn bị.** Tạo tenant đích (hoặc dùng tenant hiện có). Lập bảng ánh xạ: tổ chức, HTTT thành viên, mã danh mục địa phương trùng nhau.
2. **Chuyển dữ liệu.** PH-18 chạy công cụ chuyển dữ liệu theo từng phân hệ: sao chép bản ghi sang tenant đích với `tenant_id` mới, giữ `id` gốc (UUID v7 không trùng), ghi trường `origin_tenant_id` để truy vết. Danh mục địa phương trùng mã được đánh dấu xung đột để cán bộ nghiệp vụ xử lý.

Hồ sơ HTTT chuyển sang tenant đích giữ `id` gốc và ghi `member_system.origin_tenant_id` của tenant nguồn; định danh ứng dụng được cấp mới nên `app_credential` không sao chép. Vì mã HTTT duy nhất theo tenant và bất biến, mã trùng giữa hai tenant được đánh dấu xung đột như danh mục địa phương, cách xử lý cụ thể (ví dụ hậu tố theo mã tenant nguồn) do PH-18 chốt (D03-03-PH01 mục 4, Q01-54). PH-18 gọi công cụ chuyển dữ liệu bằng API `POST /api/ops/v1/merge-transfers` (API-18-150…153); PH-20 điều phối bằng tài khoản máy với scope `ops:merge-transfer`, và kế hoạch sáp nhập chỉ được hủy trước cutover (tenant nguồn về `ACTIVE`).
3. **Chuyển định danh.** PH-12 (FR-12-019) tạo lại người dùng ở realm đích, giữ liên kết LDAP nếu có và đặt realm nguồn ở chế độ chỉ-đọc khi tenant nguồn sang `MERGED`; thông tin xác thực ứng dụng của HTTT được cấp mới, cấp song song có thời hạn để HTTT chuyển dần.
4. **Chuyển tiếp.** Tenant nguồn sang `MERGED`; APISIX định tuyến lời gọi tới API của tenant nguồn sang API tương ứng của tenant đích trong thời gian chuyển tiếp (mặc định 6 tháng), kèm header cảnh báo `Deprecation`. Cơ chế chuyển tiếp do PH-03 hiện thực (FR-03-037): gateway sinh ảnh chụp mới cho cả hai tenant, host của tenant nguồn có route chuyển tiếp trỏ route đích, xác thực bằng token của tenant đích (HTTT đã được cấp song song), đặt `X-DH-Tenant` là tenant đích và thêm `Deprecation`, `Sunset`, `Link`; tới `endAt` host nguồn trả `ERR-03-126` (410).
5. **Kết thúc.** Hết thời gian chuyển tiếp, tenant nguồn chuyển `DECOMMISSIONED`; dữ liệu và nhật ký kiểm toán của tenant nguồn được lưu trữ theo thời hạn quy định. PH-13 đóng chuỗi kiểm toán của tenant nguồn khi sáp nhập (FR-13-060): chuỗi được niêm lại bằng một neo cuối và vẫn tra cứu được, không nối vào chuỗi của tenant đích.

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
7. Chỉ dùng `SET LOCAL` cho biến phiên, không dùng `SET` cấp phiên (PgBouncer chế độ giao dịch), và coi biến rỗng là thiếu tenant (mục 3).

**Biến phiên `app.restore_mode`.** Ngoài `app.tenant_id`, quy ước biến phiên có cờ `app.restore_mode`, chỉ công cụ `dh-tenant-restore` của PH-18 được đặt bằng `SET LOCAL app.restore_mode = on` trong giao dịch thay thế dữ liệu của một tenant (D03-09 mục 8.5). Trigger nghiệp vụ chặn xóa hoặc chặn sửa lịch sử (`tg_no_delete`, `tg_immutable`) của mọi phân hệ phải cho phép thao tác khi cờ bật và `current_user` là `dh_tenant_restorer`; ở mọi trường hợp khác cờ không có tác dụng. Vai `dh_tenant_restorer` không có `BYPASSRLS` và `SET LOCAL app.tenant_id` được đặt trước, nên RLS vẫn chặn mọi dòng của tenant khác. Công cụ loại khỏi phạm vi thay thế các bảng outbox, inbox và nhật ký kiểm toán, và theo thiết kế của PH-18 cả năm bảng nhật ký của `ph18_ops` (D03-03-PH18, Q18-54).

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
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: saga khởi tạo thành mười bảy bước theo PH-20 (mục 5.2), thêm chuyển trạng thái `MERGING → ACTIVE` và `FAILED → DECOMMISSIONED` (5.1), các biến thể mẫu RLS và ngoại lệ đọc liên tenant bằng khung nhìn (4), quy tắc biến phiên rỗng là thiếu tenant, cờ `app.restore_mode`, hạn mức ESSENTIAL, Kafka theo principal, quy mô PH-02 (5.3), chuyển tiếp và xử lý trùng khi sáp nhập (5.4) |
