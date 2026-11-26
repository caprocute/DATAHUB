# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-11
Tính năng: TS-14-11 · Gọi bất đồng bộ qua hàng chờ

  @TC-14-030 @P1 @Dương
  Kịch bản: TC-14-030 Gửi bất đồng bộ, theo dõi đến hoàn thành
    # Truy vết: FR-14-016 · API-14-076, 077 · UI-14-12 · UC-14-10 · BR-14-001.
    Biết S-HT-MC; V-HT-DK; `sim-ndxp` `OK`.
    Khi `POST /async-invocations` ghi hộ tịch.
    Và `GET /async-invocations/{requestId}` đến khi xong.
    Thì `202` kèm `requestId`; trạng thái `QUEUED → SENT → SUCCEEDED`; kết quả có chữ ký đã xác minh; hiển thị ở hàng chờ UI-14-12.

  @TC-14-031 @P2 @Âm
  Kịch bản: TC-14-031 Hủy, không thấy, hàng chờ đầy
    # Truy vết: FR-14-016 · API-14-077, 078 · ERR-14-118, 129, 130 · NFR-14-011.
    Biết `14.queue.max-size = 1000` (tenant `T90`); `sim-ndxp` `DOWN`.
    Khi gửi một yêu cầu rồi `POST …:cancel` khi còn `QUEUED`.
    Và gửi yêu cầu, cho đã `SENT`, `POST …:cancel`.
    Và `GET` `requestId` không có.
    Và gửi 1.001 yêu cầu.
    Thì bước 1 `200` `CANCELLED`; bước 2 `409` ERR-14-130; bước 3 `404` ERR-14-129; bước 4 yêu cầu thứ 1.001 `503` ERR-14-118, 1.000 yêu cầu trước giữ nguyên.
