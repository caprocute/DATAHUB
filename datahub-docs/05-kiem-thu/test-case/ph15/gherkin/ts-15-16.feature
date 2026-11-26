# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-16
Tính năng: TS-15-16 · Tham chiếu thông tin xác thực production

  @TC-15-099 @P1 @Dương
  Kịch bản: TC-15-099 Xem tham chiếu production
    # Truy vết: FR-15-032 · UC-15-17 · API-15-065 · UI-15-13 · BR-15-015 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-OR được giao ứng dụng `app-dat-dai` của HT-DATDAI; S-PH01 trả chứng thư `tls_client_auth`.
    Khi `GET /apps/app-dat-dai/prod-credentials`.
    Thì `systemCode`, `clientId`, `authMethod`, 16 ký tự đầu dấu vân tay, hạn, trạng thái `ACTIVE` hoặc `EXPIRING`; không có bí mật hay khóa riêng; ghi chú bí mật production do PH-01, PH-12 cấp riêng.

  @TC-15-100 @P1 @Âm
  Kịch bản: TC-15-100 Nhà thầu và người ngoài tổ chức bị chặn
    # Truy vết: FR-15-032 · UC-15-17 · API-15-065 · ERR-15-005 · BR-15-004, 015 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN (nhà thầu, thành viên ứng dụng); cán bộ HT-TUPHAP; DH-CANARY ở khóa riêng của S-PH01.
    Khi an và cán bộ HT-TUPHAP gọi `GET /apps/app-dat-dai/prod-credentials`.
    Và tìm canary trong phản hồi Bình.
    Thì cả hai `403` ERR-15-005; không có canary ở phản hồi thành công của Bình.

  @TC-15-101 @P2 @Âm
  Kịch bản: TC-15-101 PH-01 lỗi
    # Truy vết: FR-15-032 · API-15-065 · ERR-15-031 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết S-PH01 trả `503`.
    Khi `GET /apps/app-dat-dai/prod-credentials` bằng Bình.
    Thì `502` ERR-15-031; UI "Chưa tải được thông tin xác thực production. Thử lại sau."
