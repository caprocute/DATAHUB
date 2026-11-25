# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-20
Tính năng: TS-07-20 · Ma trận phân quyền, bốn mắt, phạm vi tổ chức và scope máy

  @TC-07-234 @P1 @Dương
  Kịch bản: TC-07-234 Quyền xem của mọi vai trò
    # Truy vết: D02-08 · PERM-07-read · API-07-001, 003
    Biết mọi người dùng ở mục 2.2.
    Khi mỗi người dùng gọi `GET /catalogs` và `GET /catalogs/LOAI_HINH_TC`.
    Thì mọi vai trò có `PERM-07-read` nhận `200`.

  @TC-07-235 @P1 @Âm
  Kịch bản: TC-07-235 Quyền soạn chỉ có ở TA, DS (trong tổ chức) và PA (COMMON)
    # Truy vết: D02-08 · PERM-07-create, update · API-07-002, 004
    Biết U-T68-VW, AU, IE, SV, DEV, DA1.
    Khi mỗi người dùng tạo danh mục `TC235_{vai trò}`.
    Thì mọi lời gọi `403-PQ`; không có danh mục nào được tạo.

  @TC-07-236 @P1 @Dương @Âm
  Kịch bản: TC-07-236 DS chỉ sửa danh mục thuộc tổ chức của mình
    # Truy vết: D02-08 (ô ○) · PERM-07-update · ERR-07-046
    Biết CAT-LH thuộc ORG-SNV.
    Khi U-T68-DS-NV tạo bản nháp CAT-LH.
    Và U-T68-DS-MT thêm bản ghi vào bản nháp đó.
    Và U-T68-DS-MT tạo danh mục mới với `ownerOrgId = ORG-SNV`.
    Thì bước 1 `201`. Bước 2 `403` `ERR-07-046`. Bước 3 `403` `ERR-07-046` (DS chỉ đặt chủ quản là tổ chức của mình).

  @TC-07-237 @P1 @Dương @Âm
  Kịch bản: TC-07-237 Quyền trình duyệt
    # Truy vết: D02-08 · PERM-07-submit · API-07-017
    Biết bản nháp của CAT-LH.
    Khi U-T68-VW trình.
    Và U-T68-DS-MT trình.
    Và U-T68-DS-NV trình.
    Thì bước 1 `403-PQ`; bước 2 `403` `ERR-07-046`; bước 3 `200`.

  @TC-07-238 @P1 @Âm
  Kịch bản: TC-07-238 Chỉ DA (và PA với COMMON) duyệt, phát hành
    # Truy vết: D02-08 · PERM-07-publish · API-07-018, 020
    Biết phiên bản `IN_REVIEW` của CAT-LH do U-T68-DS-NV trình.
    Khi U-T68-TA, DS-NV, IE, VW lần lượt gọi duyệt.
    Thì mọi lời gọi `403-PQ`; phiên bản vẫn `IN_REVIEW`.

  @TC-07-239 @P1 @Âm
  Kịch bản: TC-07-239 Bốn mắt: người trình không tự duyệt
    # Truy vết: BR-07-011 · FR-07-015 · ERR-07-015
    Biết U-T68-DA2 vừa có quyền soạn vừa có quyền duyệt.
    Khi U-T68-DA2 soạn và trình bản nháp CAT-LH.
    Và U-T68-DA2 duyệt.
    Và U-T68-DA1 duyệt.
    Thì bước 2 `403` `ERR-07-015`. Bước 3 `200`.

  @TC-07-240 @P1 @Âm
  Kịch bản: TC-07-240 Bốn mắt tính cả người sửa bản nháp
    # Truy vết: BR-07-011 · ERR-07-015
    Biết U-T68-DS-NV soạn, U-T68-DA2 sửa một bản ghi, U-T68-DS-NV trình.
    Khi U-T68-DA2 duyệt.
    Thì `403` `ERR-07-015` (người đã sửa nội dung bản nháp cũng không được duyệt).

  @TC-07-241 @P2 @Âm
  Kịch bản: TC-07-241 Bốn mắt khi thu hồi duyệt và phát hành
    # Truy vết: BR-07-011 · FR-07-015, 016
    Biết phiên bản `APPROVED` bởi U-T68-DA1.
    Khi U-T68-DA2 (người soạn) phát hành.
    Và U-T68-DA1 thu hồi duyệt (`UNAPPROVE`).
    Thì bước 1 `403` `ERR-07-015`. Bước 2 `200`, phiên bản về `IN_REVIEW`.

  @TC-07-242 @P2 @Dương
  Kịch bản: TC-07-242 Quyền xuất của mọi vai trò
    # Truy vết: D02-08 · PERM-07-export · API-07-038
    Biết mọi người dùng T68.
    Khi mỗi người dùng xuất CAT-MUC dạng CSV.
    Thì mọi lời gọi `200` hoặc `202`.

  @TC-07-243 @P1 @Dương @Âm
  Kịch bản: TC-07-243 Quyền đồng bộ
    # Truy vết: D02-08 · PERM-07-sync · API-07-058, 061
    Biết nguồn `SRC-TG` của `TON_GIAO` ở T68 (TC-07-187).
    Khi U-T68-TA, DA1 chạy đồng bộ; U-T68-DS-NV, VW chạy đồng bộ.
    Thì TA, DA1 `202`; DS-NV, VW `403-PQ` (theo D02-08, Q07-68 ở D03-06-PH07).

  @TC-07-244 @P2 @Âm
  Kịch bản: TC-07-244 Xác nhận đồng bộ kèm phát hành cần quyền phát hành
    # Truy vết: FR-07-037 · PERM-07-sync, publish
    Biết lần chạy `PENDING_CONFIRMATION` ở T68.
    Khi U-T68-TA xác nhận.
    Và U-T68-DA1 xác nhận.
    Thì bước 1 `403-PQ` (TA không có `PERM-07-publish`). Bước 2 `200`.

  @TC-07-245 @P2 @Dương @Âm
  Kịch bản: TC-07-245 Quyền ánh xạ
    # Truy vết: FR-07-041 · PERM-07-mapping (đề xuất)
    Biết bộ dữ liệu chuẩn mục 2 đã nạp
    Khi U-T68-IE, TA, DS-NV ghi ánh xạ; U-T68-VW, DA1 ghi ánh xạ.
    Thì IE, TA, DS-NV `200`; VW, DA1 `403-PQ`.

  @TC-07-246 @P1 @Dương @Âm
  Kịch bản: TC-07-246 Quyền cấp quyền khai thác
    # Truy vết: FR-07-052 · PERM-07-grant (đề xuất)
    Biết CAT-RES.
    Khi U-T68-TA thay danh sách cấp quyền của CAT-RES.
    Và U-T68-DS-NV làm như trên.
    Thì bước 1 `200`; bước 2 `403-PQ`.

  @TC-07-247 @P2 @Dương @Âm
  Kịch bản: TC-07-247 Quyền cấu hình tham số
    # Truy vết: FR-07-053 · PERM-07-configure (đề xuất)
    Biết bộ dữ liệu chuẩn mục 2 đã nạp
    Khi U-T68-TA đổi `07.rdm.import-preview-ttl-hours`.
    Và U-T68-DA1 đổi cùng tham số.
    Thì bước 1 `200`; bước 2 `403-PQ`.

  @TC-07-248 @P2 @Dương
  Kịch bản: TC-07-248 Quyền xem lịch sử của AU
    # Truy vết: FR-07-050 · ROLE-AUDITOR
    Biết danh mục `DM_THU_NGHIEM` đã xóa mềm 5 ngày trước.
    Khi U-T68-AU gọi lịch sử của `DM_THU_NGHIEM`.
    Và U-T68-VW gọi như trên.
    Thì bước 1 `200`; bước 2 `404` `ERR-07-001`.

  @TC-07-249 @P1 @Âm
  Kịch bản: TC-07-249 PA không ghi danh mục của tỉnh
    # Truy vết: D02-08 · BR-07-001
    Biết U-PA.
    Khi U-PA sửa CAT-LH của T68 (đường dẫn của tenant T68).
    Thì `404-ẩn` (PA làm việc trong tenant PLATFORM, không có quyền vào dữ liệu của tỉnh).

  @TC-07-250 @P2 @Âm
  Kịch bản: TC-07-250 PO chỉ đọc
    # Truy vết: D02-08 · ROLE-PLATFORM_OPERATOR
    Biết U-PO.
    Khi U-PO đọc `GIOI_TINH`; tạo bản nháp `GIOI_TINH`.
    Thì đọc `200`; tạo bản nháp `403-PQ`.

  @TC-07-251 @P1 @Âm
  Kịch bản: TC-07-251 Scope máy rdm.read không ghi được
    # Truy vết: FR-00-071 · API-07-031
    Biết APP-T68-READ.
    Khi nhập lô vào bản nháp CAT-LH.
    Thì `403-PQ`.

  @TC-07-252 @P1 @Dương @Âm
  Kịch bản: TC-07-252 Scope rdm.write chỉ ghi vào bản nháp
    # Truy vết: FR-07-023 · API-07-031, 017, 020
    Biết APP-T68-WRITE.
    Khi nhập lô 10 bản ghi vào bản nháp CAT-LH.
    Và trình duyệt; phát hành.
    Thì bước 1 `200`. Bước 2 `403-PQ` cho cả hai (máy không trình, không phát hành).

  @TC-07-253 @P2 @Âm
  Kịch bản: TC-07-253 Client không có scope rdm
    # Truy vết: FR-00-071
    Biết APP-T68-NOSCOPE.
    Khi `GET /catalogs`.
    Thì `403-PQ` từ APISIX hoặc từ PH-07; không có dữ liệu.

  @TC-07-254 @P2 @Âm
  Kịch bản: TC-07-254 Token hết hạn, thiếu token
    # Truy vết: ERR-07-041
    Biết token hết hạn 1 giây.
    Khi gọi `GET /catalogs` với token hết hạn; không có token.
    Thì `401` `ERR-07-041` cho cả hai, có tiêu đề `WWW-Authenticate`.

  @TC-07-255 @P2 @Dương
  Kịch bản: TC-07-255 Giao diện ẩn hoặc vô hiệu nút theo quyền
    # Truy vết: D02-08 · UI-07-01, 02, 07 · D03-06-PH07 mục 23.1
    Biết U-T68-VW, U-T68-DS-MT, U-T68-DA2.
    Khi U-T68-VW mở UI-07-01, UI-07-02 của CAT-LH.
    Và U-T68-DS-MT mở UI-07-02 của CAT-LH.
    Và U-T68-DA2 mở UI-07-07 của bản nháp chính mình đã trình.
    Thì bước 1 không có nút "Tạo danh mục", "Mở bản nháp". Bước 2 nút "Mở bản nháp" vô hiệu, di chuột hiện lý do "Danh mục thuộc Sở Nội vụ". Bước 3 nút "Duyệt" vô hiệu với lý do "Bạn đã trình hoặc sửa bản nháp này".
