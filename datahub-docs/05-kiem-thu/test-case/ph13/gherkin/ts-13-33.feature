# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-33
Tính năng: TS-13-33 · Vòng đời tenant: khởi tạo và đóng chuỗi

  @TC-13-092 @P1 @Dương
  Kịch bản: TC-13-092 Khởi tạo quan sát và chuỗi cho T90, chạy lại không đổi
    # Truy vết: FR-13-059 · UC-13-40 · API-13-072 · BR-13-017
    Biết S-PH20; T90 chưa có cấu hình.
    Khi `POST /tenants/t90/observability:provision` kèm `Idempotency-Key`; lặp lại cùng khóa cùng nội dung.
    Và ghi bản ghi đầu tiên; gọi `GET /chain-status` của T90.
    Thì `200`; Grafana, bộ luật chuẩn, dashboard, chuỗi `seq` 1 sẵn sàng; lặp lại không tạo thêm; KT: có.

  @TC-13-093 @P1 @Âm
  Kịch bản: TC-13-093 Khởi tạo lại khác tham số, khóa trùng khác nội dung, thiếu scope
    # Truy vết: FR-13-059 · API-13-072 · ERR-13-042, 037, 044
    Biết T90 đã khởi tạo; S-PH16.
    Khi khởi tạo T90 với tham số khác.
    Và dùng `Idempotency-Key` cũ với nội dung khác.
    Và S-PH16 gọi khởi tạo.
    Thì `409` ERR-13-042; `409` ERR-13-037; `403` ERR-13-044.

  @TC-13-094 @P2 @Dương @Âm
  Kịch bản: TC-13-094 Đóng chuỗi T91, neo cuối, từ chối ghi tiếp
    # Truy vết: FR-13-060 · UC-13-41 · API-13-073 · ERR-13-043, 008, 044 · BR-13-020 · UI-13-17
    Biết T91 có chuỗi 3 tháng; S-PH20.
    Khi `POST /tenants/t91/audit-chain:close` có lý do; lặp lại.
    Và gửi bản ghi vào T91.
    Thì neo cuối được ký, WORM giữ nguyên thời hạn, chuỗi `CLOSED`; lặp lại hoặc ghi tiếp `409` ERR-13-043; tra cứu chuỗi vẫn được.
