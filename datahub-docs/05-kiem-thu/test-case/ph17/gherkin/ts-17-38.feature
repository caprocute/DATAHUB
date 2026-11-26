# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-38
Tính năng: TS-17-38 · Cô lập tenant RAG, lọc theo quyền và cô lập CSDL

  @TC-17-132 @P1 @Bảo_mật
  Kịch bản: TC-17-132 Truy hồi vector và từ khóa không trả đoạn của tenant khác
    # Truy vết: NFR-17-007 · FR-17-018, 023, 024 · BR-17-027, 086 · API-17-099, 095 · ERR-17-001
    # Mục đích: Chứng minh NFR-17-007 ở tầng truy hồi: T91 hỏi không bao giờ nhận đoạn T90, kể cả khi nội dung giống hệt và điểm cao nhất.
    Biết T90 và T91 cùng mã API `API-HGD`, cùng nội dung; T90 có thêm API `API-CHI-T90` kèm canary `DH-CANARY-rag-t90`; U-T91-IE; nhiều truy vấn vector, từ khóa, hợp nhất.
    Khi U-T91-IE `POST /search` và `/messages` hỏi `API-CHI-T90` theo tên, theo từ khóa, theo ý nghĩa.
    Và U-T91-IE hỏi `API-HGD`.
    Và ép truy vấn truy hồi thiếu điều kiện `tenant_id` (kiểm thử bằng bản dựng cố ý lỗi).
    Và chạy 500 truy vấn tổng hợp qua T91.
    Thì bước 1 `NO_SOURCE`, 0 canary, 0 đoạn T90. Bước 2 chỉ đoạn của T91 (`tenant_id = T91`). Bước 3 CSDL trả 0 hàng dù thiếu điều kiện do RLS, hoặc truy vấn bị từ chối vì thiếu ngữ cảnh tenant. Bước 4 0 đoạn T90 qua 500 truy vấn.

  @TC-17-133 @P1 @Bảo_mật
  Kịch bản: TC-17-133 Lọc theo quyền người hỏi: 1.000 ca với bảy vai trò và hai tổ chức
    # Truy vết: NFR-17-008 · FR-17-024 · BR-17-035 · API-17-099, 095 · ERR-17-060
    # Mục đích: Chứng minh NFR-17-008: 0 đoạn ngoài phạm vi quyền đọc xuất hiện trong ngữ cảnh gửi mô hình và trích dẫn.
    Biết T90 có 70 đoạn với `acl` khác nhau (theo tổ chức `ORG-SYT`, `ORG-SGD` và mức hiển thị); bảy vai trò `TA, TO, SO, IE, DS, VW, AU`; mỗi vai ở hai tổ chức; ma trận 1.000 cặp (người hỏi, câu hỏi); PH-02 WireMock xác định quyền đọc.
    Khi chạy 1.000 ca và ghi ngữ cảnh gửi mô hình, trích dẫn.
    Và so từng đoạn với quyền đọc thật của người hỏi theo PH-02.
    Và đổi quyền giữa chừng (thu hồi cho 50 ca) và chạy lại.
    Thì 0 đoạn ngoài quyền ở ngữ cảnh và trích dẫn trong 1.000 ca; 50 ca bị thu hồi quyền không còn đoạn tương ứng ở lượt sau.

  @TC-17-134 @P2 @Bảo_mật @Dương
  Kịch bản: TC-17-134 Đoạn COMMON chỉ cho tenant được bật, không lẫn nội dung riêng tenant
    # Truy vết: FR-17-018 · BR-17-027, 086 · NFR-17-007 · API-17-062, 076
    # Mục đích: Chứng minh BR-17-027: đoạn dùng chung chỉ do PA quản và không chứa dữ liệu riêng tenant.
    Biết nguồn `COMMON` `SRC-ERR` (danh mục ERR dùng chung) do U-PA1 quản; T90 bật; T93 tắt; T90 và T91 mỗi bên có nguồn riêng.
    Khi IE T90 hỏi mã lỗi trong `SRC-ERR`.
    Và IE T93 (tắt) hỏi cùng câu.
    Và IE T91 hỏi về tài liệu riêng của T90.
    Và TA T90 `PATCH /knowledge/sources/{SRC-ERR}`.
    Thì bước 1 trả đoạn COMMON. Bước 2 `403` ERR-17-008. Bước 3 không có đoạn riêng T90. Bước 4 `403` ERR-00-403 (tenant không sửa nguồn COMMON).

  @TC-17-135 @P1 @Bảo_mật @Âm
  Kịch bản: TC-17-135 Rò rỉ chéo tenant: mọi API đọc của control plane
    # Truy vết: NFR-17-007 · FR-17-001, 007, 015, 027, 042, 049, 050, 055 · API-17-002, 062, 091, 120, 131, 139, 164, 168 · BR-17-086 · ERR-17-001
    # Mục đích: Chứng minh NFR-17-007 theo D05-01 mục 5.6: danh sách và chi tiết của T90 là `404-ẩn` với T91.
    Biết T90 và T91 cùng mã nguồn, mẫu, bộ đánh giá, câu hỏi mẫu; U-T91-TA, U-T91-SO, U-T91-IE (vai mạnh nhất tenant).
    Khi U-T91-TA gọi GET chi tiết và danh sách các API quản trị (`/policy`, `/knowledge/sources`, `/tools`, `/prompt-templates`, `/eval-sets`, `/ai-system-records`) với định danh của T90.
    Và U-T91-SO gọi `/logs/conversations`, `/invocations`, `/tools/calls` với định danh T90.
    Và U-T91-IE gọi `/conversations`, `/suggestions`, `/feedback`.
    Và U-T91-TA `PUT /settings/17.rag.top-k` với `tenant_id` T90 trong thân.
    Thì bước 1 đến 3 danh sách chỉ có dữ liệu T91; chi tiết `404` ERR-17-001, thân giống "không tồn tại" trừ `traceId`. Bước 4 `400` hoặc `403`, không ghi vào T90. T90 không đổi.

  @TC-17-136 @P1 @Bảo_mật
  Kịch bản: TC-17-136 RLS CSDL: mọi bảng ph17_assist bật RLS, không ngữ cảnh tenant thì không thấy hàng, không phụ thuộc pgvector
    # Truy vết: NFR-17-007 · BR-17-086, 027 · FR-17-018
    # Mục đích: Chứng minh bộ kiểm cô lập ở mức CSDL, chạy được trên `postgres:16` không có pgvector (cột `real[]` chỉ để CI).
    Biết `csdl/ph17/test/ph17_isolation_test.sql`; vai kết nối ứng dụng không `BYPASSRLS` và không là chủ bảng; hai tenant T90, T91 mỗi bảng có hàng.
    Khi liệt kê mọi bảng schema `ph17_assist` từ `information_schema`.
    Và đặt `app.tenant_id = 'T91'` và `SELECT`, `UPDATE`, `DELETE` mọi bảng.
    Và không đặt biến phiên rồi `SELECT`.
    Và `INSERT` hàng có `tenant_id = 'T90'` khi ngữ cảnh T91.
    Và chạy trên bản không có extension `vector`.
    Thì bước 1 100 % bảng bật `FORCE ROW LEVEL SECURITY` và có chính sách. Bước 2 không thấy, không sửa, không xóa hàng T90. Bước 3 lỗi hoặc 0 hàng. Bước 4 bị từ chối bởi chính sách `WITH CHECK`. Bước 5 mọi kiểm đạt, cột vector là `real[]`; ở có pgvector là `vector(1024)` kèm chỉ mục HNSW cosine.
