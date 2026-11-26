# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-15
Tính năng: TS-07-15 · Đồng bộ danh mục quốc gia

  @TC-07-177 @P1 @Dương
  Kịch bản: TC-07-177 Tạo, sửa, tắt nguồn đồng bộ
    # Truy vết: FR-07-035 · API-07-055, 056, 057 · LGC-DMDC-019
    Biết U-PA; danh mục COMMON `TC177_QT` (NATIONAL, chưa có nguồn).
    Khi `POST /sync-sources` với `catalogCode = TC177_QT`, `provider = NDXP_DMDC`, `remoteCatalogId`, `schedule = "0 30 1 * * *"`, `autoApply = false`, `fieldMapping`.
    Và `GET /sync-sources?catalogCode=TC177_QT`.
    Và `PATCH /sync-sources/{id}` với `If-Match` đổi `enabled = false`.
    Thì bước 1 trả `201`, có `ETag`, lịch chạy kế tiếp `nextRunAt` = 01:30 hôm sau giờ Việt Nam. Bước 2 trả nguồn vừa tạo. Bước 3 trả `200`, `nextRunAt = null`. KT: có (SYNC_SOURCE_CREATE, SYNC_SOURCE_UPDATE).

  @TC-07-178 @P1 @Âm
  Kịch bản: TC-07-178 Nguồn đồng bộ trùng, lịch sai, danh mục không hợp lệ
    # Truy vết: FR-07-035 · ERR-07-002, 003, 009, 018
    Biết `SRC-GT` đã có cho CAT-GT.
    Khi U-PA tạo nguồn thứ hai cùng `provider` cho CAT-GT.
    Và U-PA tạo nguồn với `schedule = "* * * * * *"` (mỗi giây) và với biểu thức sai cú pháp.
    Và U-T68-TA tạo nguồn cho CAT-GT (COMMON).
    Và U-T68-TA tạo nguồn cho CAT-LH (LOCAL).
    Và U-PA sửa `SRC-GT` với `If-Match` cũ.
    Thì bước 1 `409` `ERR-07-002`. Bước 2 `422` `ERR-07-009` (lịch dưới khoảng tối thiểu 1 giờ, cú pháp sai). Bước 3 `403` `ERR-07-003`. Bước 4 `422` `ERR-07-009` (chỉ danh mục NATIONAL hoặc COMMON có nguồn). Bước 5 `412` `ERR-07-018`.

  @TC-07-179 @P1 @Dương
  Kịch bản: TC-07-179 Lần chạy không có thay đổi
    # Truy vết: FR-07-036 · API-07-058, 060 · EVT-07-09
    Biết wireMock `BASE`.
    Khi U-PA gọi `POST /sync-sources/{SRC-GT}:run`.
    Và thăm dò `GET /sync-runs/{runId}` tới khi kết thúc.
    Thì bước 1 trả `202` kèm `runId`. Lần chạy kết thúc `NO_CHANGE`; không có phiên bản mới; EVT-07-09 phát với `status = NO_CHANGE`. KT: có (SYNC_RUN, người khởi chạy U-PA).

  @TC-07-180 @P1 @Dương
  Kịch bản: TC-07-180 Thay đổi không phá vỡ được tự áp dụng
    # Truy vết: FR-07-036 · BR-07-011, 017 · EVT-07-05, 09
    Biết wireMock `RENAMED_2`; `SRC-GT.autoApply = true`.
    Khi bộ lập lịch kích hoạt lần chạy (IT tua `Clock` tới 02:00).
    Thì lần chạy `APPLIED`; tạo và phát hành phiên bản `origin = SYNC`, 2 bản ghi đổi tên, `effectiveFrom` theo quy tắc BR-07-011; EVT-07-05 và EVT-07-09 phát; tác nhân kiểm toán là `system:rdm-sync`.

  @TC-07-181 @P2 @Dương
  Kịch bản: TC-07-181 Tắt tự áp dụng thì thay đổi an toàn cũng chờ xác nhận
    # Truy vết: FR-07-036 · BR-07-017
    Biết wireMock `ADDED_5` cho `DAN_TOC`; nguồn `SRC-DT` có `autoApply = false`.
    Khi chạy `SRC-DT`.
    Thì lần chạy `PENDING_CONFIRMATION`, `diffStats.added = 5`, `hasBreaking = false`; có bản nháp `origin = SYNC` chiếm suất phiên bản mở của `DAN_TOC`.

  @TC-07-182 @P1 @Dương
  Kịch bản: TC-07-182 Thay đổi phá vỡ dừng ở chờ xác nhận
    # Truy vết: FR-07-036 · BR-07-012, 017 · API-07-060
    Biết wireMock `REMOVED_1`; `SRC-GT.autoApply = true`.
    Khi chạy `SRC-GT`.
    Và `GET /sync-runs/{runId}` xem danh sách thay đổi.
    Thì lần chạy `PENDING_CONFIRMATION` dù `autoApply = true`; thay đổi mã `3` có `changeType = DEPRECATED`, `breaking = true` (đồng bộ không xóa bản ghi). EVT-07-09 có `hasBreaking = true`. Hộp "Việc của tôi" của người có `PERM-07-sync` nhận việc chờ.

  @TC-07-183 @P1 @Dương
  Kịch bản: TC-07-183 Xác nhận áp dụng thay đổi phá vỡ
    # Truy vết: FR-07-037 · API-07-061 · UI-07-09 · EVT-07-05
    Biết lần chạy từ TC-07-182.
    Khi U-PA mở UI-07-09, xem khác biệt, nhập ý kiến, bấm "Xác nhận".
    Thì API-07-061 trả `200`; lần chạy `APPLIED`; phiên bản `origin = SYNC` được phát hành với mã `3` ở trạng thái `DEPRECATED`; EVT-07-05 có `breaking = true`. KT: có (SYNC_ACCEPT, ý kiến).

  @TC-07-184 @P1 @Dương
  Kịch bản: TC-07-184 Từ chối thay đổi
    # Truy vết: FR-07-037 · API-07-062 · ERR-07-009
    Biết một lần chạy `PENDING_CONFIRMATION` mới (lặp TC-07-182).
    Khi gọi `:reject` không có `reason`.
    Và gọi `:reject` với `reason` 20 ký tự.
    Thì bước 1 `422` `ERR-07-009`. Bước 2 `200`, lần chạy `REJECTED`, bản nháp `origin = SYNC` bị hủy, phiên bản hiện hành giữ nguyên; EVT-07-09 `status = REJECTED`.

  @TC-07-185 @P1 @Âm
  Kịch bản: TC-07-185 Xác nhận hoặc từ chối lần chạy đã kết thúc
    # Truy vết: FR-07-037 · ERR-07-029
    Biết lần chạy `APPLIED` (TC-07-183), `REJECTED` (TC-07-184), `NO_CHANGE` (TC-07-179).
    Khi gọi `:accept` và `:reject` trên từng lần chạy.
    Thì mọi lời gọi trả `409` `ERR-07-029`; dữ liệu không đổi.

  @TC-07-186 @P1 @Âm @Khả @dụng
  Kịch bản: TC-07-186 Nguồn lỗi, quá thời gian hoặc trả dữ liệu hỏng
    # Truy vết: FR-07-036 · ERR-07-028 · EVT-07-09 · NFR-07-013, 014
    Biết wireMock lần lượt `HTTP_500`, `TIMEOUT`, `MALFORMED`.
    Khi chạy `SRC-GT` với từng trạng thái.
    Thì mỗi lần chạy kết thúc `FAILED`, `errorCode = ERR-07-028` (hai trường hợp đầu) hoặc lỗi kiểm tra dữ liệu nguồn (trường hợp ba); không tạo phiên bản; phiên bản hiện hành vẫn phục vụ tra cứu bình thường; chỉ số `rdm_sync_failed_total` tăng; sau 3 lần thất bại liên tiếp, cảnh báo `RdmSyncFailing` bật; khi `rdm_sync_last_success_timestamp` quá 24 giờ, cảnh báo độ tươi (NFR-07-013) bật.

  @TC-07-187 @P1 @Dương
  Kịch bản: TC-07-187 Khám phá danh mục quốc gia và đăng ký đồng bộ
    # Truy vết: FR-07-038 · API-07-063, 056 · LGC-NGSP-006
    Biết wireMock trả danh sách 6 danh mục quốc gia, trong đó `TON_GIAO` chưa có ở T68.
    Khi U-T68-TA gọi `GET /national-catalogs`.
    Và đăng ký đồng bộ `TON_GIAO` vào T68 (tạo danh mục NATIONAL và nguồn trong một thao tác).
    Thì bước 1 trả 6 danh mục, mỗi mục có cờ `alreadyLinked`. Bước 2 trả `201`; tạo danh mục `TON_GIAO` (NATIONAL, `DRAFT`) và nguồn; lần chạy đầu tiên tạo phiên bản 1 chờ xác nhận. EVT-07-01 phát.

  @TC-07-188 @P2 @Âm
  Kịch bản: TC-07-188 Đăng ký trùng hoặc khi nguồn quốc gia không phản hồi
    # Truy vết: FR-07-038 · ERR-07-002, 028
    Biết `TON_GIAO` đã đăng ký ở TC-07-187.
    Khi đăng ký lại `TON_GIAO`.
    Và chuyển WireMock sang `HTTP_500`, gọi `GET /national-catalogs`.
    Thì bước 1 `409` `ERR-07-002`. Bước 2 `502` `ERR-07-028` dạng problem+json, không lộ địa chỉ NDXP.

  @TC-07-189 @P1 @Âm @Biên
  Kịch bản: TC-07-189 Hai lần chạy cùng lúc trên một nguồn
    # Truy vết: FR-07-036 · ERR-07-005
    Biết wireMock `TIMEOUT` để lần chạy đầu kéo dài; hai bản sao `dh-data`.
    Khi gửi đồng thời hai lời gọi `:run` tới hai bản sao.
    Thì đúng một lời gọi trả `202`; lời gọi còn lại trả `409` `ERR-07-005`; bảng `sync_run` chỉ có một dòng `RUNNING` cho nguồn (chỉ mục `uq_sync_run_running`).

  @TC-07-190 @P3 @Dương @Âm
  Kịch bản: TC-07-190 Đề xuất bổ sung bản ghi lên danh mục quốc gia
    # Truy vết: FR-07-039 · API-07-074 · BR-07-025 · ERR-07-003, 026, 028
    Biết cờ `07.rdm.feature.national-proposal = true` ở T68; WireMock nhận đề xuất và trả mã tiếp nhận.
    Khi U-T68-TA gửi đề xuất 2 bản ghi cho `TON_GIAO`.
    Và gửi 101 bản ghi trong một đề xuất.
    Và gửi đề xuất cho CAT-LH (LOCAL).
    Và tắt cờ tính năng rồi gửi lại bước 1.
    Thì bước 1 `202`, tạo tác vụ `PROPOSAL` ở `SUBMITTED`, sau khi WireMock phản hồi chuyển `ACCEPTED` hoặc `UNKNOWN` theo kịch bản. Bước 2 `400` `ERR-07-026`. Bước 3 `403` `ERR-07-003`. Bước 4 `404` `ERR-07-045` (tính năng tắt nên endpoint không lộ).
