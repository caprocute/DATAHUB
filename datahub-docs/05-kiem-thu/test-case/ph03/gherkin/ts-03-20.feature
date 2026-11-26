# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-20
Tính năng: TS-03-20 · Nhật ký lượt gọi: ghi có che dữ liệu, tra cứu, xuất

  @TC-03-084 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-03-084 Nhật ký chỉ có siêu dữ liệu, không lộ mồi
    # Truy vết: FR-03-050 · API-03-074 · UI-03-09 · UC-03-01 · BR-03-007 · NFR-03-014 · CMP-LAW-05 · LGC-APIM-022.
    Biết `CANARY` đặt ở thân JSON, tiêu đề `Authorization` và `Cookie`, giá trị tham số `?cccd=DH-CANARY-…`; C-HTTT1.
    Khi gọi `r-ho-tich` với `CANARY` ở bốn vị trí, cả khi thành công và khi bị `403`, `429`, `502`.
    Và U-T68-AU `GET /access-logs?consumer=ht-ndxp`.
    Và quét nhật ký APISIX, nhật ký ứng dụng, vết OTel, ClickHouse, Kafka.
    Thì bước 2 mỗi dòng có `time`, `routeCode`, `consumerCode`, `method`, đường dẫn (không chuỗi truy vấn), `status`, `latencyMs`, `bytes`, `traceId`, `srcIp`; không có trường thân hay giá trị tiêu đề. Bước 3 mồi sạch ở mọi nơi (0 giá trị trường mức Nhạy cảm, 0 thân, 0 giá trị tiêu đề xác thực).

  @TC-03-085 @P1 @Dương @Hiệu @năng
  Kịch bản: TC-03-085 Tra cứu nhật ký theo bộ lọc, hiệu năng và quyền xem định danh
    # Truy vết: FR-03-051 · API-03-074, 075 · UI-03-09, 05 · UC-03-26 · ERR-03-001, 022 · BR-03-028 · NFR-03-022 · LGC-APIM-022.
    Biết clickHouse có 5 triệu bản ghi/ngày cho T68 trong 31 ngày; U-T68-AU, U-T68-TO, U-T68-VW.
    Khi AU `GET /access-logs?from=&to=&consumer=&route=&status=5xx&size=50`.
    Và `GET /access-logs/{logId}`.
    Và U-T68-VW `GET /access-logs`.
    Và U-T01-AU `GET /access-logs/{logId của T68}`.
    Thì bước 1 `200`, p95 ≤ 3 giây trên khoảng 24 giờ, phân trang đúng. Bước 2 `200` đủ trường. Bước 3 403-PQ (thiếu `PERM-03-log-read`). Bước 4 404-ẩn. Lượt kiểm tra tổng hợp có đánh dấu `synthetic = true`.

  @TC-03-086 @P2 @Âm @Biên
  Kịch bản: TC-03-086 Khoảng truy vấn quá giới hạn, PH-13 lỗi, bộ lọc sai
    # Truy vết: FR-03-051 · API-03-074 · UI-03-09 · ERR-03-021, 026, 003 · NFR-00-062.
    Biết U-T68-AU; `SIM-PH13`.
    Khi truy vấn khoảng 32 ngày; khoảng bắt đầu cách đây 13 tháng.
    Và truy vấn đúng 31 ngày trong 12 tháng.
    Và `status=abc`; `from` sau `to`.
    Và ngắt `SIM-PH13`; truy vấn.
    Thì bước 1 `400` ERR-03-021 "Chỉ tra cứu tối đa 31 ngày mỗi lần và trong vòng 12 tháng gần nhất." Bước 2 `200`. Bước 3 `400` ERR-03-003. Bước 4 `503` ERR-03-026 kèm `retryAfterSeconds`.

  @TC-03-087 @P2 @Dương @Âm @Bảo
  Kịch bản: TC-03-087 Xuất nhật ký bất đồng bộ, giới hạn dòng, không lộ mồi
    # Truy vết: FR-03-051 · API-03-076 · UI-03-09 · UC-03-26 · ERR-03-021, 022, 003 · BR-03-007, 028 · NFR-00-062.
    Biết U-T68-AU; dữ liệu `CANARY` của ca che dữ liệu; U-T68-VW.
    Khi `POST /access-logs:export` với bộ lọc hợp lệ, `Idempotency-Key`.
    Và tải tệp xuất khi xong.
    Và xuất vượt số dòng tối đa.
    Và U-T68-VW xuất.
    Thì bước 1 `202` kèm đường dẫn theo dõi. Bước 2 tệp chỉ chứa tenant T68, đúng cột, mồi sạch. Bước 3 `400` ERR-03-021. Bước 4 403-PQ. KT: có (`ACCESS_LOG_EXPORT`, ghi bộ lọc và số dòng).
