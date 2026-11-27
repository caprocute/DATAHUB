# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-30
Tính năng: TS-13-30 · Phát hiện bất thường và xử lý cảnh báo an ninh

  @TC-13-084 @P1 @Dương
  Kịch bản: TC-13-084 Chuỗi đăng nhập thất bại sinh cảnh báo an ninh
    # Truy vết: FR-13-052, 053 · UC-13-34 · API-13-056, 057 · UI-13-15 · EVT-13-04
    Biết F-SEC-EVT; U-T68-SO.
    Khi phát 6 lần đăng nhập thất bại từ một nguồn trong 5 phút; sau đó phát chuỗi hợp lệ.
    Thì một cảnh báo an ninh `NEW` với bằng chứng là `audit_id`; EVT: `security-alert.raised`; chuỗi hợp lệ không sinh cảnh báo.

  @TC-13-125 @P2 @Âm @Biên
  Kịch bản: TC-13-125 Dưới ngưỡng, hành vi hợp lệ, đồng hồ lệch không sinh cảnh báo an ninh giả
    # Truy vết: FR-13-052 · UC-13-34 · API-13-056 · BR-13-025
    Biết F-SEC-EVT; luật đăng nhập thất bại ngưỡng 5.
    Khi phát 5 lần thất bại (đúng ngưỡng chưa vượt), rồi 4 lần trong cửa sổ khác; phát thao tác hợp lệ giờ hành chính.
    Thì 0 cảnh báo an ninh; chỉ vượt ngưỡng (6 lần) mới sinh; bản ghi lệch đồng hồ ERR-13-126 không gây cảnh báo.

  @TC-13-085 @P1 @Dương
  Kịch bản: TC-13-085 Tiếp nhận, đóng kết luận và đề xuất tạm ngừng HTTT
    # Truy vết: FR-13-053 · UC-13-35 · API-13-058, 059, 060 · UI-13-15 · BR-13-024
    Biết cảnh báo an ninh `NEW`; U-T68-SO.
    Khi tiếp nhận; đề xuất tạm ngừng HTTT `HT-NDXP` kèm lý do; đóng kết luận "sự cố thật".
    Thì `NEW` → `ACKNOWLEDGED` → `CLOSED`; đề xuất tới hộp việc PH-01, HTTT chưa bị tạm ngừng cho tới khi người có quyền duyệt; KT: có từng bước.

  @TC-13-086 @P1 @Âm
  Kịch bản: TC-13-086 Đóng thiếu kết luận, thao tác sai trạng thái
    # Truy vết: FR-13-053 · API-13-058, 059, 060 · ERR-13-023, 020, 008, 028 · BR-13-024
    Biết cảnh báo an ninh `CLOSED`; cảnh báo `NEW`.
    Khi đóng không kết luận; tiếp nhận cảnh báo đã `CLOSED`; đề xuất tạm ngừng không lý do; phiên chưa xác thực lại.
    Thì ERR-13-023; ERR-13-020; ERR-13-008; ERR-13-028.

  @TC-13-132 @P1 @Dương @Bảo @mật
  Kịch bản: TC-13-132 Đề xuất tạm ngừng gửi sang PH-01 qua API-01-089 bằng token dịch vụ
    # Truy vết: FR-13-053 · UC-13-35 · API-13-060 · BR-13-024 · API-01-089 · FR-01-053
    Biết cảnh báo an ninh `ACKNOWLEDGED` của `HT-NDXP` (T68, ACTIVE) mức `HIGH`; U-T68-SO; PH-01 giả lập nhận API-01-089 (scope `onboarding:suspension-proposal`) và ghi lại thân yêu cầu.
    Khi SO `POST /security-alerts/{alertId}:propose-suspension` với `systemCode = HT-NDXP`, `reason` 40 ký tự, `If-Match` đúng.
    Và đọc yêu cầu PH-01 giả lập nhận được.
    Và đọc cảnh báo và nhật ký kiểm toán PH-13.
    Thì bước 1: `200`, cảnh báo có `proposedAction`. Bước 2: một lời gọi `POST /internal/suspension-proposals` bằng token dịch vụ của PH-13 (không phải token người dùng), thân có `systemCode = HT-NDXP`, `alertId` đúng cảnh báo, `severity = HIGH`, `reason` nguyên văn, liên kết sâu `evidenceUrl` về cảnh báo; PH-01 trả `202`, `duplicate = false`. Bước 3: có bản ghi `SECURITY.ALERT.PROPOSE_SUSPENSION` kèm HTTT, lý do; PH-13 không gọi API đổi trạng thái HTTT và không chờ quyết định.

  @TC-13-133 @P1 @Âm @Biên
  Kịch bản: TC-13-133 Đề xuất tạm ngừng khi PH-01 lỗi, từ chối hoặc báo trùng
    # Truy vết: FR-13-053 · API-13-060 · API-01-089 · ERR-13-014, 001, 009 · BR-13-024
    Biết cảnh báo an ninh `ACKNOWLEDGED`; PH-01 giả lập có công tắc `down`, `suspended` (trả `409` ERR-01-048), `duplicate`; HTTT `HT-TC-KHAC` thuộc T01; U-T68-SO, U-T68-AU.
    Khi bật `down`; SO đề xuất.
    Và tắt `down`; SO đề xuất lại.
    Và bật `suspended`: SO đề xuất cho HTTT đã bị tạm ngừng.
    Và SO đề xuất lần hai cùng cảnh báo khi PH-01 trả `duplicate = true`.
    Và SO đề xuất cho `HT-TC-KHAC`; AU đề xuất.
    Thì bước 1: `503` ERR-13-014, đề xuất chưa gửi, cảnh báo không ghi `proposedAction`, SO thử lại được. Bước 2: `200`, một đề xuất tới PH-01. Bước 3: PH-13 coi đề xuất đã được đáp ứng, không báo lỗi cho SO và không thử lại. Bước 4: `200`, không tạo việc thứ hai ở PH-01, không có bản ghi đề xuất trùng. Bước 5: `404` ERR-13-001 và PH-13 không gọi PH-01; AU `403` ERR-13-009. Không ca nào làm HTTT đổi trạng thái.

  @TC-13-134 @P1 @Âm @Biên
  Kịch bản: TC-13-134 Đề xuất tạm ngừng từ cảnh báo mức thấp hơn HIGH bị từ chối
    # Truy vết: FR-13-053 · UC-13-35 · API-13-060 · UI-13-15 · ERR-13-003 · BR-13-024
    Biết hai cảnh báo an ninh `ACKNOWLEDGED` của `HT-NDXP` (T68, ACTIVE), một mức `MEDIUM`, một mức `HIGH`; U-T68-SO; PH-01 giả lập ghi lại mọi yêu cầu nhận được.
    Khi SO mở chi tiết cảnh báo mức `MEDIUM` ở UI-13-15.
    Và SO `POST /security-alerts/{alertId}:propose-suspension` cho cảnh báo `MEDIUM` với `systemCode = HT-NDXP`, `reason` 40 ký tự, `If-Match` đúng.
    Và SO mở chi tiết cảnh báo mức `HIGH`.
    Thì bước 1: nút "Đề xuất tạm ngừng HTTT" không hiện. Bước 2: `400` ERR-13-003 "Chỉ cảnh báo mức Cao hoặc Nghiêm trọng mới đề xuất tạm ngừng HTTT được."; PH-01 giả lập không nhận yêu cầu nào, cảnh báo không ghi `proposedAction`, HTTT giữ nguyên `ACTIVE`. Bước 3: nút hiện và dùng được.

  @TC-13-135 @P1 @Âm
  Kịch bản: TC-13-135 Đề xuất tạm ngừng khi PH-01 báo HTTT không ở trạng thái cho phép
    # Truy vết: FR-13-053 · UC-13-35 · API-13-060 · API-01-089 · UI-13-15 · ERR-01-005 · BR-13-024
    Biết cảnh báo an ninh `ACKNOWLEDGED` mức `HIGH` của `HT-NDXP`; PH-01 giả lập bật công tắc `not-allowed` (trả `409` ERR-01-005); U-T68-SO.
    Khi SO đề xuất tạm ngừng `HT-NDXP` kèm `reason` 40 ký tự.
    Và đọc cảnh báo và nhật ký kiểm toán PH-13.
    Thì bước 1: PH-13 báo cho SO "HTTT HT-NDXP không ở trạng thái cho phép tạm ngừng." (khác ca PH-01 trả ERR-01-048 là coi đã đáp ứng, không báo lỗi); không thử lại. Bước 2: cảnh báo không ghi `proposedAction`; HTTT không đổi trạng thái.
