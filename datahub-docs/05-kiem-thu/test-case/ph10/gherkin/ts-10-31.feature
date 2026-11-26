# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-31
Tính năng: TS-10-31 · Phân quyền theo ma trận PERM-10 và bốn mắt

  @TC-10-129 @P1 @Dương @Bảo @mật
  Kịch bản: TC-10-129 Vai trò được phép thực hiện đúng operation của quyền
    # Truy vết: FR-10-065 · API-10-001, 002, 004, 047, 059, 050, 108 · NFR-10-020
    # Mục đích: Chứng minh luồng thành công, theo FR-10-065 (Kiểm toán và lịch sử thay đổi).
    Biết một người dùng mỗi vai trò ở T68 (mục 2.2); đối tượng `tc-` riêng cho mỗi dòng.
    Khi với mỗi ô ● của bảng, gọi mọi operation đại diện với thân hợp lệ.
    Và với ô ○, gọi trên đối tượng của tổ chức mình.
    Thì mọi lượt trả mã thành công của API §3; mọi lượt ghi có bản ghi kiểm toán (đối chiếu 100 %).
    # Hậu điều kiện: Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-130.

  @TC-10-130 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-130 Vai trò không được phép bị chặn ở máy chủ, không chỉ ẩn nút
    # Truy vết: FR-10-065 · ERR-10-044, 053, 054
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-065 (Kiểm toán và lịch sử thay đổi).
    Biết như TC-10-129.
    Khi với mỗi ô — gọi mọi operation đại diện.
    Và với ô ○ gọi trên đối tượng ngoài tổ chức.
    Và gọi không token; với token hết hạn.
    Và mở màn tương ứng bằng vai trò không có quyền.
    Thì bước 1 403-PQ (ERR-10-054), không có thay đổi dữ liệu. Bước 2 403-TC. Bước 3 `401` ERR-10-053. Bước 4 nút hành động không hiện hoặc bị vô hiệu kèm lý do (`allowedActions`, `disabledReasons`), và gọi trực tiếp vẫn bị chặn.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-131 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-131 Scope máy chỉ mở operation được cấp
    # Truy vết: FR-10-066, 069, 038, 050, 053 · API-10-071, 073, 060, 064, 009 · ERR-10-054
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-066 (Đăng ký topic hộ PH-05 cho CDC).
    Biết S-PH05, S-PH04, S-RT-T68, S-PH18, S-PH13.
    Khi mỗi tài khoản gọi operation của scope mình (API §2.2) và một operation của scope khác (S-PH05 gọi API-10-071; S-PH04 gọi API-10-009; S-PH13 gọi API-10-064; S-PH18 gọi API-10-059; S-RT-T68 gọi API-10-047).
    Và S-RT-T68 gọi API-10-073 với tenant T01.
    Thì bước 1 operation của mình thành công; operation khác 403-PQ. Bước 2 404-ẩn hoặc 403-PQ, không trả cấu hình T01.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-132 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-132 Bốn mắt cho mọi loại yêu cầu duyệt, kể cả TA và người có hai vai trò
    # Truy vết: FR-10-009, 019, 031, 037, 051, 075 · API-10-059 · ERR-10-008 · BR-10-010
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-009 (Duyệt tạo topic và cấp phát trên cụm).
    Biết U-T68-TA, U-T68-IA2 (IA + IE).
    Khi với 9 `requestType` (`TOPIC_CREATE`, `TOPIC_CHANGE`, `TOPIC_RETIRE`, `SCHEMA_VERSION`, `PUBLICATION`, `SUBSCRIPTION`, `REPLAY`, `BRIDGE`, `CUTOVER`): TA tạo hoặc gửi rồi tự duyệt.
    Và IA2 soạn phiên bản lược đồ, IE1 gửi duyệt, IA2 duyệt.
    Và IE1 tạo topic, IA2 gửi duyệt hộ (rút rồi gửi lại), IA2 duyệt.
    Thì bước 1 mọi lượt `403` ERR-10-008. Bước 2, 3 `403` ERR-10-008 (người soạn, người gửi đều không được duyệt). Không có yêu cầu nào đổi trạng thái.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-133 @P2 @Biên
  Kịch bản: TC-10-133 Yêu cầu duyệt hết hạn trả đối tượng về trạng thái trước
    # Truy vết: FR-10-009, 019 · API-10-057
    # Mục đích: Chứng minh hành vi đúng tại mốc hết hạn của yêu cầu duyệt, theo FR-10-009 (Duyệt tạo topic và cấp phát trên cụm).
    Biết topic `PENDING_APPROVAL`, phiên bản lược đồ `PENDING_APPROVAL`; `10.approval.expire-days = 30`.
    Khi đặt đồng hồ +31 ngày.
    Thì hai yêu cầu `EXPIRED`; topic, phiên bản về `DRAFT`; người gửi nhận thông báo; "Việc của tôi" của IA không còn hai mục.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.
