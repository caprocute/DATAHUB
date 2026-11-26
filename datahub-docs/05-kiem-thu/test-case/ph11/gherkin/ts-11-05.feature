# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-05
Tính năng: TS-11-05 · Gửi duyệt, duyệt phát hành bốn mắt, ngừng dùng và thu hồi phiên bản

  @TC-11-028 @P1 @Dương
  Kịch bản: TC-11-028 Gửi duyệt, việc duyệt và rút lại
    # Truy vết: FR-11-007 · API-11-016, 017, 018, 019 · UI-11-03, 07 · BR-11-004, 033 · PERM-11-model
    Biết v4 hợp lệ; IE1; IA1, IA2.
    Khi IE1 `POST /versions/4:submit` `{releaseNote:"Thêm bước kiểm tra"}`
    Và IA1 `GET /publish-requests` và `GET /tasks`
    Và IE1 `PUT /versions/4/bpmn`
    Và IE1 `POST /versions/4:withdraw`
    Và IE1 gửi lại
    Thì bước 1 `202`, v4 `IN_REVIEW`, `publish_request` `PENDING` có checksum, nhả khóa soạn. Bước 2 IA1 thấy yêu cầu và một việc `PUBLISH_REVIEW`. Bước 3 `409` ERR-11-006. Bước 4 `WITHDRAWN`, v4 `DRAFT`, việc duyệt `CANCELLED`.

  @TC-11-029 @P1 @Âm
  Kịch bản: TC-11-029 Gửi duyệt: còn lỗi, thiếu ghi chú, sai trạng thái, người duyệt chỉ định không đủ quyền
    # Truy vết: FR-11-007 · API-11-016 · ERR-11-006, 007, 010, 024 · ERR-00-403 · BR-11-033
    Biết nháp còn lỗi `ERROR`; v3 `PUBLISHED`; IE1, VW; CB-TP không có `PERM-11-publish`.
    Khi IE1 gửi nháp còn lỗi
    Và IE1 gửi nháp hợp lệ với ghi chú 5 ký tự
    Và IE1 gửi v3
    Và IE1 chỉ định `reviewer = CB-TP`
    Và VW gửi duyệt
    Thì bước 1 `422` ERR-11-010. Bước 2 `422` ERR-11-007. Bước 3 `409` ERR-11-006. Bước 4 `422` ERR-11-024. Bước 5 `403` ERR-00-403.

  @TC-11-030 @P1 @Dương
  Kịch bản: TC-11-030 Duyệt phát hành: triển khai, bản cũ ngừng, phiên cũ giữ phiên bản
    # Truy vết: FR-11-008 · API-11-020 · UI-11-07 · EVT-11-01 · BR-11-004, 005, 006, 032, 033 · PERM-11-publish
    Biết v4 `IN_REVIEW` do IE1 gửi, IE2 sửa cuối; IA1; một phiên `HS-01` đang chạy ở v3.
    Khi IA1 `POST /publish-requests/{id}:approve` `{comment:"Đồng ý, đã đối chiếu luồng PH-04"}`
    Và tra `ACT_RE_DEPLOYMENT` và `ACT_RE_PROCDEF` theo tenant
    Và S-DVC `POST /instances` `HS-02`
    Và `GET /instances/{HS-01}`
    Thì bước 1 `200`; v4 `PUBLISHED`, v3 `DEPRECATED`, `publish_request` `APPROVED`; có `deploymentId`, `processDefinitionId`. Bước 2 `tenantId = t90`, tên `LT_KHAI_SINH:v4`. EVT: `model.published` có `checksum`, `publishedBy = IE1`, `approvedBy = IA1`. Bước 3 phiên dùng v4. Bước 4 `HS-01` vẫn v3 (BR-11-006). KT: có (`model.publish`).

  @TC-11-031 @P2 @Dương
  Kịch bản: TC-11-031 Từ chối phát hành, bản về nháp
    # Truy vết: FR-11-008 · API-11-021 · UI-11-07 · BR-11-033
    Biết v5 `IN_REVIEW`; IA1.
    Khi IA1 `POST /publish-requests/{id}:reject` `{comment:"Thiếu bù trừ cho bước gửi Tư pháp, cần bổ sung"}`
    Và IE1 `GET /versions/5`
    Thì bước 1 `200`, `REJECTED`; v5 `DRAFT`; IE1 nhận việc thông báo kèm lý do; không có EVT `model.published`.

  @TC-11-032 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-032 Duyệt vi phạm bốn mắt, thiếu ý kiến, bản đổi, luồng chưa phát hành
    # Truy vết: FR-11-008 · API-11-020, 021 · ERR-11-004, 005, 007, 010, 012 · BR-11-004, 005
    Biết v6 do IE1 gửi, TA là người sửa cuối; TA có `PERM-11-model` và `PERM-11-publish` (SIT); IA1.
    Khi TA `:approve`
    Và IE1 (cấp thêm `PERM-11-publish` ở SIT) `:approve`
    Và IA1 `:approve` với `comment` rỗng
    Và IA1 `:reject` với `comment` 5 ký tự
    Và sửa `checksum` của v6 ở CSDL, IA1 `:approve`
    Và ngừng luồng PH-04 của `capTheBHYT`, IA1 `:approve` bản hợp lệ
    Thì bước 1 và 2 `403` ERR-11-005. Bước 3 và 4 `422` ERR-11-007. Bước 5 `409` ERR-11-004, yêu cầu gửi lại. Bước 6 `422` ERR-11-012. Mọi bước v6 vẫn `IN_REVIEW`, không có bản tin `model.published`.

  @TC-11-033 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-11-033 Engine từ chối triển khai
    # Truy vết: FR-11-008 · API-11-020 · ERR-11-046 · BR-11-005, 032
    Biết v7 `IN_REVIEW` có XML mà Flowable từ chối; v4 đang `PUBLISHED`; IA1.
    Khi IA1 `:approve`
    Và tra trạng thái v4, v7, `publish_request`, `ACT_RE_DEPLOYMENT`, outbox
    Và ngừng PostgreSQL 10 giây, IA1 `:approve` bản hợp lệ
    Thì bước 1 `503` hoặc `422` ERR-11-046. Bước 2 v4 vẫn `PUBLISHED`, v7 về `DRAFT`, `publish_request` `DEPLOY_FAILED`, không có deployment mới, không có EVT `model.published`. Bước 3 `503` ERR-11-046, trạng thái không đổi.

  @TC-11-167 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-11-167 Duyệt từng miễn bù trừ khi phát hành
    # Truy vết: FR-11-014, 008 · API-11-020 · UI-11-07 · ERR-11-005, 010 · BR-11-008 · PERM-11-publish
    Biết v5 `IN_REVIEW` có bước `khongBu` `NONE_APPROVED` (ghi chú 30 ký tự) do TA gửi; IA1, TA.
    Khi TA `:approve` với `waiverDecisions[]` chấp nhận `khongBu`
    Và IA1 `:approve` với `waiverDecisions[]` không chấp nhận `khongBu`
    Và IA1 `:approve` với `waiverDecisions[]` chấp nhận `khongBu`
    Thì bước 1 `403` ERR-11-005 (người đề nghị không duyệt). Bước 2 `422` ERR-11-010 vì `khongBu` chưa có miễn đã duyệt (`RISKY_NO_COMPENSATION`), v5 vẫn `IN_REVIEW`. Bước 3 v5 `PUBLISHED`, miễn ghi kiểm toán; không có API duyệt miễn riêng.

  @TC-11-034 @P1 @Dương
  Kịch bản: TC-11-034 Ngừng dùng có xác nhận, khôi phục, thu hồi
    # Truy vết: FR-11-009 · API-11-006, 022, 023, 131 · UI-11-03 · EVT-11-02 · BR-11-006, 028 · PERM-11-publish
    Biết `LT_THU_NGHIEM` v1 `PUBLISHED` là bản duy nhất, không có phiên; IA1; TA2.
    Khi IA1 `POST /versions/1:deprecate` `{confirm:true, reason:"Ngừng thử nghiệm"}`
    Và S-DVC `POST /instances` `LT_THU_NGHIEM`
    Và IA2 `POST /versions/1:restore` (API-11-131)
    Và IA1 `:deprecate` lại rồi `:retire`
    Và `GET /models/LT_THU_NGHIEM/versions`
    Thì bước 1 `DEPRECATED`, EVT `model.retired` `status = DEPRECATED`. Bước 2 `422` ERR-11-017. Bước 3 v1 về `PUBLISHED`, không triển khai lại. Bước 4 `RETIRED`, `suspendProcessDefinition` đã gọi, EVT `model.retired` `status = RETIRED`.

  @TC-11-035 @P1 @Âm
  Kịch bản: TC-11-035 Ngừng dùng, thu hồi: bản duy nhất, còn phiên, thiếu lý do, quyền
    # Truy vết: FR-11-009 · API-11-022, 023, 131 · ERR-11-006, 007, 017, 037, 038 · ERR-00-403 · BR-11-028
    Biết `M-KS` v3 `DEPRECATED` còn 2 phiên; `M-DUYET` v1 là bản `PUBLISHED` duy nhất; IA1, IE1.
    Khi IA1 `:retire` v3
    Và IA1 `:deprecate` `M-DUYET` v1 không có `confirm`
    Và IA1 `:deprecate` với `reason` 4 ký tự
    Và IE1 `:retire`
    Và IA1 `:deprecate` `M-DUYET` v1 với `confirm:true`, rồi S-PH01 khởi tạo `DUYET_KET_NAP_HTTT`
    Và IA1 `:restore` v3 (`M-KS` còn bản `PUBLISHED`), rồi `:restore` `M-DUYET` v1 thiếu lý do
    Thì bước 1 `409` ERR-11-037. Bước 2 `422` ERR-11-038. Bước 3 `422` ERR-11-007. Bước 4 `403` ERR-00-403. Bước 5 `422` ERR-11-017. Bước 6 `409` ERR-11-006, rồi `422` ERR-11-007.
