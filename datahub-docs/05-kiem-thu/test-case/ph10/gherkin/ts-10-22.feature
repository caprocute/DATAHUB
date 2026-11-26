# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-22
Tính năng: TS-10-22 · Độ trễ tiêu thụ và cảnh báo

  @TC-10-098 @P1 @Dương @Âm
  Kịch bản: TC-10-098 Thu lag theo phân vùng cho mọi chế độ
    # Truy vết: FR-10-054 · API-10-055 · UI-10-17 · ERR-10-001, 049 · LGC-HUB-007
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-054 (Thu thập consumer lag).
    Biết SUB-PUSH, SUB-PULL, SUB-KAFKA, SUB-FLOW; dừng HTTT BHXH kéo; phát 600 sự kiện.
    Khi chờ hai chu kỳ 30 giây; `GET /subscriptions/ht-bhxh-dn-cap-phep/lag`.
    Và S-PH13 gọi cùng API; mở UI-10-17.
    Và `GET /subscriptions/khong-co/lag`; `GET …/lag?from=…&to=…` khoảng 100 ngày.
    Thì `lagRecords` theo phân vùng tổng bằng 600; `lagSeconds` bằng tuổi bản tin đầu chưa commit; phân vùng không lag có `lagSeconds = 0`. SUB-KAFKA và SUB-FLOW có mẫu lag. S-PH13 `200`. Bảng `lag_sample` có mẫu mỗi 30 giây. Bước 3 404-ẩn; `400` ERR-10-049 (mẫu gộp chỉ giữ 90 ngày).
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-099 @P1 @Dương @Biên
  Kịch bản: TC-10-099 Cảnh báo WARNING, CRITICAL, STALLED và về OK
    # Truy vết: FR-10-055 · EVT-10-10 · NFR-10-010 · UC-10-20
    # Mục đích: Chứng minh luồng thành công, theo FR-10-055 (Cảnh báo lag và nhóm tiêu thụ ngừng tiến).
    Biết SUB-PULL `lagWarnSeconds = 60`, `lagCriticalSeconds = 300`; topic thử lưu giữ 25 giờ.
    Khi ngừng kéo 70 giây (một chu kỳ vượt), rồi 2 chu kỳ.
    Và ngừng tới 310 giây.
    Và kéo lại hết.
    Và Ở topic thử, để bản tin đầu chưa commit sắp quá 1 giờ tuổi trong lưu giữ 25 giờ.
    Và cho bộ giao nhận một subscription `ACTIVE` treo không commit 6 phút khi có lag.
    Thì bước 1 một chu kỳ chưa đổi; hai chu kỳ `WARNING` trong ≤ 2 phút. Bước 2 `CRITICAL`. Bước 3 `OK`. Bước 4 `CRITICAL` do thời gian còn lại dưới 24 giờ. Bước 5 `STALLED`. Mỗi lần đổi mức một EVT `subscription.lag-alerted` (cả khi về `OK`), TO và đầu mối HTTT nhận thông báo.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-100 @P2 @Dương @Âm
  Kịch bản: TC-10-100 Xác nhận cảnh báo lag
    # Truy vết: FR-10-055 · API-10-056 · UI-10-17 · ERR-10-006, 054
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-055 (Cảnh báo lag và nhóm tiêu thụ ngừng tiến).
    Biết U-T68-TO, U-T68-VW; SUB-PULL `CRITICAL`.
    Khi TO xác nhận với ghi chú "Đã liên hệ BHXH".
    Và VW xác nhận; TO xác nhận subscription `OK`.
    Thì bước 1 `200`, `alertAcknowledgedBy`, `alertAckNote`; thông báo lặp dừng tới khi đổi mức. Bước 2 403-PQ; `409` ERR-10-006.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-101 @P2 @Dương @Âm @Bảo
  Kịch bản: TC-10-101 Chỉ số xuất sang PH-13 có nhãn tenant, không có dữ liệu nghiệp vụ
    # Truy vết: FR-10-059 · NFR-10-017
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-059 (Xuất số liệu sang PH-13).
    Biết mimir của PH-13 ở SIT; tải nền ở T68, T01.
    Khi truy vấn `dh_event_consumer_lag_seconds`, `dh_event_published_total`, `dh_event_delivery_total`, `dh_event_dlq_entries`, `dh_event_quota_usage_ratio`.
    Và liệt kê mọi nhãn của chuỗi `dh_event_*`.
    Thì mọi chuỗi có nhãn `tenant`; không có nhãn `ce_subject`, khóa nghiệp vụ hay mã doanh nghiệp; số `published_total` của T68 khớp số `202` của API phát.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
