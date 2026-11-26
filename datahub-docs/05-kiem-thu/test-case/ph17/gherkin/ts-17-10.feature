# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-10
Tính năng: TS-17-10 · Đồng bộ cấu hình tuyến egress ai-proxy qua PH-03

  @TC-17-030 @P1 @Dương @Hiệu_năng
  Kịch bản: TC-17-030 Đồng bộ tuyến thành công, đo EVT-17-08 đến EVT-17-09
    # Truy vết: FR-17-011 · API-17-048, 049, 050, 051 · BR-17-020 · NFR-17-021 · EVT-17-08, 09 · UI-17-19
    # Mục đích: Chứng minh mô hình chỉ gọi được khi tuyến `SYNCED` và đo thời gian đồng bộ.
    Biết PH-03 WireMock báo `gateway.snapshot.published` sau 8 giây; U-PA1.
    Khi PA1 `POST /routes:sync`.
    Và IE gửi câu hỏi ngay khi tuyến còn `PENDING`.
    Và chờ `sync-completed`, `GET /routes/sync-runs/{runId}`.
    Và lặp 30 lần lấy p95.
    Thì bước 1 `202`, EVT: `assist.route.sync-requested`. Bước 2 lời gọi bị từ chối (mô hình chưa gọi được, `503` ERR-17-035 hoặc dùng mô hình đã `SYNCED`). Bước 3 `RouteStatus = SYNCED`, EVT: `assist.route.sync-completed`. Bước 4 p95 ≤ 60 giây.

  @TC-17-031 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-17-031 PH-03 từ chối cấu hình hoặc không phản hồi
    # Truy vết: FR-17-011 · API-17-049, 051 · BR-17-020 · ERR-17-035, ERR-17-009 · EVT-17-09
    # Mục đích: Chứng minh trạng thái `FAILED`, lỗi cho người dùng và không gọi mô hình khi tuyến chưa áp.
    Biết PH-03 WireMock trả `gateway.snapshot.rejected`; sau đó không trả gì.
    Khi PA1 `POST /routes:sync`; PH-03 từ chối.
    Và IE gửi câu hỏi tới mô hình của tuyến này.
    Và PA1 `POST /routes:sync`; PH-03 im lặng 5 phút.
    Thì bước 1 `RouteStatus = FAILED`, chi tiết lượt đồng bộ nêu lý do từ chối. Bước 2 `503` ERR-17-035, không có lời gọi ra egress. Bước 3 lượt đồng bộ `FAILED` sau thời gian chờ, cảnh báo TA, EVT: `assist.route.sync-completed` kết quả từ chối.

  @TC-17-032 @P2 @Dương @Âm
  Kịch bản: TC-17-032 Phát hiện sai lệch giữa tuyến mong muốn và tuyến thực tế
    # Truy vết: FR-17-011 · API-17-048 · BR-17-020 · EVT-17-08
    # Mục đích: Chứng minh theo dõi sai lệch (drift) khi tuyến bị sửa tay ở APISIX.
    Biết tuyến `SYNCED`; sửa tay `upstream` ở APISIX thử.
    Khi sửa tay tuyến ở APISIX.
    Và chờ chu kỳ đối soát; `GET /routes`.
    Thì tuyến hiện `drift`, hệ thống phát EVT-17-08 để đồng bộ lại, sau đó về `SYNCED`; lời gọi trong lúc lệch không tới đích sai.
