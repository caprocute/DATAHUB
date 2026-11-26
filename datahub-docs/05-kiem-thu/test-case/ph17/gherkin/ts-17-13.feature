# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-13
Tính năng: TS-17-13 · Lập chỉ mục theo sự kiện, lập lại toàn bộ và theo dõi trạng thái chỉ mục

  @TC-17-040 @P1 @Dương @Hiệu_năng
  Kịch bản: TC-17-040 Sự kiện nguồn sinh đoạn có tenant_id, acl, class_level, phiên bản nhúng, độ tươi ≤ 120 giây
    # Truy vết: FR-17-017, 018 · BR-17-016, 027, 028 · NFR-17-010 · API-17-072, 073, 076, 077 · EVT-17-14
    # Mục đích: Chứng minh chuỗi sự kiện `catalog.api.registered` đến đoạn truy hồi được, đủ metadata theo BR-17-027, và idempotent theo `content_hash`.
    Biết T90 bật, nguồn `SRC-API`, `MV-EMB-1` mặc định; PH-02 WireMock phát `t90.catalog.api.registered.v1` cho API `API-HGD-MOI` (mô tả tổng hợp 900 từ, `INTERNAL`, tổ chức sở hữu `ORG-SYT`).
    Khi phát sự kiện, ghi `t0`.
    Và gọi `POST /search` (U-T90-IE) lặp mỗi 5 giây tới khi thấy `API-HGD-MOI`; ghi `t1`.
    Và đọc các đoạn của tài liệu ở bảng `knowledge_chunk`.
    Và phát lại cùng sự kiện (cùng `content_hash`).
    Và `GET /knowledge/documents/{id}` (không hiện vector).
    Thì bước 2 `t1 - t0` p95 ≤ 120 giây khi lặp 30 lần. Bước 3 mỗi đoạn có `tenant_id = T90`, `source_id`, `acl` (tổ chức sở hữu `ORG-SYT`, mức hiển thị), `class_level = INTERNAL`, `embed_model_version = MV-EMB-1`, `content_hash`; cỡ đoạn gần 400 token, gối 50. Bước 4 không đoạn mới (idempotent), `index.completed` ghi 0 thêm. Bước 5 phản hồi không có trường vector. EVT: `assist.index.completed` có số đoạn thêm, xóa, bỏ qua.

  @TC-17-041 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-17-041 Lỗi nhúng thử lại ba lần có lùi mũ, chưa có mô hình nhúng, lượt trùng
    # Truy vết: FR-17-017, 018 · API-17-069, 074, 075 · BR-17-028 · ERR-17-044, 048 · EVT-17-15
    # Mục đích: Chứng minh BR-17-028 và các từ chối khi lập chỉ mục.
    Biết T94; `MV-EMB-1` có thể làm lỗi; nguồn `SRC-API` 30 tài liệu.
    Khi gỡ mô hình nhúng mặc định rồi `POST /knowledge/sources/{id}:reindex`.
    Và đặt lại mô hình nhúng, làm nó trả lỗi 3 lần liên tiếp rồi chạy `:reindex`.
    Và trong lúc lượt đang `RUNNING`, gọi `:reindex` lần hai cùng nguồn.
    Và `POST /knowledge/index-jobs/{jobId}:cancel`.
    Thì bước 1 `409` ERR-17-048. Bước 2 thử lại ba lần với khoảng lùi tăng (1, 2, 4 giây), lượt `FAILED`, EVT: `assist.index.failed` kèm TA, DS; nguồn khác vẫn lập chỉ mục bình thường. Bước 3 `409` ERR-17-044. Bước 4 lượt về trạng thái hủy, đoạn đã ghi giữ nhất quán.

  @TC-17-042 @P1 @Âm @Dương
  Kịch bản: TC-17-042 Đổi mô hình nhúng dựng chỉ mục song song, không trộn vector hai phiên bản
    # Truy vết: FR-17-018, 017 · BR-17-016 · API-17-074 · NFR-17-010
    # Mục đích: Chứng minh BR-17-016: không có truy hồi nào trộn đoạn của hai phiên bản nhúng.
    Biết T90 có 500 tài liệu nhúng bằng `MV-EMB-1`; `MV-EMB-2` `APPROVED`, 1024 chiều; U-T90-TA1.
    Khi TA1 `PUT /tenant-models/defaults` `embed = MV-EMB-2`, rồi `POST /knowledge/index-jobs:full-reindex`.
    Và trong lúc lập lại, IE gọi `POST /search` liên tục.
    Và sau khi chuyển xong, đếm đoạn theo `embed_model_version`.
    Thì bước 2 mọi kết quả đến từ một phiên bản nhúng duy nhất (đang chạy là `MV-EMB-1` tới khi chuyển), không có thời điểm nào trả rỗng do dựng lại. Bước 3 chỉ còn `MV-EMB-2`, đoạn cũ bị xóa sau khi chuyển.

  @TC-17-043 @P2 @Dương @Âm @Biên
  Kịch bản: TC-17-043 Theo dõi độ tươi, số đoạn, lỗi và cảnh báo chỉ mục cũ
    # Truy vết: FR-17-021 · API-17-088, 089, 076 · BR-17-031 · UI-17-08
    # Mục đích: Chứng minh trạng thái chỉ mục tổng hợp đúng và cảnh báo sau `17.index.stale-days`.
    Biết T95 (đồng hồ giả), nguồn `SRC-API` làm mới lần cuối cách 8 ngày (`stale-days = 7`); U-T95-DS.
    Khi DS `GET /knowledge/status`.
    Và `GET /knowledge/sources/{id}/health`.
    Và gửi câu hỏi tìm dịch vụ.
    Và U-T95-VW `GET /knowledge/status`.
    Thì bước 1 và 2 số đoạn, độ tươi, số lỗi đúng với bảng; hiện cảnh báo "chỉ mục cũ" cho nguồn quá 7 ngày. Bước 3 vẫn truy hồi bình thường (cảnh báo không chặn). Bước 4 `403` ERR-00-403.
