# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-09
Tính năng: TS-03-09 · Hạn mức tần suất và hạn ngạch theo bên gọi

  @TC-03-042 @P1 @Dương @Âm @Biên
  Kịch bản: TC-03-042 Hạn mức tần suất theo HTTT kèm tiêu đề hạn mức
    # Truy vết: FR-03-021, 025 · API-03-029 · UI-03-06 · UC-03-04 · ERR-03-116 · BR-03-005, 023, 024 · NFR-03-002 · LGC-APIM-012; LGC-NFR-006.
    Biết C-HTTT1 hạn mức 20 lượt/giây; U-T68-TO.
    Khi gọi 20 lượt trong 1 giây.
    Và gọi lượt thứ 21 trong cùng giây.
    Và chờ `Retry-After`; gọi lại.
    Và `GET /consumers/ht-ndxp/usage`.
    Thì mọi phản hồi (kể cả `200`) có `X-RateLimit-Limit: 20`, `X-RateLimit-Remaining` giảm đúng, `X-RateLimit-Reset`. Bước 2 `429` Lỗi GW 116 kèm `Retry-After`, câu "Bạn gửi quá nhiều yêu cầu. Chờ {n} giây rồi thử lại." Bước 3 `200`. Bước 4 `200`, thấy `rateLimit`, mức đã dùng.

  @TC-03-043 @P1 @Dương @Bảo @mật
  Kịch bản: TC-03-043 Hạn mức theo HTTT, không theo địa chỉ IP
    # Truy vết: FR-03-021 · API-03-029 · UI-03-06 · ERR-03-116 · BR-03-005 · SEC-10.
    Biết C-HTTT1 và C-ESS cùng một địa chỉ nguồn NAT `10.99.1.1`.
    Khi C-HTTT1 gửi 40 lượt/giây trong 5 giây; đồng thời C-ESS gửi 10 lượt/giây.
    Và C-HTTT1 đổi sang địa chỉ nguồn khác, gửi 40 lượt/giây.
    Thì bước 1 C-HTTT1 bị `429` mã 116 khi vượt 20 lượt/giây; C-ESS hoàn toàn `200` (không bị trừ hạn mức của C-HTTT1). Bước 2 C-HTTT1 vẫn bị `429` (đổi IP không đổi hạn mức).

  @TC-03-044 @P1 @Dương @Âm @Biên
  Kịch bản: TC-03-044 Hạn ngạch theo chu kỳ, cảnh báo 80 % và 100 %
    # Truy vết: FR-03-022, 025 · API-03-029, 030 · UI-03-05, 06 · UC-03-04 · ERR-03-117 · EVT-03-07 · BR-03-009, 020 · LGC-APIM-013.
    Biết gói `GOI-MINI`: quota 1.000 lượt/ngày; client `ht-mini`; bộ đếm đặt sẵn 799.
    Khi gọi 1 lượt (800 = 80 %).
    Và gọi tới 1.000.
    Và gọi lượt 1.001.
    Và `GET /quota-alerts`; `GET /consumers/ht-mini/usage`.
    Và tiến đồng hồ qua nửa đêm; gọi lại.
    Thì bước 1 có EVT: `quota.threshold-reached` (80 %). Bước 2 EVT thứ hai (100 %). Bước 3 `429` Lỗi GW 117 "Đã hết hạn ngạch trong kỳ này. Hạn ngạch đặt lại lúc {thời điểm}." kèm `X-RateLimit-Reset`. Bước 4 `200`, danh sách đúng hai cảnh báo; hạn ngạch chỉ dùng để bảo vệ và thống kê, không có trường tính tiền (BR-03-020). Bước 5 `200`.

  @TC-03-045 @P2 @Dương @Biên
  Kịch bản: TC-03-045 Nhóm ESSENTIAL được ưu tiên khi vượt hạn ngạch
    # Truy vết: FR-03-021, 022, 027 · API-03-029 · UI-03-06 · ERR-03-117 · BR-03-009.
    Biết C-ESS quota 1.000/ngày, nhóm `ESSENTIAL`; client thường cùng quota.
    Khi cả hai gọi tới 1.000.
    Và tiếp tục gọi tới 1.200 và 1.201.
    Thì client thường nhận `429` mã 117 từ lượt 1.001. C-ESS vẫn `200` tới 1.200 (nới tối đa 20 %) kèm cảnh báo, rồi `429` mã 117 ở lượt 1.201; không bị chặn đột ngột ở lượt 1.001.

  @TC-03-046 @P3 @Dương @Chịu @lỗi
  Kịch bản: TC-03-046 Điều tiết theo tình trạng backend (trừ ESSENTIAL)
    # Truy vết: FR-03-027 · API-03-029 · UI-03-06 · ERR-03-116 · BR-03-009 · LGC-NFR-006.
    Biết `SIM-BE-1…3` đặt p95 3 giây; C-HTTT1 và C-ESS gọi 15 lượt/giây.
    Khi chạy tải 5 phút; quan sát mã phản hồi.
    Và đưa backend về bình thường.
    Thì bước 1 gateway giảm dần số lượt chuyển tới backend của C-HTTT1 (một phần `429` mã 116 do điều tiết, nêu trong `detail`), C-ESS không bị điều tiết. Bước 2 hạn mức phục hồi dần trong ≤ 2 phút.
