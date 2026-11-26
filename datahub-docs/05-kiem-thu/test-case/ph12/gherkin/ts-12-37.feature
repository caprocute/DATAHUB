# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-37
Tính năng: TS-12-37 · Bảo mật ứng dụng, giám sát và truy cập

  @TC-12-124 @P1 @Bảo @mật
  Kịch bản: TC-12-124 Quét ASVS 5.0 mức 2 và TLS
    # Truy vết: NFR-12-022, 019, 017 · API-12-001, 058, 074, 086 · UI-12-18 · SEC-20
    Biết SIT; ZAP với hợp đồng OpenAPI của PH-12; quét TLS mọi điểm cuối.
    Khi chạy ZAP active scan có xác thực cho UI-12-01…19 và API; quét TLS; kiểm tra cấu hình băm mật khẩu của realm.
    Thì 0 lỗ hổng CRITICAL, HIGH; TLS 1.3 ở biên mức A, mTLS nội bộ; băm `argon2id` hoặc `pbkdf2-sha512` ≥ 210.000 vòng.

  @TC-12-125 @P2 @Dương
  Kịch bản: TC-12-125 Chỉ số vận hành và truy vết xuyên suốt
    # Truy vết: NFR-12-026, 027 · FR-12-056, 057 · API-12-086
    Biết prometheus, Tempo.
    Khi chạy 100 quyết định và 50 đăng nhập; đọc chỉ số, truy vết một yêu cầu qua PH-04.
    Thì có `iam_decisions_total{result,policy}`, `iam_decision_duration_seconds`, `iam_login_total{result,method}`; `trace_id` và `tenant_id` nhất quán.

  @TC-12-126 @P2 @Truy @cập
  Kịch bản: TC-12-126 Truy cập WCAG 2.2 AA mọi màn hình
    # Truy vết: NFR-12-031 · UI-12-01…19 · UC-12-01, 02, 09, 35
    Biết axe-core; NVDA.
    Khi chạy axe-core trên 19 màn; dùng NVDA hoàn thành tạo người dùng, gán vai trò, duyệt chính sách bằng bàn phím.
    Thì 0 lỗi mức nghiêm trọng; mọi thao tác dùng được bằng bàn phím, nhãn đọc đúng tiếng Việt, tương phản đạt AA ở nền kính.

  @TC-12-127 @P2 @Dương
  Kịch bản: TC-12-127 Độ phủ kiểm thử và tương thích hợp đồng
    # Truy vết: NFR-12-033, 032 · API-12-086, 087
    Biết CI; PEP phiên bản cũ.
    Khi đọc báo cáo `opa test` và JaCoCo; gọi `decide` bằng PEP bản cũ ≥ 6 tháng.
    Thì `opa test` ≥ 90 % dòng, mã `ph12_iam` ≥ 80 %; PEP cũ vẫn dùng được, API `v1` chỉ thêm trường tùy chọn.
