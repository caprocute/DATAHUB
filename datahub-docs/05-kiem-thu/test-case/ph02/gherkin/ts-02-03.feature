# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-03
Tính năng: TS-02-03 · Phân loại, gắn thẻ và bộ phân loại

  @TC-02-009 @P1 @Dương
  Kịch bản: TC-02-009 Đặt phân loại và thẻ cho API của tổ chức mình
    # Truy vết: FR-02-007 · API-02-008 · UI-02-02, 14 · UC-02-03 · KT: có (api.classify).
    Biết A-DRAFT; U-T68-SV1.
    Khi `PUT /apis/tc-nhap/classification` với nhóm `dat-dai`, `dataClass=INTERNAL`, thẻ `tra-cuu`.
    Và mở UI-02-14.
    Thì `200`; API xuất hiện trong nhóm; có bản ghi kiểm toán giá trị trước và sau.

  @TC-02-010 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-010 Từ chối bí mật nhà nước, API của tổ chức khác, mức quá cao so với hiển thị
    # Truy vết: FR-02-007 · API-02-008 · BR-02-007, 032, 037 · ERR-02-016, 014, 043.
    Biết A-DATDAI; U-T68-SV2; U-T68-SV1.
    Khi U-T68-SV1 gửi `stateSecret=true`.
    Và U-T68-SV2 đặt phân loại cho `tc-dat-dai`.
    Và U-T68-SV1 đặt `dataClass=SENSITIVE` khi mức hiển thị là `NATIONAL`.
    Thì bước 1: `422` ERR-02-016. Bước 2: 403-PQ. Bước 3: `422` ERR-02-043.

  @TC-02-011 @P2 @Dương @Âm
  Kịch bản: TC-02-011 Quản lý nhóm: thêm, đổi tên, gộp, xóa kèm chuyển API
    # Truy vết: FR-02-008 · API-02-009, 010, 011, 012 · UI-02-14 · BR-02-021 · ERR-02-002, 014.
    Biết U-T68-TA; nhóm `dat-dai` có 3 API; U-T68-SV1.
    Khi U-T68-TA `POST /categories` mã `moi-truong`; `PATCH` đổi tên; tạo lại mã `moi-truong` sau khi xóa.
    Và `DELETE /categories/dat-dai` chuyển sang `khac`.
    Và U-T68-SV1 gọi `POST /categories`.
    Thì bước 1: đổi tên thành công, tạo lại mã đã dùng `409` ERR-02-002. Bước 2: 3 API sang `khac`. Bước 3: 403-PQ.

  @TC-02-089 @P2 @Âm @Biên
  Kịch bản: TC-02-089 Nhóm phân loại: mã trùng kể cả mã đã xóa, xóa nhóm thiếu đích, vòng cây, sai quyền
    # Truy vết: FR-02-008 · API-02-009, 010, 011, 012 · UI-02-14 · UC-02-03 · BR-02-021 · ERR-02-002, 003, 014, 011.
    Biết nhóm `tc-nhom-a` (có 2 API), `tc-nhom-a1` con của nó, `tc-nhom-da-xoa` đã xóa; U-T68-TA, U-T68-SV1, U-T68-VW.
    Khi U-T68-TA `POST /categories` mã `tc-nhom-da-xoa`.
    Và `DELETE /categories/tc-nhom-a` không chỉ nhóm đích, rồi với nhóm đích không tồn tại.
    Và `PATCH /categories/tc-nhom-a` đặt cha là `tc-nhom-a1`.
    Và U-T68-SV1 và U-T68-VW gọi `POST /categories`.
    Thì bước 1: `409` ERR-02-002 (mã không dùng lại). Bước 2: `400` ERR-02-003 (thiếu đích), rồi `404` ERR-02-001. Bước 3: bị từ chối vì tạo vòng (`409` ERR-02-011 hoặc `400` ERR-02-003 nêu lý do, không đổi cây). Bước 4: `403` ERR-02-014. UI-02-14 ẩn nút thêm, xóa với SV và VW.

  @TC-02-090 @P2 @Âm @Dương
  Kịch bản: TC-02-090 Phân loại: xung đột `If-Match` và gỡ thẻ
    # Truy vết: FR-02-007 · API-02-008 · UI-02-14 · UC-02-03 · BR-02-028 · ERR-02-015.
    Biết A-DATDAI; hai phiên U-T68-SV1 (A và B) cùng lấy `ETag`.
    Khi phiên A `PUT /apis/tc-dat-dai/classification` đổi thẻ thành `[đất đai]`, kèm `If-Match`.
    Và phiên B gửi cùng thay đổi với `ETag` cũ.
    Và phiên B lấy lại `ETag` mới, gỡ hết thẻ (`tags: []`).
    Thì bước 1: `200`, `ETag` đổi. Bước 2: `412` ERR-02-015, dữ liệu giữ nguyên bản của phiên A. Bước 3: `200`, API không còn thẻ; mỗi thay đổi có một dòng kiểm toán giá trị trước, sau.
