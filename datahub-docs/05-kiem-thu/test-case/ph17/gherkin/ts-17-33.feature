# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-33
Tính năng: TS-17-33 · Xuất bằng chứng tuân thủ và báo cáo sử dụng

  @TC-17-107 @P1 @Dương @Bảo_mật
  Kịch bản: TC-17-107 Gói bằng chứng có băm và chữ ký, không chứa nội dung hội thoại, tải trong hạn
    # Truy vết: FR-17-057 · API-17-173, 174, 175, 176 · BR-17-076 · ERR-17-081 · EVT-17-26 · UI-17-17
    # Mục đích: Chứng minh AC-17-15 và BR-17-076.
    Biết T95; T90 có cấu hình, 2 phiên bản mô hình, kết quả đánh giá, 66 ca đỏ, sổ đăng ký; canary `DH-CANARY-bc` trong hội thoại; U-T95-SO.
    Khi SO `POST /compliance-exports`.
    Và chờ `READY`; `GET /compliance-exports/{id}/download`.
    Và kiểm băm SHA-256 và chữ ký OpenBao; mở gói tìm canary.
    Và đẩy đồng hồ qua hạn tải; tải lại.
    Thì bước 2 `200` gói có cấu hình, mô hình và phiên bản, kết quả đánh giá, kết quả ca đỏ, sổ đăng ký, EVT: `assist.export.ready`, KT: có. Bước 3 băm và chữ ký hợp lệ; 0 nội dung hội thoại, 0 canary. Bước 4 `410` ERR-17-081.

  @TC-17-108 @P2 @Dương @Độ_chính_xác
  Kịch bản: TC-17-108 Báo cáo sử dụng theo lượt, token, chi phí ước tính; số liệu cho PH-16
    # Truy vết: FR-17-058 · API-17-177, 178, 179 · BR-17-024, 077 · ERR-17-079
    # Mục đích: Chứng minh BR-17-024, 077: chi phí = token × đơn giá khai báo, chỉ số liệu tổng hợp.
    Biết T90 `17.report.cost-per-1k-tokens = 100`; 1.000 lượt đã biết số token (tổng 2.500.000); mô hình nội bộ đơn giá 0; U-T90-TA1, tài khoản máy PH-16 scope `assist:report`.
    Khi TA1 `GET /reports/usage` theo tenant, năng lực, mô hình.
    Và TA1 `GET /reports/usage/export`.
    Và PH-16 `GET /reports/usage:feed`.
    Và TA1 `GET /reports/usage` khoảng 200 ngày.
    Thì bước 1 số lượt và token đúng 100 %; chi phí ước tính 250.000 đồng theo đơn giá khai báo. Bước 2 tệp xuất có dòng chú "ước tính", không có nội dung hội thoại. Bước 3 `200` chỉ số liệu tổng hợp. Bước 4 `422` ERR-17-079.

  @TC-17-109 @P2 @Âm @Bảo_mật
  Kịch bản: TC-17-109 Báo cáo và gói bằng chứng chỉ cho người có quyền
    # Truy vết: FR-17-057, 058 · API-17-173, 177, 179 · ERR-00-403
    # Mục đích: Chứng minh phân quyền `PERM-17-log-read`, `PERM-17-admin`.
    Biết U-T90-IE; S-T90-NOSCOPE.
    Khi IE `POST /compliance-exports`.
    Và IE `GET /reports/usage`.
    Và S-T90-NOSCOPE `GET /reports/usage:feed`.
    Thì `403` ERR-00-403 ở cả ba bước.
