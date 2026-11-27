# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-30
Tính năng: TS-12-30 · Ghi vết, nhật ký quyết định, cảnh báo và báo cáo

  @TC-12-097 @P1 @Dương @Âm
  Kịch bản: TC-12-097 Ghi vết sự kiện xác thực và quản trị
    # Truy vết: FR-12-056 · UC-12-37 · UI-12-15 · API-12-105 · FR-00-041 · NFR-12-027 · SEC-61
    Biết U-T68-AU; đăng nhập đúng, sai, đổi vai trò, thu hồi.
    Khi thực hiện 10 sự kiện; `GET /security-events?loai=...`.
    Thì đủ sự kiện, mỗi dòng có `trace_id`, `tenant_id`, chủ thể, kết quả, không có mật khẩu, mã TOTP, token (BR-12-045); sự kiện tới PH-13.

  @TC-12-098 @P1 @Dương @Âm
  Kịch bản: TC-12-098 Ghi vết quyết định: từ chối, mức Nhạy cảm, lấy mẫu
    # Truy vết: FR-12-057, 058 · UC-12-37, 38 · UI-12-14 · API-12-103, 104 · NFR-12-029, 030 · BR-12-013 · CMP-LAW-05
    Biết 1.000 quyết định hỗn hợp; U-T68-AU; AU của T01.
    Khi chạy 1.000 quyết định; so số bản ghi với bộ đếm `iam_decisions_total` lấy bằng truy vấn Prometheus từ điểm cuối `/metrics` của OPA và `dh-platform` (không có API công bố riêng cho bộ đếm; đã chốt 27/11/2026).
    Và `GET /decisions?ket-qua=deny`; `GET /decisions/{id}`; AU T01 gọi id của T68.
    Thì 100 % từ chối và mức Hạn chế, Nhạy cảm có vết; cho phép mức thấp lấy mẫu ~10 %; sai lệch tới bộ đếm ≤ ngưỡng; AU T01 nhận 404-ẩn ERR-12-001; cấu hình lưu giữ đúng NFR-12-030 (log xác thực 12 tháng, kiểm toán 12 tháng và WORM 5 năm).

  @TC-12-099 @P2 @Dương
  Kịch bản: TC-12-099 Phát hiện bất thường và xác nhận cảnh báo
    # Truy vết: FR-12-059 · UC-12-39 · UI-12-15 · API-12-106, 107 · NFR-12-028 · SEC-64
    Biết U-T68-SO; hành vi giả lập: đăng nhập từ hai quốc gia trong 5 phút, 30 lần bị từ chối liên tiếp.
    Khi chạy hành vi giả lập; `GET /alerts`; `POST /alerts/{id}:acknowledge`.
    Thì cảnh báo tới SO ≤ 60 giây; xác nhận ghi người xác nhận và thời điểm; KT: có.

  @TC-12-100 @P2 @Dương
  Kịch bản: TC-12-100 Báo cáo tình trạng tài khoản và phủ xác thực hai yếu tố
    # Truy vết: FR-12-060 · UC-12-40 · UI-12-15 · API-12-108, 109 · CMP-LAW-08 · BR-12-015
    Biết U-T68-AU; 120 người dùng trong đó 20 thiếu yếu tố thứ hai.
    Khi `GET /reports/accounts`; `GET /reports/mfa-coverage`.
    Thì số tài khoản theo trạng thái, số quá 45 ngày, tỷ lệ phủ yếu tố thứ hai khớp dữ liệu nạp; chỉ dữ liệu T68.
