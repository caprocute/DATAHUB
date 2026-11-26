# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-30
Tính năng: TS-10-30 · Cô lập tenant: RLS, ACL Kafka theo tiền tố, Apicurio, OPA

  @TC-10-123 @P1 @Bảo @mật
  Kịch bản: TC-10-123 RLS của ph10_event chặn đọc, ghi chéo tenant
    # Truy vết: FR-10-064 · NFR-10-017 · BR-10-001
    # Mục đích: Chứng minh yêu cầu an toàn nêu ở tên ca không có đường vòng, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).
    Biết CSDL rỗng đã áp `ph10_event.sql`; vai trò `dh_integration_app`, `dh_report_ro` (`NOBYPASSRLS`).
    Khi chạy `psql -v ON_ERROR_STOP=1 -f 03-thiet-ke/csdl/ph10/test/ph10_isolation_test.sql`.
    Và với `app.tenant_id = 'T90'`, `SELECT` và `UPDATE` mọi bảng có `tenant_id` nhắm dòng của T91; `INSERT` dòng `tenant_id = 'T91'`.
    Và đặt `app.tenant_id` rỗng, rồi `'COMMON'`, rồi `'PLATFORM'`.
    Thì mọi khối kiểm in PASS. Bước 2 đọc 0 dòng, cập nhật 0 dòng, chèn bị chặn bởi `WITH CHECK`. Bước 3 không đọc được dòng tenant nào; `COMMON` chỉ ghi được khi `PLATFORM` (bảng chế độ S); 28 bảng đều `FORCE ROW LEVEL SECURITY`.
    # Hậu điều kiện: Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.

  @TC-10-124 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-124 API control plane không lộ đối tượng tenant khác
    # Truy vết: FR-10-064, 002, 006, 007, 025, 035, 050, 052 · API-10-003, 010, 034, 039, 044, 048, 061, 104, 058 · ERR-10-001, 005
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).
    Biết U-T68-IE1; T01 có đối tượng trùng mã mục 2.3.
    Khi với mỗi API đọc có tham số đường dẫn (API-10-003, 010, 021, 024, 034, 039, 044, 048, 052, 053, 055, 058, 061, 104, 110), gọi bằng mã của đối tượng chỉ có ở T01, rồi bằng mã không tồn tại.
    Và gọi `GET /topics/t01.dkkd.doanh-nghiep.da-cap-phep.v1` bằng token T68.
    Và thử đặt tiêu đề `X-Dh-Tenant: T01`, tham số `tenant=T01`, trường `tenantId` trong thân.
    Thì bước 1 mọi cặp trả 404-ẩn giống hệt nhau trừ `traceId`. Bước 2 404-ẩn. Bước 3 bị bỏ qua, tenant luôn lấy từ token; ghi mới đều thuộc T68 hoặc bị `422` ERR-10-005 với tên topic tiền tố khác.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-125 @P1 @Bảo @mật
  Kịch bản: TC-10-125 ACL Kafka theo tiền tố tenant cho principal nội bộ, literal cho HTTT
    # Truy vết: FR-10-064, 031, 037 · ERR-10-120 · BR-10-018, 022 · ADR-072
    # Mục đích: Chứng minh yêu cầu an toàn nêu ở tên ca không có đường vòng, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).
    Biết principal `User:CN=dh-runtime-t90`, `User:CN=dh-runtime-t91`; HTTT T90 có ACL literal trên một topic.
    Khi liệt kê ACL của cụm (`kafka-acls --list`).
    Và `dh-runtime-t90` đọc, ghi topic `t91.*`; tham gia nhóm `dh-sub-t91-*`.
    Và HTTT T90 đọc topic khác của T90 không có subscription; mô tả danh sách topic của cụm.
    Và kyverno: commit `KafkaTopic` tên `t91.x.y.z.v1` vào kho `dh-config-t90`.
    Thì bước 1 không principal nào của tenant A có ACL trên tiền tố hay nhóm của tenant B; ACL nội bộ là `PREFIXED` `t90.`, của HTTT là `LITERAL`. Bước 2, 3 bị từ chối, liệt kê topic chỉ trả topic được phép. Bước 4 Kyverno từ chối, không có topic nào được tạo.
    # Hậu điều kiện: Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.

  @TC-10-126 @P1 @Bảo @mật
  Kịch bản: TC-10-126 Apicurio, OPA và Valkey theo tenant
    # Truy vết: FR-10-064, 024 · API-10-084 · ERR-10-103
    # Mục đích: Chứng minh yêu cầu an toàn nêu ở tên ca không có đường vòng, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).
    Biết client HTTT T90 có scope subscribe một topic T90; bundle OPA `event/grants/t90.json`, `t91.json`.
    Khi tra artifact nhóm `t91` qua API-10-084; liệt kê nhóm.
    Và sửa thủ công token T90 thêm scope `topic:t91.….v1:subscribe` (ký bằng khóa Keycloak thử của T90) rồi kéo.
    Và đọc khóa Valkey `dh:t91:evt:*` bằng thông tin của cổng T90.
    Thì bước 1 404-ẩn; liệt kê chỉ có `t90`. Bước 2 bị từ chối vì không có cặp cấp quyền trong dữ liệu OPA của T90 và tiền tố khác tenant (404-ẩn ERR-10-103). Bước 3 ACL Valkey từ chối.
    # Hậu điều kiện: Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.

  @TC-10-127 @P1 @Bảo @mật
  Kịch bản: TC-10-127 Bộ rò rỉ đầu cuối T90…T99
    # Truy vết: FR-10-064 · NFR-10-017
    # Mục đích: Chứng minh yêu cầu an toàn nêu ở tên ca không có đường vòng, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).
    Biết T90…T99 mỗi tenant một bộ dữ liệu mục 2.3 sinh bằng `ph10/seed/perf.py`, mã trùng nhau.
    Khi với mỗi cặp (A, B) chạy kịch bản: đọc mọi API của B bằng người dùng A; phát lên topic B bằng client A; kéo subscription B bằng client A; đọc Kafka B bằng principal A; tra lược đồ B.
    Và tìm chuỗi mồi `DH-CANARY-T9n` của B trong mọi phản hồi, log, vết của A.
    Thì 0 lượt thành công trên 90 cặp; 0 lần thấy mồi khác tenant. Kết quả ghi vào báo cáo đêm.
    # Hậu điều kiện: Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.

  @TC-10-128 @P2 @Dương @Bảo @mật
  Kịch bản: TC-10-128 PO xem liên tenant có lý do và kiểm toán
    # Truy vết: FR-10-064, 065 · ERR-10-009
    # Mục đích: Chứng minh luồng thành công, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).
    Biết U-PO.
    Khi U-PO xem dashboard T68 không lý do; có lý do "Hỗ trợ sự cố lag cụm".
    Thì không lý do bị chặn (`400` ERR-10-009); có lý do xem được chỉ đọc; KT: có (truy cập liên tenant, lý do).
    # Hậu điều kiện: Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.
