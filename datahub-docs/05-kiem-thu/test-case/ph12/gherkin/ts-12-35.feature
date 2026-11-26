# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-35
Tính năng: TS-12-35 · Chịu lỗi, độc lập control plane và phục hồi

  @TC-12-110 @P1 @Chaos
  Kịch bản: TC-12-110 Control plane ngừng: vẫn đăng nhập, vẫn quyết định ≥ 24 giờ
    # Truy vết: NFR-12-013 · FR-12-020, 044 · API-12-074, 086 · ERR-12-103
    Biết PERF; tắt mọi DU control plane (`dh-platform`, `dh-connect`, `dh-integration`).
    Khi đăng nhập, lấy token, gọi `decide` mỗi giây trong 24 giờ (rút gọn bằng đồng hồ nhanh ở SIT).
    Thì keycloak vẫn cấp token, OPA vẫn quyết định bằng gói đã nạp; thay đổi chính sách mới thì chờ (không áp), không từ chối nhầm.

  @TC-12-111 @P1 @Chaos @Khả @dụng
  Kịch bản: TC-12-111 Mất một bản sao Keycloak, một pod OPA, một instance `pg-iam`
    # Truy vết: NFR-12-011, 012, 015 · FR-12-020, 044
    Biết keycloak 3 bản sao; OPA sidecar; `pg-iam` 3 instance.
    Khi xóa lần lượt từng thành phần dưới tải 100 đăng nhập/phút và 300 quyết định/giây.
    Thì tỷ lệ lỗi < 0,01 % ngoài cửa sổ chuyển; không mất phiên có sẵn; cấu hình đủ bản sao theo NFR-12-015; thang sẵn sàng đo bằng kiểm tra tổng hợp mỗi phút.

  @TC-12-112 @P2 @Chaos
  Kịch bản: TC-12-112 Diễn tập khôi phục `pg-iam`
    # Truy vết: NFR-12-016 · NFR-12-011
    Biết sao lưu và WAL đang chạy; ADR-034 DR hai site.
    Khi hủy `pg-iam` primary, chuyển sang site standby; đo thời gian và dữ liệu mất.
    Thì RPO ≤ 15 phút, RTO ≤ 1 giờ; đăng nhập và quyết định chạy lại, khóa ký không đổi.
