# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-03
Tính năng: TS-03-03 · WAF: chặn tấn công, chế độ phát hiện và chặn

  @TC-03-015 @P1 @Dương @Bảo @mật
  Kịch bản: TC-03-015 WAF chặn payload OWASP ở chế độ BLOCK
    # Truy vết: FR-03-005 · API-03-039 · UI-03-07 · ERR-03-109 · BR-03-007 · NFR-03-012 · UC-03-05 · SEC-11.
    Biết `gw.waf.mode = BLOCK`; `gw.waf.paranoia.api = 1`; `SIM-ATTACK` có 200 payload (SQLi, XSS, path traversal, SSRF, log4shell) và 1.000 yêu cầu hợp lệ.
    Khi gửi toàn bộ payload tới `ext.t68.sim.test/ho-tich/...` bằng C-HTTT1.
    Và gửi 1.000 yêu cầu hợp lệ.
    Và U-T68-SO1 `GET /waf/events?from=…&to=…`.
    Thì bước 1 ≥ 99 % payload nhận `403` Lỗi GW 109 (câu "Yêu cầu bị chặn bởi hệ thống bảo vệ. Gửi mã truy vết cho quản trị nếu bị chặn nhầm."); backend không nhận. Bước 2 chặn nhầm < 0,1 %. Bước 3 `200`, mỗi sự kiện có `ruleId`, `traceId`, địa chỉ nguồn, không có thân bản tin hay giá trị tham số (mồi sạch). EVT: `security.alert-raised` khi vượt ngưỡng cảnh báo.

  @TC-03-016 @P2 @Dương
  Kịch bản: TC-03-016 Chế độ DETECT chỉ ghi, không chặn
    # Truy vết: FR-03-006, 005 · API-03-040 · UI-03-07 · BR-03-019.
    Biết `gw.waf.mode = DETECT`; U-T68-VW.
    Khi gửi 20 payload SQLi qua `ext.t68.sim.test`.
    Và `GET /waf/mode`; `GET /waf/events`.
    Thì bước 1 các lượt vẫn tới backend (`200` hoặc lỗi của backend), không có `403` mã 109. Bước 2 `mode = DETECT`, `detectDays`, `fpOpen`; có 20 sự kiện `DETECTED`.

  @TC-03-017 @P1 @Dương @Âm
  Kịch bản: TC-03-017 Đổi chế độ WAF sang BLOCK cần bốn mắt và đủ 14 ngày phát hiện
    # Truy vết: FR-03-006 · API-03-041, 071, 072 · UI-03-07, 17 · ERR-03-008, 027 · BR-03-019 · UC-03-13.
    Biết U-T68-SO1, U-T68-SO2; `detectDays = 3` rồi tiến `faketime` tới 14 ngày; `fpOpen = 25` rồi xử lý còn 15 (`gw.waf.fpReviewMax = 20`).
    Khi SO1 `PUT /waf/mode` `BLOCK` khi `detectDays = 3`.
    Và khi đủ 14 ngày nhưng `fpOpen = 25`, lặp bước 1.
    Và khi đủ điều kiện, SO1 `PUT /waf/mode` `BLOCK`.
    Và SO1 gọi `POST /change-requests/{id}:approve` cho yêu cầu của chính mình.
    Và SO2 duyệt qua UI-03-17.
    Thì bước 1, 2 `422` ERR-03-027 "Chưa thể chuyển sang chế độ chặn: cần chạy phát hiện tối thiểu 14 ngày (đã chạy {n} ngày)." (bước 2 nêu số cảnh báo giả chưa xử lý). Bước 3 `202`, yêu cầu chờ duyệt, chế độ chưa đổi. Bước 4 `403` ERR-03-008 "Bạn đã đề nghị thay đổi này nên không thể tự duyệt." Bước 5 `200`; ảnh chụp mới có `BLOCK` hiệu lực ≤ 60 s. KT: có (`WAF_MODE_REQUEST`, `WAF_MODE_APPROVE`).

  @TC-03-018 @P2 @Chịu @lỗi
  Kịch bản: TC-03-018 WAF tự hạ về DETECT khi quá tải và báo cáo
    # Truy vết: FR-03-006 · API-03-040 · UI-03-07 · ERR-03-008 · EVT-03-09 · NFR-03-002, 012 · BR-03-019.
    Biết `gw.waf.mode = BLOCK`; `gw.waf.degradeP99Ms = 15`; Chaos thêm CPU giới hạn để p99 WAF > 15 ms trong 5 phút.
    Khi chạy tải 300 lượt/giây với thân 32 KB khi WAF bị bóp CPU.
    Và `GET /waf/mode`; `GET /security-alerts`.
    Và bỏ bóp CPU; theo dõi.
    Thì bước 2 `effectiveMode = DETECT` (tự hạ, không cần bốn mắt vì là hạ an toàn), có cảnh báo mức Cao "WAF tự hạ về chế độ phát hiện". Bước 3: sau khi p99 về dưới ngưỡng, hệ thống đề nghị đổi lại `BLOCK` cần bốn mắt, không tự đổi. Không lượt gọi nào bị lỗi do tự hạ.

  @TC-03-019 @P2 @Âm @Bảo @mật
  Kịch bản: TC-03-019 Thiếu quyền xem sự kiện WAF và đổi chế độ
    # Truy vết: FR-03-005, 006 · API-03-039, 041 · ERR-03-022 · BR-03-019.
    Biết U-T68-VW; U-T68-TO; U-T01-AU.
    Khi U-T68-VW `GET /waf/events`.
    Và U-T68-TO `PUT /waf/mode`.
    Và U-T01-AU `GET /waf/events` của T68.
    Thì bước 1 và 2 403-PQ (TO chỉ có `PERM-03-waf-request`, không có `PERM-03-waf`). Bước 3 không thấy sự kiện của T68 (danh sách rỗng hoặc 403-PQ), không lộ sự tồn tại.
