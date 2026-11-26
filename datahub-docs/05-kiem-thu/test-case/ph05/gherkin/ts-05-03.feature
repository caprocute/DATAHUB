# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-03
Tính năng: TS-05-03 · Kiểm tra kết nối

  @TC-05-011 @P1 @Dương
  Kịch bản: TC-05-011 Kiểm tra đạt, đủ bước, có hiệu lực 24 giờ
    # Truy vết: FR-05-010 · API-05-017, 019 · UI-05-04 · NFR-05-004 · LGC-BUS-013
    Biết U-T68-IE1; `tc-ndxp-moi` TEST đủ tham số, bí mật; SIM-HTTP trả 200 ở `/health`.
    Khi mở UI-05-02, chọn "Kiểm tra ▾ TEST".
    Và theo dõi drawer UI-05-04 tới khi xong.
    Và `GET …/tests/{testId}`.
    Thì bước 1 gọi `POST …/environments/TEST/tests` trả `202`, `Location`. Drawer hiện lần lượt các bước DNS, TCP, TLS, xác thực (lấy token OAuth2), gọi thăm dò; mỗi bước ✓ kèm thời lượng. Tổng ≤ 15 giây. Bước 3: `status = PASSED`, `expiresAt = startedAt + 24h`, `paramsHash`, `secretVersion = 1`. SIM-HTTP chỉ nhận yêu cầu `GET /health` và yêu cầu token, không có yêu cầu ghi. KT: có (`CONNECTION_TEST`).

  @TC-05-012 @P1 @Âm
  Kịch bản: TC-05-012 Kiểm tra không đạt theo từng nguyên nhân
    # Truy vết: FR-05-010 · API-05-017, 019 · UI-05-04 · ERR-05-102, 103, 104, 119 · BR-05-011
    Biết U-T68-IE1; `tc-ndxp-moi` TEST.
    Thì mỗi lần `status = FAILED` và bước lỗi đúng: 1 DNS `cause = DNS_NXDOMAIN`; 2 TCP `TCP_REFUSED`; 3 TLS `TLS_UNTRUSTED`; 4 TLS `TLS_VERSION` (BR-05-011); 5 xác thực `AUTH_TOKEN_URL` (endpoint token trả 401); 6 gọi thăm dò hết thời gian chờ, kết thúc ≤ 10 giây với `PROBE_HTTP_STATUS` hoặc `TCP_TIMEOUT` tùy tầng chặn (ghi rõ trong báo cáo). Mọi bước sau bước lỗi `SKIPPED`. `hint` tiếng Việt khớp bảng nguyên nhân FRS §5.2.1. Không bước nào ghi giá trị bí mật vào `detail`.

  @TC-05-013 @P2 @Âm @Biên
  Kịch bản: TC-05-013 Kiểm tra trùng lúc và vượt hạn mức
    # Truy vết: FR-05-010 · API-05-017 · ERR-05-018, 019
    Biết U-T68-IE1; `05.test.max-per-hour = 20`.
    Khi gửi hai `POST …/TEST/tests` cách nhau 100 ms khi SIM-HTTP chậm 5 giây.
    Và gửi 21 lần trong một giờ.
    Thì bước 1 lần hai `409` ERR-05-018 với `testId` của lần đang chạy. Bước 2 lần 21 `429` ERR-05-019, `retryAfterSeconds` > 0.

  @TC-05-014 @P1 @Bảo @mật
  Kịch bản: TC-05-014 Kiểm tra không tác dụng phụ với CSDL và SFTP
    # Truy vết: FR-05-010 · API-05-017
    Biết U-T68-IE1; C-DKKD TEST, C-SFTP TEST; ghi nhật ký câu lệnh SIM-PG (`log_statement = all`), nhật ký SIM-SFTP.
    Khi chạy kiểm tra C-DKKD TEST.
    Và chạy kiểm tra C-SFTP TEST.
    Thì SIM-PG chỉ nhận `SELECT 1` và truy vấn danh mục quyền; không `INSERT`, `UPDATE`, `CREATE`. SIM-SFTP chỉ nhận `ls` thư mục khai báo; không tạo, xóa tệp.
