# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-21
Tính năng: TS-03-21 · Chỉ số, vết, kiểm tra tổng hợp, cảnh báo an ninh và bảng điều khiển

  @TC-03-088 @P2 @Dương @Âm @Bảo
  Kịch bản: TC-03-088 Chỉ số và vết OpenTelemetry, lấy mẫu, không nhãn nhạy cảm
    # Truy vết: FR-03-052 · API-03-077 · UI-03-01 · BR-03-007, 023 · NFR-03-020, 021 · NFR-00-050, 051 · SEC-43.
    Biết tải hỗn hợp 100 lượt/giây trong 10 phút, 5 % lỗi; `CANARY`.
    Khi đọc chỉ số `dh_gateway_requests_total`, `dh_gateway_added_latency_seconds`.
    Và đếm vết thành công và vết lỗi.
    Và quét nhãn chỉ số và thuộc tính vết.
    Thì bước 1 chỉ số đủ nhãn `tenant`, `route`, `status_class`, tới Grafana ≤ 15 giây. Bước 2 giữ 100 % vết lỗi và ≈ 5 % vết thành công. Bước 3 không nhãn hay thuộc tính chứa giá trị thân, tiêu đề xác thực, định danh cá nhân; nhãn có số giá trị hữu hạn.

  @TC-03-089 @P2 @Dương @Âm @Bảo
  Kịch bản: TC-03-089 Bảng điều khiển lưu lượng, top HTTT và top route
    # Truy vết: FR-03-055 · API-03-077, 078, 079 · UI-03-01 · UC-03-27 · ERR-03-026 · BR-03-028 · NFR-03-021 · LGC-APIM-026.
    Biết T68 và T01 chạy tải khác nhau; U-T68-VW; `SIM-PH13`.
    Khi `GET /overview`; `GET /overview/top-consumers`; `GET /overview/top-routes`.
    Và đối chiếu tổng với số lượt gọi của bộ tạo tải.
    Và ngắt `SIM-PH13`; lặp bước 1.
    Thì bước 1 `200`; chỉ có consumer và route của T68, không có số liệu T01. Bước 2 sai lệch ≤ 1 %. Bước 3 `503` ERR-03-026; UI-03-01 hiện trạng thái lỗi từng thẻ và nút "Thử lại", không trắng trang.

  @TC-03-090 @P2 @Dương @Âm
  Kịch bản: TC-03-090 Kiểm tra tổng hợp cho API quan trọng
    # Truy vết: FR-03-053 · API-03-080, 081, 082, 083 · UI-03-01 · UC-03-28 · ERR-03-001, 003, 022 · BR-03-027, 028.
    Biết U-T68-TA; route đích có hạn mức 20 lượt/giây; U-T68-VW.
    Khi `POST /synthetic-checks` `{route, intervalSeconds: 60, expectStatus: 200}` kèm `Idempotency-Key`.
    Và chờ 5 phút; xem báo cáo sử dụng và bộ đếm hạn mức của HTTT.
    Và `PUT /synthetic-checks/{id}` đổi chu kỳ; `DELETE`.
    Và tạo với route lạ; `intervalSeconds = 1`; VW tạo.
    Và làm backend lỗi; chờ kiểm tra tiếp.
    Thì bước 1 `201`. Bước 2 lượt kiểm tra có `synthetic = true`, bị loại khỏi báo cáo, không tăng bộ đếm hạn mức của HTTT thật. Bước 3 `200`, `204`. Bước 4 404-ẩn, `400` ERR-03-003, 403-PQ. Bước 5 có cảnh báo `synthetic-failed` ≤ 3 phút; `GET /synthetic-checks` hiện `lastResult`.

  @TC-03-091 @P1 @Dương @Âm
  Kịch bản: TC-03-091 Cảnh báo sự kiện an ninh và xác nhận xử lý
    # Truy vết: FR-03-054 · API-03-084, 085 · UI-03-01, 07 · UC-03-18 · ERR-03-019, 022, 001 · EVT-03-09 · BR-03-007 · SEC-61, 63, 64 · CMP-LAW-16.
    Biết U-T68-TO; U-T68-AU; sự kiện giả lập: WAF chặn hàng loạt, mTLS sai, token chéo tenant, tự chặn IP, Valkey mất.
    Khi gây từng loại sự kiện.
    Và `GET /security-alerts`.
    Và TO `POST /security-alerts/{alertId}:acknowledge`; lần hai.
    Và AU `POST …:acknowledge`; `GET /security-alerts` bằng U-T01-AU.
    Thì bước 2 mỗi sự kiện có cảnh báo đúng mức (Nghiêm trọng, Cao, Trung bình), `traceId`, không chứa dữ liệu nhạy cảm; EVT: `security.alert-raised`. Bước 3 `200` rồi `409` ERR-03-019. Bước 4 403-PQ; T01 không thấy cảnh báo của T68. KT: có (`ALERT_ACK`).
