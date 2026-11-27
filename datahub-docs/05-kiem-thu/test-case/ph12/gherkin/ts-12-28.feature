# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-28
Tính năng: TS-12-28 · Dữ liệu vai trò–quyền, soạn, kiểm thử, chạy khô chính sách

  @TC-12-089 @P1 @Dương @Âm
  Kịch bản: TC-12-089 Sinh lại dữ liệu vai trò–quyền cho OPA
    # Truy vết: FR-12-051 · UC-12-33 · UI-12-12 · API-12-101, 102 · ADR-068 · BR-12-010
    Biết U-PA; ma trận D02-08 đổi một ô.
    Khi `POST /policy-data:regenerate`; `GET /policy-bundles`.
    Và đo từ lúc duyệt đến mọi OPA nạp.
    Thì gói mới có chữ ký, `bundleRevision` tăng; mọi OPA nạp ≤ 60 giây; OPA từ chối gói không chữ ký.

  @TC-12-090 @P1 @Dương @Âm
  Kịch bản: TC-12-090 Soạn chính sách, tạo phiên bản, chạy bộ ca kiểm thử
    # Truy vết: FR-12-052 · UC-12-34 · UI-12-12 · API-12-089, 090, 091, 092, 093, 094, 112 · BR-12-009
    Biết U-T68-SO; POL-T68-OK; bộ ca có 1 dương, 1 âm.
    Khi `POST /policies`; `POST …/versions`; `GET` danh sách, chi tiết, phiên bản.
    Và `:test`.
    Và `PUT …/versions/{versionNo}` kèm `If-Match` ghi đè nội dung bản nháp (tự lưu); gọi lại với `If-Match` cũ; gọi với phiên bản không ở `DRAFT`.
    Thì phiên bản `DRAFT`, `contentHash` cố định; kết quả test có độ phủ; KT: có (policy.create); bước 3 đổi `contentHash` và xóa kết quả kiểm thử đã có, `If-Match` cũ nhận `412` ERR-12-044, phiên bản không ở `DRAFT` nhận `409` ERR-12-027.

  @TC-12-091 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-091 Chính sách sai cú pháp hoặc có luật cho phép của tenant
    # Truy vết: FR-12-052 · BR-12-007 · API-12-091, 092, 094 · ERR-12-024 · ERR-12-028 · SEC-26
    Biết U-T68-SO; POL-T68-ALLOW; một Rego sai cú pháp.
    Khi tạo phiên bản với Rego sai cú pháp.
    Và tạo phiên bản POL-T68-ALLOW (có `allow` hoặc nới quyền).
    Thì bước 1 `422` ERR-12-024 kèm dòng lỗi; bước 2 `422` ERR-12-028; không phiên bản nào chuyển được đi tiếp.

  @TC-12-092 @P1 @Dương @Âm
  Kịch bản: TC-12-092 Chạy khô trên lưu lượng thật, báo cáo thay đổi quyết định
    # Truy vết: FR-12-053 · UC-12-34 · UI-12-13 · API-12-095 · BR-12-011 · BR-12-009
    Biết phiên bản đạt test; 10.000 quyết định mẫu từ nhật ký.
    Khi `:dry-run`; xem số quyết định đổi và các trường hợp từ chối chuyển sang cho phép.
    Và `:dry-run` phiên bản `DRAFT` chưa đạt kiểm thử.
    Thì báo cáo gắn đúng `contentHash`; đổi quá 20 % hoặc có từ chối→cho phép thì đánh dấu cần xác nhận bổ sung; bước 2 `409` ERR-12-025.
