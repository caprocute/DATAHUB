# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-24
Tính năng: TS-01-24 · Đồng bộ trạng thái và bản sao đọc cho phân hệ khác

  @TC-01-093 @P1 @Dương @Chịulỗi
  Kịch bản: TC-01-093 Sự kiện trạng thái qua outbox, không mất khi Kafka ngừng
    # Truy vết: FR-01-037 · UC-01-26 · BR-01-031 · EVT-01-03, 04 · NFR-01-021.
    Biết kafka, Debezium thật; U-T68-TA1; một HTTT thử.
    Khi thực hiện năm chuyển trạng thái liên tiếp; đọc topic.
    Và dừng Kafka; thực hiện hai chuyển; khởi động lại.
    Thì bước 1: năm bản `EVT-01-03` đúng thứ tự theo `systemCode`, p95 ≤ 5 giây từ commit. Bước 2: API vẫn trả thành công; sau khi Kafka lên, hai bản còn lại được phát, không trùng, không mất.

  @TC-01-094 @P2 @Dương @Âm
  Kịch bản: TC-01-094 Đối chiếu và ảnh chụp trạng thái
    # Truy vết: FR-01-037 · API-01-062 · EVT-01-03 · ERR-01-052.
    Biết S-RECON; token S-INT; U-T68-TA1.
    Khi S-RECON `POST /internal/reconciliations`.
    Và gọi bằng S-INT và bằng token người dùng TA1.
    Thì bước 1: `202`; mỗi HTTT hoạt động có một `EVT-01-03` với `snapshot = true`. Bước 2: `403-PQ` (sai scope).

  @TC-01-095 @P1 @Dương @Âm @Bảomật
  Kịch bản: TC-01-095 Bản sao đọc nội bộ: đúng scope, đúng tenant, không bí mật
    # Truy vết: FR-01-038 · UC-01-26 · API-01-063, 064 · BR-01-030 · ERR-01-001, 003, 052.
    Biết S-INT của T68; S-INT-T01 (token dịch vụ của T01); `HT-QLVB` có ở cả hai tenant.
    Khi S-INT `GET /internal/systems?status=ACTIVE`; `GET /internal/systems/HT-QLVB`.
    Và S-INT `GET /internal/systems/HT-TC-KHAC`.
    Và token người dùng gọi `/internal/systems`; S-INT gọi `?status=SAI`.
    Thì bước 1: `200`, bản T68, không có đầu mối `SECURITY`, không có `secret_ref` hay bí mật. Bước 2: `404-ẩn`. Bước 3: `403-PQ`; `400` ERR-01-003.
