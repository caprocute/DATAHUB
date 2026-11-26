# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-10
Tính năng: TS-09-10 · Thẩm định, chấp thuận có điều kiện hoặc từ chối

  @TC-09-031 @P1 @Dương
  Kịch bản: TC-09-031 Chấp thuận có điều kiện tạo chấp thuận `ACTIVE` kèm điều kiện
    # Truy vết: FR-09-016 · API-09-064, 065 · UI-09-09 · EVT-09-06 · BR-09-016 · PERM-09-purpose-approve
    # Mục đích: Chứng minh quyết định `APPROVE_WITH_CONDITIONS` ghi điều kiện `FIELD_SUBSET`, `DAILY_QUOTA`, `NO_EXPORT` vào chấp thuận và bundle.
    Biết T90; yêu cầu của ca req-submit; U-T90-DO1 (chủ quản `HT-YT`).
    Khi DO1 `GET /access-requests:inbox`.
    Và DO1 `POST /access-requests/{id}:decide` `APPROVE_WITH_CONDITIONS`, hạn 180 ngày, 4 trong 6 trường, hạn ngạch 2.000 lượt mỗi ngày, `NO_EXPORT`.
    Và `GET /purpose-grants/{gid}`.
    Thì bước 2 `200`, yêu cầu `APPROVED`, chấp thuận `ACTIVE` đúng bộ ba (HTTT-BH, `MD-TRACUU-HGD`, API-HGD). EVT: `purpose-grant.approved`; KT: có (grant-approve). Bước 3 hiện đủ điều kiện, `validTo` = hôm nay + 180 ngày.

  @TC-09-032 @P2 @Dương @Âm
  Kịch bản: TC-09-032 Từ chối bắt buộc lý do, yêu cầu bổ sung thông tin
    # Truy vết: FR-09-016 · API-09-065, 066 · ERR-09-007 · UI-09-09
    # Mục đích: Chứng minh từ chối có lý do và yêu cầu bổ sung đưa yêu cầu về `NEEDS_INFO`.
    Biết T90; hai yêu cầu `SUBMITTED`; U-T90-DO1, U-T90-OR1.
    Khi DO1 `:request-info` yêu cầu thứ nhất, câu hỏi 25 ký tự.
    Và DO1 `:decide` `REJECT` yêu cầu thứ hai, lý do 10 ký tự.
    Và DO1 `:decide` `REJECT` lý do 30 ký tự.
    Thì bước 1 `AccessRequestStatus = NEEDS_INFO`, OR1 nhận thông báo. Bước 2 `422` ERR-09-007. Bước 3 `REJECTED`; không có chấp thuận nào; OR1 xem được lý do.

  @TC-09-033 @P1 @Âm
  Kịch bản: TC-09-033 Người lập tự duyệt, DO tổ chức khác, trùng chấp thuận, vượt thời hạn tối đa
    # Truy vết: FR-09-016 · API-09-065 · ERR-09-005, 008, 029, 030 · BR-09-013, 014, 015
    # Mục đích: Chứng minh BR-09-013, 014, 015.
    Biết T90; TA đồng thời lập yêu cầu; DO2 thuộc Sở GD; chấp thuận ACTIVE của HTTT-BH.
    Khi TA lập yêu cầu rồi tự `:decide` `APPROVE`.
    Và DO2 `:decide` yêu cầu của dữ liệu `HT-YT`.
    Và DO1 duyệt yêu cầu thứ hai cùng bộ ba đã có chấp thuận `ACTIVE`.
    Và DO1 duyệt với hạn 400 ngày.
    Thì bước 1 `403` ERR-09-005. Bước 2 `403` ERR-09-008. Bước 3 `409` ERR-09-029. Bước 4 `422` ERR-09-030 "Thời hạn chấp thuận tối đa 365 ngày."

  @TC-09-034 @P3 @Biên
  Kịch bản: TC-09-034 Hộp việc sắp theo hạn và quá hạn thẩm định
    # Truy vết: FR-09-016 · API-09-064 · UI-09-09 · NFR-09-016
    # Mục đích: Chứng minh thứ tự hộp việc và cờ quá hạn theo ngày làm việc.
    Biết T92 `09.request.sla-days = 3`; ba yêu cầu gửi cách nhau 1, 3, 4 ngày làm việc (đồng hồ giả).
    Khi DO1 `GET /access-requests:inbox` sau 4 ngày làm việc.
    Thì sắp theo hạn tăng dần; yêu cầu 4 ngày có cờ quá hạn, yêu cầu 3 ngày đến hạn hôm nay, yêu cầu 1 ngày chưa đến hạn.
