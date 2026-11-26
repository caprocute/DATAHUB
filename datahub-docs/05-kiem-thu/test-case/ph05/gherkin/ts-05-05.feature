# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-05
Tính năng: TS-05-05 · Xoay vòng bí mật

  @TC-05-020 @P1 @Dương
  Kịch bản: TC-05-020 Xoay bí mật PROD không gián đoạn
    # Truy vết: FR-05-012 · API-05-020, 021 · BR-05-007 · EVT-05-03 · UC-05-04
    Biết U-T68-TO; C-NDXP PROD bí mật v2; SIM-HTTP chấp nhận cả v2 và v3; luồng mẫu gọi mỗi giây.
    Khi `POST …/ndxp-ho-tich/environments/PROD:rotate-secret` với bí mật v3, chuyển tiếp 1 giờ.
    Và theo dõi kiểm tra `ROTATION`.
    Và cho SIM-HTTP thôi chấp nhận v2.
    Và đồng hồ giả vượt 1 giờ.
    Thì bước 2 đạt; OpenBao có v3, v2 vẫn còn. EVT: `connection.secret-rotated` (chỉ số phiên bản). Bước 1–3: 0 lượt lỗi của luồng; runtime dùng v3 trước. Bước 4: v2 bị hủy ở OpenBao, `rotations[0].status = COMPLETED`.

  @TC-05-021 @P1 @Âm
  Kịch bản: TC-05-021 Bí mật mới sai thì giữ nguyên bí mật cũ
    # Truy vết: FR-05-012 · API-05-020 · ERR-05-036 · UI-05-02
    Biết U-T68-TO; C-NDXP PROD.
    Khi xoay với bí mật SIM-HTTP từ chối.
    Và trong khi một lần xoay khác đang chuyển tiếp, gửi lần xoay mới.
    Thì bước 1: kiểm tra `ROTATION` không đạt ở bước xác thực; OpenBao không có phiên bản mới dùng được (phiên bản tạm bị hủy), `currentVersion` giữ nguyên; hộp xoay nói "Bí mật cũ vẫn đang dùng". Bước 2 `409` ERR-05-036.

  @TC-05-022 @P2 @Biên
  Kịch bản: TC-05-022 Lỗi xác thực không thử lại dồn dập
    # Truy vết: FR-05-012, 033 · BR-05-008 · ERR-05-102
    Biết C-NDXP TEST; SIM-HTTP luôn trả 401.
    Thì SIM-HTTP nhận tối đa 2 yêu cầu lấy token trong 5 phút (một lần thử lại); các lượt còn lại trả ERR-05-102 ngay, không gọi ra.
