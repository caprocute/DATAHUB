# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-06
Tính năng: TS-02-06 · Bí mật, dữ liệu cá nhân thật và API trùng chức năng

  @TC-02-021 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-021 Đặc tả chứa khóa PEM, JWT, mật khẩu trong URL bị chặn mọi bước
    # Truy vết: FR-02-018 · API-02-021, 042, 045, 047 · BR-02-015 · ERR-02-008 · NFR-02-012.
    Biết F-SPEC-SECRET, mồi `DH-CANARY-secret-{uuid}`; U-T68-SV1, U-T68-CA.
    Khi nạp F-SPEC-SECRET, chạy kiểm tra.
    Và gửi duyệt; ép duyệt và công bố bằng lời gọi trực tiếp.
    Và tìm mồi ở phản hồi, log, vết, bảng, Kafka, danh mục cho máy.
    Thì bước 1: phát hiện đủ 4 loại, giá trị che một phần trong kết quả. Bước 2: ba thao tác đều `422` ERR-02-008. Bước 3: mồi sạch.

  @TC-02-022 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-022 Dữ liệu cá nhân thật (CCCD, điện thoại) trong ví dụ
    # Truy vết: FR-02-018 · API-02-021, 042 · BR-02-015 · ERR-02-008 · NFR-02-012.
    Biết F-SPEC-PII; bộ 50 mẫu chuẩn bí mật, PII.
    Khi chạy kiểm tra F-SPEC-PII.
    Và chạy bộ 50 mẫu chuẩn.
    Thì bước 1: chặn gửi duyệt. Bước 2: phát hiện ≥ 95 % (≥ 48/50), mỗi mẫu bỏ sót ghi lỗi theo dõi.

  @TC-02-023 @P2 @Dương @Âm
  Kịch bản: TC-02-023 Phản đối nhận diện bí mật: người đề nghị khác người xác nhận
    # Truy vết: FR-02-018 · API-02-093, 094 · ERR-02-013, 014 · KT: có (lint.dispute).
    Biết phát hiện giả tính dương ở API nháp; U-T68-SV1, U-T68-SO.
    Khi U-T68-SV1 `:dispute-secret` kèm lý do.
    Và U-T68-SV1 gọi `:confirm-dispute`.
    Và U-T68-SO `:confirm-dispute` chấp nhận.
    Thì bước 1: chờ xác nhận. Bước 2: 403-PQ. Bước 3: phát hiện chuyển "đã xác nhận không phải bí mật", có kiểm toán; nếu SO là người đề nghị thì `403` ERR-02-013.

  @TC-02-024 @P3 @Dương @Biên
  Kịch bản: TC-02-024 Phát hiện API trùng chức năng theo ngưỡng
    # Truy vết: FR-02-020 · API-02-023 · UI-02-03, 10 · UC-02-07.
    Biết `02.duplicate.threshold` = 0,8; API nháp có đặc tả gần giống A-DATDAI (điểm 0,85) và một API khác (điểm 0,79).
    Khi `GET …/duplicates`.
    Và mở hồ sơ duyệt ở UI-02-10.
    Thì chỉ A-DATDAI được liệt kê; người duyệt thấy "API gần giống"; không chặn gửi duyệt.

  @TC-02-096 @P2 @Âm @Dương
  Kịch bản: TC-02-096 Phát hiện API trùng chức năng: không trùng, tenant khác, quyền đọc
    # Truy vết: FR-02-020 · API-02-023 · UI-02-03 · UC-02-07 · BR-02-033 · ERR-02-001, 014.
    Biết A-DRAFT với đặc tả khác biệt hoàn toàn; A-T01 có đặc tả giống A-DATDAI; U-T68-VW; `02.duplicate.threshold` mặc định.
    Khi U-T68-VW gọi `GET …/tc-nhap/versions/1.0.0/duplicates`.
    Và gọi cho phiên bản của A-T01.
    Và nạp đặc tả giống A-DATDAI vào A-DRAFT rồi gọi lại.
    Thì bước 1: `200`, danh sách rỗng, không lỗi. Bước 2: `404` ERR-02-001 (không lộ việc A-T01 giống A-DATDAI). Bước 3: có A-DATDAI với điểm giống ≥ ngưỡng; kết quả chỉ là gợi ý, không chặn gửi duyệt.

  @TC-02-097 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-097 Dịch vụ khai `x-dh-stateSecret` bị chặn ở mọi đường vào
    # Truy vết: FR-02-007, 010, 018 · API-02-008, 014, 015 · UI-02-03, 14 · UC-02-03 · BR-02-007 · ERR-02-016.
    Biết F-SPEC-STATE; A-DRAFT; U-T68-SV1.
    Khi `POST /apis` kèm đặc tả F-SPEC-STATE.
    Và `PUT /apis/tc-nhap/classification` đặt `stateSecret = true`.
    Và nạp F-SPEC-STATE bằng `POST /spec-uploads`.
    Thì cả ba `422` ERR-02-016. Không có bản ghi nào được tạo hoặc đổi; log không chứa nội dung đặc tả.
