# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-13
Tính năng: TS-02-13 · Phiên bản mới, so sánh và tác động

  @TC-02-044 @P1 @Dương
  Kịch bản: TC-02-044 Tạo phiên bản mới, so sánh phá vỡ và tác động
    # Truy vết: FR-02-042, 043, 044 · API-02-054, 055, 056 · UI-02-05 · UC-02-18 · BR-02-003, 035 · NFR-02-004.
    Biết A-DATDAI 1.0.0 có SUB-ACTIVE; U-T68-SV1.
    Khi `POST /apis/tc-dat-dai/versions` số 2.0.0 và bản 1.1.0.
    Và đổi kiểu một trường bắt buộc ở 2.0.0; `GET /version-diff?from=1.0.0&to=2.0.0`.
    Và `GET …/2.0.0/impact`.
    Thì `201`; diff phân loại "phá vỡ", sinh ≤ 3 giây; impact liệt kê H-KHAITHAC-1 và đăng ký bị ảnh hưởng; 2.0.0 có đường dẫn `/v2` chạy song song.

  @TC-02-045 @P1 @Âm
  Kịch bản: TC-02-045 Phá vỡ nhưng giữ số chính, số hiệu không tăng, lặp số
    # Truy vết: FR-02-042, 043 · API-02-054, 042 · BR-02-003, 021 · ERR-02-017, 018, 002, 014.
    Biết bản 1.1.0 có thay đổi phá vỡ so với 1.0.0; U-T68-SV2.
    Khi gửi duyệt 1.1.0.
    Và tạo phiên bản `0.9.0`; tạo lại `1.0.0`.
    Và U-T68-SV2 tạo phiên bản cho `tc-dat-dai`.
    Thì `409` ERR-02-017; `422` ERR-02-018; `409` ERR-02-002; 403-PQ.

  @TC-02-046 @P2 @Âm @Bảo @mật
  Kịch bản: TC-02-046 Tác động của phiên bản không tồn tại, tenant khác
    # Truy vết: FR-02-044, 043 · API-02-055, 056 · BR-02-033 · ERR-02-001.
    Biết A-T01.
    Khi `GET /apis/tc-chi-t01/version-diff`; `GET /apis/tc-dat-dai/versions/9.9.9/impact`.
    Thì cả hai 404-ẩn.

  @TC-02-116 @P2 @Âm @Biên
  Kịch bản: TC-02-116 So sánh phiên bản: tham số sai, cùng một phiên bản, tenant khác
    # Truy vết: FR-02-043 · API-02-055 · UI-02-05 · UC-02-18 · BR-02-033 · ERR-02-003, 001.
    Biết A-DATDAI 1.0.0, 1.1.0, 2.0.0; A-T01; U-T68-VW.
    Khi `GET /apis/tc-dat-dai/version-diff?from=1.0.0` (thiếu `to`).
    Và `from=1.0.0&to=1.0.0`.
    Và `from=1.0.0&to=9.9.9`.
    Và `GET /apis/tc-chi-t01/version-diff?from=1.0.0&to=1.1.0`.
    Và `from=2.0.0&to=1.0.0` (ngược chiều).
    Thì bước 1: `400` ERR-02-003. Bước 2: `200` không có thay đổi. Bước 3: `404` ERR-02-001. Bước 4: `404`, cùng thân. Bước 5: `200`, báo cáo theo chiều ngược, thay đổi "thêm" thành "bớt". UI-02-05 hiện đúng trạng thái "không có thay đổi".

  @TC-02-117 @P1 @Âm @Dương
  Kịch bản: TC-02-117 Công bố phiên bản cùng số chính khi thiếu gói cùng mã
    # Truy vết: FR-02-042, 036 · API-02-042, 054 · UI-02-02 · UC-02-18 · BR-02-024, 035 · ERR-02-012.
    Biết A-DATDAI 1.0.0 có `goi-co-ban` với SUB-ACTIVE; phiên bản 1.1.0 tương thích, chỉ có gói `goi-moi`; U-T68-SV1.
    Khi `POST …/1.1.0:submit`.
    Và `POST …/1.1.0/plans:copy-from` từ 1.0.0 (sao chép `goi-co-ban`); gửi lại.
    Và duyệt, công bố 1.1.0.
    Thì bước 1: `409` ERR-02-012, `missing[]` nêu thiếu gói cùng mã với gói đang có đăng ký. Bước 2: `202`. Bước 3: 1.1.0 thay 1.0.0 ở cùng đường dẫn `/v1`; SUB-ACTIVE vẫn gọi được, không phải đăng ký lại.
