# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-20
Tính năng: TS-15-20 · Lịch sử thử, bộ sưu tập, xuất

  @TC-15-120 @P2 @Dương
  Kịch bản: TC-15-120 Lịch sử thử và giữ 30 ngày
    # Truy vết: FR-15-040 · UC-15-20 · API-15-075, 076 · UI-15-14 · BR-15-024 · NFR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết an đã thử 5 lượt; đồng hồ +31 ngày.
    Khi `GET /try/history`.
    Và `DELETE /try/history`; làm lại, đẩy đồng hồ 31 ngày.
    Thì có tryId, thao tác, môi trường, kết quả, độ trễ, `traceId`; không có thân yêu cầu, phản hồi, tiêu đề xác thực; bước 2 xóa sạch; quá 30 ngày bản ghi tự mất.

  @TC-15-121 @P2 @Dương
  Kịch bản: TC-15-121 Bộ sưu tập yêu cầu
    # Truy vết: FR-15-040 · UC-15-20 · API-15-077, 078, 079, 080 · UI-15-14 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết an; yêu cầu mẫu có tiêu đề `Authorization`.
    Khi tạo bộ sưu tập 3 yêu cầu; sửa; xóa.
    Thì yêu cầu lưu ≤ 16 KB; tiêu đề `Authorization`, `Cookie` bị loại khi lưu; chỉ An thấy.

  @TC-15-122 @P2 @Âm
  Kịch bản: TC-15-122 Vượt bộ, vượt cỡ, bộ của người khác
    # Truy vết: FR-15-040 · API-15-077, 078, 079 · ERR-15-001, 003 · NFR-15-017 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết an đã có 50 bộ; Cự; bộ thứ 51; bộ với 101 yêu cầu.
    Khi an tạo bộ thứ 51; `PUT` bộ có 101 yêu cầu.
    Và cự `GET`, `PUT`, `DELETE`, xuất bộ của An; `GET /try/requests/{tryId của An}`.
    Thì `400` ERR-15-003 "Đã đạt số bộ sưu tập tối đa"; Cự `404` ERR-15-001 ở mọi đường, dữ liệu của An không đổi.

  @TC-15-123 @P3 @Dương
  Kịch bản: TC-15-123 Xuất Postman, Bruno, HTTP không lộ bí mật
    # Truy vết: FR-15-041 · UC-15-20 · API-15-081 · UI-15-14 · BR-15-011 · ERR-15-003 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết bộ sưu tập có yêu cầu dùng credential; DH-CANARY ở thông tin xác thực.
    Khi `GET /try/collections/{id}/export?dinh-dang=postman|bruno|http`.
    Và `dinh-dang=curl`.
    Thì ba tệp nhập được và chạy được bằng Newman, Bruno CLI, REST Client; dùng biến `{{clientSecret}}` thay giá trị; 0 canary; `400` ERR-15-003 cho định dạng ngoài danh sách.
