# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-20
Tính năng: TS-12-20 · Quản lý phiên

  @TC-12-061 @P1 @Dương
  Kịch bản: TC-12-061 Xem phiên và buộc đăng xuất mọi phiên
    # Truy vết: FR-12-029 · UC-12-20 · UI-12-02 · API-12-016, 017 · LGC-IAM-005 · BR-12-036
    Biết U-T68-TA1; U-T68-IE hai phiên; U-T01-TA.
    Khi `GET /users/{id}/sessions`; `POST …:sign-out`.
    Và U-T01-TA gọi cùng đường dẫn với `userId` của IE.
    Thì bước 1 liệt kê đủ hai phiên (địa chỉ, thiết bị, lần cuối); sau buộc đăng xuất mọi token bị từ chối ≤ 60 giây; bước 2 trả 404-ẩn; KT: có.
