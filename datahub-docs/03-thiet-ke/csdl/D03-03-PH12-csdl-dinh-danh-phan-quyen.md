---
ma_tai_lieu: D03-03-PH12
ten: Thiết kế cơ sở dữ liệu phân hệ PH-12 Định danh và phân quyền
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiến trúc sư dữ liệu, DBA, kỹ sư dh-platform, cán bộ ATTT, kiểm thử viên, hội đồng thẩm định
phan_he: PH-12
mo_ta: Thiết kế 43 bảng của schema ph12_iam trên cụm pg-core gồm khóa, ràng buộc, RLS theo tenant, các quy tắc tách nhiệm vụ, bốn mắt và máy trạng thái chính sách chốt ở CSDL, không lưu bí mật, sao lưu, lưu giữ và ánh xạ dữ liệu hệ cũ, trích từ DDL đã chạy thử.
tai_lieu_lien_quan: D02-03-PH12 FRS; D02-04-PH12 Use case; D03-02-PH12 SDD; D03-04-PH12 API; D03-10 Thiết kế đa tenant; D02-08 Ma trận phân quyền; D03-07 Thiết kế ATTT; D03-09 Hạ tầng triển khai, DR; D05-02-PH12 Test case
---

# D03-03-PH12 · Thiết kế cơ sở dữ liệu phân hệ PH-12 Định danh và phân quyền

## Tóm tắt cho hội đồng thẩm định

PH-12 trả lời "người gọi là ai" và "người gọi được làm gì" cho toàn Datahub. Keycloak giữ phần danh tính (người dùng, mật khẩu, yếu tố xác thực, phiên, khóa ký) ở cụm `pg-iam` riêng; tài liệu này thiết kế **phần còn lại**, tức schema `ph12_iam` trên cụm `pg-core`: bản chiếu người dùng, gán vai trò có phạm vi và thời hạn, ngoại lệ tách nhiệm vụ, quyền có thời hạn, rà soát quyền, client của hệ thống thông tin (HTTT), danh sách chặn, realm theo tenant, chính sách Rego và gói chính sách ký, cảnh báo và báo cáo. Schema có **43 bảng** cho 17 trong 20 thực thể logic EN-12 của [D02-03-PH12](../../02-yeu-cau/frs/D02-03-PH12-frs-dinh-danh-phan-quyen.md) §4.2; ba thực thể còn lại (yếu tố xác thực, phiên, nhật ký quyết định) nằm ở Keycloak và Loki theo thiết kế.

Bốn điểm thiết kế chính:

1. **Không có bí mật trong CSDL.** Không bảng nào chứa mật khẩu, mã TOTP, bí mật client, khóa riêng hay token. Bảng chỉ giữ tham chiếu OpenBao (`secret_ref`), dấu vân tay chứng thư, `wrap_accessor` và băm HMAC. Mọi cột JSON nhận dữ liệu từ ngoài bị `CHECK` chặn khóa tên bí mật (kể cả lồng), nên một lỗi lập trình ở dịch vụ cũng không ghi được `wrappingToken` hay `clientSecret` xuống đĩa (BR-12-023, BR-12-045, NFR-12-020).
2. **Quy tắc phân quyền chốt ở CSDL, không chỉ ở dịch vụ.** Cặp vai trò xung đột bị trigger chặn trừ khi có ngoại lệ còn hiệu lực (BR-12-030); mỗi tenant luôn còn một quản trị tỉnh (BR-12-033); người duyệt không được là người soạn, người gửi hay người đóng góp (BR-12-008); phiên bản chính sách chỉ gửi duyệt khi đã kiểm thử đạt và chạy khô trên đúng băm nội dung (BR-12-009, ADR-069); mức hợp đồng của HTTT quyết định phương thức xác thực của client (BR-12-024); mỗi nguồn chỉ đặt đúng loại scope của mình (BR-12-025); quyền có thời hạn không quá 4 giờ (BR-12-032).
3. **Cách ly tỉnh bằng CSDL.** 41 bảng có `tenant_id` đều bật `FORCE ROW LEVEL SECURITY` với 164 chính sách theo ba mẫu (riêng tenant, dùng chung `COMMON`, quyền có thời hạn vào tenant khác); mọi khóa ngoại giữa các bảng của tenant mang kèm `tenant_id` (chỉ khóa tới bảng dùng chung `sod_pair` không có). Đã chạy thử ngày 26/11/2026 trên PostgreSQL 16.16: [bài kiểm](ph12/test/ph12_isolation_test.sql) đạt 100 khối thuộc 24 nhóm, gồm đọc chéo, ghi chéo, khóa ngoại chéo tỉnh, ba mẫu RLS và từng quy tắc ở điểm 2 (mục 4.2).
4. **Nhỏ, nên đơn giản và vẫn chịu được sự cố.** Với tỉnh vừa (3.000 cán bộ, 200 HTTT, giả định GĐ-12-02) schema chỉ khoảng 75 MB (mục 8.1) nên không phân vùng; khối lượng lớn (nhật ký quyết định, sự kiện xác thực) đi qua Loki và chuỗi kiểm toán PH-13, không vào PostgreSQL. Cụm `pg-core` thuộc tầng phục hồi `TPH-1`; khi control plane ngừng, Keycloak (`pg-iam`, `TPH-0`) vẫn đăng nhập và OPA vẫn quyết định với gói đã nạp (NFR-12-013).

Nguồn duy nhất của DDL là [`ph12/ddl/`](ph12/ddl/ph12_iam_all.sql) (sáu tệp, chạy bằng `ph12_iam_all.sql`). Bảng cột ở chương 3 sinh từ DDL bằng [`ph12/tools/gen_tables_md.py`](ph12/tools/gen_tables_md.py), khối đặc tả 10 mục của từng bảng bằng [`ph12/tools/them_dac_ta_bang.py`](ph12/tools/them_dac_ta_bang.py), nên tài liệu không lệch DDL.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Bảng trong `ph12_iam` | 43 (41 có `tenant_id` và FORCE RLS, 2 bảng kỹ thuật) |
| Cột, khóa ngoại, ràng buộc `CHECK`, chỉ mục | 647 · 28 · 240 · 155 (kể cả khóa chính, khóa duy nhất) |
| Trigger, hàm và thủ tục | 45 · 19 |
| Chính sách RLS | 164 (41 bảng × 4 thao tác) theo mẫu P (37 bảng), S (3), G (1) |
| Quy tắc nghiệp vụ chốt ở CSDL | 25 ràng buộc và trigger tiêu biểu (mục 3.44) |
| Khối kiểm cô lập và ràng buộc đã đạt | 100 khối PASS trong 24 nhóm |
| Dữ liệu khởi tạo | 10 cặp vai trò xung đột, 17 dòng ánh xạ vai trò hệ cũ |
| Câu hỏi mở mới của tập | 5 (Q12-50…Q12-54) |

: Con số chính của tập CSDL PH-12

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả cơ sở dữ liệu của PH-12 ở mức đủ để DBA tạo lược đồ, kỹ sư `dh-platform` viết tầng truy cập dữ liệu và kiểm thử viên viết ca kiểm thử cô lập tenant, toàn vẹn, tách nhiệm vụ và bất biến. Phạm vi gồm 43 bảng của schema `ph12_iam` trên cụm `pg-core`, các hàm, thủ tục và trigger đi kèm, dữ liệu khởi tạo dùng chung (`COMMON`), phần dữ liệu ngoài PostgreSQL (Keycloak, OpenBao, Kafka, Valkey, kho đối tượng, Loki), sao lưu, lưu giữ và ánh xạ dữ liệu hệ cũ sang thiết kế mới.

Ngoài phạm vi: dữ liệu của Keycloak trong `pg-iam` (do Keycloak toàn quyền, `dh-platform` chỉ gọi Admin API, SDD §4.5); nhật ký kiểm toán chung và chuỗi băm (PH-13); danh mục đơn vị (PH-07); tham số `12.*` (kho tham số PH-18); mô hình dữ liệu của lớp dữ liệu dùng chung. Mã Rego của chính sách nằm trong bảng `policy_version` nhưng việc thực thi Rego do OPA và `policy-runner` làm; `policy-runner` không có thông tin xác thực CSDL.

### 0.2. Người đọc và cách đọc

Bảng dưới cho biết mỗi nhóm người đọc nên bắt đầu từ phần nào để đạt mục đích của mình, khỏi đọc toàn bộ tài liệu dài.

| Người đọc | Phần cần đọc | Mục đích |
|---|---|---|
| Hội đồng thẩm định, cán bộ ATTT | Tóm tắt, mục 1.2, 3.44, chương 5, chương 8 | Đánh giá cách ly giữa các tỉnh, quy tắc tách nhiệm vụ và bốn mắt có chốt ở CSDL, không lưu bí mật, lưu giữ dữ liệu cá nhân |
| Kiến trúc sư dữ liệu, DBA | Chương 1, 2, 4, 7, 8 | Dựng schema, vai trò, quyền; kế hoạch sao lưu, dọn dữ liệu; so với thiết kế SDD |
| Kỹ sư `dh-platform` (module `iam`) | Chương 1.3, 2, 3, 3.44, 3.45 | Ánh xạ aggregate sang bảng, biết trigger nào ném `SQLSTATE` nào, truy vấn đúng chỉ mục |
| Kiểm thử viên | Mục 3.44, 4.2 và bài kiểm `ph12/test` | Viết ca âm, ca dương cho ràng buộc, RLS, bất biến, rò rỉ chéo tenant |
| Đội di trú | Chương 6, 9 | Dữ liệu khởi tạo, ánh xạ vai trò và người dùng hệ cũ |

: Người đọc và phần cần đọc của tập CSDL PH-12

### 0.3. Thuật ngữ và chữ viết tắt

Các thuật ngữ dưới đây dùng xuyên suốt tập; thuật ngữ chung của dự án theo D00-01 §2 và D02-03-PH12 §1.4.

| Thuật ngữ | Giải thích |
|---|---|
| Tenant, `PLATFORM`, `COMMON` | Một tỉnh dùng Datahub (`T01`…`T99`); `PLATFORM` là tenant của chính nền tảng (nhân sự nền tảng, chính sách gốc, realm); `COMMON` đánh dấu dữ liệu dùng chung cho mọi tenant |
| RLS, FORCE RLS | Row Level Security, chính sách lọc dòng của PostgreSQL; FORCE bắt buộc cả chủ bảng, để không vai trò ứng dụng nào đi vòng |
| Mẫu P, S, G | Ba mẫu RLS của PH-12: P riêng tenant; S dùng chung (đọc thêm `COMMON`); G như P nhưng đọc thêm dòng có `target_tenant` của phiên (mục 1.2) |
| Khóa ngoại kép | Khóa ngoại gồm (`id`, `tenant_id`) nên không thể trỏ sang bản ghi của tenant khác |
| Bản chiếu | Bản sao phần nghiệp vụ của người dùng, client ở `ph12_iam`; Keycloak vẫn là nguồn sự thật của thông tin đăng nhập |
| Ý định (`sync_task`) | Lệnh ghi sang Keycloak được lưu cùng giao dịch với thay đổi ở `ph12_iam`, thực hiện sau và phát lại lũy đẳng (SDD §4.2) |
| Tách nhiệm vụ (SoD) | Một người không giữ cùng lúc hai vai trò xung đột (D02-08 §4); ngoại lệ có thời hạn tối đa 90 ngày |
| Quyền có thời hạn | Quyền đặc quyền hoặc truy cập tenant khác tối đa 4 giờ, có người duyệt thứ hai (FR-12-017) |
| Bốn mắt | Người duyệt khác người đề nghị, người soạn, người gửi và người đóng góp (BR-12-008) |
| Gói chính sách (bundle) | Tập Rego và dữ liệu đã ký mà OPA tải về; mỗi tenant có một gói tenant, nền tảng có một gói `platform` |
| Danh sách chặn | Mục thu hồi truy cập mà cổng từ chối dù token chưa hết hạn (FR-12-040) |
| `ltree` | Kiểu PostgreSQL lưu đường đi trong cây, dùng cho nhóm tổ chức |
| `SQLSTATE` tùy biến `P12nn` | Mã lỗi do trigger của PH-12 ném, ánh xạ một-một sang mã `ERR-12-0nn` (mục 3.44) |
| Outbox | Bảng ghi sự kiện cùng giao dịch để Debezium phát lên Kafka (ADR-042) |
| WORM | Write Once Read Many, lưu trữ không sửa được (kho chuỗi băm của PH-13) |

: Thuật ngữ và chữ viết tắt của tập CSDL PH-12

### 0.4. Tài liệu tham chiếu

Bảng dưới liệt kê tài liệu gốc cần mở khi đối chiếu một chi tiết, kèm nội dung được dùng ở tập này.

| Tài liệu | Nội dung dùng ở tập này |
|---|---|
| [D02-03-PH12](../../02-yeu-cau/frs/D02-03-PH12-frs-dinh-danh-phan-quyen.md) FRS | 20 thực thể EN-12-01…20 (§4.2), máy trạng thái (§4.3…4.8), BR-12, NFR-12, tham số `12.*`, mã lỗi, sự kiện, ánh xạ hệ cũ (§11) |
| [D03-02-PH12](../sdd/D03-02-PH12-sdd-dinh-danh-phan-quyen.md) SDD | Mô hình miền (§4.1), danh sách bảng suy ra (Đề nghị đồng bộ), nhất quán Keycloak, OpenBao, `ph12_iam` (§8.4), bảng chuyển trạng thái (§8.1) |
| [D02-08](../../02-yeu-cau/D02-08-ma-tran-phan-quyen.md) | 22 vai trò chuẩn (§2), bảy cặp tách nhiệm vụ (§4), scope máy (§5) |
| [D03-10](../D03-10-thiet-ke-da-tenant.md) | Mẫu RLS, xác định tenant từ token, `COMMON` |
| [D03-09](../ha-tang/D03-09-ha-tang-trien-khai-dr.md) | Cụm `pg-core`, `pg-iam`, tầng phục hồi, sao lưu |
| D03-07 | SEC-20…29 (IAM), SEC-31, SEC-32, SEC-36, SEC-84, SEC-85 |
| ADR-003, ADR-012, ADR-031, ADR-035, ADR-041, ADR-042, ADR-068, ADR-069 | RLS, OpenBao, chuỗi băm, sao lưu, lũy đẳng, outbox, kho cấu hình Git, máy trạng thái phiên bản và bốn mắt |
| D00-01 §5 | Kiểu dữ liệu chuẩn, trường ngữ cảnh bắt buộc |
| `docs/07-srs/SRS-PH-12-iam.md` (repo cũ) §4 | Mô hình dữ liệu hệ cũ để ánh xạ (chương 9) |

: Tài liệu tham chiếu của tập CSDL PH-12

### 0.5. Cấu trúc tài liệu

Chương 1 nêu chiến lược lưu trữ: cụm, schema, vai trò, cách ly tenant, quy ước bảng và danh mục 43 bảng. Chương 2 là sơ đồ thực thể – quan hệ. Chương 3 đặc tả từng bảng (khối 10 mục sinh từ DDL), các quy tắc chốt ở CSDL và truy vấn chính. Chương 4 mô tả tệp DDL, changelog Liquibase và kết quả chạy thử. Chương 5 về dữ liệu cá nhân và không lưu bí mật. Chương 6 là dữ liệu khởi tạo, chương 7 là kho ngoài PostgreSQL, chương 8 là sao lưu, khôi phục và lưu giữ, chương 9 là ánh xạ dữ liệu hệ cũ, chương 10 là câu hỏi mở. Cuối tập có đề nghị đồng bộ cho tài liệu dùng chung.

## 1. Chiến lược lưu trữ

Chương này trả lời bốn câu hỏi: dữ liệu của PH-12 nằm ở cụm nào và ai được chạm vào, cách ly giữa các tỉnh được thực thi ra sao, mỗi bảng theo quy ước nào, và 43 bảng chia theo nhóm nào. Điểm cần nhớ là nguyên tắc "Keycloak đúng với thông tin đăng nhập, `ph12_iam` đúng với vai trò và phạm vi" (SDD §8.4): hai kho không chung giao dịch, nên lược đồ có sẵn chỗ ghi ý định và dấu hiệu đồng bộ để phát hiện và sửa lệch.

### 1.1. Cụm, schema, vai trò và kết nối

Schema `ph12_iam` (quy ước `ph{nn}_{tên ngắn}`, D00-04 §4) đặt ở cụm `pg-core`, thuộc tầng phục hồi `TPH-1`, do `ph12_owner` (NOLOGIN) sở hữu. Schema `ph12` rỗng trong `deploy/compose/init-db/01-schemas.sql` ("IAM bridge metadata") chỉ là chỗ giữ chỗ của bản mã hiện tại và được thay bằng schema này; trong repo chưa có bảng nào của PH-12 nên không có di trú dữ liệu (chương 9).

| Đối tượng | Vai trò PostgreSQL | Quyền | Ghi chú |
|---|---|---|---|
| Chủ schema | `ph12_owner` (NOLOGIN, NOINHERIT, NOBYPASSRLS) | Sở hữu mọi đối tượng | Chỉ Liquibase và thủ tục dọn dữ liệu dùng, qua `dh_platform_iam_migrator` |
| `dh-platform` (module `iam`, vai trò `api` và `worker`) | `dh_platform_iam_app`, thành viên `ph12_app` | DML theo mục 1.5; không `BYPASSRLS`; không là chủ bảng | Kết nối qua PgBouncer chế độ giao dịch; `SET LOCAL app.tenant_id` ở đầu mỗi giao dịch |
| Báo cáo, kiểm toán | `ph12_readonly` | `SELECT`, trừ bảng chứa tham chiếu bí mật và nội dung nhập; không đọc `email` và `full_name` của người dùng | Dùng cho kiểm toán viên và báo cáo ngoài giờ cao điểm |
| `policy-runner` | Không có | Không có | Chạy Rego do người dùng soạn, không có thông tin xác thực CSDL, không có đường ra mạng (SDD §4.13) |
| Keycloak | Tài khoản riêng ở `pg-iam` | Chỉ trên `pg-iam` | Không kết nối `pg-core`; `dh-platform` không kết nối `pg-iam` |

: Vai trò PostgreSQL và kết nối của schema ph12_iam

Hai điều đáng chú ý. Một là `dh-platform` không đọc trực tiếp `pg-iam`: mọi thao tác Keycloak đi qua `KeycloakGateway`, nên một lần nâng cấp Keycloak đổi lược đồ của nó không làm vỡ PH-12. Hai là OPA, APISIX và các đơn vị triển khai khác **không** kết nối `ph12_iam`: họ nhận dữ liệu qua gói chính sách ký và qua API danh sách chặn (SDD §4.9, §4.12), nên sự cố `pg-core` không làm dừng quyết định ủy quyền.

### 1.2. Cách ly tenant

Tenant của một giao dịch lấy từ token đã xác minh và đặt vào biến phiên `app.tenant_id` bằng `SET LOCAL` (D03-10 §3). Mọi bảng nghiệp vụ có cột `tenant_id varchar(16)`, bật `ENABLE` và `FORCE ROW LEVEL SECURITY` qua thủ tục `ph12_iam.p_enable_rls(bảng, mẫu)`, và tên tenant được `CHECK` theo mẫu `^(T[0-9]{2}|PLATFORM)$` (`COMMON` ở bảng dùng chung). Chính sách dùng `current_setting('app.tenant_id', false)` nên truy vấn **lỗi** khi quên đặt biến phiên, thay vì trả rỗng. Ba mẫu RLS của PH-12 mở rộng hai mẫu P, S của PH-05:

| Mẫu | Đọc | Ghi | Bảng |
|---|---|---|---|
| P (riêng tenant) | Dòng có `tenant_id` = tenant phiên | Cùng điều kiện | 37 bảng tác nghiệp |
| S (dùng chung) | Dòng của tenant phiên và dòng `COMMON` | Chỉ dòng `COMMON`, và chỉ khi phiên là `PLATFORM` | `sod_pair`, `legacy_role_map`, `node_heartbeat` |
| G (quyền có thời hạn) | Dòng của tenant phiên **và** dòng có `target_tenant` bằng tenant phiên | Chỉ dòng của tenant phiên | `privileged_grant` |

: Ba mẫu RLS của schema ph12_iam

Mẫu G giải quyết một nghịch lý của quyền có thời hạn: người nhận quyền thuộc tenant `PLATFORM`, nhưng quản trị tỉnh bị truy cập phải thấy được quyền đang mở vào tỉnh mình (BR-12-032). Với mẫu G, dòng quyền vẫn do phiên `PLATFORM` ghi, còn phiên của tỉnh đích chỉ **đọc** được dòng có `target_tenant` của mình và không sửa được. Bài kiểm khối 7 xác nhận ba điều: tỉnh bị truy cập thấy quyền, tỉnh khác không thấy, và tỉnh đích không sửa được.

Một số bảng thuộc dữ liệu của chính nền tảng nên `tenant_id` luôn là `PLATFORM`, ràng buộc bằng `CHECK`: `service_account`, `realm_state`, `realm_provision_step`, `tenant_merge_step`. Tenant mà realm phục vụ nằm ở cột `tenant_code`; nhờ vậy quản trị nền tảng (PA) xem và thao tác mọi realm trong một phiên `PLATFORM` mà không phải đổi `app.tenant_id` sang từng tỉnh. Chính sách gốc `base-authz` và gói `platform` cũng ở tenant `PLATFORM` (Q12-50). Năm bảng chỉ có ở tenant tỉnh (`CHECK` `^T[0-9]{2}$`): `custom_role`, `custom_role_permission`, `client`, `client_scope`, `client_credential` (client luôn thuộc một tỉnh; tenant nền tảng dùng `service_account`).

Hai bảng không có `tenant_id` và không bật RLS vì chỉ là bảng kỹ thuật: `revocation_feed_version` (một dòng đếm phiên bản danh sách chặn) và `shedlock`. Danh sách chặn của các tenant được đọc bằng cách lặp từng tenant, không có ngoại lệ RLS nào (Q12-52).

Ba tầng bảo vệ chồng nhau: (1) vai trò ứng dụng không `BYPASSRLS` và không là chủ bảng, DU tự kiểm khi khởi động; (2) khóa ngoại kép; (3) `CHECK` tenant trên từng bảng. Bài kiểm khối 24 duyệt `pg_class` để chắc chắn mọi bảng có cột `tenant_id` đều có `relforcerowsecurity`.

### 1.3. Quy ước bảng

Theo D00-01 §5.1, mỗi bảng nghiệp vụ có `id uuid` (UUID v7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by` và `version` (khóa lạc quan, trigger `tg_touch` tăng khi ứng dụng không tự tăng; thành phần của ETag và `If-Match`, ERR-12-044). `created_by` và `updated_by` là `varchar(64)` thay vì `uuid` vì nhận cả mã người dùng lẫn tác nhân hệ thống `system:*`. Trạng thái dùng `varchar` cộng `CHECK` liệt kê đúng FRS §4.3…4.8; thêm giá trị là một changeset mới. Cột JSON luôn có `CHECK (jsonb_typeof(...))`, và cột nhận dữ liệu từ ngoài còn có `CHECK` không chứa khóa bí mật (hàm `ph12_iam.f_json_has_secret_key`, đệ quy). Ngoại lệ có chủ đích:

| Bảng | Ngoại lệ so với D00-01 §5.1 | Lý do |
|---|---|---|
| `user_import_row`, `org_group_member`, `custom_role_permission`, `client_scope`, `policy_version_contributor`, `policy_test_run`, `policy_dryrun_report`, `bundle_ack`, `alert_ack`, `idempotency_key`, `realm_provision_step` | Chỉ `created_*`, không có `updated_*` và `version` | Dòng chỉ thêm, hoặc thay theo nguồn bằng xóa rồi chèn; riêng `policy_dryrun_report` chỉ sửa được khi `RUNNING` |
| `account_report_daily`, `mfa_coverage_daily` | Khóa tự nhiên (`tenant_id`, `report_date`), không có `id`, chỉ `created_at` | Báo cáo tính lại được, ghi đè khi chạy lại cùng ngày |
| `outbox` | Khóa `event_id`, chỉ `created_at` | Chuẩn outbox của DD-11 (ADR-042) |
| `revocation_feed_version`, `shedlock` | Không có `tenant_id` | Bảng kỹ thuật, không dữ liệu nghiệp vụ |
| `sod_pair`, `legacy_role_map`, `node_heartbeat` | `tenant_id` luôn là `COMMON` | Dữ liệu dùng chung (mẫu S) |
| `service_account`, `realm_state`, `realm_provision_step`, `tenant_merge_step` | `tenant_id` luôn là `PLATFORM` | Dữ liệu của nền tảng (mục 1.2) |

: Ngoại lệ của quy ước bảng

Đối tượng chỉ kết thúc bằng trạng thái (không xóa vật lý) có trigger `tg_no_delete` và bị thu hồi quyền `DELETE` ở vai trò ứng dụng: `user_account`, `client`, `policy`, `policy_version`, `bundle_release` (BR-12-035). Bảng chứng cứ có trigger `tg_append_only`: `policy_version_contributor`, `policy_test_run`, `alert_ack`.

### 1.4. Danh mục bảng

43 bảng chia thành chín nhóm. Cột "EN" nối bảng với thực thể logic của FRS §4.2; cột RLS ghi mẫu ở mục 1.2.

| STT | Bảng | EN | RLS | Nội dung |
|---|---|---|---|---|
| 1 | `user_account` | EN-12-01 | P | Bản chiếu người dùng: đơn vị, trạng thái, mức xác thực, đồng bộ Keycloak |
| 2 | `user_import` | — | P | Lần nhập người dùng hàng loạt hai pha |
| 3 | `user_import_row` | — | P | Từng dòng tệp nhập và kết quả kiểm tra, tạo |
| 4 | `sod_pair` | — | S | Cặp vai trò xung đột sinh từ D02-08 §4 |
| 5 | `legacy_role_map` | — | S | Ánh xạ vai trò hệ cũ sang vai trò chuẩn |
| 6 | `role_assignment` | EN-12-02 | P | Gán vai trò có phạm vi và thời hạn |
| 7 | `sod_exception` | EN-12-03 | P | Ngoại lệ tách nhiệm vụ có thời hạn |
| 8 | `org_group` | EN-12-04 | P | Nhóm và đơn vị theo cây `ltree` |
| 9 | `org_group_member` | EN-12-04 | P | Thành viên nhóm |
| 10 | `custom_role` | EN-12-05 | P | Vai trò tùy biến của tỉnh (Đợt 2) |
| 11 | `custom_role_permission` | EN-12-05 | P | Quyền trong vai trò tùy biến |
| 12 | `privileged_grant` | EN-12-11 | G | Quyền có thời hạn, truy cập liên tenant |
| 13 | `recert_campaign` | EN-12-17 | P | Chiến dịch rà soát quyền |
| 14 | `recert_item` | EN-12-17 | P | Mục rà soát và quyết định |
| 15 | `federation` | EN-12-18 | P | Liên kết LDAP, Active Directory |
| 16 | `saml_client` | EN-12-18 | P | Ứng dụng SAML 2 cũ |
| 17 | `vneid_link` | EN-12-18 | P | Liên kết VNeID (băm) |
| 18 | `client` | EN-12-08 | P | Client OAuth của HTTT hoặc sandbox |
| 19 | `client_scope` | EN-12-09 | P | Scope theo nguồn duyệt |
| 20 | `client_credential` | EN-12-08 | P | Siêu dữ liệu chứng thư, khóa, bí mật của client |
| 21 | `service_account` | EN-12-10 | P | Tài khoản dịch vụ của đơn vị triển khai |
| 22 | `revocation_feed_version` | — | không | Số thứ tự toàn cục của danh sách chặn |
| 23 | `revocation_entry` | EN-12-19 | P | Danh sách chặn (`SUB`, `CLIENT`, `JTI`) |
| 24 | `node_heartbeat` | — | S | Phiên bản mà từng nút cổng, OPA đã áp |
| 25 | `realm_state` | EN-12-20 | P | Trạng thái, lệch cấu hình của realm |
| 26 | `realm_provision_step` | EN-12-20 | P | Bước của saga tạo realm |
| 27 | `tenant_merge_step` | — | P | Bước chuyển định danh khi sáp nhập |
| 28 | `policy` | EN-12-12 | P | Mã chính sách và phạm vi |
| 29 | `policy_version` | EN-12-12 | P | Phiên bản Rego và máy trạng thái |
| 30 | `policy_version_contributor` | EN-12-12 | P | Người đóng góp mỗi phiên bản |
| 31 | `policy_test_case` | EN-12-13 | P | Ca kiểm thử chính sách |
| 32 | `policy_test_run` | EN-12-13 | P | Kết quả chạy kiểm thử |
| 33 | `policy_dryrun_report` | EN-12-12 | P | Báo cáo chạy khô |
| 34 | `bundle_release` | EN-12-14 | P | Bản phát hành gói chính sách |
| 35 | `bundle_ack` | EN-12-14 | P | Nút OPA đã nạp bản nào |
| 36 | `alert` | EN-12-16 | P | Cảnh báo an ninh AN-01…09 |
| 37 | `alert_ack` | EN-12-16 | P | Xác nhận cảnh báo |
| 38 | `account_report_daily` | — | P | Báo cáo tài khoản theo ngày |
| 39 | `mfa_coverage_daily` | — | P | Tỷ lệ phủ xác thực hai yếu tố |
| 40 | `sync_task` | — | P | Ý định ghi sang Keycloak |
| 41 | `idempotency_key` | — | P | Khóa lũy đẳng của API ghi |
| 42 | `outbox` | — | P | Sự kiện EVT-12-01…15 chờ phát |
| 43 | `shedlock` | — | không | Khóa tác vụ định kỳ |

: Danh mục 43 bảng của schema ph12_iam

Ba thực thể logic không có bảng: EN-12-06 (yếu tố xác thực) và EN-12-07 (phiên) ở Keycloak, EN-12-15 (bản ghi quyết định) ở Loki và chuỗi kiểm toán PH-13 (FRS §11.2). EN-12-01 ở cả hai nơi: Keycloak giữ thông tin đăng nhập, bảng `user_account` giữ bản chiếu nghiệp vụ. So với danh sách bảng suy ra ở SDD (Đề nghị đồng bộ của D03-02-PH12) có thêm ba bảng: `sod_pair` và `legacy_role_map` để chốt tách nhiệm vụ và ánh xạ vai trò cũ ở CSDL, và `shedlock` cho tác vụ định kỳ; không bảng nào của SDD bị bỏ.

### 1.5. Quyền của vai trò ứng dụng

Quyền được cấp bằng thủ tục chạy lại mỗi lần (`ph12_iam_06_seed_grants.sql`, changeset `runAlways`) theo ba danh sách, nên thêm bảng mới mà quên khai báo thì mặc định chỉ có `SELECT, INSERT, UPDATE`, không có `DELETE`.

| Nhóm | Bảng | `ph12_app` | `ph12_readonly` |
|---|---|---|---|
| Mặc định | Phần lớn bảng | `SELECT, INSERT, UPDATE` | `SELECT` |
| Được xóa dòng | `user_import`, `user_import_row`, `org_group`, `org_group_member`, `custom_role_permission`, `client_scope`, `revocation_entry`, `policy_dryrun_report` (sau hạn), `bundle_ack`, `account_report_daily`, `mfa_coverage_daily`, `sync_task`, `idempotency_key`, `outbox`, `shedlock` | Thêm `DELETE` | Như mặc định |
| Chỉ thêm | `policy_version_contributor`, `policy_test_run`, `alert_ack` | `SELECT, INSERT` | `SELECT` |
| Chỉ đọc với ứng dụng | `sod_pair`, `legacy_role_map` | `SELECT` | `SELECT` |
| Không cho báo cáo đọc | `user_import_row`, `vneid_link`, `client_credential`, `federation`, `saml_client`, `idempotency_key`, `outbox`, `sync_task` | Như mặc định | Không có quyền |
| Quyền theo cột | `user_account` | Như mặc định | Mọi cột trừ `email` và `full_name` |
| Không xóa vật lý | `user_account`, `client`, `policy`, `policy_version`, `bundle_release` (và mọi bảng không nêu ở dòng "Được xóa dòng", như `role_assignment`) | Không có `DELETE`; trigger `tg_no_delete` chặn cả chủ bảng ở năm bảng đầu | Như mặc định |

: Quyền của vai trò ứng dụng và vai trò chỉ đọc

## 2. Sơ đồ thực thể – quan hệ

Bốn sơ đồ dưới chia 43 bảng theo miền để mỗi hình đọc được trên khổ A4. Đường liền là khóa ngoại thật, kèm `tenant_id` (khóa ngoại kép) nên không thể trỏ chéo tenant; ngoại lệ duy nhất là khóa tới `sod_pair`, bảng dùng chung `COMMON`. Đường chấm là liên kết theo mã hoặc theo cột JSON, không có khóa ngoại, vì hai phía thuộc tenant khác nhau, khác schema hoặc đến từ Keycloak. Hai bảng kỹ thuật `revocation_feed_version` và `shedlock` không có quan hệ nên không vẽ.

### 2.1. Người dùng, vai trò, nhóm, quyền có thời hạn và rà soát

Hình dưới gom các bảng xoay quanh người dùng: ai được gán vai trò gì, ngoại lệ tách nhiệm vụ, nhóm, quyền có thời hạn, rà soát quyền và nhập hàng loạt.

```{.mermaid caption="ERD miền người dùng, vai trò, nhóm, quyền có thời hạn và rà soát quyền"}
erDiagram
  user_account ||--o{ role_assignment : "được gán"
  user_account ||--o{ sod_exception : "ngoại lệ SoD"
  user_account ||--o{ org_group_member : "thuộc nhóm"
  user_account ||--o{ privileged_grant : "nhận quyền"
  user_account ||--o{ vneid_link : "liên kết VNeID"
  user_account ||--o{ recert_item : "được rà soát"
  user_account ||--o{ user_account : "quản lý trực tiếp"
  federation ||--o{ user_account : "nguồn LDAP"
  org_group ||--o{ org_group_member : "thành viên"
  org_group ||--o{ org_group : "cha và con"
  sod_pair ||--o{ sod_exception : "cặp xung đột"
  role_assignment ||--o{ recert_item : "mục rà soát"
  recert_campaign ||--o{ recert_item : "gồm"
  user_import ||--o{ user_import_row : "dòng"
  user_import_row }o--o| user_account : "tạo ra"
  custom_role ||--o{ custom_role_permission : "quyền"
  role_assignment }o..o| custom_role : "role_code CUSTOM_ (theo mã)"
  legacy_role_map }o..o{ user_import : "gợi ý ánh xạ"

  user_account {
    uuid id PK
    varchar tenant_id
    varchar username
    varchar org_code
    varchar state
    smallint mfa_level
    varchar sync_state
  }
  role_assignment {
    uuid id PK
    uuid user_id FK
    varchar role_code
    varchar scope_type
    timestamptz valid_to
    varchar state
  }
  sod_pair {
    varchar role_a
    varchar role_b
    boolean allow_exception
  }
  sod_exception {
    uuid id PK
    uuid user_id FK
    timestamptz expires_at
    varchar state
  }
  org_group {
    uuid id PK
    varchar code
    ltree path
    uuid parent_id FK
  }
  privileged_grant {
    uuid id PK
    varchar tenant_id
    varchar target_tenant
    smallint requested_hours
    varchar state
  }
  recert_item {
    uuid id PK
    uuid assignment_id FK
    uuid reviewer_user_id FK
    varchar decision
  }
```

Hình cho thấy `user_account` là trung tâm: gán vai trò, ngoại lệ, nhóm, quyền có thời hạn, liên kết VNeID và rà soát đều trỏ về người dùng bằng khóa ngoại kép. Hai vòng tự tham chiếu là quản lý trực tiếp (`manager_user_id`) và cây nhóm (`parent_id`); cây nhóm có thêm cột `path` kiểu `ltree` do trigger giữ đúng. `sod_pair` là dữ liệu dùng chung (`COMMON`) nên trỏ tới `sod_exception` bằng khóa ngoại theo cặp vai trò, không kèm `tenant_id`. `role_assignment` trỏ tới vai trò tùy biến theo mã (`CUSTOM_…`), không bằng khóa ngoại, vì vai trò chuẩn không có bảng.

### 2.2. Danh tính máy, liên kết ngoài, thu hồi và realm

Hình dưới gom danh tính máy (client và scope), liên kết với hệ ngoài, danh sách chặn, nút cổng và realm của từng tenant.

```{.mermaid caption="ERD miền client, liên kết ngoài, danh sách chặn, nút cổng và realm"}
erDiagram
  client ||--o{ client_scope : "scope theo nguồn"
  client ||--o{ client_credential : "chứng thư, khóa, bí mật"
  client }o..o{ revocation_entry : "theo mã clientId"
  user_account }o..o{ revocation_entry : "theo mã người dùng"
  revocation_entry }o..|| revocation_feed_version : "tăng số thứ tự"
  realm_state ||--o{ realm_provision_step : "tám bước"
  realm_state }o..o{ tenant_merge_step : "theo tenant_code"
  service_account }o..o{ node_heartbeat : "cùng danh tính mTLS"

  client {
    uuid id PK
    varchar client_id
    varchar system_code
    varchar auth_method
    varchar contract_level
    varchar state
    boolean credential_ready
  }
  client_scope {
    uuid id PK
    uuid client_pk FK
    varchar scope
    varchar source
  }
  client_credential {
    uuid id PK
    uuid client_pk FK
    varchar kind
    char thumbprint
    timestamptz not_after
    varchar state
  }
  revocation_entry {
    uuid id PK
    varchar kind
    varchar value
    boolean block_all
    timestamptz expires_at
  }
  revocation_feed_version {
    smallint id PK
    bigint version
  }
  realm_state {
    uuid id PK
    varchar tenant_code
    varchar realm_name
    varchar state
    varchar drift_status
  }
  service_account {
    uuid id PK
    varchar account_code
    varchar du_code
    text scopes
  }
  federation {
    uuid id PK
    varchar kind
    varchar state
  }
  saml_client {
    uuid id PK
    varchar entity_id
    varchar state
  }
  vneid_link {
    uuid id PK
    uuid user_id FK
    char subject_hash
  }
```

Hình cho thấy hai cụm. Cụm client giữ `client` cùng scope và siêu dữ liệu thông tin xác thực bằng khóa ngoại kép; danh sách chặn trỏ tới client và người dùng chỉ **theo mã** (`CLIENT` theo `azp`, `SUB` theo mã người dùng, `JTI` theo mã token), nên một mục thu hồi vẫn hiệu lực dù client đã `REVOKED` và không cần chạm bảng `client`. Cụm realm thuộc tenant `PLATFORM`; `realm_state` nối `realm_provision_step` bằng khóa ngoại và nối `tenant_merge_step` theo mã tenant. `federation`, `saml_client` và `vneid_link` đứng riêng vì chỉ liên kết vào Keycloak (`federation` còn là nguồn của `user_account.federation_id` ở hình 2.1).

### 2.3. Chính sách, kiểm thử, chạy khô và gói chính sách

Hình dưới gom đường đi của một chính sách từ bản nháp đến gói đã ký mà OPA nạp, cùng các bằng chứng gắn với băm nội dung.

```{.mermaid caption="ERD miền chính sách và gói chính sách"}
erDiagram
  policy ||--o{ policy_version : "phiên bản"
  policy ||--o{ policy_test_case : "ca kiểm thử"
  policy_version ||--o{ policy_version_contributor : "người đóng góp"
  policy_version ||--o{ policy_test_run : "kết quả kiểm thử"
  policy_version ||--o{ policy_dryrun_report : "báo cáo chạy khô"
  bundle_release ||--o{ bundle_ack : "nút đã nạp"
  bundle_release ||--o| bundle_release : "quay lui từ"
  policy_version }o..o{ bundle_release : "nằm trong (policy_versions)"
  node_heartbeat }o..o{ bundle_ack : "theo node_id"

  policy {
    uuid id PK
    varchar tenant_id
    varchar code
    varchar scope
    boolean is_root
  }
  policy_version {
    uuid id PK
    uuid policy_id FK
    int version_no
    char content_hash
    varchar state
    varchar author
    varchar approved_by
  }
  policy_test_run {
    uuid id PK
    uuid version_id FK
    char content_hash
    boolean passed
    numeric coverage_pct
  }
  policy_dryrun_report {
    uuid id PK
    uuid version_id FK
    char content_hash
    numeric changed_ratio
    int deny_to_allow_count
  }
  bundle_release {
    uuid id PK
    varchar tenant_id
    varchar bundle_revision
    char digest
    varchar state
  }
  bundle_ack {
    uuid id PK
    uuid release_id FK
    varchar node_id
  }
```

Hình cho thấy chuỗi bằng chứng gắn với **băm nội dung**: `policy_test_run` và `policy_dryrun_report` cùng mang `content_hash` của phiên bản mà chúng đã chạy, và trigger của `policy_version` chỉ cho gửi duyệt khi cả hai khớp băm hiện tại. Quan hệ giữa phiên bản chính sách và gói là theo cột JSON `policy_versions` của `bundle_release` (một gói chứa nhiều phiên bản, một phiên bản nằm trong nhiều gói qua các lần phát hành), nên không có khóa ngoại. `bundle_release.rollback_of` trỏ về chính bảng để ghi bản quay lui là một bản phát hành mới.

### 2.4. Cảnh báo, báo cáo và bảng kỹ thuật

Hình dưới gom cảnh báo, báo cáo ngày và các bảng kỹ thuật phục vụ đồng bộ Keycloak, lũy đẳng, outbox và khóa tác vụ.

```{.mermaid caption="ERD miền cảnh báo, báo cáo và bảng kỹ thuật"}
erDiagram
  alert ||--o| alert_ack : "được xác nhận"
  user_account }o..o{ alert : "subject_ref"
  user_account }o..o{ sync_task : "target_id"
  client }o..o{ sync_task : "target_id"
  user_account }o..o{ account_report_daily : "tổng hợp theo ngày"
  user_account }o..o{ mfa_coverage_daily : "tổng hợp theo ngày"

  alert {
    uuid id PK
    varchar rule_code
    varchar severity
    varchar dedup_key
    varchar state
  }
  alert_ack {
    uuid id PK
    uuid alert_id FK
    varchar acked_by
  }
  account_report_daily {
    varchar tenant_id PK
    date report_date PK
    int users_total
    int inactive_45d
  }
  mfa_coverage_daily {
    varchar tenant_id PK
    date report_date PK
    int required_users
    int enrolled_users
  }
  sync_task {
    uuid id PK
    varchar task_type
    uuid target_id
    varchar status
  }
  idempotency_key {
    uuid id PK
    varchar idem_key
    char body_hash
  }
  outbox {
    uuid event_id PK
    varchar event_type
    varchar topic
    jsonb payload
  }
  shedlock {
    varchar name PK
    timestamptz lock_until
  }
```

Hình cho thấy nhóm này gần như độc lập: cảnh báo có một quan hệ với xác nhận, còn các báo cáo ngày, ý định đồng bộ, khóa lũy đẳng và outbox chỉ tham chiếu đối tượng theo mã hoặc là bảng kỹ thuật. Chúng được tách khỏi bảng nghiệp vụ để dọn dữ liệu hết hạn (24 giờ, 3 ngày, 7 ngày, 24 tháng) bằng xóa theo `expires_at` hoặc `purge_after` mà không chạm dữ liệu gốc (chương 8).

## 3. Đặc tả bảng

Chương này đặc tả từng bảng theo thứ tự trong DDL (mục 3.1 đến 3.43), rồi gom các quy tắc nghiệp vụ chốt ở CSDL kèm `SQLSTATE` mà dịch vụ phải ánh xạ sang mã lỗi (mục 3.44) và các truy vấn chính cùng chỉ mục phục vụ (mục 3.45). Mỗi bảng mở đầu bằng bảng đặc tả 10 mục (Mục đích, FR phục vụ, Khóa chính, Duy nhất, Khóa ngoại, Ràng buộc CHECK, Chỉ mục, Cách ly tenant, Phân vùng và chỉ thêm, Ghi chú) rồi đến danh sách cột. Cả hai phần được sinh từ DDL đã chạy thử bằng [`ph12/tools/gen_tables_md.py`](ph12/tools/gen_tables_md.py) và [`ph12/tools/them_dac_ta_bang.py`](ph12/tools/them_dac_ta_bang.py) (đọc `CREATE TABLE`, `CREATE INDEX`, `CREATE TRIGGER`, `CALL p_enable_rls` và `COMMENT ON`); sửa ở DDL rồi sinh lại, không sửa tay giữa hai dấu `gen:tables`. Cột "Ghi chú" của bảng cột có thêm tập giá trị của trạng thái và mẫu của mã, suy ra từ `CHECK` đặt tên `ck_{bảng}_{cột}`.

<!-- gen:tables:start -->
### 3.1. `user_account`

::: dac-ta
**Mục đích.** EN-12-01 Bản chiếu người dùng (FR-12-001…010). Keycloak là nguồn sự thật của thông tin đăng nhập; bảng giữ phần nghiệp vụ. Không xóa vật lý, kết thúc là DISABLED (BR-12-035).

**FR phục vụ.** FR-12-001…006, 008…010, 062.

**Khóa chính.** (id).

**Duy nhất.** `uq_user_account_keycloak` (tenant_id, keycloak_id); `uq_user_account_username` (tenant_id, lower(username)); `uq_user_account_email` (tenant_id, lower(email)).

**Khóa ngoại.** (manager_user_id, tenant_id) → `user_account` (chính bảng này).

**Ràng buộc CHECK.** `ck_user_account_tenant`; `ck_user_account_username`; `ck_user_account_email`; `ck_user_account_state`; `ck_user_account_auth_source`; `ck_user_account_federation`; `ck_user_account_mfa`; `ck_user_account_sync`; `ck_user_account_disabled`; `ck_user_account_activated`; `ck_user_account_manager`; `ck_user_account_origin`.

**Chỉ mục.** `ix_user_account_org_state` (tenant_id, org_code, state); `ix_user_account_inactivity` (tenant_id, last_login_at) khi state = 'ACTIVE'; `ix_user_account_pending` (tenant_id, created_at) khi state = 'PENDING_ACTIVATION'; `ix_user_account_sync` (tenant_id, updated_at) khi sync_state <> 'SYNCED'; `ix_user_account_manager` (tenant_id, manager_user_id) khi manager_user_id IS NOT NULL; `ix_user_account_name_trgm` (lower(full_name) gin_trgm_ops) GIN.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Không xóa vật lý, kết thúc bằng trạng thái (trigger `tg_user_account_no_delete`, BR-12-035); Trigger nghiệp vụ `tg_user_account_last_admin` (hàm `tg_user_account_last_admin`).

**Ghi chú.** Chứa dữ liệu cá nhân (họ tên, thư điện tử; mục 5); `ph12_readonly` không đọc được `email` và `full_name`. Trigger `tg_user_account_last_admin` giữ tenant còn ít nhất một quản trị tỉnh (ERR-12-046). Ước lượng 3.000 dòng mỗi tỉnh vừa (GĐ-12-02), thiết kế tới 10.000 (NFR-12-023). Lưu giữ: vĩnh viễn (mục 8).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `keycloak_id` | `uuid` | Không |  | Mã người dùng ở Keycloak; rỗng khi sync_state = PENDING (ghi ý định trước, tạo ở Keycloak sau, SDD §4.2). |
| `username` | `varchar(80)` | Có |  | Tên đăng nhập; duy nhất trong tenant, không phân biệt hoa thường. Mẫu `^[a-z0-9][a-z0-9._-]{2,79}$`. |
| `full_name` | `varchar(255)` | Có |  | Họ tên đầy đủ (dữ liệu cá nhân, mục 5). |
| `email` | `varchar(254)` | Có |  | Thư điện tử công vụ (dữ liệu cá nhân, mục 5); duy nhất trong tenant, không phân biệt hoa thường. Mẫu `^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$`. |
| `org_code` | `varchar(64)` | Có |  | Mã đơn vị ở PH-07; không khóa ngoại vì khác schema, kiểm ở dịch vụ (ERR-12-004). |
| `title` | `varchar(255)` | Không |  | Chức danh. |
| `manager_user_id` | `uuid` | Không |  | Người quản lý trực tiếp; người rà soát quyền mặc định (FR-12-018). |
| `auth_source` | `varchar(8)` | Có | `'LOCAL'` | Một trong: `LOCAL`, `LDAP`. |
| `federation_id` | `uuid` | Không |  | Liên kết LDAP, AD là nguồn xác thực khi `auth_source = LDAP`. |
| `state` | `varchar(20)` | Có | `'PENDING_ACTIVATION'` | Năm trạng thái của FRS §4.3. LOCKED, BLOCKED do Keycloak quyết định, cập nhật qua EVT-12-16. Một trong: `PENDING_ACTIVATION`, `ACTIVE`, `LOCKED`, `BLOCKED`, `DISABLED`. |
| `disabled_reason` | `varchar(40)` | Không |  | Mã lý do vô hiệu: MANUAL, INACTIVE_45D, INACTIVE_30D_ADMIN, NEVER_ACTIVATED, LDAP_REMOVED, MERGED. |
| `disabled_note` | `varchar(1000)` | Không |  | Ghi chú của người vô hiệu. |
| `mfa_level` | `smallint` | Có | `1` | Mức xác thực yêu cầu (thuộc tính dh_mfa_level ở Keycloak): 1 mật khẩu, 2 cộng TOTP hoặc WebAuthn, 3 WebAuthn. Lấy mức cao nhất của vai trò mfaRequired. |
| `sync_state` | `varchar(8)` | Có | `'PENDING'` | Trạng thái đồng bộ với Keycloak: PENDING (ghi ý định, chưa tạo), SYNCED, FAILED. |
| `activated_at` | `timestamptz` | Không |  | Thời điểm kích hoạt lần đầu. |
| `last_login_at` | `timestamptz` | Không |  | Lấy từ sự kiện đăng nhập (EVT-12-16); nguồn của tác vụ tự vô hiệu 45 ngày (FR-12-008). |
| `disabled_at` | `timestamptz` | Không |  | Thời điểm vô hiệu. |
| `origin_tenant_id` | `varchar(16)` | Không |  | Tenant nguồn khi người dùng được chuyển do sáp nhập (FR-12-019); cùng origin_user_id. |
| `origin_user_id` | `uuid` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `user_account`

### 3.2. `user_import`

::: dac-ta
**Mục đích.** Lần nhập người dùng hàng loạt hai pha (FR-12-009, BR-12-043): xem trước rồi xác nhận. Tệp gốc ở kho đối tượng, xóa sau 24 giờ; tối đa 20.000 dòng (trần của 12.import.max-rows).

**FR phục vụ.** FR-12-009.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_user_import_tenant`; `ck_user_import_status`; `ck_user_import_hash`; `ck_user_import_rows`; `ck_user_import_mapping`; `ck_user_import_confirm`.

**Chỉ mục.** `ix_user_import_status` (tenant_id, status, created_at DESC); `ix_user_import_purge` (file_purge_at) khi file_ref IS NOT NULL.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Tệp gốc ở bucket `dh-iam-import`, xóa sau 24 giờ; bản ghi giữ 30 ngày sau khi xong (giả định) rồi tác vụ dọn dữ liệu hết hạn xóa, cùng với các dòng của lần nhập.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `file_name` | `varchar(255)` | Có |  |  |
| `file_ref` | `varchar(512)` | Không |  | Khóa đối tượng của tệp gốc trong bucket dh-iam-import; đặt NULL sau khi xóa (file_purge_at = tạo + 24 giờ). |
| `file_sha256` | `char(64)` | Có |  |  |
| `file_purge_at` | `timestamptz` | Có |  |  |
| `status` | `varchar(12)` | Có | `'PREVIEW'` | Một trong: `PREVIEW`, `CONFIRMED`, `RUNNING`, `DONE`, `FAILED`, `EXPIRED`. |
| `role_mapping` | `jsonb` | Có | `'{}'` | Ánh xạ vai trò hệ cũ sang vai trò chuẩn của lần nhập này, khởi tạo từ legacy_role_map, TA sửa được (FRS §11.4). |
| `total_rows` | `integer` | Có | `0` |  |
| `ok_rows` | `integer` | Có | `0` |  |
| `warn_rows` | `integer` | Có | `0` |  |
| `error_rows` | `integer` | Có | `0` |  |
| `created_rows` | `integer` | Có | `0` |  |
| `failed_rows` | `integer` | Có | `0` |  |
| `confirmed_by` | `varchar(64)` | Không |  |  |
| `confirmed_at` | `timestamptz` | Không |  |  |
| `finished_at` | `timestamptz` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `user_import`

### 3.3. `user_import_row`

::: dac-ta
**Mục đích.** Từng dòng của tệp nhập với kết quả kiểm tra (OK, WARN, ERROR) rồi kết quả tạo (CREATED, FAILED). Không nhận mật khẩu qua tệp: cột raw bị CHECK chặn khóa tên bí mật (BR-12-043, BR-12-045).

**FR phục vụ.** FR-12-009.

**Khóa chính.** (id).

**Duy nhất.** `uq_user_import_row` (import_id, row_no).

**Khóa ngoại.** (import_id, tenant_id) → `user_import` xóa theo; (user_id, tenant_id) → `user_account`.

**Ràng buộc CHECK.** `ck_user_import_row_tenant`; `ck_user_import_row_result`; `ck_user_import_row_no`; `ck_user_import_row_messages`; `ck_user_import_row_no_secret`.

**Chỉ mục.** `ix_user_import_row_result` (tenant_id, import_id, result).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Có dữ liệu cá nhân của người được nhập; cột `raw` không nhận mật khẩu (CHECK `ck_user_import_row_no_secret`). Xóa theo lần nhập sau 30 ngày (giả định).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `import_id` | `uuid` | Có |  |  |
| `row_no` | `integer` | Có |  |  |
| `raw` | `jsonb` | Có |  |  |
| `result` | `varchar(8)` | Có |  | Một trong: `OK`, `WARN`, `ERROR`, `CREATED`, `FAILED`. |
| `messages` | `jsonb` | Có | `'[]'` |  |
| `user_id` | `uuid` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `user_import_row`

### 3.4. `sod_pair`

::: dac-ta
**Mục đích.** Cặp vai trò xung đột của D02-08 §4, sinh từ ma trận khi phát hành (FR-12-051, BR-12-030). Dùng chung mọi tenant (COMMON), chỉ PLATFORM ghi. Cặp có AUDITOR với vai trò ghi của PH-19 có allow_exception = false.

**FR phục vụ.** FR-12-013, 051.

**Khóa chính.** (id).

**Duy nhất.** `uq_sod_pair` (role_a, role_b).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_sod_pair_tenant`; `ck_sod_pair_order`; `ck_sod_pair_role`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và dòng `COMMON`; chỉ phiên `PLATFORM` được ghi dòng `COMMON` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Dữ liệu `COMMON`, 10 dòng sinh từ D02-08 §4 bằng changeset `runOnChange` (mục 6). Đổi ma trận là đổi changeset và đi qua duyệt chính sách nền tảng (FR-12-051).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có | `'COMMON'` | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `role_a` | `varchar(64)` | Có |  | Mã vai trò bỏ tiền tố ROLE-, role_a < role_b theo thứ tự chữ cái để tra một chiều. |
| `role_b` | `varchar(64)` | Có |  |  |
| `allow_exception` | `boolean` | Có | `true` |  |
| `reason` | `varchar(500)` | Có |  | Lý do (bắt buộc, độ dài tối thiểu theo CHECK). |
| `source_ref` | `varchar(64)` | Có | `'D02-08 §4'` |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `sod_pair`

### 3.5. `legacy_role_map`

::: dac-ta
**Mục đích.** Ánh xạ mặc định vai trò hệ cũ sang vai trò chuẩn D02-08 (FRS §11.4), đầu vào của nhập người dùng (FR-12-009, ERR-12-036) và di trú (D06-01). role_code rỗng nghĩa là chưa có vai trò tương ứng (Q12-05).

**FR phục vụ.** FR-12-009, 011.

**Khóa chính.** (id).

**Duy nhất.** `uq_legacy_role_map` (legacy_role).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_legacy_role_map_tenant`; `ck_legacy_role_map_source`; `ck_legacy_role_map_role`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và dòng `COMMON`; chỉ phiên `PLATFORM` được ghi dòng `COMMON` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Dữ liệu `COMMON`, 17 dòng (mục 6): 15 vai trò của SRS repo (FRS §11.4) và 2 vai trò của realm `lgsp` ở compose. Đầu vào của nhập người dùng và di trú.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có | `'COMMON'` | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `legacy_role` | `varchar(64)` | Có |  |  |
| `role_code` | `varchar(64)` | Không |  |  |
| `source` | `varchar(16)` | Có |  | Một trong: `SRS_REPO`, `COMPOSE_REALM`, `MIDPOINT`. |
| `note` | `varchar(500)` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `legacy_role_map`

### 3.6. `role_assignment`

::: dac-ta
**Mục đích.** EN-12-02 Gán vai trò chuẩn cho người dùng, có phạm vi (TENANT, ORG, WORKSPACE) và thời hạn (FR-12-012). Cặp xung đột bị trigger tg_role_assignment_sod chặn (BR-12-030); tenant còn ít nhất một TENANT_ADMIN (BR-12-033). Vai trò chỉ gán cho người, không gán cho nhóm (BR-12-039).

**FR phục vụ.** FR-12-004, 011…013, 016, 018, 046, 051.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (user_id, tenant_id) → `user_account`.

**Ràng buộc CHECK.** `ck_role_assignment_tenant`; `ck_role_assignment_role`; `ck_role_assignment_machine`; `ck_role_assignment_platform`; `ck_role_assignment_scope`; `ck_role_assignment_state`; `ck_role_assignment_source`; `ck_role_assignment_valid`; `ck_role_assignment_revoked`; `ck_role_assignment_no_self`.

**Chỉ mục.** `ix_role_assignment_user` (tenant_id, user_id, state); `ix_role_assignment_role` (tenant_id, role_code) khi state = 'ACTIVE'; `ix_role_assignment_expiry` (valid_to) khi state = 'ACTIVE' AND valid_to IS NOT NULL.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Trigger nghiệp vụ `tg_role_assignment_last_admin` (hàm `tg_role_assignment_last_admin`); Trigger nghiệp vụ `tg_role_assignment_sod` (hàm `tg_role_assignment_sod`).

**Ghi chú.** Hai trigger chốt tách nhiệm vụ (`tg_role_assignment_sod`, khóa tư vấn theo người dùng) và tenant còn quản trị cuối cùng. `AssignmentExpiryJob` đặt EXPIRED mỗi phút; hết hạn đã có hiệu lực ngay ở OPA vì Rego kiểm `valid_to` ở mọi quyết định (SDD §4.3). Không xóa vật lý: gỡ là REVOKED.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `user_id` | `uuid` | Có |  |  |
| `role_code` | `varchar(64)` | Có |  | Mã vai trò chuẩn bỏ tiền tố ROLE-, ví dụ TENANT_ADMIN; hoặc vai trò tùy biến CUSTOM_* (custom_role.code). Danh mục 22 vai trò chuẩn nằm ở roles.json sinh từ D02-08, không lưu bảng. |
| `scope_type` | `varchar(10)` | Có | `'TENANT'` |  |
| `scope_ref` | `varchar(64)` | Không |  | Mã đơn vị (ORG, cùng cây con) hoặc mã không gian làm việc của PH-04 (WORKSPACE); rỗng khi phạm vi TENANT. |
| `valid_from` | `timestamptz` | Có | `now()` | Hiệu lực từ. |
| `valid_to` | `timestamptz` | Không |  | Hiệu lực đến; rỗng là không thời hạn. |
| `state` | `varchar(8)` | Có | `'ACTIVE'` | Một trong: `ACTIVE`, `EXPIRED`, `REVOKED`. |
| `source` | `varchar(8)` | Có | `'MANUAL'` | Một trong: `MANUAL`, `IMPORT`, `RECERT`, `SYSTEM`, `MERGE`. |
| `reason` | `varchar(1000)` | Không |  | Lý do (bắt buộc, độ dài tối thiểu theo CHECK). |
| `revoked_by` | `varchar(64)` | Không |  | Người thu hồi. |
| `revoked_at` | `timestamptz` | Không |  | Thời điểm thu hồi. |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người gán (assignedBy); khác người nhận vai trò (BR-12-033). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `role_assignment`

### 3.7. `sod_exception`

::: dac-ta
**Mục đích.** EN-12-03 Ngoại lệ tách nhiệm vụ: TA đề nghị, SO duyệt (khác người), lý do ≥ 30 ký tự, tối đa 90 ngày, tự gỡ khi hết hạn (FR-12-013, BR-12-030, EVT-12-12).

**FR phục vụ.** FR-12-013.

**Khóa chính.** (id).

**Duy nhất.** `uq_sod_exception_open` (tenant_id, user_id, role_a, role_b) khi state IN ('REQUESTED', 'ACTIVE').

**Khóa ngoại.** (user_id, tenant_id) → `user_account`; (role_a, role_b) → `sod_pair`.

**Ràng buộc CHECK.** `ck_sod_exception_tenant`; `ck_sod_exception_state`; `ck_sod_exception_reason`; `ck_sod_exception_max_days`; `ck_sod_exception_four_eyes`; `ck_sod_exception_decided`.

**Chỉ mục.** `ix_sod_exception_expiry` (expires_at) khi state = 'ACTIVE'.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Trigger nghiệp vụ `tg_sod_exception_guard` (hàm `tg_sod_exception_guard`).

**Ghi chú.** Trigger `tg_sod_exception_guard` từ chối cặp có `allow_exception = false`. Hết hạn thì `AssignmentExpiryJob` đặt EXPIRED và gỡ vai trò thứ hai. Cột `approved_by` ghi người quyết định cả khi từ chối hoặc thu hồi.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `user_id` | `uuid` | Có |  |  |
| `role_a` | `varchar(64)` | Có |  | Cặp vai trò theo thứ tự chữ cái, khóa ngoại tới sod_pair; trigger tg_sod_exception_guard từ chối cặp có allow_exception = false. |
| `role_b` | `varchar(64)` | Có |  |  |
| `reason` | `varchar(2000)` | Có |  | Lý do (bắt buộc, độ dài tối thiểu theo CHECK). |
| `state` | `varchar(10)` | Có | `'REQUESTED'` | Một trong: `REQUESTED`, `ACTIVE`, `REJECTED`, `EXPIRED`, `REVOKED`. |
| `expires_at` | `timestamptz` | Có |  | Thời điểm hết hiệu lực. |
| `proposed_by` | `varchar(64)` | Có |  | Người đề nghị. |
| `approved_by` | `varchar(64)` | Không |  | Người duyệt; khác người đề nghị hoặc người soạn (bốn mắt, CHECK). |
| `decided_at` | `timestamptz` | Không |  | Thời điểm quyết định (duyệt, từ chối, thu hồi). |
| `decision_note` | `varchar(1000)` | Không |  | Ý kiến của người quyết định. |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `sod_exception`

### 3.8. `org_group`

::: dac-ta
**Mục đích.** EN-12-04 Nhóm và đơn vị tổ chức theo cây (FR-12-014). path là ltree do trigger tính từ cha và mã; cấm vòng lặp (BR-12-039). Phạm vi ORG của gán vai trò hiểu là mọi nhóm có path <@ path của đơn vị.

**FR phục vụ.** FR-12-010, 014, 046.

**Khóa chính.** (id).

**Duy nhất.** `uq_org_group_code` (tenant_id, code); `uq_org_group_path` (tenant_id, path); `uq_org_group_org_code` (tenant_id, org_code) khi org_code IS NOT NULL.

**Khóa ngoại.** (parent_id, tenant_id) → `org_group` (chính bảng này).

**Ràng buộc CHECK.** `ck_org_group_tenant`; `ck_org_group_code`; `ck_org_group_type`; `ck_org_group_parent`.

**Chỉ mục.** `ix_org_group_path` (path) GIST; `ix_org_group_parent` (tenant_id, parent_id).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Trigger nghiệp vụ `tg_org_group_path` (hàm `tg_org_group_path`); Trigger nghiệp vụ `tg_org_group_subtree` (hàm `tg_org_group_subtree`).

**Ghi chú.** `path` là `ltree` do trigger tính; chỉ mục GiST phục vụ truy vấn cây con (phạm vi `ORG`). Cây này vào gói dữ liệu tenant dưới dạng `org_tree`. Nhóm còn thành viên không xóa được (ERR-12-011).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `code` | `varchar(40)` | Có |  | Mã nghiệp vụ, duy nhất trong tenant. Mẫu `^[A-Z0-9_]{1,40}$`. |
| `name` | `varchar(255)` | Có |  | Tên hiển thị. |
| `type` | `varchar(8)` | Có | `'CUSTOM'` | Một trong: `ORG`, `CUSTOM`. |
| `org_code` | `varchar(64)` | Không |  | Mã đơn vị ở PH-07 khi type = ORG (đồng bộ từ danh mục, FR-12-010); rỗng với nhóm tùy biến. |
| `parent_id` | `uuid` | Không |  |  |
| `path` | `ltree` | Có |  | Đường đi ltree gốc → nút, nhãn là mã nhóm; trigger tg_org_group_path đặt, tg_org_group_subtree cập nhật cây con khi đổi cha. |
| `active` | `boolean` | Có | `true` |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `org_group`

### 3.9. `org_group_member`

::: dac-ta
**Mục đích.** Thành viên của nhóm (FR-12-014). Nhóm còn thành viên không xóa được (ERR-12-011); vai trò không gán cho nhóm.

**FR phục vụ.** FR-12-014.

**Khóa chính.** (id).

**Duy nhất.** `uq_org_group_member` (group_id, user_id).

**Khóa ngoại.** (group_id, tenant_id) → `org_group`; (user_id, tenant_id) → `user_account`.

**Ràng buộc CHECK.** `ck_org_group_member_tenant`.

**Chỉ mục.** `ix_org_group_member_user` (tenant_id, user_id).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Bảng nối, không có cột sửa; thêm hoặc bớt thành viên là thêm hoặc xóa dòng.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `group_id` | `uuid` | Có |  |  |
| `user_id` | `uuid` | Có |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `org_group_member`

### 3.10. `custom_role`

::: dac-ta
**Mục đích.** EN-12-05 Vai trò tùy biến của tenant (FR-12-015, Đợt 2): chỉ cấu từ quyền đã có, bốn mắt (BR-07, BR-12-008). Tenant PLATFORM không có vai trò tùy biến. Mã bắt buộc tiền tố CUSTOM_ để không trùng vai trò chuẩn.

**FR phục vụ.** FR-12-015.

**Khóa chính.** (id).

**Duy nhất.** `uq_custom_role_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_custom_role_tenant`; `ck_custom_role_code`; `ck_custom_role_state`; `ck_custom_role_four_eyes`; `ck_custom_role_active`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Đợt 2 (FR-12-015), tham số `12.role.custom-enabled`. Chỉ tenant tỉnh (CHECK `ck_custom_role_tenant`). Vai trò tùy biến vào gói dữ liệu tenant (`custom_roles`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `code` | `varchar(64)` | Có |  | Mã nghiệp vụ, duy nhất trong tenant. Mẫu `^CUSTOM_[A-Z0-9_]{2,56}$`. |
| `name` | `varchar(255)` | Có |  | Tên hiển thị. |
| `description` | `varchar(2000)` | Không |  | Mô tả. |
| `state` | `varchar(14)` | Có | `'DRAFT'` | Một trong: `DRAFT`, `PENDING_REVIEW`, `ACTIVE`, `DISABLED`. |
| `submitted_by` | `varchar(64)` | Không |  | Người gửi duyệt (mã người dùng). |
| `approved_by` | `varchar(64)` | Không |  | Người duyệt; khác người đề nghị hoặc người soạn (bốn mắt, CHECK). |
| `approved_at` | `timestamptz` | Không |  | Thời điểm duyệt. |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `custom_role`

### 3.11. `custom_role_permission`

::: dac-ta
**Mục đích.** Quyền PERM-{PH}-{động từ} trong vai trò tùy biến. Quyền phải có trong D02-08 và không đặc quyền (BR-12-007): dịch vụ kiểm theo permissions.json, CSDL chỉ kiểm định dạng.

**FR phục vụ.** FR-12-015.

**Khóa chính.** (id).

**Duy nhất.** `uq_custom_role_permission` (custom_role_id, permission_code).

**Khóa ngoại.** (custom_role_id, tenant_id) → `custom_role` xóa theo.

**Ràng buộc CHECK.** `ck_custom_role_permission_tenant`; `ck_custom_role_permission_code`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Quyền đặc quyền bị dịch vụ từ chối theo `permissions.json` (BR-12-007); CSDL chỉ kiểm định dạng mã quyền.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `custom_role_id` | `uuid` | Có |  |  |
| `permission_code` | `varchar(64)` | Có |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `custom_role_permission`

### 3.12. `privileged_grant`

::: dac-ta
**Mục đích.** EN-12-11 Quyền có thời hạn: vai trò đặc quyền hoặc truy cập tenant khác, tối đa 4 giờ, mã phiếu, người duyệt thứ hai (FR-12-017, BR-12-032, EVT-12-11). Dòng ACTIVE vào gói dữ liệu platform (grants); OPA kiểm hạn ở mọi quyết định. RLS mẫu G: quản trị tỉnh bị truy cập đọc được dòng có target_tenant của mình.

**FR phục vụ.** FR-12-017, 027.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (user_id, tenant_id) → `user_account`.

**Ràng buộc CHECK.** `ck_privileged_grant_tenant`; `ck_privileged_grant_cross`; `ck_privileged_grant_role`; `ck_privileged_grant_hours`; `ck_privileged_grant_state`; `ck_privileged_grant_ticket`; `ck_privileged_grant_reason`; `ck_privileged_grant_four_eyes`; `ck_privileged_grant_window`; `ck_privileged_grant_max`; `ck_privileged_grant_revoked`.

**Chỉ mục.** `ix_privileged_grant_target` (target_tenant, state, expires_at); `ix_privileged_grant_user` (tenant_id, user_id, state); `ix_privileged_grant_expiry` (expires_at) khi state = 'ACTIVE'.

**Cách ly tenant.** RLS mẫu G (FORCE): như mẫu P, đọc thêm dòng có `target_tenant` bằng tenant phiên để tỉnh bị truy cập thấy quyền đang mở vào mình; ghi chỉ ở tenant của người nhận quyền (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Giữ vĩnh viễn làm bằng chứng truy cập liên tenant. Chỉ dòng ACTIVE vào gói `platform` (`grants`); hết hạn có hiệu lực ngay vì OPA kiểm `expires_at` ở mọi quyết định (BR-12-032). Bản ghi kiểm toán đi vào chuỗi băm của tenant bị truy cập ở PH-13, không ở bảng này.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Tenant của người nhận quyền (PLATFORM với nhân sự nền tảng); khóa ngoại kép tới user_account. |
| `user_id` | `uuid` | Có |  |  |
| `role_code` | `varchar(64)` | Có |  |  |
| `target_tenant` | `varchar(16)` | Có |  | Tenant được truy cập; khác tenant_id chỉ khi người nhận thuộc PLATFORM (BR-12-031). Mẫu G cho tenant này đọc dòng. |
| `reason` | `varchar(2000)` | Có |  | Lý do (bắt buộc, độ dài tối thiểu theo CHECK). |
| `ticket_ref` | `varchar(64)` | Có |  | Mã phiếu hỗ trợ; ở bản này chỉ kiểm định dạng (Q12-15 của FRS). |
| `requested_hours` | `smallint` | Có |  | Số giờ đề nghị 1…4, trần cứng 4 giờ; tham số 12.jit.max-hours có thể thu hẹp. |
| `state` | `varchar(10)` | Có | `'REQUESTED'` | Một trong: `REQUESTED`, `ACTIVE`, `REJECTED`, `CANCELLED`, `EXPIRED`, `REVOKED`. |
| `requested_by` | `varchar(64)` | Có |  | Người đề nghị. |
| `approved_by` | `varchar(64)` | Không |  | Người duyệt; khác người đề nghị hoặc người soạn (bốn mắt, CHECK). |
| `starts_at` | `timestamptz` | Không |  |  |
| `expires_at` | `timestamptz` | Không |  | Thời điểm hết hiệu lực. |
| `decided_at` | `timestamptz` | Không |  | Thời điểm quyết định (duyệt, từ chối, thu hồi). |
| `decision_note` | `varchar(1000)` | Không |  | Ý kiến của người quyết định. |
| `revoked_by` | `varchar(64)` | Không |  | Người thu hồi. |
| `revoked_reason` | `varchar(1000)` | Không |  | Lý do thu hồi (bắt buộc khi thu hồi). |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `privileged_grant`

### 3.13. `recert_campaign`

::: dac-ta
**Mục đích.** EN-12-17 Chiến dịch rà soát quyền định kỳ (FR-12-018, Đợt 2). Một chiến dịch mở cho mỗi (loại, phạm vi) (ERR-12-031). Hạn trả lời tối đa 30 ngày, mặc định 14 (12.recert.deadline-days).

**FR phục vụ.** FR-12-018.

**Khóa chính.** (id).

**Duy nhất.** `uq_recert_campaign_code` (tenant_id, code); `uq_recert_campaign_open` (tenant_id, kind, coalesce(scope_ref, '')) khi state = 'OPEN'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_recert_campaign_tenant`; `ck_recert_campaign_kind`; `ck_recert_campaign_state`; `ck_recert_campaign_due`; `ck_recert_campaign_closed`; `ck_recert_campaign_counts`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Tác vụ `RecertScheduler` mở theo chu kỳ 90 ngày (quản trị) và 180 ngày (khác). Dữ liệu nhỏ, giữ vĩnh viễn.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `code` | `varchar(40)` | Có |  | Mã nghiệp vụ, duy nhất trong tenant. |
| `kind` | `varchar(8)` | Có |  | Một trong: `ADMIN`, `OTHER`. |
| `scope_ref` | `varchar(64)` | Không |  |  |
| `state` | `varchar(8)` | Có | `'OPEN'` | Một trong: `OPEN`, `CLOSED`. |
| `opens_at` | `timestamptz` | Có | `now()` |  |
| `due_at` | `timestamptz` | Có |  |  |
| `closed_at` | `timestamptz` | Không |  |  |
| `total_items` | `integer` | Có | `0` |  |
| `kept_items` | `integer` | Có | `0` |  |
| `revoked_items` | `integer` | Có | `0` |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `recert_campaign`

### 3.14. `recert_item`

::: dac-ta
**Mục đích.** Từng gán vai trò cần rà soát và quyết định của người quản lý trực tiếp (hoặc TA, SO của đơn vị, Q12-08). Không tự rà quyền của mình (BR-12-044); quá hạn không trả lời thì AUTO_REVOKE và gỡ gán.

**FR phục vụ.** FR-12-018.

**Khóa chính.** (id).

**Duy nhất.** `uq_recert_item` (campaign_id, assignment_id).

**Khóa ngoại.** (campaign_id, tenant_id) → `recert_campaign` xóa theo; (user_id, tenant_id) → `user_account`; (assignment_id, tenant_id) → `role_assignment`; (reviewer_user_id, tenant_id) → `user_account`.

**Ràng buộc CHECK.** `ck_recert_item_tenant`; `ck_recert_item_decision`; `ck_recert_item_no_self`; `ck_recert_item_decided`.

**Chỉ mục.** `ix_recert_item_reviewer` (tenant_id, reviewer_user_id) khi decision = 'PENDING'; `ix_recert_item_campaign` (tenant_id, campaign_id, decision).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Mục chưa trả lời sau hạn bị `RecertService.closeExpired` đặt `AUTO_REVOKE` và gỡ gán vai trò (BR-12-044).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `campaign_id` | `uuid` | Có |  |  |
| `user_id` | `uuid` | Có |  |  |
| `assignment_id` | `uuid` | Có |  |  |
| `reviewer_user_id` | `uuid` | Có |  |  |
| `decision` | `varchar(10)` | Có | `'PENDING'` | Một trong: `PENDING`, `KEEP`, `REVOKE`, `AUTO_REVOKE`. |
| `decided_at` | `timestamptz` | Không |  | Thời điểm quyết định (duyệt, từ chối, thu hồi). |
| `note` | `varchar(1000)` | Không |  |  |
| `last_reminded_at` | `timestamptz` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `recert_item`

### 3.15. `federation`

::: dac-ta
**Mục đích.** EN-12-18 (phần LDAP, AD) Liên kết thư mục của tỉnh (FR-12-026): DRAFT, PENDING_APPROVAL, ACTIVE, DISABLED. Chỉ LDAPS, chỉ-đọc, ba kiểm tra (kết nối, bind, mẫu 5 người dùng) đạt mới gửi duyệt, SO khác TA duyệt (PERM-12-approve, BR-12-029).

**FR phục vụ.** FR-12-026.

**Khóa chính.** (id).

**Duy nhất.** `uq_federation_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_federation_tenant`; `ck_federation_code`; `ck_federation_kind`; `ck_federation_ldaps`; `ck_federation_secret_ref`; `ck_federation_attr`; `ck_federation_edit_mode`; `ck_federation_sync_hours`; `ck_federation_state`; `ck_federation_tests`; `ck_federation_four_eyes`; `ck_federation_active`; `ck_federation_sync_status`.

**Chỉ mục.** `ix_federation_state` (tenant_id, state).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Không lưu bí mật bind, chỉ `secret_ref` tới OpenBao; External Secrets Operator đưa vào Keycloak (SDD §4.7). Đồng bộ thay đổi mỗi `sync_changed_hours` giờ, đồng bộ đầy đủ 03:30.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `code` | `varchar(40)` | Có |  | Mã nghiệp vụ, duy nhất trong tenant. Mẫu `^[a-z][a-z0-9-]{2,39}$`. |
| `name` | `varchar(255)` | Có |  | Tên hiển thị. |
| `kind` | `varchar(4)` | Có |  | Một trong: `LDAP`, `AD`. |
| `url` | `varchar(2048)` | Có |  |  |
| `base_dn` | `varchar(512)` | Có |  |  |
| `user_filter` | `varchar(512)` | Không |  |  |
| `bind_dn` | `varchar(512)` | Có |  |  |
| `secret_ref` | `varchar(255)` | Có |  | Đường OpenBao kv/dh/{tenant viết thường}/iam/ldap/{code} của bí mật bind; ghi một chiều, không lưu giá trị (BR-12-045). Mẫu `^kv/dh/[a-z0-9]+/iam/ldap/[a-z][a-z0-9-]+$`. |
| `ca_ref` | `varchar(255)` | Không |  |  |
| `attribute_map` | `jsonb` | Có | `'{}'` |  |
| `edit_mode` | `varchar(10)` | Có | `'READ_ONLY'` |  |
| `force_mfa` | `boolean` | Có | `false` | true: mọi người dùng nguồn này có mfa_level >= 2, dùng khi chính sách mật khẩu LDAP yếu hơn SEC-22 (đề xuất Q12-11). |
| `sync_changed_hours` | `smallint` | Có | `4` |  |
| `state` | `varchar(16)` | Có | `'DRAFT'` | Một trong: `DRAFT`, `PENDING_APPROVAL`, `ACTIVE`, `DISABLED`. |
| `test_result` | `jsonb` | Có | `'{}'` | Kết quả ba kiểm tra {connect, bind, sample} kèm thời điểm; không có mật khẩu hay bản ghi người dùng. |
| `tests_passed_at` | `timestamptz` | Không |  |  |
| `proposed_by` | `varchar(64)` | Không |  | Người đề nghị. |
| `approved_by` | `varchar(64)` | Không |  | Người duyệt; khác người đề nghị hoặc người soạn (bốn mắt, CHECK). |
| `approved_at` | `timestamptz` | Không |  | Thời điểm duyệt. |
| `last_sync_at` | `timestamptz` | Không |  |  |
| `last_sync_status` | `varchar(8)` | Không |  |  |
| `last_sync_users` | `integer` | Không |  |  |
| `disabled_reason` | `varchar(1000)` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `federation`

### 3.16. `saml_client`

::: dac-ta
**Mục đích.** EN-12-18 (phần SAML) Ứng dụng SAML 2 cũ dùng chung phiên SSO với OIDC (FR-12-025). Siêu dữ liệu nhận bằng tệp tải lên, không tự tải URL (SSRF, SEC-45); redirect URI https, cấm ký tự đại diện; chữ ký SHA-256 bắt buộc; SO duyệt mới ENABLED.

**FR phục vụ.** FR-12-025.

**Khóa chính.** (id).

**Duy nhất.** `uq_saml_client_entity` (tenant_id, entity_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_saml_client_tenant`; `ck_saml_client_urls`; `ck_saml_client_hash`; `ck_saml_client_nameid`; `ck_saml_client_sig`; `ck_saml_client_lifespan`; `ck_saml_client_state`; `ck_saml_client_four_eyes`; `ck_saml_client_enabled`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Dành cho ứng dụng cũ (FR-12-025); siêu dữ liệu XML nhận bằng tệp tải lên, không tự tải URL (SEC-45).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `entity_id` | `varchar(512)` | Có |  |  |
| `name` | `varchar(255)` | Có |  | Tên hiển thị. |
| `acs_urls` | `text[]` | Có |  |  |
| `metadata_ref` | `varchar(512)` | Không |  |  |
| `metadata_sha256` | `char(64)` | Không |  |  |
| `name_id_format` | `varchar(16)` | Có | `'persistent'` |  |
| `signature_algorithm` | `varchar(12)` | Có | `'RSA_SHA256'` |  |
| `assertion_lifespan_s` | `integer` | Có | `300` |  |
| `keycloak_client_id` | `uuid` | Không |  |  |
| `state` | `varchar(16)` | Có | `'DRAFT'` | Một trong: `DRAFT`, `PENDING_APPROVAL`, `ENABLED`, `DISABLED`. |
| `proposed_by` | `varchar(64)` | Không |  | Người đề nghị. |
| `approved_by` | `varchar(64)` | Không |  | Người duyệt; khác người đề nghị hoặc người soạn (bốn mắt, CHECK). |
| `approved_at` | `timestamptz` | Không |  | Thời điểm duyệt. |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `saml_client`

### 3.17. `vneid_link`

::: dac-ta
**Mục đích.** EN-12-18 (phần VNeID) Liên kết người dùng với định danh điện tử, Đợt 2 (FR-12-028). Chỉ lưu băm HMAC-SHA256 có khóa của định danh, không lưu số định danh rõ (BR-12-045, Luật BVDLCN); chỉ liên kết vào tài khoản có sẵn, không tự tạo (BR-12-029); một định danh một tài khoản (ERR-12-034).

**FR phục vụ.** FR-12-028.

**Khóa chính.** (id).

**Duy nhất.** `uq_vneid_link_subject` (tenant_id, subject_hash) khi state = 'ACTIVE'; `uq_vneid_link_user` (tenant_id, user_id) khi state = 'ACTIVE'.

**Khóa ngoại.** (user_id, tenant_id) → `user_account`.

**Ràng buộc CHECK.** `ck_vneid_link_tenant`; `ck_vneid_link_hash`; `ck_vneid_link_state`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Đợt 2, cờ `12.vneid.enabled` mặc định tắt. Chỉ lưu băm HMAC của định danh; khóa HMAC ở OpenBao.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `user_id` | `uuid` | Có |  |  |
| `subject_hash` | `char(64)` | Có |  | HMAC-SHA256 hex của sub do VNeID cấp, khóa ở OpenBao (kv/dh/{tenant}/iam/vneid-hmac); đạt ở Q12-02. |
| `state` | `varchar(8)` | Có | `'ACTIVE'` | Một trong: `ACTIVE`, `UNLINKED`. |
| `linked_at` | `timestamptz` | Có | `now()` |  |
| `unlinked_at` | `timestamptz` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `vneid_link`

### 3.18. `client`

::: dac-ta
**Mục đích.** EN-12-08 Danh tính máy của một HTTT (kind SYSTEM, cấp qua PH-01) hoặc ứng dụng sandbox (SANDBOX, PH-15, Đợt 2). Một client đang sống cho mỗi HTTT (BR-12-024, ERR-12-018); phương thức xác thực không thấp hơn mức hợp đồng: Hạn chế trở lên cấm client_secret, Nhạy cảm bắt buộc mTLS. Không xóa vật lý; REVOKED vĩnh viễn, mã client không dùng lại.

**FR phục vụ.** FR-12-008, 030…033, 036.

**Khóa chính.** (id).

**Duy nhất.** `uq_client_client_id` (tenant_id, client_id); `uq_client_system` (tenant_id, system_code) khi system_code IS NOT NULL AND state <> 'REVOKED'; `uq_client_provision_key` (tenant_id, provision_key) khi provision_key IS NOT NULL.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_client_tenant`; `ck_client_client_id`; `ck_client_kind`; `ck_client_owner`; `ck_client_sandbox_level`; `ck_client_auth`; `ck_client_level`; `ck_client_level_auth`; `ck_client_sensitive_mtls`; `ck_client_state`; `ck_client_suspended`; `ck_client_revoked`; `ck_client_enabled`; `ck_client_thumbprint`.

**Chỉ mục.** `ix_client_state` (tenant_id, state, auth_method); `ix_client_inactivity` (tenant_id, last_used_at) khi state = 'ENABLED'; `ix_client_org` (tenant_id, org_code).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Không xóa vật lý, kết thúc bằng trạng thái (trigger `tg_client_no_delete`, BR-12-035).

**Ghi chú.** Không lưu bí mật. Client `REVOKED` giữ vĩnh viễn, mã client không dùng lại. Trigger `tg_client_no_delete` và quyền DELETE bị thu hồi. `last_used_at` do bộ tiêu thụ EVT-12-16 cập nhật, nguồn của tự tạm ngừng 90 ngày (BR-12-020).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `client_id` | `varchar(64)` | Có |  | clientId ở Keycloak: mã HTTT viết thường; client cấp lại sau khi REVOKED mang hậu tố -r{n} vì mã cũ không dùng lại (Q12-53). Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `kind` | `varchar(8)` | Có | `'SYSTEM'` | Một trong: `SYSTEM`, `SANDBOX`. |
| `system_code` | `varchar(64)` | Không |  | Mã HTTT ở PH-01; không khóa ngoại vì khác schema. |
| `app_ref` | `varchar(64)` | Không |  |  |
| `org_code` | `varchar(64)` | Có |  |  |
| `name` | `varchar(255)` | Có |  | Tên hiển thị. |
| `auth_method` | `varchar(16)` | Có |  |  |
| `contract_level` | `varchar(10)` | Có |  |  |
| `state` | `varchar(12)` | Có | `'PROVISIONING'` | Một trong: `PROVISIONING`, `ENABLED`, `SUSPENDED`, `REVOKED`, `FAILED`. |
| `credential_ready` | `boolean` | Có | `false` | false khi mTLS hoặc private_key_jwt chưa có chứng thư, khóa công khai: client ENABLED nhưng chưa cấp token được (FR-12-033). |
| `suspended_reason` | `varchar(1000)` | Không |  |  |
| `suspended_auto` | `boolean` | Có | `false` | true khi hệ thống tự tạm ngừng vì 90 ngày không gọi: tiếp tục cần đầu mối xác nhận (ERR-12-020). |
| `revoked_at` | `timestamptz` | Không |  | Thời điểm thu hồi. |
| `revoked_reason` | `varchar(1000)` | Không |  | Lý do thu hồi (bắt buộc khi thu hồi). |
| `last_used_at` | `timestamptz` | Không |  |  |
| `secret_expires_at` | `timestamptz` | Không |  |  |
| `cert_thumbprint` | `char(64)` | Không |  | SHA-256 hex của chứng thư hiện hành, để APISIX đối chiếu cnf.x5t#S256 (EVT-12-08); bản gốc ở client_credential. |
| `keycloak_client_id` | `uuid` | Không |  |  |
| `provision_key` | `varchar(128)` | Không |  | Idempotency-Key của lời gọi cấp client từ saga PH-01; cùng khóa thì tìm lại client dở (SDD §4.8). |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `client`

### 3.19. `client_scope`

::: dac-ta
**Mục đích.** EN-12-09 Scope của client, mỗi dòng gắn nguồn duyệt (FR-12-036). CHECK bảo đảm mỗi nguồn chỉ đặt đúng loại scope của mình: PH-02 api:, PH-09 purpose:, PH-10 topic:, PH-07 rdm:, PH-19 payment:; scope iam:, event: là INTERNAL (BR-12-025, ERR-12-019). Thay theo nguồn bằng ScopeSynchronizer.

**FR phục vụ.** FR-12-035, 036, 051.

**Khóa chính.** (id).

**Duy nhất.** `uq_client_scope` (client_pk, scope).

**Khóa ngoại.** (client_pk, tenant_id) → `client` xóa theo.

**Ràng buộc CHECK.** `ck_client_scope_tenant`; `ck_client_scope_source`; `ck_client_scope_prefix`.

**Chỉ mục.** `ix_client_scope_source` (tenant_id, client_pk, source).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Thay theo nguồn bằng `ScopeSynchronizer`: xóa phần scope của nguồn rồi chèn tập mới trong một giao dịch, giữ phần của nguồn khác. Vào gói tenant dưới dạng `client_scopes`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `client_pk` | `uuid` | Có |  |  |
| `scope` | `varchar(255)` | Có |  |  |
| `source` | `varchar(8)` | Có |  | Một trong: `PH-02`, `PH-07`, `PH-09`, `PH-10`, `PH-19`, `INTERNAL`. |
| `source_ref` | `varchar(128)` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `client_scope`

### 3.20. `client_credential`

::: dac-ta
**Mục đích.** Siêu dữ liệu thông tin xác thực của client: chứng thư mTLS (dấu vân tay), khóa công khai (kid), bí mật chia sẻ (chỉ hạn và wrap_accessor). KHÔNG chứa bí mật hay khóa riêng (BR-12-023, NFR-12-020). Bí mật hết hạn ≤ 180 ngày; hai dòng ACTIVE và TRANSITION cùng loại trong lúc xoay (FR-12-034).

**FR phục vụ.** FR-12-033, 034.

**Khóa chính.** (id).

**Duy nhất.** `uq_client_credential_current` (client_pk, kind, state) khi state IN ('ACTIVE', 'TRANSITION'); `uq_client_credential_thumb` (tenant_id, thumbprint) khi thumbprint IS NOT NULL AND state <> 'RETIRED'.

**Khóa ngoại.** (client_pk, tenant_id) → `client` xóa theo.

**Ràng buộc CHECK.** `ck_client_credential_tenant`; `ck_client_credential_kind`; `ck_client_credential_state`; `ck_client_credential_cert`; `ck_client_credential_jwks`; `ck_client_credential_secret`; `ck_client_credential_transition`.

**Chỉ mục.** `ix_client_credential_expiry` (not_after) khi state <> 'RETIRED'.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Chỉ siêu dữ liệu (dấu vân tay, hạn, `wrap_accessor`), không có bí mật, khóa riêng hay chứng thư đầy đủ. Dòng `RETIRED` giữ 12 tháng rồi xóa (mục 8).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `client_pk` | `uuid` | Có |  |  |
| `kind` | `varchar(8)` | Có |  | Một trong: `CERT`, `JWKS_KEY`, `SECRET`. |
| `state` | `varchar(10)` | Có | `'ACTIVE'` | Một trong: `ACTIVE`, `TRANSITION`, `RETIRED`. |
| `thumbprint` | `char(64)` | Không |  |  |
| `subject_dn` | `varchar(1024)` | Không |  |  |
| `kid` | `varchar(128)` | Không |  |  |
| `key_alg` | `varchar(16)` | Không |  |  |
| `not_before` | `timestamptz` | Không |  |  |
| `not_after` | `timestamptz` | Không |  |  |
| `wrap_accessor` | `varchar(128)` | Không |  | Accessor của token bọc OpenBao (sys/wrapping/lookup) để tra tình trạng giao bí mật mà không mở được bí mật; không phải wrappingToken. |
| `transition_until` | `timestamptz` | Không |  |  |
| `retired_at` | `timestamptz` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `client_credential`

### 3.21. `service_account`

::: dac-ta
**Mục đích.** EN-12-10 Tài khoản dịch vụ của đơn vị triển khai ở realm dh-platform (FR-12-037), tenant PLATFORM. Khai báo ở kho cấu hình qua yêu cầu hợp nhất có người duyệt thứ hai; xác thực private_key_jwt bằng khóa ký ở OpenBao transit (khóa riêng không rời OpenBao), xoay 90 ngày.

**FR phục vụ.** FR-12-037.

**Khóa chính.** (id).

**Duy nhất.** `uq_service_account_code` (tenant_id, account_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_service_account_tenant`; `ck_service_account_code`; `ck_service_account_du`; `ck_service_account_scopes`; `ck_service_account_state`; `ck_service_account_enabled`; `ck_service_account_rotation`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Tenant `PLATFORM`. Khóa riêng không rời OpenBao (`transit/sign/dh-svc-{account}`); chỉ khóa công khai ở JWKS của client. Khai báo qua yêu cầu hợp nhất có người duyệt thứ hai.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có | `'PLATFORM'` | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `account_code` | `varchar(48)` | Có |  |  |
| `du_code` | `varchar(32)` | Có |  |  |
| `description` | `varchar(1000)` | Không |  | Mô tả. |
| `scopes` | `text[]` | Có |  | Scope máy nội bộ: iam:client-provision, iam:dev-client, iam:realm-provision, iam:revocation-read, iam:directory-read, iam:decide, iam:policy-data-read và scope nội bộ của PH khác (event:*). |
| `state` | `varchar(10)` | Có | `'PENDING'` | Một trong: `PENDING`, `ENABLED`, `SUSPENDED`, `REVOKED`. |
| `declaration_ref` | `varchar(255)` | Có |  |  |
| `approved_by` | `varchar(64)` | Không |  | Người duyệt; khác người đề nghị hoặc người soạn (bốn mắt, CHECK). |
| `kid` | `varchar(128)` | Không |  |  |
| `key_rotated_at` | `timestamptz` | Không |  |  |
| `rotate_due_at` | `timestamptz` | Không |  |  |
| `keycloak_client_id` | `uuid` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `service_account`

### 3.22. `revocation_feed_version`

::: dac-ta
**Mục đích.** Bộ đếm phiên bản toàn cục của danh sách chặn (ETag của API-12-079). Một dòng duy nhất, không có tenant_id và không bật RLS vì chỉ là số thứ tự, không chứa dữ liệu nghiệp vụ; trigger của revocation_entry tăng sau mỗi thay đổi.

**FR phục vụ.** FR-12-040.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_revocation_feed_version_single`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS. Bảng kỹ thuật không có `tenant_id` và không chứa dữ liệu nghiệp vụ (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Một dòng toàn cục. Trigger `tg_revocation_entry_bump` (mức câu lệnh) tăng `version` sau mỗi lệnh ghi `revocation_entry`; API-12-079 dùng làm ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `smallint` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `version` | `bigint` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |

: Cột của bảng `revocation_feed_version`

### 3.23. `revocation_entry`

::: dac-ta
**Mục đích.** EN-12-19 Danh sách chặn: SUB (người dùng, mọi token có iat < not_before), CLIENT (theo azp), JTI (một token, RFC 7009). Ghi TRƯỚC khi chạm Keycloak với block_all = true; khi Keycloak xác nhận hạ cờ và đặt hạn 330 giây (FR-12-040, BR-12-028, EVT-12-05). Hiệu lực tại cổng ≤ 60 giây (NFR-12-005).

**FR phục vụ.** FR-12-005, 024, 031, 040.

**Khóa chính.** (id).

**Duy nhất.** `uq_revocation_entry_blocking` (tenant_id, kind, value) khi block_all.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_revocation_entry_tenant`; `ck_revocation_entry_kind`; `ck_revocation_entry_value`; `ck_revocation_entry_reason`; `ck_revocation_entry_expiry`; `ck_revocation_entry_no_self`.

**Chỉ mục.** `ix_revocation_entry_lookup` (tenant_id, kind, value, not_before DESC); `ix_revocation_entry_expiry` (expires_at) khi expires_at IS NOT NULL; `ix_revocation_entry_unconfirmed` (created_at) khi block_all.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Trigger nghiệp vụ `tg_revocation_entry_bump` (hàm `tg_revocation_bump`).

**Ghi chú.** Ghi trước khi gọi Keycloak (`block_all = true`). Dòng đã hạ cờ hết hạn sau 330 giây và tác vụ dọn xóa sau 7 ngày. Cổng đọc danh sách của mọi tenant bằng cách lặp từng tenant, không có ngoại lệ RLS (Q12-52).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `kind` | `varchar(6)` | Có |  | Một trong: `SUB`, `CLIENT`, `JTI`. |
| `value` | `varchar(128)` | Có |  |  |
| `not_before` | `timestamptz` | Có | `now()` |  |
| `block_all` | `boolean` | Có | `true` | true: từ chối mọi token của chủ thể bất kể iat vì Keycloak chưa xác nhận vô hiệu (chủ thể còn xin được token mới). Khi hạ cờ phải có expires_at và keycloak_confirmed_at. |
| `expires_at` | `timestamptz` | Không |  | Hạn giữ sau khi Keycloak xác nhận = lúc xác nhận + 330 giây (token 300 giây cộng dung sai 30 giây); rỗng khi còn block_all. |
| `reason` | `varchar(1000)` | Có |  | Lý do (bắt buộc, độ dài tối thiểu theo CHECK). |
| `keycloak_confirmed_at` | `timestamptz` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người thu hồi; với kind SUB khác chủ thể bị thu hồi (BR-12-033, ERR-12-013). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `revocation_entry`

### 3.24. `node_heartbeat`

::: dac-ta
**Mục đích.** Phiên bản danh sách chặn và bản gói mà từng nút cổng, DU, OPA đã áp (tiêu đề X-DH-Applied-Version, plugin status của OPA). Dùng chung (COMMON): quản trị tỉnh thấy "đã áp dụng ở n/m nút cổng"; chỉ phiên PLATFORM ghi. Nút im lặng quá 60 giây kể từ phiên bản mới thì cảnh báo nghiêm trọng.

**FR phục vụ.** FR-12-040, 051, 054.

**Khóa chính.** (id).

**Duy nhất.** `uq_node_heartbeat_node` (node_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_node_heartbeat_tenant`; `ck_node_heartbeat_kind`; `ck_node_heartbeat_bundles`.

**Chỉ mục.** `ix_node_heartbeat_seen` (node_kind, last_seen_at DESC).

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và dòng `COMMON`; chỉ phiên `PLATFORM` được ghi dòng `COMMON` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Dữ liệu `COMMON`. Chỉ phiên `PLATFORM` ghi (bộ tiếp nhận `X-DH-Applied-Version` và plugin `status` của OPA). Dòng nút im lặng quá 24 giờ bị xóa.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có | `'COMMON'` | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `node_id` | `varchar(128)` | Có |  |  |
| `node_kind` | `varchar(8)` | Có |  |  |
| `applied_revocation` | `bigint` | Có | `0` |  |
| `bundle_revisions` | `jsonb` | Có | `'{}'` |  |
| `first_seen_at` | `timestamptz` | Có | `now()` |  |
| `last_seen_at` | `timestamptz` | Có | `now()` |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `node_heartbeat`

### 3.25. `realm_state`

::: dac-ta
**Mục đích.** EN-12-20 Trạng thái realm Keycloak của từng tenant (FR-12-041…043): PROVISIONING, ACTIVE, SUSPENDED, READ_ONLY, DELETED. Dữ liệu của nền tảng nên tenant_id luôn là PLATFORM, tenant mà realm phục vụ nằm ở tenant_code; chỉ PA (PERM-12-realm-admin) thao tác. Cấu hình bảo mật chỉ đổi qua GitOps (BR-12-038).

**FR phục vụ.** FR-12-039, 041…043.

**Khóa chính.** (id).

**Duy nhất.** `uq_realm_state_tenant` (tenant_code); `uq_realm_state_realm` (realm_name).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_realm_state_tenant`; `ck_realm_state_code`; `ck_realm_state_name`; `ck_realm_state_state`; `ck_realm_state_drift`; `ck_realm_state_hold`; `ck_realm_state_commit`; `ck_realm_state_baseline`; `ck_realm_state_active`; `ck_realm_state_deleted`; `ck_realm_state_reason`.

**Chỉ mục.** `ix_realm_state_drift` (drift_status) khi drift_status IN ('DRIFTED', 'HELD').

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Tenant `PLATFORM` (dữ liệu của nền tảng); tenant mà realm phục vụ nằm ở `tenant_code`. Cấu hình bảo mật chỉ đổi qua GitOps, `baseline_snapshot` là mức chuẩn so lệch hằng giờ. Realm `DELETED` giữ dòng vĩnh viễn.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có | `'PLATFORM'` | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `tenant_code` | `varchar(16)` | Có |  |  |
| `realm_name` | `varchar(40)` | Có |  |  |
| `state` | `varchar(12)` | Có | `'PROVISIONING'` | Một trong: `PROVISIONING`, `ACTIVE`, `SUSPENDED`, `READ_ONLY`, `DELETED`. |
| `template_version` | `varchar(32)` | Không |  |  |
| `git_commit` | `char(40)` | Không |  | Mã commit ở kho Git cấu hình hoặc `dh-policies` để truy vết. |
| `drift_status` | `varchar(8)` | Có | `'UNKNOWN'` | IN_SYNC khớp mẫu Git; DRIFTED lệch, tự áp lại sau 15 phút nếu 12.realm.auto-reconcile; HELD giữ tạm có lý do, người xác nhận và hạn. |
| `drift_fields` | `jsonb` | Có | `'[]'` |  |
| `baseline_hash` | `char(64)` | Không |  |  |
| `baseline_snapshot` | `jsonb` | Không |  | Bản chụp chuẩn hóa (chỉ trường bảo mật cho phép) lập sau mỗi lần áp mẫu, dùng so lệch hằng giờ (SDD §4.10); không chứa bí mật hay người dùng. |
| `baseline_at` | `timestamptz` | Không |  |  |
| `last_check_at` | `timestamptz` | Không |  |  |
| `last_apply_at` | `timestamptz` | Không |  |  |
| `hold_reason` | `varchar(1000)` | Không |  |  |
| `hold_by` | `varchar(64)` | Không |  |  |
| `hold_until` | `timestamptz` | Không |  |  |
| `state_reason` | `varchar(1000)` | Không |  |  |
| `signing_key_rotated_at` | `timestamptz` | Không |  |  |
| `provisioned_at` | `timestamptz` | Không |  |  |
| `deleted_at` | `timestamptz` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `realm_state`

### 3.26. `realm_provision_step`

::: dac-ta
**Mục đích.** Bước đã làm của saga tạo realm (FR-12-041). Gọi lại cùng khóa lũy đẳng thì tiếp tục từ bước dở; tám bước theo SDD §4.10. detail không chứa bí mật (bí mật ghi một chiều vào OpenBao).

**FR phục vụ.** FR-12-041.

**Khóa chính.** (id).

**Duy nhất.** `uq_realm_provision_step` (realm_id, step_code).

**Khóa ngoại.** (realm_id, tenant_id) → `realm_state` xóa theo.

**Ràng buộc CHECK.** `ck_realm_provision_step_tenant`; `ck_realm_provision_step_code`; `ck_realm_provision_step_status`; `ck_realm_provision_step_detail`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Tám bước lũy đẳng của saga tạo realm; xóa cùng realm đang `PROVISIONING` khi bù trừ.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có | `'PLATFORM'` | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `realm_id` | `uuid` | Có |  |  |
| `step_code` | `varchar(24)` | Có |  |  |
| `status` | `varchar(8)` | Có | `'RUNNING'` | Một trong: `RUNNING`, `DONE`, `FAILED`. |
| `idempotency_key` | `varchar(128)` | Có |  |  |
| `error_code` | `varchar(16)` | Không |  |  |
| `detail` | `jsonb` | Có | `'{}'` | Chi tiết dạng JSON, không chứa bí mật (CHECK). |
| `started_at` | `timestamptz` | Có | `now()` |  |
| `finished_at` | `timestamptz` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `realm_provision_step`

### 3.27. `tenant_merge_step`

::: dac-ta
**Mục đích.** Chuyển định danh khi sáp nhập tenant (FR-12-019, Đợt 2): mỗi người dùng nguồn là một bước lũy đẳng nên chạy lại không tạo trùng. Dữ liệu điều phối của nền tảng nên tenant_id là PLATFORM; người dùng nguồn và đích ở hai tenant khác nhau nên không có khóa ngoại tới user_account.

**FR phục vụ.** FR-12-019.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_merge_step` (merge_code, source_user_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_merge_step_tenant`; `ck_tenant_merge_step_status`; `ck_tenant_merge_step_conflict`; `ck_tenant_merge_step_done`; `ck_tenant_merge_step_json`.

**Chỉ mục.** `ix_tenant_merge_step_status` (merge_code, status).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Đợt 2. Không có khóa ngoại tới `user_account` vì người dùng nguồn và đích ở hai tenant. Giữ 12 tháng sau khi sáp nhập xong (giả định).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có | `'PLATFORM'` | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `merge_code` | `varchar(40)` | Có |  |  |
| `source_tenant` | `varchar(16)` | Có |  |  |
| `target_tenant` | `varchar(16)` | Có |  |  |
| `source_user_id` | `uuid` | Có |  |  |
| `target_user_id` | `uuid` | Không |  |  |
| `status` | `varchar(8)` | Có | `'PLANNED'` | Một trong: `PLANNED`, `CONFLICT`, `DONE`, `FAILED`. |
| `conflict_type` | `varchar(24)` | Không |  |  |
| `role_mapping` | `jsonb` | Có | `'{}'` |  |
| `detail` | `jsonb` | Có | `'{}'` | Chi tiết dạng JSON, không chứa bí mật (CHECK). |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `tenant_merge_step`

### 3.28. `policy`

::: dac-ta
**Mục đích.** EN-12-12 (phần chính sách) Một mã chính sách Rego, ví dụ base-authz. Phạm vi PLATFORM (mọi tenant, tenant_id = PLATFORM) hoặc TENANT (một tỉnh, chỉ thêm luật chặt hơn, BR-12-007). Nội dung nằm ở policy_version. Chính sách gốc is_root không thu hồi được (ERR-12-027).

**FR phục vụ.** FR-12-052, 055.

**Khóa chính.** (id).

**Duy nhất.** `uq_policy_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_policy_tenant`; `ck_policy_code`; `ck_policy_scope`; `ck_policy_root`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Không xóa vật lý, kết thúc bằng trạng thái (trigger `tg_policy_no_delete`, BR-12-035).

**Ghi chú.** Không xóa vật lý. Chính sách gốc `base-authz` (`is_root`) tạo bằng changeset khởi tạo ở tenant `PLATFORM`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `code` | `varchar(64)` | Có |  | Mã nghiệp vụ, duy nhất trong tenant. Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `scope` | `varchar(8)` | Có |  | Một trong: `PLATFORM`, `TENANT`. |
| `name` | `varchar(255)` | Có |  | Tên hiển thị. |
| `description` | `varchar(2000)` | Không |  | Mô tả. |
| `is_root` | `boolean` | Có | `false` | true với base-authz: gói gốc bảo đảm từ chối mặc định, từ chối thắng cho phép và cách ly tenant; không thu hồi, không quay lui về rỗng. |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `policy`

### 3.29. `policy_version`

::: dac-ta
**Mục đích.** EN-12-12 Phiên bản chính sách Rego, bất biến sau khi gửi duyệt (nội dung chỉ sửa được ở DRAFT, CHANGES_REQUESTED). Máy trạng thái, điều kiện gửi duyệt (kiểm thử đạt, chạy khô đúng content_hash), bốn mắt và xác nhận tác động lớn đều chốt ở trigger tg_policy_version_guard (ADR-069, BR-12-008…010). Mỗi mã có đúng một PUBLISHED. Không xóa vật lý.

**FR phục vụ.** FR-12-052…055.

**Khóa chính.** (id).

**Duy nhất.** `uq_policy_version_no` (policy_id, version_no); `uq_policy_version_published` (tenant_id, policy_id) khi state = 'PUBLISHED'.

**Khóa ngoại.** (policy_id, tenant_id) → `policy`.

**Ràng buộc CHECK.** `ck_policy_version_tenant`; `ck_policy_version_no`; `ck_policy_version_content`; `ck_policy_version_hash`; `ck_policy_version_state`; `ck_policy_version_submitted`; `ck_policy_version_four_eyes`; `ck_policy_version_approved`; `ck_policy_version_published`; `ck_policy_version_revoked`; `ck_policy_version_commit`.

**Chỉ mục.** `ix_policy_version_state` (tenant_id, state, updated_at DESC); `ix_policy_version_pending` (tenant_id, submitted_at) khi state = 'PENDING_REVIEW'; `ix_policy_version_hash` (content_hash).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Không xóa vật lý, kết thúc bằng trạng thái (trigger `tg_policy_version_no_delete`, BR-12-035); Trigger nghiệp vụ `tg_policy_version_0hash` (hàm `tg_policy_version_hash`); Trigger nghiệp vụ `tg_policy_version_guard` (hàm `tg_policy_version_guard`).

**Ghi chú.** Máy trạng thái ở trigger `tg_policy_version_guard`; nội dung bất biến sau gửi duyệt; `content_hash` do trigger `tg_policy_version_0hash` tính. Giữ vĩnh viễn (NFR-12-030); `GitMirror` ghi bản sao PUBLISHED vào kho `dh-policies`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `policy_id` | `uuid` | Có |  |  |
| `version_no` | `integer` | Có |  |  |
| `content` | `text` | Có |  | Mã Rego, tối đa 256 KiB (PolicyLinter kiểm trước khi chạm policy-runner). |
| `content_hash` | `char(64)` | Có |  | SHA-256 hex của content (UTF-8), do trigger tg_policy_version_hash tính; kết quả kiểm thử và chạy khô gắn với băm này nên sửa một ký tự là mất hiệu lực (BR-12-009). |
| `state` | `varchar(18)` | Có | `'DRAFT'` | Một trong: `DRAFT`, `PENDING_REVIEW`, `CHANGES_REQUESTED`, `APPROVED`, `PUBLISHED`, `SUPERSEDED`, `REVOKED`, `DISCARDED`. |
| `author` | `varchar(64)` | Có |  | Người soạn (tạo bản nháp); người đóng góp khác ở policy_version_contributor. |
| `submitted_by` | `varchar(64)` | Không |  | Người gửi duyệt (mã người dùng). |
| `submitted_at` | `timestamptz` | Không |  | Thời điểm gửi duyệt. |
| `approved_by` | `varchar(64)` | Không |  | Người duyệt; khác người đề nghị hoặc người soạn (bốn mắt, CHECK). |
| `approved_at` | `timestamptz` | Không |  | Thời điểm duyệt. |
| `review_note` | `varchar(2000)` | Không |  | Ý kiến của người duyệt. |
| `high_impact_confirmed` | `boolean` | Có | `false` | Người duyệt đã xác nhận bổ sung khi chạy khô đổi quá ngưỡng hoặc có trường hợp từ chối sang cho phép (BR-12-011, ERR-12-029). |
| `git_commit` | `char(40)` | Không |  | Mã commit ở kho Git cấu hình hoặc `dh-policies` để truy vết. |
| `bundle_revision` | `varchar(64)` | Không |  | bundleRevision của gói đầu tiên chứa phiên bản này, ví dụ t68-20261126-0153; đặt khi PUBLISHED. |
| `published_at` | `timestamptz` | Không |  | Thời điểm có hiệu lực (PUBLISHED). |
| `revoked_by` | `varchar(64)` | Không |  | Người thu hồi. |
| `revoked_reason` | `varchar(1000)` | Không |  | Lý do thu hồi (bắt buộc khi thu hồi). |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `policy_version`

### 3.30. `policy_version_contributor`

::: dac-ta
**Mục đích.** Người đóng góp mỗi phiên bản, ghi ở lần lưu nháp đầu tiên của từng người. Người duyệt không được nằm trong danh sách này (BR-12-008). Chỉ thêm.

**FR phục vụ.** FR-12-052, 054.

**Khóa chính.** (id).

**Duy nhất.** `uq_policy_version_contributor` (version_id, user_ref).

**Khóa ngoại.** (version_id, tenant_id) → `policy_version`.

**Ràng buộc CHECK.** `ck_policy_version_contributor_tenant`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_policy_version_contributor_append_only`).

**Ghi chú.** Chỉ thêm; người duyệt không được nằm trong bảng này (kiểm ở `tg_policy_version_guard`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `version_id` | `uuid` | Có |  |  |
| `user_ref` | `varchar(64)` | Có |  |  |
| `first_saved_at` | `timestamptz` | Có | `now()` |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `policy_version_contributor`

### 3.31. `policy_test_case`

::: dac-ta
**Mục đích.** EN-12-13 Ca kiểm thử của một chính sách (đầu vào input JSON, kết quả mong đợi {allow, reason}); mỗi luật mới cần ít nhất một ca dương (POSITIVE: mong allow) và một ca âm (NEGATIVE: mong từ chối) (FR-12-052). Bản sao ở Git dh-policies.

**FR phục vụ.** FR-12-052.

**Khóa chính.** (id).

**Duy nhất.** `uq_policy_test_case` (policy_id, name).

**Khóa ngoại.** (policy_id, tenant_id) → `policy`.

**Ràng buộc CHECK.** `ck_policy_test_case_tenant`; `ck_policy_test_case_kind`; `ck_policy_test_case_json`; `ck_policy_test_case_no_secret`; `ck_policy_test_case_size`.

**Chỉ mục.** `ix_policy_test_case_policy` (tenant_id, policy_id) khi active.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Ca kiểm thử theo chính sách, không theo phiên bản: cùng bộ ca chạy lại ở mọi phiên bản. Bản sao ở Git `dh-policies`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `policy_id` | `uuid` | Có |  |  |
| `name` | `varchar(255)` | Có |  | Tên hiển thị. |
| `kind` | `varchar(8)` | Có |  | Một trong: `POSITIVE`, `NEGATIVE`. |
| `input` | `jsonb` | Có |  |  |
| `expected` | `jsonb` | Có |  |  |
| `description` | `varchar(2000)` | Không |  | Mô tả. |
| `active` | `boolean` | Có | `true` |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `policy_test_case`

### 3.32. `policy_test_run`

::: dac-ta
**Mục đích.** Kết quả một lần chạy opa test gắn với content_hash và bundleRevision của gói gốc (FR-12-052, BR-12-009). passed = true chỉ khi mọi ca đạt, có ít nhất một ca dương và một ca âm, độ phủ dòng ≥ 90% (CHECK ck_policy_test_run_passed, SEC-26). Chỉ thêm.

**FR phục vụ.** FR-12-052, 054.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (version_id, tenant_id) → `policy_version`.

**Ràng buộc CHECK.** `ck_policy_test_run_tenant`; `ck_policy_test_run_hash`; `ck_policy_test_run_counts`; `ck_policy_test_run_coverage`; `ck_policy_test_run_passed`; `ck_policy_test_run_time`; `ck_policy_test_run_trace`.

**Chỉ mục.** `ix_policy_test_run_version` (tenant_id, version_id, content_hash, finished_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_policy_test_run_append_only`).

**Ghi chú.** Chỉ thêm; ứng dụng không có quyền UPDATE. Giữ cùng vòng đời phiên bản chính sách.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `version_id` | `uuid` | Có |  |  |
| `content_hash` | `char(64)` | Có |  |  |
| `base_bundle_revision` | `varchar(64)` | Có |  |  |
| `passed` | `boolean` | Có |  |  |
| `total_cases` | `integer` | Có |  |  |
| `positive_cases` | `integer` | Có |  |  |
| `negative_cases` | `integer` | Có |  |  |
| `failed_cases` | `integer` | Có |  |  |
| `coverage_pct` | `numeric(5,2)` | Có |  |  |
| `started_at` | `timestamptz` | Có |  |  |
| `finished_at` | `timestamptz` | Có |  |  |
| `runner_log_ref` | `varchar(512)` | Không |  |  |
| `trace_id` | `char(32)` | Có |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `policy_test_run`

### 3.33. `policy_dryrun_report`

::: dac-ta
**Mục đích.** Báo cáo chạy khô trên lưu lượng thật gần đây (FR-12-053): số mẫu, tỷ lệ quyết định đổi (cột sinh changed_ratio), số ca từ chối sang cho phép (nới quyền), 20 ví dụ tiêu biểu trong summary. Mẫu đã che, không dữ liệu cá nhân (SEC-32, SEC-37). Giữ 12 tháng (NFR-12-030); sau khi DONE hoặc FAILED không sửa được.

**FR phục vụ.** FR-12-053, 054.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (version_id, tenant_id) → `policy_version`.

**Ràng buộc CHECK.** `ck_policy_dryrun_report_tenant`; `ck_policy_dryrun_report_hash`; `ck_policy_dryrun_report_status`; `ck_policy_dryrun_report_window`; `ck_policy_dryrun_report_counts`; `ck_policy_dryrun_report_threshold`; `ck_policy_dryrun_report_summary`.

**Chỉ mục.** `ix_policy_dryrun_report_version` (tenant_id, version_id, content_hash, finished_at DESC); `ix_policy_dryrun_report_purge` (purge_after).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Trigger nghiệp vụ `tg_policy_dryrun_report_frozen` (hàm `tg_dryrun_frozen`).

**Ghi chú.** Giữ 12 tháng (`purge_after`), xóa được sau hạn dù đã DONE; trong hạn chỉ sửa được khi RUNNING. Mẫu đã che, không có dữ liệu cá nhân.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `version_id` | `uuid` | Có |  |  |
| `content_hash` | `char(64)` | Có |  |  |
| `base_bundle_revision` | `varchar(64)` | Có |  |  |
| `status` | `varchar(8)` | Có | `'RUNNING'` | Một trong: `RUNNING`, `DONE`, `FAILED`. |
| `window_from` | `timestamptz` | Có |  |  |
| `window_to` | `timestamptz` | Có |  |  |
| `sample_count` | `integer` | Có | `0` |  |
| `changed_count` | `integer` | Có | `0` |  |
| `deny_to_allow_count` | `integer` | Có | `0` |  |
| `allow_to_deny_count` | `integer` | Có | `0` |  |
| `change_threshold` | `numeric(4,3)` | Có | `0.200` | Ngưỡng 12.policy.dryrun.change-threshold tại thời điểm chạy (0,05…0,5, mặc định 0,2); vượt ngưỡng hoặc có deny_to_allow_count > 0 thì duyệt cần xác nhận bổ sung (BR-12-011). |
| `changed_ratio` | `numeric(6,5)` | Không |  | Cột sinh (STORED): `CASE WHEN sample_count = 0 THEN 0 ELSE round(changed_count::numeric / sample_count, 5) END`. |
| `small_sample` | `boolean` | Không |  | Mẫu dưới 100 yêu cầu: báo "mẫu quá ít" nhưng vẫn cho gửi duyệt. Cột sinh (STORED): `sample_count < 100`. |
| `summary` | `jsonb` | Có | `'{}'` |  |
| `error_code` | `varchar(16)` | Không |  |  |
| `finished_at` | `timestamptz` | Không |  |  |
| `purge_after` | `timestamptz` | Có | `now() + interval '12 months'` |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `policy_dryrun_report`

### 3.34. `bundle_release`

::: dac-ta
**Mục đích.** EN-12-14 Bản phát hành gói chính sách và dữ liệu cho OPA (FR-12-051, 054, 055). Hai loại: PLATFORM (Rego gốc, permissions, grants; tenant_id = PLATFORM) và TENANT (Rego riêng của tỉnh, assignments, org_tree, client_scopes, tenant_state; tenant_id = tỉnh). Mỗi tenant đúng một PUBLISHED. Quay lui dựng bản MỚI có revision mới với nội dung bản cũ (rollback_of), giữ chuỗi revision đơn điệu. Không xóa vật lý; thân gói ở bucket dh-platform-policy.

**FR phục vụ.** FR-12-051, 054, 055.

**Khóa chính.** (id).

**Duy nhất.** `uq_bundle_release_revision` (tenant_id, bundle_revision); `uq_bundle_release_published` (tenant_id) khi state = 'PUBLISHED'.

**Khóa ngoại.** (rollback_of, tenant_id) → `bundle_release` (chính bảng này).

**Ràng buộc CHECK.** `ck_bundle_release_tenant`; `ck_bundle_release_kind`; `ck_bundle_release_revision`; `ck_bundle_release_state`; `ck_bundle_release_digest`; `ck_bundle_release_size`; `ck_bundle_release_signed`; `ck_bundle_release_published`; `ck_bundle_release_failed`; `ck_bundle_release_versions`.

**Chỉ mục.** `ix_bundle_release_digest` (tenant_id, digest); `ix_bundle_release_state` (tenant_id, state, created_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Không xóa vật lý, kết thúc bằng trạng thái (trigger `tg_bundle_release_no_delete`, BR-12-035).

**Ghi chú.** Không xóa vật lý; thân gói ở bucket `dh-platform-policy`, bản bất biến `releases/{revision}.tar.gz`. Giữ 12 tháng bản phát hành cũ ở kho (mục 8), dòng ở CSDL giữ vĩnh viễn.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `bundle_kind` | `varchar(8)` | Có |  |  |
| `bundle_revision` | `varchar(64)` | Có |  | Dạng {tenant viết thường}-{yyyyMMdd}-{số thứ tự}, ví dụ t68-20261126-0153, platform-20261126-0007; nằm trong .manifest và đi vào mọi quyết định (khóa đệm của PEP). |
| `state` | `varchar(10)` | Có | `'BUILDING'` | Một trong: `BUILDING`, `SIGNED`, `PUBLISHED`, `SUPERSEDED`, `FAILED`. |
| `digest` | `char(64)` | Không |  | SHA-256 hex của gói đã đóng (dựng tất định, cùng dữ liệu cùng băm); BundleBuilder bỏ qua phát hành khi không đổi. Mẫu `^[0-9a-f]{64}$`. |
| `data_digest` | `char(64)` | Không |  |  |
| `size_bytes` | `bigint` | Không |  | Kích thước gói; trần cứng 200 MiB của kho, ngưỡng cảnh báo 20 MiB (dh.iam.bundle.max-size) thì chia theo đơn vị. |
| `policy_versions` | `jsonb` | Có | `'[]'` |  |
| `signing_kid` | `varchar(128)` | Không |  | Mã khóa ký transit/sign/dh-policy-signing; OPA kiểm bằng khóa công khai trong cấu hình (SEC-36). |
| `signed_at` | `timestamptz` | Không |  |  |
| `object_key` | `varchar(512)` | Không |  |  |
| `published_at` | `timestamptz` | Không |  | Thời điểm có hiệu lực (PUBLISHED). |
| `rollback_of` | `uuid` | Không |  |  |
| `failure_code` | `varchar(16)` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `bundle_release`

### 3.35. `bundle_ack`

::: dac-ta
**Mục đích.** Nút OPA đã nạp bản phát hành nào (plugin status của OPA, danh tính mTLS của pod). Cơ sở của chỉ số iam_policy_reload_seconds, tiến độ "n/m nút" và điều kiện APPROVED sang PUBLISHED (OPA đầu tiên xác nhận). Giữ 30 ngày. Bộ tiếp nhận ghi theo từng tenant của gói, không ghi chéo.

**FR phục vụ.** FR-12-051, 054, 055.

**Khóa chính.** (id).

**Duy nhất.** `uq_bundle_ack` (release_id, node_id).

**Khóa ngoại.** (release_id, tenant_id) → `bundle_release`.

**Ràng buộc CHECK.** `ck_bundle_ack_tenant`.

**Chỉ mục.** `ix_bundle_ack_time` (acked_at).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Giữ 30 ngày. Bộ tiếp nhận trạng thái OPA ghi theo từng tenant của gói (đặt `app.tenant_id` theo tên gói), không ghi chéo.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `release_id` | `uuid` | Có |  |  |
| `node_id` | `varchar(128)` | Có |  |  |
| `active_revision` | `varchar(64)` | Có |  |  |
| `acked_at` | `timestamptz` | Có | `now()` |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `bundle_ack`

### 3.36. `alert`

::: dac-ta
**Mục đích.** EN-12-16 Cảnh báo an ninh do chín luật AN-01…AN-09 phát (FR-12-059, EVT-12-14). dedup_key = luật|đối tượng|ô thời gian 30 phút nên cùng sự việc trong 30 phút chỉ một dòng (tăng occurrences). Mức nghiêm trọng cố định theo luật (CHECK): AN-05, 06, 08 nghiêm trọng; AN-01, 02, 07 cao; AN-03, 04, 09 trung bình. detail chỉ có số đo và mã, không dữ liệu cá nhân hay bí mật.

**FR phục vụ.** FR-12-059.

**Khóa chính.** (id).

**Duy nhất.** `uq_alert_dedup` (tenant_id, dedup_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_alert_tenant`; `ck_alert_rule`; `ck_alert_severity`; `ck_alert_subject`; `ck_alert_state`; `ck_alert_seen`; `ck_alert_detail`.

**Chỉ mục.** `ix_alert_open` (tenant_id, severity, last_seen_at DESC) khi state = 'OPEN'; `ix_alert_subject` (tenant_id, subject_kind, subject_ref, last_seen_at DESC); `ix_alert_time` (tenant_id, first_seen_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Dữ liệu nhỏ (giả định dưới 500 dòng mỗi tháng mỗi tỉnh). Giữ 24 tháng rồi xóa (mục 8); sự kiện EVT-12-14 và chuỗi PH-13 giữ lâu hơn.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `rule_code` | `varchar(5)` | Có |  |  |
| `severity` | `varchar(8)` | Có |  | Một trong: `MEDIUM`, `HIGH`, `CRITICAL`. |
| `subject_kind` | `varchar(8)` | Có |  |  |
| `subject_ref` | `varchar(255)` | Có |  | Mã người dùng, clientId, địa chỉ IP (đã băm một phần theo SEC-32 khi hiển thị), tên realm hoặc mã vai trò, tùy subject_kind. |
| `dedup_key` | `varchar(255)` | Có |  |  |
| `detail` | `jsonb` | Có | `'{}'` | Chi tiết dạng JSON, không chứa bí mật (CHECK). |
| `occurrences` | `integer` | Có | `1` |  |
| `first_seen_at` | `timestamptz` | Có | `now()` |  |
| `last_seen_at` | `timestamptz` | Có | `now()` |  |
| `state` | `varchar(12)` | Có | `'OPEN'` | Một trong: `OPEN`, `ACKNOWLEDGED`. |
| `notified_at` | `timestamptz` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `alert`

### 3.37. `alert_ack`

::: dac-ta
**Mục đích.** Xác nhận cảnh báo (PERM-12-alert): người xác nhận, thời điểm, ghi chú. Chỉ thêm, mỗi cảnh báo một xác nhận; dịch vụ đặt alert.state = ACKNOWLEDGED cùng giao dịch.

**FR phục vụ.** FR-12-059.

**Khóa chính.** (id).

**Duy nhất.** `uq_alert_ack_alert` (alert_id).

**Khóa ngoại.** (alert_id, tenant_id) → `alert`.

**Ràng buộc CHECK.** `ck_alert_ack_tenant`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_alert_ack_append_only`).

**Ghi chú.** Chỉ thêm; cùng vòng đời với cảnh báo.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `alert_id` | `uuid` | Có |  |  |
| `acked_by` | `varchar(64)` | Có |  |  |
| `acked_at` | `timestamptz` | Có | `now()` |  |
| `note` | `varchar(1000)` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `alert_ack`

### 3.38. `account_report_daily`

::: dac-ta
**Mục đích.** Báo cáo tình trạng tài khoản theo ngày (FR-12-060, chạy 01:30): đếm theo trạng thái, nhóm ngày không đăng nhập, số tài khoản quản trị. Khóa tự nhiên (tenant_id, report_date), tính lại được nên ghi đè khi chạy lại. Giữ 24 tháng (NFR-12-030): purge_after = report_date + 24 tháng.

**FR phục vụ.** FR-12-060.

**Khóa chính.** (tenant_id, report_date).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_account_report_daily_tenant`; `ck_account_report_daily_counts`; `ck_account_report_daily_org`.

**Chỉ mục.** `ix_account_report_daily_purge` (purge_after).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Khóa tự nhiên, ghi đè khi tính lại cùng ngày. Giữ 24 tháng (`purge_after`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `report_date` | `date` | Có |  |  |
| `users_total` | `integer` | Có |  |  |
| `users_active` | `integer` | Có |  |  |
| `users_pending` | `integer` | Có |  |  |
| `users_locked` | `integer` | Có |  |  |
| `users_blocked` | `integer` | Có |  |  |
| `users_disabled` | `integer` | Có |  |  |
| `never_logged_in` | `integer` | Có | `0` |  |
| `inactive_30d` | `integer` | Có | `0` |  |
| `inactive_45d` | `integer` | Có | `0` |  |
| `admin_accounts` | `integer` | Có | `0` |  |
| `disabled_by_inactivity` | `integer` | Có | `0` |  |
| `by_org` | `jsonb` | Có | `'{}'` |  |
| `purge_after` | `timestamptz` | Có |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |

: Cột của bảng `account_report_daily`

### 3.39. `mfa_coverage_daily`

::: dac-ta
**Mục đích.** Tỷ lệ tài khoản thuộc nhóm mfa-required đã đăng ký yếu tố thứ hai (FR-12-060, BR-12-015); đối chiếu mẫu hằng tuần với Keycloak để chống lệch (sample_mismatch). Mục tiêu 100%, quản trị nền tảng và quản trị tỉnh chỉ WebAuthn (admin_webauthn = admin_required). Giữ 24 tháng.

**FR phục vụ.** FR-12-022, 060.

**Khóa chính.** (tenant_id, report_date).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_mfa_coverage_daily_tenant`; `ck_mfa_coverage_daily_counts`.

**Chỉ mục.** `ix_mfa_coverage_daily_purge` (purge_after).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Khóa tự nhiên. Giữ 24 tháng (`purge_after`); `sample_mismatch` > 0 thì phát cảnh báo cấu hình.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `report_date` | `date` | Có |  |  |
| `required_users` | `integer` | Có |  |  |
| `enrolled_users` | `integer` | Có |  |  |
| `coverage_ratio` | `numeric(6,5)` | Không |  | Cột sinh (STORED): `CASE WHEN required_users = 0 THEN 1 ELSE round(enrolled_users::numeric / required_users, 5) END`. |
| `admin_required` | `integer` | Có | `0` |  |
| `admin_webauthn` | `integer` | Có | `0` |  |
| `sampled_users` | `integer` | Có | `0` |  |
| `sample_mismatch` | `integer` | Có | `0` |  |
| `checked_at` | `timestamptz` | Không |  |  |
| `purge_after` | `timestamptz` | Có |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |

: Cột của bảng `mfa_coverage_daily`

### 3.40. `sync_task`

::: dac-ta
**Mục đích.** Ý định ghi sang Keycloak, ghi cùng giao dịch với thay đổi ở ph12_iam rồi SyncReconciler thực hiện và phát lại lũy đẳng (mẫu "ghi ý định trước, thực hiện sau", SDD §4.2, §8.4). Mỗi (loại, đối tượng) một việc đang mở. payload không chứa bí mật; thu hồi vẫn ghi revocation_entry trước (SDD §4.9). Việc DONE xóa sau 7 ngày.

**FR phục vụ.** FR-12-003…005, 009, 012, 030, 031, 040.

**Khóa chính.** (id).

**Duy nhất.** `uq_sync_task_open` (tenant_id, task_type, target_id) khi status IN ('PENDING', 'RUNNING').

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_sync_task_tenant`; `ck_sync_task_type`; `ck_sync_task_target`; `ck_sync_task_status`; `ck_sync_task_attempts`; `ck_sync_task_payload`.

**Chỉ mục.** `ix_sync_task_due` (next_attempt_at) khi status IN ('PENDING', 'RUNNING'); `ix_sync_task_done` (done_at) khi status = 'DONE'.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Việc DONE xóa sau 7 ngày; việc FAILED giữ 30 ngày để điều tra. Ý định không chứa bí mật; người dùng mới nhận liên kết kích hoạt do Keycloak gửi, không có mật khẩu trong ý định.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `task_type` | `varchar(24)` | Có |  |  |
| `target_kind` | `varchar(12)` | Có |  |  |
| `target_id` | `uuid` | Có |  |  |
| `payload` | `jsonb` | Có | `'{}'` | Nội dung dạng JSON, không chứa khóa bí mật (CHECK). |
| `status` | `varchar(8)` | Có | `'PENDING'` | Một trong: `PENDING`, `RUNNING`, `DONE`, `FAILED`. |
| `attempts` | `smallint` | Có | `0` |  |
| `next_attempt_at` | `timestamptz` | Có | `now()` |  |
| `last_error` | `varchar(1000)` | Không |  |  |
| `done_at` | `timestamptz` | Không |  |  |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | Có | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | Có |  | Người sửa cuối. |
| `version` | `integer` | Có | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044). |

: Cột của bảng `sync_task`

### 3.41. `idempotency_key`

::: dac-ta
**Mục đích.** Khóa lũy đẳng của API ghi (ADR-041): giữ băm thân và phản hồi 24 giờ; cùng khóa khác thân là ERR-12-045 (422). Với saga của PH-01, PH-20 khóa còn là khóa tìm lại tiến trình dở. response_body bị CHECK chặn khóa bí mật: phản hồi cấp client chỉ được lưu dạng handoverId, không có wrappingToken (BR-12-023).

**FR phục vụ.** Mọi API ghi của PH-12 (ADR-041); FR-12-030, 041 (saga của PH-01, PH-20).

**Khóa chính.** (id).

**Duy nhất.** `uq_idempotency_key` (tenant_id, idem_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_idempotency_key_tenant`; `ck_idempotency_key_key`; `ck_idempotency_key_method`; `ck_idempotency_key_hash`; `ck_idempotency_key_state`; `ck_idempotency_key_response`.

**Chỉ mục.** `ix_idempotency_key_expiry` (expires_at).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Giữ 24 giờ rồi tác vụ dọn xóa (`expires_at`). Thân phản hồi lưu không có `wrappingToken` (BR-12-023).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Có |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `idem_key` | `varchar(128)` | Có |  |  |
| `method` | `varchar(8)` | Có |  | Một trong: `POST`, `PUT`, `PATCH`, `DELETE`. |
| `path` | `varchar(255)` | Có |  |  |
| `body_hash` | `char(64)` | Có |  |  |
| `state` | `varchar(10)` | Có | `'PROCESSING'` | Một trong: `PROCESSING`, `DONE`. |
| `response_status` | `smallint` | Không |  |  |
| `response_body` | `jsonb` | Không |  |  |
| `resource_ref` | `varchar(255)` | Không |  |  |
| `expires_at` | `timestamptz` | Có | `now() + interval '24 hours'` | Thời điểm hết hiệu lực. |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | Có |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `idempotency_key`

### 3.42. `outbox`

::: dac-ta
**Mục đích.** Hộp thư đi (ADR-042, DD-11): EVT-12-01…15 ghi cùng giao dịch với thay đổi trạng thái; Debezium outbox router phát lên Kafka dạng CloudEvents (EVT-12-16 do Keycloak phát trực tiếp, không qua đây). Topic mang đúng mã tenant viết thường (platform cho tenant nền tảng, D03-10 §3) và payload không có khóa bí mật. Xóa sau 3 ngày.

**FR phục vụ.** Mọi FR phát sự kiện EVT-12-01…15 (ADR-042).

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_tenant`; `ck_outbox_type`; `ck_outbox_topic`; `ck_outbox_json`; `ck_outbox_no_secret`.

**Chỉ mục.** `ix_outbox_created` (created_at).

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Debezium outbox router đọc WAL rồi phát CloudEvents; dòng đã gửi xóa sau 3 ngày. Không phân vùng vì khối lượng thấp (giả định khoảng 5.000 sự kiện mỗi ngày mỗi tỉnh vừa).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `event_id` | `uuid` | Có |  |  |
| `tenant_id` | `varchar(16)` | Có |  | Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `event_type` | `varchar(12)` | Có |  |  |
| `aggregate_type` | `varchar(32)` | Có |  |  |
| `aggregate_id` | `uuid` | Có |  |  |
| `topic` | `varchar(255)` | Có |  | Mẫu `^[a-z0-9]+\.iam\.[a-z-]+\.[a-z-]+\.v[0-9]+$`. |
| `partition_key` | `varchar(128)` | Có |  | Khóa phân vùng giữ thứ tự theo đối tượng: userId, clientId, policyCode, grantId, exceptionId, tenantCode hoặc alertId (SDD §8.2). |
| `headers` | `jsonb` | Có | `'{}'` |  |
| `payload` | `jsonb` | Có |  | Nội dung dạng JSON, không chứa khóa bí mật (CHECK). |
| `created_at` | `timestamptz` | Có | `now()` | Thời điểm tạo. |

: Cột của bảng `outbox`

### 3.43. `shedlock`

::: dac-ta
**Mục đích.** Bảng kỹ thuật của thư viện ShedLock cho tác vụ định kỳ (InactivityJob 02:00, AssignmentExpiryJob, GrantExpiryJob, SyncReconciler, DriftDetector, RecertScheduler, báo cáo ngày). Không có dữ liệu nghiệp vụ nên không có tenant_id và không bật RLS.

**FR phục vụ.** Tác vụ định kỳ: FR-12-008, 017, 018, 042, 051, 060.

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS. Bảng kỹ thuật không có `tenant_id` và không chứa dữ liệu nghiệp vụ (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn.

**Ghi chú.** Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `name` | `varchar(64)` | Có |  | Tên hiển thị. |
| `lock_until` | `timestamptz` | Có |  |  |
| `locked_at` | `timestamptz` | Có |  |  |
| `locked_by` | `varchar(255)` | Có |  |  |

: Cột của bảng `shedlock`
<!-- gen:tables:end -->

### 3.44. Quy tắc nghiệp vụ chốt ở CSDL

Hai lớp bảo vệ chồng nhau: dịch vụ kiểm trước để trả thông báo đẹp (`ERR-12-xxx` kèm câu cho người dùng), CSDL chốt sau để lỗi lập trình, hai giao dịch đồng thời hay một công cụ quản trị chạy tay cũng không phá được quy tắc. Bảng sau liệt kê 25 ràng buộc và trigger tiêu biểu. Cột cuối cho biết mã lỗi mà dịch vụ phải ánh xạ: lỗi do trigger mang `SQLSTATE` tùy biến `P12nn` (lớp `P1` do người dùng định nghĩa), lỗi do `CHECK` là `23514`, do khóa duy nhất là `23505`; lớp `ExceptionTranslator` của module `iam` đọc tên ràng buộc (`constraint_name`) để chọn mã.

| # | Ràng buộc, trigger | Quy tắc | BR, FR | `SQLSTATE` → mã lỗi |
|---|---|---|---|---|
| 1 | `tg_role_assignment_sod`, `sod_pair` | Gán vai trò thứ hai tạo cặp xung đột (D02-08 §4) bị chặn trừ khi có `sod_exception` `ACTIVE` còn hạn; khóa tư vấn theo người dùng chống hai giao dịch gán đồng thời | BR-12-030, FR-12-013 | `P1209` → ERR-12-009 |
| 2 | `tg_sod_exception_guard`, `fk_sod_exception_pair` | Ngoại lệ chỉ cho cặp có trong `sod_pair` và `allow_exception`; cặp `AUDITOR` với vai trò ghi của PH-19 không có ngoại lệ | BR-12-030 | `P1210` → ERR-12-010 |
| 3 | `ck_sod_exception_max_days`, `_reason`, `_four_eyes`, `_decided` | Ngoại lệ tối đa 90 ngày, lý do từ 30 ký tự, người duyệt khác người đề nghị, `ACTIVE` phải có người duyệt và thời điểm | BR-12-030 | `23514` → ERR-12-043 (hạn), ERR-12-014 (lý do), ERR-12-008 (bốn mắt) |
| 4 | `tg_role_assignment_last_admin`, `tg_user_account_last_admin` | Không gỡ, hết hạn, thu hồi hay vô hiệu người giữ `TENANT_ADMIN` cuối cùng của tenant tỉnh; khóa tư vấn theo tenant | BR-12-033, FR-12-012 | `P1246` → ERR-12-046 |
| 5 | `ck_role_assignment_no_self`, `ck_revocation_entry_no_self`, `ck_recert_item_no_self` | Không tự gán, gỡ vai trò, không tự thu hồi truy cập, không tự rà soát quyền của mình | BR-12-033, BR-12-044 | `23514` → ERR-12-013 |
| 6 | `ck_role_assignment_platform`, `ck_role_assignment_machine` | Vai trò `PLATFORM_*` chỉ ở tenant `PLATFORM`; `PARTNER_SYSTEM` chỉ gán cho client, không gán cho người | BR-12-031 | `23514` → ERR-12-010 |
| 7 | `uq_role_assignment_active` | Một gán `ACTIVE` cho mỗi (người, vai trò, loại phạm vi, phạm vi) | FR-12-012 | `23505` → ERR-12-002 |
| 8 | `tg_org_group_path`, `tg_org_group_subtree` | `path` `ltree` do trigger tính; đổi cha vào chính cây con của nút là vòng lặp; đổi cha cập nhật cây con | BR-12-039, FR-12-014 | `P1212` → ERR-12-012; cha không tồn tại `P1210` → ERR-12-010 |
| 9 | `ck_privileged_grant_hours`, `_max`, `_ticket`, `_four_eyes`, `_cross`, `_window` | Quyền có thời hạn 1 đến 4 giờ, cửa sổ hiệu lực không quá 4 giờ, có mã phiếu, người duyệt khác người đề nghị, chỉ tenant `PLATFORM` được vào tenant khác | BR-12-032, BR-12-031 | `23514` → ERR-12-030 (giờ, phiếu), ERR-12-008, ERR-12-010 |
| 10 | `tg_policy_version_guard` (máy trạng thái) | Chỉ 8 chuyển trạng thái của FRS §4.5; nội dung bất biến sau khi gửi duyệt | ADR-069, FR-12-054 | `P1227` → ERR-12-027 |
| 11 | `tg_policy_version_guard` (gửi duyệt) | `DRAFT` sang `PENDING_REVIEW` cần `policy_test_run` đạt và `policy_dryrun_report` `DONE` trên đúng `content_hash` | BR-12-009, FR-12-052, 053 | `P1225` → ERR-12-025; `P1226` → ERR-12-026 |
| 12 | `tg_policy_version_guard` (duyệt), `ck_policy_version_four_eyes`, bảng `policy_version_contributor` | Người duyệt không là người soạn, người gửi hay người đóng góp | BR-12-008 | `P1208` và `23514` → ERR-12-008 |
| 13 | `tg_policy_version_guard` (tác động lớn) | Chạy khô đổi quá ngưỡng hoặc có ca từ chối sang cho phép thì duyệt cần `high_impact_confirmed` | BR-12-011 | `P1229` → ERR-12-029 |
| 14 | `ck_policy_test_run_passed` | `passed` chỉ khi không ca lỗi, có ít nhất một ca dương và một ca âm, độ phủ từ 90% | BR-12-009, SEC-26 | `23514` → ERR-12-025 |
| 15 | `tg_policy_version_0hash`, `ck_policy_version_content` | `content_hash` do CSDL tính từ nội dung; nội dung 1 byte đến 256 KiB | BR-12-009 | `23514` → ERR-12-003 |
| 16 | `uq_policy_version_published`, `uq_bundle_release_published` | Mỗi mã chính sách đúng một phiên bản `PUBLISHED`; mỗi tenant đúng một gói `PUBLISHED` (dịch vụ đổi bản cũ sang `SUPERSEDED` cùng giao dịch) | BR-12-010 | `23505` → lỗi nội bộ, thử lại |
| 17 | `ck_policy_scope`, `ck_policy_root`, `tg_policy_version_guard` | Chính sách phạm vi `PLATFORM` chỉ thuộc tenant `PLATFORM`; chính sách gốc không thu hồi được | BR-12-007, FR-12-055 | `23514` → ERR-12-010; `P1227` → ERR-12-027 |
| 18 | `ck_client_level_auth`, `ck_client_sensitive_mtls` | Hợp đồng từ mức Hạn chế cấm `client_secret`; mức Nhạy cảm bắt buộc mTLS | BR-12-024, FR-12-030 | `23514` → ERR-12-022 |
| 19 | `uq_client_system`, `uq_client_client_id` | Một client chưa thu hồi cho mỗi HTTT; mã client không dùng lại sau `REVOKED` | BR-12-024, FR-12-031 | `23505` → ERR-12-018 |
| 20 | `ck_client_scope_prefix` | PH-02 chỉ đặt `api:`, PH-09 `purpose:`, PH-10 `topic:`, PH-07 `rdm:`, PH-19 `payment:`; `iam:`, `event:` chỉ `INTERNAL` | BR-12-025, FR-12-036 | `23514` → ERR-12-019 |
| 21 | `ck_client_credential_secret`, `uq_client_credential_current` | Bí mật hết hạn không quá 180 ngày; một bản `ACTIVE` và một `TRANSITION` mỗi loại khi xoay | BR-12-023, FR-12-034 | `23514` → ERR-12-043; `23505` → ERR-12-023 |
| 22 | `ck_revocation_entry_expiry`, `_reason`, `uq_revocation_entry_blocking`, `tg_revocation_entry_bump` | Mục thu hồi ghi trước Keycloak với `block_all`; hạ cờ cần xác nhận của Keycloak và hạn; bắt buộc lý do; mỗi lệnh ghi tăng phiên bản danh sách | BR-12-028, FR-12-040 | `23514` → ERR-12-014 |
| 23 | `ck_federation_ldaps`, `_tests`, `_four_eyes`, `ck_saml_client_urls` | Chỉ LDAPS; chưa đạt ba kiểm tra không gửi duyệt; người duyệt khác người đề nghị; redirect URI SAML `https`, cấm ký tự đại diện | BR-12-029, FR-12-025, 026 | `23514` → ERR-12-032, ERR-12-033 |
| 24 | `uq_vneid_link_subject`, `uq_vneid_link_user` | Một định danh VNeID chỉ liên kết một tài khoản và ngược lại; chỉ lưu băm | BR-12-029, FR-12-028 | `23505` → ERR-12-034 |
| 25 | `ck_*_no_secret`, `f_json_has_secret_key` | Cột JSON nhận dữ liệu ngoài (tệp nhập, `outbox`, `idempotency_key`, `sync_task`, `federation`, `realm_*`) không có khóa `password`, `secret`, `clientSecret`, `token`, `wrappingToken`… (đệ quy) | BR-12-023, BR-12-045 | `23514` → lỗi nội bộ (dịch vụ phải lọc trước) |

: Quy tắc nghiệp vụ chốt ở CSDL

Ngoài 25 dòng trên, `P1235` (xóa vật lý bị chặn, BR-12-035) và `P1299` (sửa bảng chỉ thêm) là lỗi lập trình, không có thao tác API tương ứng nên không có mã `ERR` riêng và trả `500` kèm cảnh báo. Quy tắc phụ thuộc thời gian thực (token mức 3 trong 5 phút, hạn liên kết kích hoạt) không chốt được bằng CSDL nên ở dịch vụ và OPA (SDD §8.1).

### 3.45. Truy vấn chính và chỉ mục phục vụ

Bảng sau nối truy vấn nặng nhất của từng chức năng với chỉ mục phục vụ. Với mọi truy vấn của tenant, RLS thêm điều kiện `tenant_id` nên mọi chỉ mục tác nghiệp đều bắt đầu bằng `tenant_id`.

| Truy vấn | API, tác vụ | Chỉ mục |
|---|---|---|
| Danh sách người dùng lọc đơn vị, trạng thái, tìm theo tên | API-12-001; UI-12-01 | `ix_user_account_org_state`, `ix_user_account_name_trgm` (`pg_trgm`) |
| Tìm người dùng theo tên đăng nhập, thư điện tử, kiểm trùng | API-12-003 | `uq_user_account_username`, `uq_user_account_email` |
| Tài khoản `ACTIVE` quá ngưỡng không đăng nhập | `InactivityJob` 02:00 (FR-12-008) | `ix_user_account_inactivity` (một phần) |
| Tài khoản chưa kích hoạt quá 30 ngày | `InactivityJob` | `ix_user_account_pending` (một phần) |
| Việc đồng bộ Keycloak đến hạn, người dùng chưa `SYNCED` | `SyncReconciler` mỗi 5 phút | `ix_sync_task_due`, `ix_user_account_sync` (một phần) |
| Vai trò đang có của một người; gán sắp hết hạn; người giữ vai trò | Gán vai trò, `AssignmentExpiryJob`, quyền hiệu lực | `ix_role_assignment_user`, `ix_role_assignment_expiry`, `ix_role_assignment_role` |
| Cây con của một đơn vị | Phạm vi `ORG`, gói dữ liệu `org_tree` | `ix_org_group_path` (GiST) |
| Quyền có thời hạn vào một tenant; quyền hết hạn | UI-12-08, `GrantExpiryJob` mỗi 30 giây | `ix_privileged_grant_target`, `ix_privileged_grant_expiry` (một phần) |
| Danh sách chặn cho cổng, mục hết hạn, mục chờ Keycloak xác nhận | API-12-079 | `ix_revocation_entry_lookup`, `ix_revocation_entry_expiry`, `ix_revocation_entry_unconfirmed` |
| Client không gọi quá ngưỡng; client theo trạng thái | `ClientInactivityJob`, UI-12-10 | `ix_client_inactivity`, `ix_client_state` |
| Chứng thư, bí mật sắp hết hạn | Cảnh báo hạn thông tin xác thực | `ix_client_credential_expiry` (một phần) |
| Scope của client theo nguồn; dựng gói dữ liệu tenant | `ScopeSynchronizer`, `PolicyDataGenerator` | `ix_client_scope_source`, `ix_role_assignment_user` |
| Phiên bản chính sách chờ duyệt (hộp việc) | UI-12-17 | `ix_policy_version_pending` (một phần) |
| Kết quả kiểm thử và chạy khô gần nhất của đúng băm | Điều kiện gửi duyệt (trigger) | `ix_policy_test_run_version`, `ix_policy_dryrun_report_version` |
| Cảnh báo đang mở theo mức nghiêm trọng; theo đối tượng | UI-12-15 | `ix_alert_open` (một phần), `ix_alert_subject` |
| Realm lệch cấu hình | `DriftDetector`, UI-12-19 | `ix_realm_state_drift` (một phần) |
| Dọn dữ liệu hết hạn | Tác vụ dọn hằng ngày | `ix_idempotency_key_expiry`, `ix_outbox_created`, `ix_bundle_ack_time`, `ix_policy_dryrun_report_purge`, `ix_account_report_daily_purge`, `ix_mfa_coverage_daily_purge`, `ix_sync_task_done`, `ix_user_import_purge` |

: Truy vấn chính và chỉ mục phục vụ

## 4. DDL, changelog Liquibase và kiểm thử

Chương này cho biết DDL nằm ở đâu, chạy theo thứ tự nào, đã chạy thử ra sao và bài kiểm cô lập tenant kiểm những gì. Nguồn duy nhất là thư mục [`ph12/ddl/`](ph12/ddl/ph12_iam_all.sql); tài liệu này không chép lại DDL mà trích từ đó.

### 4.1. Tệp và thứ tự changeset

DDL chia sáu tệp theo nhóm bảng, mỗi tệp tự chạy được (đầu tệp đặt lại `SET ROLE ph12_owner` và `app.tenant_id = 'PLATFORM'`) và có tệp bọc `ph12_iam_all.sql` chạy cả sáu bằng `\ir` trong một phiên. Môi trường thật dùng Liquibase: mỗi tệp chia changeset bằng các dấu `-- @file`, `-- @changeset`, `-- @rollback` như PH-04, PH-05, PH-07, công cụ sinh changelog `../ph07/tools/gen_liquibase.py` (tham số hóa tên phân hệ) chạy bằng `dh_platform_iam_migrator`. Tổng cộng 61 changeset; mỗi changeset tạo một bảng hoặc một nhóm hàm, kèm `@rollback` xóa đúng đối tượng đó.

| Tệp | Changeset | Nội dung |
|---|---|---|
| `ph12_iam_01_bootstrap.sql` | 9 | Vai trò `ph12_owner`, `ph12_app`, `ph12_readonly`; tiện ích `ltree`, `pg_trgm`; schema; biến phiên; `tg_touch`, `p_enable_rls`, `tg_append_only`, `tg_no_delete`, `f_json_has_secret_key`, `f_realm_name` |
| `ph12_iam_02_user_role.sql` | 17 | `user_account`, `user_import`, `user_import_row`; `sod_pair`, `legacy_role_map`, `role_assignment` và trigger quản trị cuối cùng, tách nhiệm vụ; `sod_exception`; `org_group` và trigger cây; `org_group_member`; `custom_role`, `custom_role_permission`; `privileged_grant`; `recert_campaign`, `recert_item` |
| `ph12_iam_03_identity.sql` | 15 | Hàm kiểm URL, scope; `federation`, `saml_client`, `vneid_link`; `client`, `client_scope`, `client_credential`, `service_account`; `revocation_feed_version`, `revocation_entry` và trigger tăng phiên bản; `node_heartbeat`; `realm_state`, `realm_provision_step`, `tenant_merge_step` |
| `ph12_iam_04_policy.sql` | 9 | `policy`, `policy_version`, `policy_version_contributor`, `policy_test_case`, `policy_test_run`, `policy_dryrun_report`; trigger băm, đóng băng, máy trạng thái; `bundle_release`, `bundle_ack` |
| `ph12_iam_05_audit_tech.sql` | 8 | `alert`, `alert_ack`, `account_report_daily`, `mfa_coverage_daily`; `sync_task`, `idempotency_key`, `outbox`, `shedlock` |
| `ph12_iam_06_seed_grants.sql` | 3 | Dữ liệu khởi tạo `COMMON` (`runOnChange`) và quyền của vai trò (`runAlways`) |

: Tệp DDL và changeset của schema ph12_iam

Thứ tự bắt buộc: tệp 01 trước, rồi 02 (tạo `sod_pair` trước `role_assignment` vì trigger tham chiếu), 03 (thêm khóa ngoại `fk_user_account_federation` sau khi tạo `federation`), 04, 05, và 06 cuối cùng vì cấp quyền cho các bảng đã có. Thêm bảng mới: tạo changeset mới, gọi `p_enable_rls` ngay sau `CREATE TABLE`, rồi khai báo bảng vào ba danh sách của tệp 06 nếu cần xóa dòng, chỉ thêm, hoặc cấm báo cáo đọc; công cụ lint migration chặn bảng có `tenant_id` mà thiếu chính sách (D03-10 §4).

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.16 cài sạch (tài khoản quản trị `postgres`, dữ liệu giả):

- `psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f ph12_iam_all.sql` chạy không lỗi trên CSDL không có schema `ph12_iam`: tạo 43 bảng, 155 chỉ mục, 45 trigger, 19 hàm và thủ tục, 164 chính sách RLS. Chạy lại riêng tệp 06 (`runAlways`) không lỗi; hai bảng không bật RLS đúng là `revocation_feed_version` và `shedlock`.
- [`ph12_isolation_test.sql`](ph12/test/ph12_isolation_test.sql) chạy dưới tài khoản `dh_platform_iam_app` (thành viên `ph12_app`, `NOBYPASSRLS`) trong một giao dịch rồi `ROLLBACK`, nên chạy lại được; đạt **100 khối PASS** thuộc 24 nhóm ở bảng dưới. Mỗi khối là một khối `DO` kiểm một điều: lỗi mong đợi bị bắt và ghi PASS, sai thì `RAISE` làm dừng tệp.

| Nhóm | Điều được kiểm | Khối PASS |
|---|---|---|
| 1 đến 5 | Cô lập đọc, ghi chéo, sửa chéo, khóa ngoại kép chéo tenant, thiếu `app.tenant_id` | 5 |
| 6 | Mẫu S: tỉnh đọc `sod_pair`, `legacy_role_map`, `node_heartbeat` (`COMMON`), không ghi được | 4 |
| 7 | Mẫu G: tenant bị truy cập đọc được quyền có thời hạn, tenant khác không thấy, không sửa được, không tạo chéo | 3 |
| 8 | Không xóa vật lý: ứng dụng không có quyền, chủ bảng bị trigger chặn (tài khoản, phiên bản chính sách) | 3 |
| 9 | Tên đăng nhập và thư điện tử duy nhất trong tenant, trùng được giữa hai tenant; `DISABLED` phải có lý do | 3 |
| 10 | Tách nhiệm vụ: cặp xung đột, cặp không ngoại lệ, ngoại lệ quá 90 ngày, lý do ngắn, tự duyệt, ngoại lệ chưa duyệt, ngoại lệ hợp lệ mở cặp | 8 |
| 11 | Không tự gán, `PLATFORM_*` ngoài `PLATFORM`, `PARTNER_SYSTEM` cho người, phạm vi `ORG` thiếu mã, gán trùng | 5 |
| 12 | Quản trị tỉnh cuối cùng: không gỡ, không vô hiệu; có người thứ hai thì gỡ được | 3 |
| 13 | Cây nhóm: path đúng, cấm vòng lặp, đổi cha cập nhật cây con, nhóm `ORG` cần mã đơn vị | 4 |
| 14 | Quyền có thời hạn: quá 4 giờ, tự duyệt, cửa sổ quá 4 giờ, duyệt hợp lệ, tỉnh đích thấy | 5 |
| 15 | Client: mức Nhạy cảm bắt buộc mTLS, mức Hạn chế cấm `client_secret`, một client sống mỗi HTTT, cấp lại sau thu hồi, không dùng lại mã, scope theo nguồn | 7 |
| 16 | Thông tin xác thực: bí mật quá 180 ngày, một chứng thư `ACTIVE` mỗi client | 2 |
| 17 | Danh sách chặn: tăng phiên bản, không tự thu hồi, hạ cờ cần xác nhận, cần lý do | 4 |
| 18 | Chính sách: băm do CSDL tính, máy trạng thái, kiểm thử và chạy khô gắn băm, bốn mắt với người đóng góp, xác nhận tác động lớn, một `PUBLISHED`, chỉ thêm, chính sách gốc không thu hồi | 17 |
| 19 | Gói chính sách: loại gói đúng tenant, một `PUBLISHED` mỗi tenant, `bundleRevision` đúng tenant, mỗi nút xác nhận một lần | 4 |
| 20 | Realm và dữ liệu nền tảng: tỉnh không thấy `realm_state`, tên realm, giữ tạm có lý do, scope tài khoản dịch vụ, chỉ tenant `PLATFORM` | 5 |
| 21 | Liên kết ngoài: chỉ LDAPS, kiểm tra trước khi duyệt, bốn mắt, không bí mật, VNeID một một, SAML không ký tự đại diện | 6 |
| 22 | Rà soát, cảnh báo, outbox: chiến dịch mở duy nhất, không tự rà soát, mức cảnh báo theo luật, khử trùng, topic đúng tenant, không bí mật ở outbox, lũy đẳng, tệp nhập, ý định | 9 |
| 23 | Quyền của vai trò: ứng dụng không xóa gán vai trò; `ph12_readonly` không đọc bí mật, không đọc `email` | 2 |
| 24 | Vai trò ứng dụng không `BYPASSRLS`; 41 bảng có `tenant_id` đều `FORCE RLS` | 1 |

: Kết quả chạy thử bài kiểm ph12_isolation_test.sql trên PostgreSQL 16.16

Bài kiểm chạy ở mức SQL để DBA và kiểm thử viên chạy ngay trên CSDL trống. Trong CI, `TenantIsolationIT` của module `iam` (SDD §12, Testcontainers PostgreSQL 16) lặp lại các ca này qua repository thật và qua API, thêm ca đồng thời (hai giao dịch gán vai trò xung đột, hai giao dịch gỡ quản trị cuối cùng) mà một phiên `psql` đơn lẻ không mô phỏng được.

## 5. Mã hóa và dữ liệu cá nhân

Chương này nêu dữ liệu cá nhân nào nằm ở `ph12_iam`, ai đọc được, bảo vệ ra sao và vì sao một số dữ liệu cố ý không có ở đây. Nguyên tắc: Keycloak giữ phần nhạy cảm nhất (mật khẩu, yếu tố xác thực), `ph12_iam` chỉ giữ thông tin nghiệp vụ tối thiểu, và bí mật nằm ở OpenBao.

### 5.1. Dữ liệu cá nhân ở ph12_iam

Dữ liệu cá nhân của PH-12 là dữ liệu cơ bản của **cán bộ** (không phải của công dân): họ tên, thư công vụ, tên đăng nhập, đơn vị, chức danh. Theo bốn mức phân loại của D03-07 §4, giả định xếp mức Nội bộ (cần ý kiến cán bộ ATTT nếu tỉnh coi là Hạn chế); khi đó không cần mã hóa cột theo ADR-032 và dùng các lớp bảo vệ dưới.

| Dữ liệu | Cột | Bảo vệ |
|---|---|---|
| Họ tên, thư điện tử, tên đăng nhập, chức danh | `user_account.full_name`, `email`, `username`, `title` | RLS theo tenant; `ph12_readonly` không đọc `full_name` và `email` (quyền theo cột); danh bạ cho phân hệ khác chỉ trả mã, tên hiển thị, đơn vị, chức danh, trạng thái, không trả thư (BR-12-042); che trong log (SEC-32, BR-12-045); gói chính sách chỉ chứa mã người dùng, không chứa họ tên, thư |
| Dữ liệu người được nhập | `user_import_row.raw` | Không nhận mật khẩu (CHECK); `ph12_readonly` không đọc; xóa cùng lần nhập sau 30 ngày (giả định); tệp gốc xóa sau 24 giờ |
| Định danh điện tử | `vneid_link.subject_hash` | Chỉ băm HMAC-SHA256 có khóa ở OpenBao; không lưu số định danh; `ph12_readonly` không đọc (BR-12-045, Q12-02 của FRS) |
| Địa chỉ nguồn, mã người dùng trong cảnh báo | `alert.subject_ref`, `detail` | Cảnh báo chỉ mang số đo và mã; địa chỉ IP hiển thị che một phần; `detail` bị CHECK chặn khóa bí mật |
| Lý do, mã phiếu của quyền có thời hạn | `privileged_grant.reason`, `ticket_ref` | Văn bản tự do của nhân sự nền tảng, không nhập dữ liệu của công dân (hướng dẫn trên UI-12-08); giữ vĩnh viễn làm bằng chứng |
| Ca kiểm thử, mẫu chạy khô | `policy_test_case.input`, `policy_dryrun_report.summary` | Dữ liệu mẫu giả hoặc từ nhật ký quyết định đã che (SEC-32, SEC-37) |

: Dữ liệu cá nhân ở schema ph12_iam và cách bảo vệ

### 5.2. Không lưu bí mật

Bảng dưới chỉ ra mỗi loại bí mật thật sự nằm ở đâu và cột nào của `ph12_iam` chỉ giữ tham chiếu. Ba lớp chặn lộ bí mật: dịch vụ dùng kiểu `SecretValue` không ghi log; cột `jsonb` nhận từ ngoài bị `CHECK` đệ quy theo `f_json_has_secret_key`; `ph12_readonly` không đọc các bảng tham chiếu bí mật.

| Bí mật | Nơi thật | Cột ở `ph12_iam` |
|---|---|---|
| Mật khẩu người dùng, mã TOTP, khóa WebAuthn | Keycloak, `pg-iam` (băm `argon2` hoặc `pbkdf2-sha512`) | Không có |
| Bí mật client | Keycloak sinh, OpenBao bọc một lần (`wrap_ttl` 24 giờ) | `client_credential.wrap_accessor` (không phải token bọc), `not_after` |
| Chứng thư, khóa công khai của client | Siêu dữ liệu công khai | `client_credential.thumbprint`, `subject_dn`, `kid` |
| Khóa riêng của đơn vị triển khai | OpenBao `transit/sign/dh-svc-{account}`, không xuất được | `service_account.kid`, `rotate_due_at` |
| Bí mật bind LDAP | OpenBao `kv/dh/{tenant}/iam/ldap/{code}` | `federation.secret_ref` (CHECK đường dẫn) |
| Khóa HMAC của VNeID | OpenBao `kv/dh/{tenant}/iam/vneid-hmac` | `vneid_link.subject_hash` |
| Khóa ký token realm | Keycloak, `pg-iam`, mã hóa khi lưu (NFR-12-018, Q12-07) | Không có |
| Khóa ký gói chính sách | OpenBao `transit/sign/dh-policy-signing` | `bundle_release.signing_kid`, `digest` |
| Token truy cập, refresh token | Không lưu | `revocation_entry.value` chỉ là `jti`, `sub` hoặc `clientId`, không phải token |

: Nơi lưu từng loại bí mật và cột tham chiếu

### 5.3. Mã hóa khi lưu và khi truyền

Dữ liệu `pg-core` mã hóa ở tầng đĩa (D03-01 §4, D03-09), truyền qua TLS 1.3 ở biên và mTLS giữa dịch vụ (NFR-12-019); bản sao lưu mã hóa phía máy khách bằng khóa do OpenBao quản lý (ADR-035). Schema không dùng mã hóa cột: không có cột nào thuộc mức Nhạy cảm theo giả định ở mục 5.1. Nếu tỉnh xếp họ tên, thư vào mức Hạn chế trở lên thì thêm mã hóa trường bằng khóa bọc của OpenBao (ADR-032) cho `full_name`, `email`; việc này ảnh hưởng chỉ mục `ix_user_account_name_trgm` và `uq_user_account_email` nên cần chuyển sang băm có khóa để tìm kiếm.

### 5.4. Quyền của chủ thể dữ liệu và thời hạn giữ

Tài khoản không bị xóa vật lý để giữ truy vết (BR-12-035), nên họ tên và thư của cán bộ đã nghỉ vẫn nằm ở `user_account`. Đề xuất ẩn danh hóa (thay `full_name`, `email`, `username`, `title` bằng giá trị băm không đảo ngược, giữ `id` và trạng thái) khi tài khoản `DISABLED` quá hạn nêu ở Q12-54, để thỏa nguyên tắc hạn chế lưu trữ của Luật BVDLCN 91/2025 mà không phá truy vết quyết định cũ.

## 6. Dữ liệu khởi tạo

Dữ liệu khởi tạo nhỏ vì phần lớn danh mục của PH-12 (22 vai trò chuẩn, quyền, ma trận) không lưu ở bảng mà sinh từ D02-08 thành tệp `roles.json`, `permissions.json` đóng cùng ảnh `dh-platform` và thành gói chính sách ký (FR-12-051). CSDL chỉ giữ hai bảng dùng chung và một dòng bộ đếm.

| Dữ liệu | Tenant | Nội dung | Nguồn | Cách nạp |
|---|---|---|---|---|
| `sod_pair` | `COMMON` | 10 dòng: 6 cặp tường minh và 4 cặp khai triển của "`AUDITOR` với mọi vai trò có quyền ghi của PH-19" (4 cặp sau `allow_exception = false`) | D02-08 §4 | Changeset `ph12-8000-seed-sod-pair`, `runOnChange`, id tất định `md5('ph12:sod:' ∥ a ∥ ':' ∥ b)` |
| `legacy_role_map` | `COMMON` | 17 dòng: 15 vai trò của SRS repo (3 chưa có vai trò chuẩn: `LEGAL_REVIEWER`, `ARCHITECT`, `AI_GOVERNOR`) và 2 vai trò chỉ có ở realm `lgsp` của compose (`INTEGRATION_DEVELOPER` ánh xạ `INTEGRATION_ENGINEER`, `INTEGRATION_ADMIN` chưa có ánh xạ) | FRS §11.4; `deploy/compose/keycloak/realm-lgsp.json` | Changeset `ph12-8010-seed-legacy-role-map`, `runOnChange` |
| `revocation_feed_version` | Không có | Một dòng `(id = 1, version = 0)` | Thiết kế | Cùng changeset tạo bảng |
| Chính sách gốc `base-authz` | `PLATFORM` | Một dòng `policy` (`is_root`) và phiên bản 1 | Kho `dh-policies` | Ngoài DDL: Job `dh-iam-provisioner` nạp ở lần dựng nền tảng đầu tiên theo đường phát hành khẩn có hai người duyệt (SDD §11) |
| Realm `dh-platform`, quản trị nền tảng đầu tiên | `PLATFORM` | `realm_state`, `user_account`, `role_assignment` `PLATFORM_ADMIN` | Cấu hình dựng nền tảng | Cùng Job; yếu tố WebAuthn đăng ký ở lần đăng nhập đầu (BR-12-015) |
| Tài khoản dịch vụ của đơn vị triển khai | `PLATFORM` | `service_account` cho PH-01, PH-15, PH-20, APISIX, DU | Kho cấu hình | Yêu cầu hợp nhất có người duyệt thứ hai (FR-12-037) |
| Tham số `12.*` | Không ở đây | 38 tham số mặc định | FRS §8.2 | Kho tham số PH-18 |
| Realm, vai trò chuẩn của từng tỉnh | Keycloak | Tạo ở bước 2 của saga khởi tạo tenant | D03-10 §5.2 | `RealmProvisioner` (FR-12-041), ghi `realm_state`, `realm_provision_step` |

: Dữ liệu khởi tạo của PH-12

Seed chạy dưới `app.tenant_id = 'PLATFORM'` (được phép ghi dòng `COMMON` theo mẫu S) và lũy đẳng (`ON CONFLICT … DO UPDATE`); `runOnChange` nên đổi nội dung changeset thì chạy lại. Danh sách tên vai trò chuẩn dùng trong `sod_pair` và `legacy_role_map` bỏ tiền tố `ROLE-` để khớp tên vai trò ở Keycloak.

## 7. Kho lưu trữ ngoài PostgreSQL

PH-12 dùng sáu kho ngoài `ph12_iam`. Chương này liệt kê từng kho, nội dung và ranh giới với CSDL, để biết khi sự cố hoặc khi khôi phục thì thứ gì ở đâu. Điểm chung: mọi tài nguyên mang tenant trong tên hoặc nhãn (SDD §6, D03-10 §4), và không kho nào giữ dữ liệu mà `ph12_iam` cần làm nguồn sự thật.

### 7.1. Keycloak và pg-iam

Keycloak 26 ở namespace `dh-iam` dùng cụm `pg-iam` riêng (3 instance, `TPH-0`, từ 5 GB ở `QM-NHO` đến 60 GB ở `QM-CHUNG`, D03-09 §5.3): realm, người dùng, thông tin đăng nhập, yếu tố xác thực, phiên (bền vào CSDL từ Keycloak 26), khóa ký, client. `ph12_iam` không sao chép những thứ này. Để hai kho nối được với nhau, PH-12 đặt các thuộc tính sau ở Keycloak:

| Thuộc tính ở Keycloak | Phía `ph12_iam` | Mục đích |
|---|---|---|
| `dh_user_id` (người dùng) | `user_account.id` | Tra ngược khi ghi ý định xong mà chưa ghi `keycloak_id`, không tạo trùng (SDD §4.2, §8.4) |
| `dh_mfa_level` (người dùng) | `user_account.mfa_level` | Điều kiện của luồng xác thực có điều kiện (mức 2, 3) |
| `dh_disabled_reason`, `dh_blocked` (người dùng) | `user_account.disabled_reason`, `state` | Dựng trạng thái `DISABLED`, `BLOCKED` mà Keycloak không có sẵn |
| `orgCode` (người dùng) | `user_account.org_code` | Claim `org` của token |
| `origin_tenant_id`, `origin_user_id` | cùng tên | Truy vết người dùng chuyển do sáp nhập |
| `dh_managed` (client) | `client` | Giới hạn client `dh-client-provisioner` chỉ sửa client của HTTT (SDD §4.5) |
| `dh_suspended_by_realm` (client) | `realm_state.state` | Khôi phục đúng tập client đã vô hiệu khi tenant được khôi phục |

: Thuộc tính Keycloak do PH-12 đặt và cột đối ứng

### 7.2. OpenBao

OpenBao là nơi duy nhất giữ bí mật của PH-12; bảng dưới liệt kê đường dẫn, nội dung, bên ghi và bên đọc.

| Đường dẫn | Nội dung | Ai ghi, ai đọc |
|---|---|---|
| `kv/dh/{tenant}/iam/admin-client` | Thông tin xác thực client `dh-platform-iam` (vai trò `realm-user-admin`) | Dựng realm ghi; `dh-platform` đọc qua xác thực Kubernetes |
| `kv/dh/{tenant}/iam/client-provisioner` | Thông tin xác thực client `dh-client-provisioner` (`manage-clients` giới hạn `dh_managed`) | Dựng realm ghi; chỉ `ClientService` đọc |
| `kv/dh/{tenant}/iam/ldap/{code}` | Bí mật bind của liên kết LDAP (`federation.secret_ref`) | `dh-platform` ghi một chiều; External Secrets Operator đồng bộ sang `dh-iam` |
| `kv/dh/{tenant}/iam/vneid-hmac` | Khóa HMAC băm định danh VNeID | `dh-platform` ghi, đọc |
| `transit/sign/dh-policy-signing` | Khóa ký gói chính sách, không xuất được | `BundleSigner` ký; khóa công khai trong cấu hình OPA |
| `transit/sign/dh-svc-{account}` | Khóa ký `private_key_jwt` của đơn vị triển khai | Pod ký qua danh tính Kubernetes |
| `sys/wrapping` (`wrap_ttl` 24 giờ) | Token bọc dùng một lần giao bí mật client | `SecretHandover` bọc; PH-01, PH-15 mở |
| `pki-clients` | CA cấp, kiểm chứng thư mTLS của client | `CertificateValidator` kiểm chuỗi |

: Đường dẫn OpenBao của PH-12

### 7.3. Kafka

Sự kiện EVT-12-01…15 ghi vào `outbox` cùng giao dịch, Debezium outbox router phát CloudEvents; EVT-12-16 do Keycloak phát trực tiếp (producer idempotent, khóa phân vùng `sub`). Tên topic theo `{tenant}.iam.{thực thể}.{sự kiện}.v1`, tenant nền tảng dùng tiền tố `platform` (CHECK `ck_outbox_topic` ép khớp `tenant_id`). Số phân vùng và thời hạn giữ dưới đây là giả định theo quy mô tỉnh vừa (3 phân vùng, 7 ngày như PH-05), riêng EVT-12-16 có khối lượng lớn nhất nên 6 phân vùng và 3 ngày.

| Topic | Sự kiện | Khóa phân vùng | Phân vùng, giữ |
|---|---|---|---|
| `{tenant}.iam.user.created.v1` | EVT-12-01 | `userId` | 3, 7 ngày |
| `{tenant}.iam.user.state-changed.v1` | EVT-12-02 | `userId` | 3, 7 ngày |
| `{tenant}.iam.user.role-changed.v1` | EVT-12-03 | `userId` | 3, 7 ngày |
| `{tenant}.iam.user.credential-changed.v1` | EVT-12-04 | `userId` | 3, 7 ngày |
| `{tenant}.iam.access.revoked.v1` | EVT-12-05 | `tenantCode` | 3, 7 ngày |
| `{tenant}.iam.client.provisioned.v1`, `….client.state-changed.v1`, `….client.credential-changed.v1` | EVT-12-06, 07, 08 | `clientId` | 3, 7 ngày |
| `{tenant}.iam.policy.published.v1`, `….policy.revoked.v1` | EVT-12-09, 10 | `policyCode` | 3, 7 ngày |
| `{tenant}.iam.grant.state-changed.v1` | EVT-12-11 | `grantId` | 3, 7 ngày |
| `{tenant}.iam.sod.exception-changed.v1` | EVT-12-12 | `exceptionId` | 3, 7 ngày |
| `{tenant}.iam.realm.changed.v1`, `….recert.completed.v1` | EVT-12-13, 15 | `tenantCode` | 3, 7 ngày |
| `{tenant}.iam.alert.raised.v1` | EVT-12-14 | `alertId` | 3, 7 ngày |
| `{tenant}.iam.auth.event-recorded.v1` | EVT-12-16 | `sub` | 6, 3 ngày |

: Topic Kafka của PH-12

### 7.4. Valkey

Bộ đệm quyết định của PEP nằm trong tiến trình (Caffeine), không ở Valkey (SDD §4.11). Valkey chỉ giữ bộ đếm cửa sổ trượt của `AlertEngine`, khóa tạo bằng `TenantKeys.of(tenant, …)` nên luôn có tiền tố tenant: `{tenant}:iam:an01:{ip}` (đăng nhập sai theo địa chỉ), `{tenant}:iam:an02:{user}` (địa chỉ đăng nhập thành công), `{tenant}:iam:an07:{client}` (xác thực client sai). Thời hạn khóa bằng cửa sổ của luật cộng 5 phút; mất Valkey chỉ làm mất bộ đếm đang chạy, không mất cảnh báo đã tạo (đã ở bảng `alert`).

### 7.5. Kho đối tượng

Kho đối tượng chứa gói chính sách đã ký và tệp nhập tạm; không chứa dữ liệu nào mà CSDL cần làm nguồn sự thật.

| Bucket | Nội dung | Vòng đời |
|---|---|---|
| `dh-platform-policy` (Garage, `TPH-0`) | `platform/bundle.tar.gz`, `tenants/{tenant}/bundle.tar.gz`, `releases/{revision}.tar.gz` (bản bất biến để quay lui), `.signatures.json` | Gói hiện hành giữ đến khi thay; bản phát hành giữ 12 tháng (giả định) |
| `dh-iam-import` (đề xuất, Garage) | Tệp nhập người dùng đã qua bộ quét mã độc, khóa `{tenant}/{importId}` | Lifecycle 24 giờ; `user_import.file_ref` đặt rỗng khi xóa |

: Bucket kho đối tượng của PH-12

Garage chưa có khóa đối tượng đầy đủ (ADR-008) nên tính toàn vẹn của gói do chữ ký bảo đảm, không do kho: ghi được vào bucket vẫn không đổi được chính sách (SDD §7). Bằng chứng cần WORM đi theo chuỗi băm kiểm toán của PH-13 trên Ceph RGW, không ở bucket này.

### 7.6. Loki, chuỗi kiểm toán và Git

Nhật ký quyết định ủy quyền (EN-12-15) và sự kiện xác thực ghi vào Loki, nhãn `tenant` bắt buộc, giữ 12 tháng trực tuyến; quyết định từ chối, truy cập mức Nhạy cảm và thay đổi quyền còn vào chuỗi băm kiểm toán của PH-13 (WORM 5 năm, ADR-031). Kho Git `dh-policies` giữ bản sao mọi phiên bản `PUBLISHED` và ca kiểm thử (`ph12_iam` vẫn là nguồn sự thật); kho cấu hình Git theo tenant (ADR-068) giữ mẫu realm và tệp giá trị bảo mật của từng tỉnh.

## 8. Sao lưu, khôi phục và lưu giữ

Chương này nêu quy mô dữ liệu, cách sao lưu và khôi phục, và thời hạn giữ từng loại dữ liệu. Vì `ph12_iam` nhỏ và nằm ở `pg-core`, sao lưu theo chế độ chung của cụm; phần cần thiết kế riêng là thứ tự khôi phục giữa các kho không chung giao dịch.

### 8.1. Quy mô dữ liệu

Bảng dưới ước lượng cho một tỉnh vừa theo hồ sơ GĐ-12-02: 3.000 cán bộ, bình quân 4 gán vai trò mỗi người, 200 HTTT mỗi client 10 scope, 12 nút cổng và OPA. Số liệu là **giả định** để định cỡ, kích thước dòng gồm cả chỉ mục; thay bằng số thật khi khảo sát tỉnh thí điểm.

| Nhóm | Số dòng ổn định | Dung lượng ước tính |
|---|---|---|
| `user_account` và chỉ mục tìm kiếm | 3.000 | 5 MB |
| `role_assignment`, `sod_exception`, `org_group`, `org_group_member` | 12.000, vài chục, 300, 3.000 | 10 MB |
| `client`, `client_scope`, `client_credential` | 200, 2.000, 400 | 2 MB |
| `policy`, `policy_version`, ca và kết quả kiểm thử, chạy khô | tối đa 500 phiên bản `PUBLISHED` (NFR-12-024), nội dung trung bình 8 KB | 10 MB |
| `bundle_release`, `bundle_ack` | khoảng 50 gói mỗi ngày, giữ ack 30 ngày × 12 nút | 15 MB |
| `alert`, `account_report_daily`, `mfa_coverage_daily` | 24 tháng: 7.200, 730, 730 | 8 MB |
| `outbox`, `sync_task`, `idempotency_key` | khoảng 5.000 sự kiện mỗi ngày giữ 3 ngày; việc đồng bộ; 1.000 khóa mỗi ngày giữ 24 giờ | 20 MB |
| Còn lại (liên kết, realm, thu hồi, nhập) | dưới 2.000 | 5 MB |
| **Tổng mỗi tỉnh** | | **khoảng 75 MB** |

: Ước lượng dung lượng ph12_iam cho một tỉnh vừa (giả định)

Ở `QM-CHUNG` (34 tenant) cộng khoảng 2,6 GB, không đáng kể so với `pg-core` (60 GB ở `QM-NHO` đến 6,5 TB ở `QM-CHUNG`, D03-09 §5.3). Không bảng nào vượt vài chục nghìn dòng ổn định nên không phân vùng; các bảng quay vòng nhanh (`outbox`, `sync_task`, `idempotency_key`) đặt `autovacuum_vacuum_scale_factor = 0,02` ngay trong DDL (cả `bundle_ack`) để bảng không phình sau mỗi đợt xóa.

### 8.2. Sao lưu và khôi phục

`pg-core` sao lưu bằng CloudNativePG với plugin Barman Cloud: bản sao cơ sở hằng ngày cộng WAL liên tục ra kho S3 có khóa đối tượng chế độ tuân thủ ở ngoài cụm và ngoài site (Ceph RGW, ADR-035), mã hóa phía máy khách, giữ 35 ngày và 12 tháng cho bản tháng; có xuất logic theo tenant hằng ngày để khôi phục một tỉnh riêng lẻ. Bản sao DR streaming ở site thứ hai có độ trễ dưới 10 giây (D03-09 §7). `ph12_iam` thuộc `TPH-1`: RPO thực tế cỡ một phút, RTO không quá 4 giờ; trần RPO 15 phút áp dụng khi kênh liên site đã đứt trước sự cố (NFR-00-014).

Quan trọng hơn con số là hành vi khi `pg-core` ngừng hoặc phải khôi phục: Keycloak (`pg-iam`, `TPH-0`) vẫn đăng nhập và phát token, OPA vẫn quyết định bằng gói đã nạp trong ít nhất 24 giờ, APISIX vẫn chặn theo danh sách chặn đã kéo (NFR-12-013). Cái dừng là phần quản trị: tạo người dùng, gán vai trò, duyệt chính sách, thu hồi qua giao diện (khoảng hở thu hồi được nêu ở Q12-23 của SDD).

Thứ tự khôi phục sau thảm họa nhiều kho, cùng nguyên tắc với PH-05: **OpenBao trước, rồi `pg-iam`, rồi `pg-core`**. Các tình huống lệch giữa các kho:

| Tình huống sau khôi phục | Hiện tượng | Cách xử lý |
|---|---|---|
| `ph12_iam` cũ hơn Keycloak (mất tối đa một RPO) | Keycloak có người dùng hoặc vai trò mà `ph12_iam` chưa có | `SyncReconciler` đối soát theo nguyên tắc "Keycloak đúng với thông tin đăng nhập, `ph12_iam` đúng với vai trò"; vai trò chỉ có ở Keycloak bị gỡ, lỗi nghiêng về thiếu quyền (SDD §8.4) |
| `ph12_iam` mới hơn Keycloak | `user_account.sync_state` còn `PENDING` hoặc `keycloak_id` trỏ tới người dùng không còn | Phát lại `sync_task` lũy đẳng, tra theo `dh_user_id` trước khi tạo |
| Mất vài mục `revocation_entry` mới nhất | Cổng quên một lệnh thu hồi | Người dùng, client bị thu hồi vẫn bị vô hiệu ở Keycloak nên token mới không cấp được; token cũ sống tối đa 5 phút; cán bộ ATTT đối chiếu sự kiện quản trị Keycloak và thu hồi lại phần thiếu |
| Gói chính sách của OPA cũ hơn `bundle_release` | `bundleRevision` ở bảng và ở OPA không khớp | `BundleBuilder` dựng bản phát hành mới từ `ph12_iam` (digest khác thì phát hành), OPA nạp trong 60 giây |
| OpenBao cũ hơn `ph12_iam` | `federation.secret_ref`, `service_account.kid` trỏ tới phiên bản không còn | Kiểm tra liên kết, đăng ký khóa báo lỗi rõ; TA khai lại bí mật bind, đơn vị triển khai đăng ký khóa mới |

: Tình huống lệch giữa các kho sau khôi phục

### 8.3. Lưu giữ

Bảng dưới là thời hạn giữ của từng nhóm dữ liệu và cơ chế dọn: dữ liệu nghiệp vụ giữ vĩnh viễn, dữ liệu kỹ thuật giữ ngắn.

| Dữ liệu | Thời hạn | Cơ chế dọn |
|---|---|---|
| `user_account`, `role_assignment`, `sod_exception`, `org_group`, `custom_role`, `privileged_grant`, `recert_*`, `client`, `federation`, `saml_client`, `vneid_link`, `service_account`, `realm_*`, `tenant_merge_step` | Vĩnh viễn (không xóa vật lý, BR-12-035); ẩn danh hóa dữ liệu cá nhân theo Q12-54 | Không |
| `policy`, `policy_version`, ca và kết quả kiểm thử, `bundle_release` | Vĩnh viễn (NFR-12-030) | Không |
| `policy_dryrun_report` | 12 tháng (`purge_after`) | Xóa sau hạn; trigger chặn xóa trong hạn |
| `account_report_daily`, `mfa_coverage_daily` | 24 tháng (`purge_after`) | Tác vụ dọn hằng ngày |
| `alert`, `alert_ack` | 24 tháng (giả định, dài hơn log an ninh 12 tháng vì cần cho rà soát) | Tác vụ dọn theo `first_seen_at` |
| `client_credential` dòng `RETIRED`, `revocation_entry` đã hạ cờ | 12 tháng; 7 ngày sau `expires_at` | Tác vụ dọn |
| `user_import`, `user_import_row` | 30 ngày sau khi xong (giả định); tệp gốc 24 giờ | Tác vụ dọn |
| `sync_task` | `DONE` 7 ngày, `FAILED` 30 ngày | Tác vụ dọn |
| `idempotency_key`, `outbox`, `bundle_ack`, `node_heartbeat` | 24 giờ; 3 ngày; 30 ngày; 24 giờ im lặng | Tác vụ dọn theo `expires_at`, `created_at`, `acked_at`, `last_seen_at` |
| Nhật ký quyết định, sự kiện xác thực (Loki) | 12 tháng trực tuyến | Chính sách giữ của Loki |
| Chuỗi kiểm toán (quyết định từ chối, mức Nhạy cảm, thay đổi quyền) | 12 tháng trực tuyến, WORM 5 năm | PH-13, ADR-031 |
| Bản phát hành gói ở kho | 12 tháng (giả định) | Lifecycle bucket |
| Bản sao lưu `pg-core` | 35 ngày; bản tháng 12 tháng | ADR-035 |
| Kafka `*.iam.*` | 7 ngày; sự kiện xác thực 3 ngày | Cấu hình topic |

: Thời hạn lưu giữ dữ liệu PH-12

Tác vụ dọn chạy hằng ngày theo từng tenant (`TenantContext.runAs`) bằng `DELETE` theo chỉ mục `*_purge`, `*_expiry`, `*_created`; vai trò ứng dụng chỉ có `DELETE` trên đúng các bảng cần dọn (mục 1.5). Vì không có phân vùng nên không dùng `DETACH PARTITION`; lượng xóa mỗi ngày nhỏ (vài nghìn dòng mỗi tỉnh).

## 9. Ánh xạ dữ liệu hệ cũ sang thiết kế mới

Chương này là đầu vào cho D06-01 (di trú) và cho nhập người dùng hàng loạt (FR-12-009). Trước hết cần nói rõ ba nguồn "hệ cũ" vì chúng khác bản chất, và chỉ một nguồn có dữ liệu thật để chuyển.

### 9.1. Ba nguồn hệ cũ

Ba nguồn dưới đây đều gọi là hệ cũ nhưng khác bản chất, nên cần tách để biết chỗ nào có dữ liệu thật để chuyển.

| Nguồn | Hiện trạng | Có dữ liệu để di trú không |
|---|---|---|
| Mô hình dữ liệu trong `docs/07-srs/SRS-PH-12-iam.md` §4 (16 thực thể tiếng Việt) | Chỉ là đặc tả của repo, chưa có bảng nào chạy; schema `ph12` ở compose rỗng ("IAM bridge metadata") | Không. Mục 9.2 ánh xạ **thiết kế** cũ sang thiết kế mới để người đọc SRS cũ tra được |
| Keycloak của hệ LGSP cũ và midPoint (SSO SAML của màn quản trị Bus) ở từng tỉnh | Một realm dùng chung cho các khối, vai trò tự đặt ở từng khối, khóa của HTTT cấp tay dạng văn bản (FRS §2.1) | Có (người dùng, vai trò, client) nhưng lược đồ CSDL của hai hệ này ở tỉnh chưa có trong tài liệu được cung cấp. Giả định: xuất được qua Admin API của Keycloak và công cụ xuất của midPoint; đối chiếu khi có bản xuất của tỉnh (Q12-05, FRS §11.4) |
| Realm `lgsp` ở `deploy/compose/keycloak/realm-lgsp.json` | Môi trường phát triển: năm vai trò (`PLATFORM_ADMIN`, `INTEGRATION_ADMIN`, `INTEGRATION_REVIEWER`, `INTEGRATION_DEVELOPER`, `OPERATOR`), client `lgsp-console`, `lgsp-control` và vài người dùng thử | Không chuyển dữ liệu; chỉ lấy tên vai trò để ánh xạ (bảng `legacy_role_map`) |

: Ba nguồn hệ cũ của PH-12

### 9.2. Thực thể của SRS cũ sang bảng mới

Mã thực thể cũ trùng EN-12-01…06 nhưng mang nghĩa khác; FRS §11.5 đã nối sang EN mới, bảng dưới nối tiếp đến bảng và cột.

| Thực thể, cột cũ | Bảng, cột mới | Chuyển đổi, ghi chú |
|---|---|---|
| `NGUOI_DUNG` (`nguoi_dung_id`, `ten_dang_nhap`, `ho_ten`, `thu_dien_tu`, `ma_don_vi`, `chuc_danh`) | `user_account` (`id`, `username`, `full_name`, `email`, `org_code`, `title`) | Đổi tên cột sang tiếng Anh số ít; `username` giữ mẫu chữ thường nhưng tối thiểu 3 ký tự |
| `NGUOI_DUNG.trang_thai` (`PENDING_ACTIVATION`, `ACTIVE`, `LOCKED`, `SUSPENDED`, `DISABLED`) | `user_account.state` | `SUSPENDED` (90 ngày không đăng nhập) thành `DISABLED` với `disabled_reason = 'INACTIVE_45D'`; thêm `BLOCKED` (FRS §4.3) |
| `NGUOI_DUNG.mfa_bat_buoc` (boolean) | `user_account.mfa_level` (1…3) | Tính lại từ vai trò: vai trò `mfaRequired` ra mức 2, quản trị ra mức 3 (BR-12-015) |
| `NGUOI_DUNG.so_lan_that_bai`, `khoa_den` | Không chuyển | Keycloak giữ trạng thái chống dò mật khẩu |
| `NGUOI_DUNG.dang_nhap_cuoi` | `user_account.last_login_at` | Chép một lần khi di trú; sau đó do sự kiện EVT-12-16 cập nhật |
| `VAI_TRO` (kể cả `vai_tro_cha_id`, `la_he_thong`) | Không bảng cho vai trò chuẩn; `custom_role` cho vai trò tùy biến | 22 vai trò chuẩn nằm ở `roles.json`; bỏ phân cấp vai trò (22 vai trò phẳng); `la_he_thong = false` thành `custom_role` có mã `CUSTOM_*` (Đợt 2) |
| `NGUOI_DUNG_VAI_TRO` (`hieu_luc_tu`, `hieu_luc_den`, `nguoi_gan`) | `role_assignment` (`valid_from`, `valid_to`, `created_by`) | Thêm `scope_type` (mặc định `TENANT`) và `scope_ref`; qua `legacy_role_map` và kiểm tách nhiệm vụ khi chèn |
| `PHAM_VI` (`congdan.read`, `datdai.read`…) | Không còn bảng | Scope mới sinh theo nguồn duyệt (`api:{mã API}:{mã gói}`…); mức nhạy cảm do PH-02, PH-09 giữ |
| `VAI_TRO_PHAM_VI` | `permissions.json` và gói chính sách (`role_perms`) | Sinh từ D02-08, không nhập tay (FR-12-051) |
| `CLIENT` (`client_id`, `ten_he_thong`, `ma_don_vi`, `loai_xac_thuc`, `bat_buoc_mtls`, `trang_thai`) | `client` (`client_id`, `name`, `org_code`, `auth_method`, `contract_level`, `state`) | `bat_buoc_mtls` thành `contract_level = 'SENSITIVE'`; `ENABLED`, `DISABLED` thành `ENABLED`, `SUSPENDED`; thêm `system_code` (mã HTTT ở PH-01) |
| `CLIENT.vault_secret_ref` | Không chuyển | Bí mật chỉ giao một lần qua token bọc, không lưu tham chiếu ở CSDL quản trị (BR-12-023) |
| `CLIENT_PHAM_VI` (`nguoi_duyet`, `ngay_duyet`) | `client_scope` (`scope`, `source`, `source_ref`) | Người duyệt nằm ở phân hệ nguồn (`source_ref`), không lưu lại |
| `YEU_TO_XAC_THUC` (`du_lieu_ma_hoa`…) | Không bảng (Keycloak, EN-12-06) | Không chuyển; người dùng đăng ký lại yếu tố thứ hai |
| `PHIEN` | Không bảng (Keycloak, EN-12-07) | Không chuyển; phiên cũ hết hạn |
| `LIEN_KET_VNEID` (`so_dinh_danh`) | `vneid_link` (`subject_hash`) | Số định danh rõ thành băm HMAC có khóa; không lưu số rõ (BR-12-045) |
| `CHINH_SACH` (`ma_chinh_sach`, `phien_ban_hien_tai`) | `policy` (`code`) | `phien_ban_hien_tai` thành chỉ mục duy nhất từng phần theo `PUBLISHED`; thêm `scope`, `is_root` |
| `CHINH_SACH_PHIEN_BAN` (`so_phien_ban`, `noi_dung_rego`, `trang_thai`, `nguoi_soan`, `nguoi_duyet`, `phat_hanh_luc`, `git_commit`) | `policy_version` (`version_no`, `content`, `state`, `author`, `approved_by`, `published_at`, `git_commit`) | `TESTING` bỏ, `PENDING_APPROVAL` thành `PENDING_REVIEW`; thêm `CHANGES_REQUESTED`, `APPROVED`, `DISCARDED` (ADR-069); `content_hash` do CSDL tính |
| `CA_KIEM_THU` (`dau_vao`, `ket_qua_mong_doi` boolean) | `policy_test_case` (`input`, `expected`, `kind`) | `ket_qua_mong_doi` thành `expected = {"allow": …}`; `kind = 'POSITIVE'` khi đúng, `'NEGATIVE'` khi sai |
| `THUC_THE_TRUONG`, `MAT_NA_TRUONG` | Không còn bảng | Tập trường và mức phân loại do PH-07, PH-02, PH-09 giữ, vào gói dữ liệu `entities` (FRS §11.5) |
| `QUYET_DINH` | Không bảng PostgreSQL | Loki 12 tháng và chuỗi kiểm toán PH-13 (WORM 5 năm); không dùng MinIO vì hạ tầng mới không có |

: Ánh xạ thực thể SRS cũ của repo sang bảng PH-12

### 9.3. Dữ liệu Keycloak, midPoint của hệ cũ ở tỉnh

Hệ cũ ở tỉnh không có bảng của PH-12 để chép; việc chuyển là dựng lại đối tượng tương ứng qua chức năng của PH-12, như bảng dưới.

| Đối tượng cũ | Đối tượng mới | Cách chuyển |
|---|---|---|
| Realm dùng chung của hệ cũ (`lgsp` ở compose) | Một realm `dh-{tenant}` cho mỗi tỉnh (`realm_state`) | Không chuyển realm: PH-20 tạo realm từ mẫu (FR-12-041); người dùng nhập vào đó |
| Người dùng Keycloak, midPoint | `user_account` | Nhập hàng loạt hai pha (`user_import`, `user_import_row`): xem trước rồi xác nhận, tối đa 5.000 dòng mỗi lần; mật khẩu không chuyển, tài khoản vào `PENDING_ACTIVATION` và nhận liên kết kích hoạt (BR-12-018, BR-12-043) |
| Vai trò của từng khối | `role_assignment` | Qua `legacy_role_map` (17 dòng khởi tạo); vai trò chưa có ánh xạ báo ERR-12-036 để TA chọn (Q12-05) |
| Cặp vai trò cũ nay xung đột (ví dụ cùng người giữ kỹ sư và người duyệt tích hợp) | `sod_exception` hoặc tách vai trò | Dòng nhập dính cặp xung đột bị `WARN`; TA đề nghị ngoại lệ, SO duyệt, tối đa 90 ngày |
| Consumer Key, Secret của HTTT (APIM, NGSP) | `client`, `client_credential`, `client_scope` | Không chuyển khóa: cấp client mới từ hồ sơ kết nạp đã duyệt, chạy song song với khóa cũ trong giai đoạn chuyển (BP-09); bí mật mới giao một lần |
| Cấu hình LDAP, AD ở Keycloak cũ | `federation` | Khai lại, qua ba kiểm tra và SO duyệt (FR-12-026); bí mật bind ghi mới vào OpenBao |
| SSO SAML của midPoint cho màn quản trị Bus | OIDC; `saml_client` chỉ cho ứng dụng cũ còn cần | Thay thế (LGC-IAM-008); ứng dụng SAML còn dùng khai báo ở `saml_client` |
| Đăng nhập mạng xã hội | Không | Loại bỏ (LGC-IAM-007); VNeID khi có yêu cầu (`vneid_link`) |

: Ánh xạ dữ liệu định danh của hệ cũ ở tỉnh

### 9.4. Chạy lại và đối soát

Nhập người dùng lũy đẳng theo `username` và `email` trong tenant: chạy lại cùng tệp không nhân đôi, dòng trùng báo `ERROR` ở bước xem trước. Đối soát sau di trú dùng chính các bảng nhập:

```sql
-- Kết quả lần nhập: số dòng theo từng trạng thái (xem trước và tạo)
SELECT result, count(*) FROM ph12_iam.user_import_row WHERE import_id = :import_id GROUP BY result ORDER BY result;
-- Người dùng đã tạo nhưng chưa kích hoạt sau 24 giờ
SELECT id, username FROM ph12_iam.user_account WHERE state = 'PENDING_ACTIVATION' AND created_at < now() - interval '24 hours';
```

Báo cáo đối soát liệt kê: số người dùng ở hệ cũ, số dòng `OK`, `WARN`, `ERROR`, số đã tạo, số đã kích hoạt, vai trò chưa ánh xạ, người dùng dính cặp xung đột. Nghiệm thu bước chuyển định danh khi không còn dòng `ERROR` chưa xử lý, 100% người dùng đang làm việc đã kích hoạt và người thuộc nhóm `mfa-required` đã đăng ký yếu tố thứ hai (`mfa_coverage_daily`).

## 10. Câu hỏi mở

Năm câu hỏi dưới đây phát sinh khi chuyển thiết kế SDD sang bảng và ràng buộc. Mỗi câu nêu vấn đề và đề xuất tạm; DDL hiện tại chạy theo đề xuất.

> **Câu hỏi mở Q12-50:** Chính sách phạm vi `PLATFORM`, kể cả `base-authz`, nằm ở tenant `PLATFORM` nên cán bộ ATTT của tỉnh không đọc được Rego gốc khi viết luật `deny` chặt hơn và ca kiểm thử, dù `PERM-12-read` có nghĩa "xem chính sách". Đề xuất tạm: giữ như SDD §6 (chỉ nhân sự nền tảng thấy) và cung cấp Rego gốc cho tỉnh qua tài liệu; nếu cần, chiếu bản `PUBLISHED` thành dòng `COMMON` chỉ đọc theo mẫu S. Cần cán bộ ATTT xác nhận Rego gốc có được công khai với tỉnh không.

> **Câu hỏi mở Q12-51:** SDD §6 nói nhân sự nền tảng xem dữ liệu tenant khác qua nhóm API `/api/platform/` kèm quyền có thời hạn, "không bằng cách đổi `app.tenant_id`", nhưng CSDL không có ngoại lệ RLS cho phiên `PLATFORM` (mẫu G chỉ cho tenant đích đọc dòng quyền). Đề xuất tạm: dịch vụ đặt `app.tenant_id` bằng tenant đích **sau khi** OPA xác nhận quyền `ACTIVE` còn hạn và đã ghi kiểm toán vào chuỗi của tenant đích, để RLS vẫn là lớp cuối. Cần kiến trúc sư xác nhận cách này hay dùng hàm `SECURITY DEFINER` hẹp cho từng truy vấn.

> **Câu hỏi mở Q12-52:** API danh sách chặn (API-12-079) trả mục của mọi tenant cho cổng dùng chung, nhưng bảng `revocation_entry` theo mẫu P nên dịch vụ phải lặp từng tenant mỗi lần kéo. Ước tính 34 tenant × 12 nút cổng, mỗi 10 giây, khoảng 40 truy vấn nhỏ mỗi giây, chấp nhận được nhưng tăng theo số tenant. Đề xuất tạm: dựng danh sách trong bộ nhớ và chỉ dựng lại khi `revocation_feed_version.version` đổi. Nếu vượt khoảng 100 tenant, cần đo lại hoặc dùng bảng chiếu không RLS chỉ chứa mã như `callback_route` của PH-19 (ADR-045). Cần kiến trúc sư xác nhận.

> **Câu hỏi mở Q12-53:** Client bị thu hồi không dùng lại mã (FRS §4.4) nhưng `clientId` bằng mã HTTT viết thường (SDD §4.8). CSDL cho phép cấp lại client cho cùng HTTT với `client_id` khác (`uq_client_system` chỉ xét client chưa thu hồi, `uq_client_client_id` cấm trùng); đề xuất hậu tố `-r{n}` (ví dụ `qlvb-so-tttt-r2`). Cần PH-01 và PH-03 xác nhận quy tắc đặt tên, cách thông báo cho đầu mối và việc APISIX, OPA nhận `clientId` mới.

> **Câu hỏi mở Q12-54:** Tài khoản `DISABLED` giữ họ tên và thư điện tử vô thời hạn để truy vết (BR-12-035), trái nguyên tắc hạn chế lưu trữ của Luật BVDLCN 91/2025 nếu cán bộ đã nghỉ nhiều năm. Đề xuất tạm: ẩn danh hóa `full_name`, `email`, `username`, `title` (băm không đảo ngược, giữ `id` và trạng thái) sau 5 năm kể từ `disabled_at`, khớp thời hạn WORM của chuỗi kiểm toán; theo yêu cầu của cán bộ thì ẩn danh sớm hơn. Cần pháp chế xác nhận mốc 5 năm và quyền yêu cầu ẩn danh sớm.


## Đề nghị đồng bộ

Các việc dưới đây ở tài liệu dùng chung hoặc phân hệ khác do luồng khác chịu trách nhiệm; tập này chỉ ghi lại để đợt đồng bộ cuối xử lý.

| Tài liệu | Đề nghị |
|---|---|
| D03-02-PH12 (SDD) | Cập nhật danh sách bảng thành 43 bảng, thêm `sod_pair`, `legacy_role_map`, `shedlock`; `SodGuard` dùng `sod_pair` làm bản chốt ở CSDL (tệp `SodRuleSet` vẫn là nguồn sinh, CI so hai nguồn); `ExceptionTranslator` ánh xạ `SQLSTATE` `P12nn` theo mục 3.44; ghi `realm_state`, `realm_provision_step`, `tenant_merge_step`, `service_account` mang `tenant_id = 'PLATFORM'`; ghi `revocation_entry.keycloak_confirmed_at`, mã nhóm `org_group.code` chữ hoa, hậu tố `-r{n}` của client cấp lại (Q12-53) |
| D03-04-PH12 (API) | Ánh xạ lỗi CSDL sang ERR (mục 3.44); `ETag` bằng cột `version`; phản hồi lũy đẳng của API cấp client không lưu `wrappingToken` (chỉ `handoverId`); API-12-079 trả số thứ tự toàn cục của `revocation_feed_version` |
| D03-10 §4 (mẫu RLS) | Thêm mẫu G (đọc theo `target_tenant`) cho quyền có thời hạn, và quy ước dữ liệu của chính nền tảng dùng `tenant_id = 'PLATFORM'`; hiện D03-10 chỉ nêu mẫu cơ bản và `COMMON` |
| D02-08 §4 | Dòng "`AUDITOR` với mọi vai trò có quyền ghi của PH-19" nên liệt kê tường minh bốn vai trò `PAYMENT_ADMIN`, `PAYMENT_APPROVER`, `PAYMENT_ACCOUNTANT`, `PAYMENT_OPERATOR` như đã khai triển ở `sod_pair`, để D02-08 và dữ liệu khởi tạo không lệch |
| D02-03-PH12 (FRS) | Bảng §11.4 thêm hai vai trò của realm `lgsp` ở compose (`INTEGRATION_DEVELOPER`, `INTEGRATION_ADMIN`) vào Q12-05; FR-12-017 ghi tenant bị truy cập đọc được quyền có thời hạn vào mình (mẫu G) |
| D03-09 §5.3, §8 | Ghi `ph12_iam` khoảng 75 MB mỗi tỉnh vừa vào định cỡ `pg-core`; ghi bucket `dh-iam-import` (đề xuất) cạnh `dh-platform-policy` |
| D00-04 §2, §3.2 | Khi các tập khác của PH-12 xong, cập nhật tình trạng tài liệu; chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu`; ghi schema PH-12 là `ph12_iam` |
| D05-02-PH12 (Test case) | Dùng 24 nhóm của `ph12_isolation_test.sql` làm cơ sở cho ca kiểm thử CSDL, và `TenantIsolationIT` cho ca đồng thời |
| PH-20 | Token dịch vụ của PH-20 mang tenant `PLATFORM` để ghi `realm_state`; bước khởi tạo realm ghi `realm_provision_step` theo khóa lũy đẳng |
| ADR đề xuất (chưa tạo, dải 014–019 còn trống) | Ngoài (a)…(g) đã nêu ở FRS và SDD: (h) Chốt tách nhiệm vụ, bốn mắt và máy trạng thái ở CSDL bằng trigger kèm khóa tư vấn, bổ sung ADR-069; (i) Mẫu RLS G cho quyền có thời hạn vào tenant khác |

: Đề nghị đồng bộ cho tài liệu dùng chung và phân hệ khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-CSDL và K-TRINH-BAY: tóm tắt cho hội đồng, giới thiệu; chiến lược lưu trữ (vai trò, ba mẫu RLS P, S, G, quy ước, danh mục 43 bảng, quyền); bốn ERD; đặc tả 43 bảng với khối 10 mục sinh từ DDL; 25 quy tắc chốt ở CSDL kèm ánh xạ `SQLSTATE` sang ERR; DDL sáu tệp đã chạy thử trên PostgreSQL 16.16 và bài kiểm 100 khối PASS; dữ liệu cá nhân và không lưu bí mật; dữ liệu khởi tạo; kho ngoài PostgreSQL; sao lưu, khôi phục, lưu giữ; ánh xạ hệ cũ; 5 câu hỏi mở (Q12-50…Q12-54); đề nghị đồng bộ |

