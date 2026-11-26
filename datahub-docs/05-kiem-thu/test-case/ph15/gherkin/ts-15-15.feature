# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-15
Tính năng: TS-15-15 · Xoay vòng, thu hồi, hết hạn thông tin xác thực

  @TC-15-093 @P1 @Dương
  Kịch bản: TC-15-093 Xoay có thời gian chuyển tiếp
    # Truy vết: FR-15-030 · UC-15-16 · API-15-063, 082 · UI-15-13 · EVT-15-04 · BR-15-011 · NFR-15-020 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết credential C1 ACTIVE; `graceHours = 24`; đồng hồ giả lập.
    Khi `POST /apps/app-tra-cuu-ho-tich/credentials/{C1}:rotate`.
    Và gọi sandbox bằng bí mật cũ và mới.
    Và đẩy đồng hồ +25 giờ; gọi bằng bí mật cũ.
    Thì C1 `ROTATING`, bản mới `ACTIVE` với bí mật hiện một lần; bước 2 cả hai `200`, chỉ số `dh_portal_cred_old_use_total` tăng khi dùng bí mật cũ; bước 3 `401` (C1 `EXPIRED`); EVT-15-04 và EVT-15-05 (hết hạn); KT: có.

  @TC-15-094 @P2 @Dương
  Kịch bản: TC-15-094 Xoay và thu hồi bản cũ ngay
    # Truy vết: FR-15-030 · API-15-063 · EVT-15-05 · NFR-15-007 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết credential C2 ACTIVE.
    Khi `:rotate` với `graceHours = 0`.
    Và gọi sandbox bằng bí mật cũ trong 60 giây.
    Thì C2 chuyển thẳng `REVOKED`; bí mật cũ bị chặn ≤ 60 giây (≤ 5 giây khi nhận EVT-15-05).

  @TC-15-095 @P2 @Âm
  Kịch bản: TC-15-095 Xoay sai trạng thái, Keycloak lỗi
    # Truy vết: FR-15-030 · API-15-063 · ERR-15-018, 020, 003 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết C3 REVOKED; C4 ACTIVE khi ngắt Keycloak.
    Khi `:rotate` C3; `graceHours = 73`.
    Và `:rotate` C4.
    Thì `409` ERR-15-018 "Thông tin xác thực đang REVOKED..."; `400` ERR-15-003; `503` ERR-15-020, C4 vẫn `ACTIVE`, không có bản mới.

  @TC-15-096 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-096 Thu hồi chặn lời gọi trong 60 giây
    # Truy vết: FR-15-031 · UC-15-16 · API-15-064, 082 · EVT-15-05 · NFR-15-007 · BR-15-010 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết credential ACTIVE; vòng gọi sandbox liên tục 5 lần/giây; bộ đệm `forward-auth` 60 giây.
    Khi `POST .../credentials/{id}:revoke`.
    Và ghi thời điểm lời gọi đầu tiên bị từ chối.
    Thì `REVOKED`; EVT-15-05 tới PH-03, PH-13; mọi lời gọi sau ≤ 60 giây (≤ 5 giây với EVT) bị `401` ở gateway; KT: có; sau khi Keycloak lỗi lúc xóa client, cổng vẫn đánh dấu `REVOKED` và thử lại xóa client.

  @TC-15-097 @P2 @Âm
  Kịch bản: TC-15-097 Thu hồi lại, thu hồi không có quyền
    # Truy vết: FR-15-031 · API-15-064 · ERR-15-005, 018 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết credential đã REVOKED; Bi `VIEWER`.
    Khi `:revoke` lần hai.
    Và bi `:revoke` credential ACTIVE.
    Thì `409` ERR-15-018; `403` ERR-15-005; không đổi dữ liệu.

  @TC-15-098 @P2 @Dương
  Kịch bản: TC-15-098 Nhắc hạn 30, 7, 1 ngày và hết hạn
    # Truy vết: FR-15-031 · UC-15-16 · EVT-15-05 · BR-15-011 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `15.cred.ttl-days = 90`, `15.cred.expiry-notice-days = [30,7,1]`; đồng hồ giả lập; yêu cầu `ttlDays = 181`.
    Khi cấp credential; đẩy đồng hồ qua ngày 60, 83, 89, 91.
    Và cấp với `ttlDays = 181`.
    Thì ba thông báo (hộp thư và thư điện tử) tại 30, 7, 1 ngày trước; ngày 91 `EXPIRED`, EVT-15-05 `reason` hết hạn, gọi sandbox `401`; `ttlDays = 181` bị `400` ERR-15-003.
