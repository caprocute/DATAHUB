# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-15
Tính năng: TS-16-15 · Công bố báo cáo chính thức

  @TC-16-062 @P1 @Dương
  Kịch bản: TC-16-062 Công bố: chụp, PDF theo thể thức, ký số, lưu WORM
    # Truy vết: FR-16-029 · API-16-074, 066, 088 · UI-16-12 · EVT-16-08 · BR-16-009, BR-16-010, BR-16-027 · NFR-16-009
    Biết `bc-thang-2026-10` `APPROVED` (người lập TO1, người duyệt TA1); U-T90-TA2 công bố; `sign-sim` và `worm-sim` thành công; `16.report.signing = true`.
    Khi U-T90-TA2 `POST /reports/bc-thang-2026-10:publish` `{publishNote: "Công bố kỳ tháng 10"}` kèm `If-Match`
    Và `GET /reports/bc-thang-2026-10`
    Và `GET /reports/bc-thang-2026-10/evidence`
    Thì bước 1 `200`, `state = PUBLISHED`, `publishedVersion = 1`, `publishedAt`, `contentHash` 64 ký tự hex, `signature = {signer, signedAt, certificateSerial, format}`, `wormRef`. Bước 3 `verified = true`, `downloadUrl`. PDF có tên cơ quan, số ký hiệu, nơi nhận, chữ ký số (NĐ 30/2020). Bản lưu WORM giữ ≥ 10 năm. EVT: `report.published` (EVT-16-08) tới PH-13, PH-17 và kích hoạt phân phối (xem TC-16-073).

  @TC-16-063 @P1 @Âm @Bảo @mật
  Kịch bản: TC-16-063 Người lập công bố, kỳ bị mở lại, thiếu If-Match
    # Truy vết: FR-16-029 · API-16-074 · ERR-16-005, ERR-16-006, ERR-00-428 · BR-16-004
    Biết báo cáo `APPROVED` do U-T90-TO1 lập; U-T90-TA3 là người gửi; kỳ báo cáo bị mở lại sau duyệt (REOPENED).
    Khi U-T90-TA3 `POST …:publish`
    Và U-T90-TA2 `POST …:publish` khi kỳ `REOPENED`
    Và U-T90-TA2 `POST …:publish` không có `If-Match`
    Thì bước 1 `403` ERR-16-005. Bước 2 `409` ERR-16-006 (báo cáo không còn khớp lần tổng hợp chính thức). Bước 3 `428` ERR-00-428. Báo cáo vẫn `APPROVED`; không tệp nào ghi vào WORM; không EVT-16-08.

  @TC-16-064 @P1 @Chịu @lỗi
  Kịch bản: TC-16-064 Dịch vụ ký số không sẵn sàng rồi công bố lại
    # Truy vết: FR-16-029 · API-16-074 · ERR-16-031 · EVT-16-08
    Biết báo cáo `APPROVED`; `sign-sim` trả `503`.
    Khi U-T90-TA2 `POST …:publish`
    Và `GET /reports/{reportCode}`
    Và đưa `sign-sim` về `200`, `POST …:publish` lại
    Thì bước 1 `503` ERR-16-031. Bước 2 `state = APPROVED`, không `wormRef`, không EVT-16-08. Bước 3 `200 PUBLISHED`, đúng một EVT-16-08, một tệp ký.

  @TC-16-065 @P1 @Chịu @lỗi
  Kịch bản: TC-16-065 Lưu WORM lỗi hoặc dựng PDF lỗi: không công bố
    # Truy vết: FR-16-029 · API-16-074 · ERR-16-113, ERR-16-114 · UI-16-12
    Biết hai báo cáo `APPROVED`; `worm-sim` trả lỗi ghi; bộ dựng PDF được làm lỗi bằng mẫu hỏng.
    Khi `POST …:publish` khi `worm-sim` lỗi
    Và `POST …:publish` bản khác khi dựng PDF lỗi
    Và sửa lỗi, công bố lại cả hai
    Thì bước 1 báo lỗi ERR-16-114 (`5xx` hoặc `502`), báo cáo vẫn `APPROVED`, không `contentHash` công bố, không EVT-16-08, cảnh báo PH-13. Bước 2 ERR-16-113, báo cáo vẫn `APPROVED`. Bước 3 thành công, không tệp mồ côi nào ở kho (`worm-sim` chỉ có tệp của lần thành công).

  @TC-16-066 @P1 @Âm @Bảo @mật
  Kịch bản: TC-16-066 Báo cáo đã công bố bất biến
    # Truy vết: FR-16-029, FR-16-036 · API-16-067, 068, 069, 076, 088 · ERR-16-032, ERR-16-006, ERR-16-124 · BR-16-009, BR-16-010 · NFR-16-013
    Biết `bc-thang-2026-10` `PUBLISHED`; quyền DBA ở CSDL thử; `worm-sim`.
    Khi `PATCH /reports/bc-thang-2026-10`, `PUT …/explanations/mttd`, `POST …:refresh`
    Và `POST …:submit`, `POST …:approve` trên báo cáo `PUBLISHED`
    Và ghi SQL trực tiếp bằng vai trò dịch vụ để đổi `contentHash`
    Và xóa hoặc ghi đè tệp ở `worm-sim` trước hạn
    Và `GET …/evidence` rồi tính SHA-256 tệp tải về
    Và thay tệp ở `worm-sim` bằng tệp khác, chạy tác vụ kiểm băm, `GET …/evidence`
    Thì bước 1 `409` ERR-16-032 (hoặc ERR-16-006 cho `:refresh`). Bước 2 `409` ERR-16-006. Bước 3 bị chặn bởi trigger hoặc không có quyền ghi. Bước 4 từ chối (WORM). Bước 5 SHA-256 tệp khớp `contentHash` và chữ ký kiểm chứng được ngoài hệ thống; 0 lệnh sửa thành công (NFR-16-013). Bước 6 tác vụ ghi ERR-16-124, thông báo SO và PH-13, `verified = false`, báo cáo không bị tự sửa.
