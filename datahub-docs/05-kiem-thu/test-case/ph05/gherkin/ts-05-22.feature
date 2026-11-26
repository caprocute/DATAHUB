# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-22
Tính năng: TS-05-22 · Phiên bản và so sánh trên lưu lượng thật

  @TC-05-087 @P2 @Dương @Âm
  Kịch bản: TC-05-087 Tạo bản nháp mới sao từ phiên bản hiệu lực; chỉ một bản nháp
    # Truy vết: FR-05-045 · API-05-047, 048 · ERR-05-008
    Biết U-T68-IE1; A-DVC v7 hiệu lực, không có nháp.
    Thì lần 1 `201` v8 `DRAFT`, thao tác giống v7. Lần 2 `409` ERR-05-008.

  @TC-05-088 @P2 @Dương
  Kịch bản: TC-05-088 Thay đổi không tương thích tăng số chính Kamelet
    # Truy vết: FR-05-045, 047 · UI-05-10
    Biết A-DVC v8 nháp.
    Thì nhãn "Thay đổi không tương thích → v2"; sau duyệt có Kamelet `dvc-rest-tra-cuu-ho-so-v2-action` mới, `…-v1-action` giữ cho luồng cũ.

  @TC-05-089 @P3 @Dương @Âm
  Kịch bản: TC-05-089 So sánh v7 và v8 trên lưu lượng thật
    # Truy vết: FR-05-045 · API-05-063, 064 · ERR-05-003 · UI-05-09 · UC-05-18
    Biết U-T68-IE1; v8 kiểm thử đạt; luồng PROD gọi `tra-cuu-ho-so` 10 lượt/giây.
    Khi `POST …/versions/8:compare` với `operations = ["tra-cuu-ho-so"]`, 10 % lưu lượng, 15 phút.
    Và `GET …/comparisons/{id}`.
    Và `POST …/versions/8:compare` với thao tác `WRITE`.
    Thì bước 2: số yêu cầu, tỷ lệ khác, mẫu khác đã che dữ liệu cá nhân; luồng vẫn nhận phản hồi v7. Bước 3 `400` ERR-05-003.
