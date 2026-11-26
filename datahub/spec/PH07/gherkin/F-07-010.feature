# language: vi
# Gói đặc tả máy đọc PH-07 · tiêu chí nghiệm thu chạy được của F-07-010 (FR-07-010).
# Viết lại từ datahub-docs/05-kiem-thu/test-case/ph07/gherkin/ts-07-02.feature (TC-07-019…023)
# thành bước cụ thể. @bo-sung: kịch bản an toàn thêm theo D04-01 CC-TEST-03/04, chờ chép về D05-02.
# TÁC NHÂN VIẾT MÃ KHÔNG ĐƯỢC SỬA TỆP NÀY (chỉ viết step definition).
#
# Quy ước bước (step definition phải hiện thực đúng nghĩa):
#  - "người dùng {vai} của tenant {T}": token JWT hợp lệ, claim tenant={T}, quyền theo D02-08
#    (TA: PERM-07-read,create,update; DS: PERM-07-read; PA: tenant PLATFORM, PERM-07-*).
#  - "<id X>" trong đường dẫn/thân được thay bằng id của nhóm mã X đã tạo hoặc có sẵn.
#  - "If-Match đúng" = ETag W/"{version}" lấy từ lần đọc gần nhất của nhóm đó.
#  - Mọi lệnh ghi thành công phải để lại đúng một dòng outbox kiểm toán có action đã nêu.

@PH-07 @F-07-010 @TS-07-02
Tính năng: F-07-010 · Quản lý nhóm danh mục

  Bối cảnh:
    Biết CSDL đã nạp dữ liệu nền nhóm COMMON
    Và tenant "T68" có nhóm "HANH_CHINH" tên "Hành chính" thứ tự 10
    Và tenant "T68" có nhóm "HANH_CHINH.TO_CHUC" tên "Tổ chức" là con của "HANH_CHINH"
    Và tenant "T68" có 2 danh mục thuộc nhóm "HANH_CHINH"
    Và tôi là người dùng "TA" của tenant "T68"

  @TC-07-019 @P2
  Kịch bản: TC-07-019 Tạo nhóm con và xem cây nhóm
    Khi tôi gọi POST "/catalog-groups" với thân:
      """
      {"code":"TC019_NHOM","name":"Nhóm thử","parentId":"<id HANH_CHINH>","sortOrder":5}
      """
    Thì mã phản hồi là 201
    Và phản hồi có header "ETag" bằng 'W/"0"'
    Và phản hồi có header "Location" kết thúc bằng id của nhóm "TC019_NHOM"
    Và có bản ghi kiểm toán "RDM_GROUP_CREATE" cho nhóm "TC019_NHOM"
    Khi tôi gọi GET "/catalog-groups"
    Thì mã phản hồi là 200
    Và trong cây, nhóm "HANH_CHINH" có các con theo thứ tự "TC019_NHOM, HANH_CHINH.TO_CHUC"
    Và trong cây, nhóm "HANH_CHINH" có catalogCount là 2
    Và trong cây có nhóm gốc "KHAC" của tenant "COMMON"

  @TC-07-020 @P3
  Kịch bản: TC-07-020 Di chuyển nhóm tạo vòng trong cây nhóm
    Khi tôi gọi PATCH "/catalog-groups/<id HANH_CHINH>" với If-Match đúng và thân:
      """
      {"parentId":"<id HANH_CHINH.TO_CHUC>"}
      """
    Thì mã phản hồi là 409
    Và lỗi có code "ERR-07-039" và errors chứa code "CYCLE" ở trường "parentId"
    Và nhóm "HANH_CHINH" vẫn không có nhóm cha

  @TC-07-021 @P3
  Kịch bản: TC-07-021 Xóa nhóm rỗng
    Biết tenant "T68" có nhóm "TC019_NHOM" tên "Nhóm thử" là con của "HANH_CHINH"
    Khi tôi gọi DELETE "/catalog-groups/<id TC019_NHOM>" với If-Match đúng
    Thì mã phản hồi là 204
    Và có bản ghi kiểm toán "RDM_GROUP_DELETE" cho nhóm "TC019_NHOM"
    Khi tôi gọi GET "/catalog-groups?flat=true"
    Thì danh sách không có nhóm "TC019_NHOM"

  @TC-07-022 @P2
  Kịch bản: TC-07-022 Không xóa được nhóm còn danh mục
    Khi tôi gọi DELETE "/catalog-groups/<id HANH_CHINH>" với If-Match đúng
    Thì mã phản hồi là 409
    Và lỗi có code "ERR-07-037" và detail chứa "còn 2 danh mục"
    Và nhóm "HANH_CHINH" vẫn tồn tại

  @TC-07-023 @P3
  Kịch bản: TC-07-023 Tạo nhóm trùng mã (mã chữ thường được chuẩn hóa chữ hoa)
    Khi tôi gọi POST "/catalog-groups" với thân:
      """
      {"code":"hanh_chinh","name":"Trùng"}
      """
    Thì mã phản hồi là 409
    Và lỗi có code "ERR-07-039" và errors chứa code "UNIQUE" ở trường "code"
    Và tenant "T68" chỉ có 1 nhóm mã "HANH_CHINH"

  @bo-sung @P2
  Kịch bản: Vượt độ sâu 5 khi tạo nhóm
    Biết tenant "T68" có chuỗi nhóm lồng "D1>D2>D3>D4>D5"
    Khi tôi gọi POST "/catalog-groups" với thân:
      """
      {"code":"D6","name":"Sâu 6","parentId":"<id D5>"}
      """
    Thì mã phản hồi là 409
    Và lỗi có code "ERR-07-039" và errors chứa code "DEPTH" ở trường "parentId"

  @bo-sung @P1 @CC-TEST-03
  Kịch bản: Không thấy và không sửa được nhóm của tenant khác
    Biết tenant "T01" có nhóm "RIENG_T01" tên "Riêng T01"
    Khi tôi gọi GET "/catalog-groups?flat=true"
    Thì danh sách không có nhóm "RIENG_T01"
    Khi tôi gọi PATCH "/catalog-groups/<id RIENG_T01>" với If-Match 'W/"0"' và thân:
      """
      {"name":"Chiếm"}
      """
    Thì mã phản hồi là 404
    Và lỗi có code "ERR-07-045"

  @bo-sung @P1
  Kịch bản: Tenant tỉnh không sửa được nhóm COMMON
    Khi tôi gọi PATCH "/catalog-groups/<id KHAC>" với If-Match đúng và thân:
      """
      {"name":"Sửa trộm"}
      """
    Thì mã phản hồi là 403
    Và lỗi có code "ERR-07-003"

  @bo-sung @P1 @CC-TEST-04
  Kịch bản: Người chỉ có quyền xem không tạo được nhóm
    Biết tôi là người dùng "DS" của tenant "T68"
    Khi tôi gọi POST "/catalog-groups" với thân:
      """
      {"code":"KHONG_QUYEN","name":"Không quyền"}
      """
    Thì mã phản hồi là 403
    Và lỗi có code "ERR-07-046"

  @bo-sung @P2
  Kịch bản: Không có token
    Biết tôi chưa đăng nhập
    Khi tôi gọi GET "/catalog-groups"
    Thì mã phản hồi là 401
    Và lỗi có code "ERR-07-041"

  @bo-sung @P2
  Kịch bản: Sửa với ETag cũ và thiếu If-Match
    Khi tôi gọi PATCH "/catalog-groups/<id HANH_CHINH>" với If-Match 'W/"99"' và thân:
      """
      {"name":"Hành chính mới"}
      """
    Thì mã phản hồi là 412
    Và lỗi có code "ERR-07-018"
    Khi tôi gọi PATCH "/catalog-groups/<id HANH_CHINH>" không có If-Match và thân:
      """
      {"name":"Hành chính mới"}
      """
    Thì mã phản hồi là 400
    Và lỗi có code "ERR-07-040"

  @bo-sung @P2
  Kịch bản: Sửa thành công tăng version và không cho đổi mã
    Khi tôi gọi PATCH "/catalog-groups/<id HANH_CHINH>" với If-Match đúng và thân:
      """
      {"name":"Hành chính, địa giới","sortOrder":1}
      """
    Thì mã phản hồi là 200
    Và phản hồi có header "ETag" bằng 'W/"1"'
    Và có bản ghi kiểm toán "RDM_GROUP_UPDATE" cho nhóm "HANH_CHINH"
    Khi tôi gọi PATCH "/catalog-groups/<id HANH_CHINH>" với If-Match đúng và thân:
      """
      {"code":"DOI_MA"}
      """
    Thì mã phản hồi là 422
    Và lỗi có code "ERR-07-009"

  @bo-sung @P2
  Kịch bản: Gửi lại cùng Idempotency-Key
    Khi tôi gọi POST "/catalog-groups" với Idempotency-Key "k-0123456789abcdef" và thân:
      """
      {"code":"IDEM","name":"Một lần"}
      """
    Thì mã phản hồi là 201
    Khi tôi gọi POST "/catalog-groups" với Idempotency-Key "k-0123456789abcdef" và thân:
      """
      {"code":"IDEM","name":"Một lần"}
      """
    Thì mã phản hồi là 201
    Và phản hồi có header "Idempotent-Replayed" bằng "true"
    Và tenant "T68" chỉ có 1 nhóm mã "IDEM"
    Khi tôi gọi POST "/catalog-groups" với Idempotency-Key "k-0123456789abcdef" và thân:
      """
      {"code":"IDEM","name":"Khác thân"}
      """
    Thì mã phản hồi là 409
    Và lỗi có code "ERR-07-022"

  @bo-sung @P2
  Kịch bản: Quản trị nền tảng tạo nhóm COMMON, tenant tỉnh thấy ngay
    Biết tôi là người dùng "PA" của tenant "PLATFORM"
    Khi tôi gọi POST "/catalog-groups" với thân:
      """
      {"code":"MOI_TRUONG","name":"Môi trường","sortOrder":75}
      """
    Thì mã phản hồi là 201
    Và phản hồi có trường "tenantId" bằng "COMMON"
    Biết tôi là người dùng "TA" của tenant "T68"
    Khi tôi gọi GET "/catalog-groups?flat=true"
    Thì danh sách có nhóm "MOI_TRUONG" của tenant "COMMON"
