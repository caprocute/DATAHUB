# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-02
Tính năng: TS-14-02 · Bật nền tảng và duyệt bốn mắt

  @TC-14-005 @P1 @Dương
  Kịch bản: TC-14-005 Kiểm tra kết nối, gửi duyệt và duyệt bật
    # Truy vết: FR-14-003, 047 · API-14-059, 008, 009 · UI-14-03, 17 · UC-14-02 · BR-14-022.
    Biết `ndxp-moi` `DRAFT`; `sim-ndxp` chế độ `OK`; U-T68-TA, U-T68-IA.
    Khi U-T68-TA gọi `POST /platforms/ndxp-moi:probe`; trạng thái sang `TESTED`.
    Và `POST /platforms/ndxp-moi:request-activation`.
    Và U-T68-IA (đã xác thực lại TOTP) mở "Việc của tôi" ở UI-14-17, `POST …:approve-activation`.
    Thì sau bước 2 `PENDING_ACTIVATION`; sau bước 3 `ACTIVE`, ghi người đề nghị, người duyệt, thời điểm; sự kiện đổi trạng thái được phát; hàng chờ của IA tự bỏ mục.

  @TC-14-006 @P1 @Âm
  Kịch bản: TC-14-006 Gửi duyệt khi chưa kiểm tra đạt hoặc đã có yêu cầu chờ
    # Truy vết: FR-14-003 · API-14-008 · ERR-14-006, 008, 004.
    Biết `ndxp-moi` `DRAFT`, chưa có kiểm tra đạt trong 24 giờ; sau đó một yêu cầu đang chờ duyệt.
    Khi `POST …:request-activation` khi chưa kiểm tra đạt.
    Và kiểm tra đạt, gửi duyệt; gửi duyệt lần hai.
    Và `POST …:approve-activation` lên nền tảng đang `ACTIVE`.
    Thì bước 1 `422` ERR-14-008; bước 2 lần hai `409` ERR-14-006; bước 3 `409` ERR-14-004.

  @TC-14-007 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-007 Bốn mắt: người duyệt trùng người đề nghị hoặc người sửa
    # Truy vết: FR-14-003 · API-14-009 · ERR-14-007 · BR-14-022 · PERM-14-approve.
    Biết U-T68-IA2 (vừa IA vừa TA); yêu cầu bật do U-T68-IA2 đề nghị; yêu cầu khác do U-T68-TA sửa lần cuối.
    Khi U-T68-IA2 duyệt yêu cầu chính mình đề nghị.
    Và U-T68-IA2 duyệt yêu cầu mà U-T68-TA đề nghị nhưng U-T68-IA2 sửa gần nhất.
    Và U-T68-IA duyệt khi chưa xác thực lại nhiều yếu tố.
    Thì bước 1, 2 `403` ERR-14-007, nền tảng vẫn `PENDING_ACTIVATION`; bước 3 bị từ chối yêu cầu xác thực lại theo FR-00. Kiểm toán ghi cả lần bị từ chối.
