# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-26
Tính năng: TS-10-26 · DU nội bộ đăng ký topic SYSTEM và topic nền tảng

  @TC-10-112 @P1 @Dương
  Kịch bản: TC-10-112 DU đăng ký topic SYSTEM khi khởi tạo tenant; HTTT đăng ký nhận
    # Truy vết: FR-10-067, 035 · API-10-009, 047 · UC-10-24 · BR-10-031 · LGC-BUS-039
    # Mục đích: Chứng minh luồng thành công, theo FR-10-067 (Đăng ký topic cho DU nội bộ và topic nền tảng).
    Biết S-DU-DATA; tenant T98 vừa khởi tạo; U-T68-IE1.
    Khi S-DU-DATA đăng ký `t98.rdm.catalog.published.v1` `SYSTEM`.
    Và Ở T68, IE1 đề nghị subscription PUSH cho SB-THUE trên TP-RDM.
    Thì bước 1 `202`, tự duyệt, publication `INTERNAL_SERVICE` của `dh-data` tự duyệt theo `10.approval.auto-approve-internal`. Bước 2 đi quy trình bình thường, cần IA duyệt, khi `ACTIVE` HTTT có scope phù hợp theo chế độ.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-113 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-113 Người dùng đăng ký miền dành riêng; DU đăng ký topic nền tảng hoặc tenant khác
    # Truy vết: FR-10-067 · API-10-009 · ERR-10-004, 005, 054 · BR-10-030
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-067 (Đăng ký topic cho DU nội bộ và topic nền tảng).
    Biết U-T68-IE1; S-DU-DATA; U-PA.
    Khi IE1 tạo topic `BUSINESS` miền `rdm`.
    Và S-DU-DATA đăng ký `platform.tenant.created.v1`.
    Và S-DU-DATA với token T68 đăng ký `t01.rdm.catalog.published.v1`.
    Và U-PA đăng ký `platform.tenant.created.v1`.
    Thì bước 1 `422` ERR-10-004. Bước 2 403-PQ (tiền tố `platform.` của topic cấp nền tảng chỉ PA và tài khoản dịch vụ nền tảng). Bước 3 `422` ERR-10-005. Bước 4 thành công, topic thuộc tenant `COMMON`, artifact `groupId = platform`.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
