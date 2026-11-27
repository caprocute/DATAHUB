# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-40
Tính năng: TS-20-40 · Saga khởi tạo từng bước S01…S17

  @TC-20-203 @P1 @Dương @Âm
  Kịch bản: TC-20-203 S01_RECORD, S02_CONFIG_REPO: lỗi Git rồi thử lại, bù trừ revert
    # Truy vết: FR-20-008, 010, 011 · API-20-013, 017, 018, 020 · BR-20-007 · ERR-20-018, ERR-20-019 · EVT-20-02
    Biết `U-PA1`; `T94` `PROVISIONING`; F-SAGA `FAIL_ONCE` ở `S02_CONFIG_REPO` (`git-sim` từ chối ghi một lần).
    Khi `POST P/tenants/T94/provisioning-runs` (`INITIAL`)
    Và `POST P/provisioning-runs/{runId}/steps/S02_CONFIG_REPO:retry`
    Và chạy lại với `FAIL_ALWAYS` ở `S02`, rồi `POST P/provisioning-runs/{runId}:compensate`
    Thì bước 1 `S01` `SUCCEEDED`, `S02` `FAILED`, lần chạy `FAILED`, EVT-20-02. Bước 2 `S02` `SUCCEEDED`, tiếp tục các bước sau. Bước 3 bù trừ: revert commit ở `dh-tenant-config`, `S01` xóa bản ghi chỉ khi chưa có bước nào khác xong (ở đây còn bước khác nên giữ, tenant về `FAILED`); bước bù không làm được trả `ERR-20-019`.

  @TC-20-204 @P1 @Dương @Âm
  Kịch bản: TC-20-204 S03_REALM: PH-12 lỗi `409`, `503`, trễ; bù trừ xóa realm đang PROVISIONING
    # Truy vết: FR-20-008, 011 · API-20-013, 018, 020 · ERR-20-062, ERR-20-107 · BR-20-007
    Biết `U-PA1`; `T94`; `iam-sim` kịch bản `409` (realm đã có), `503`, trễ 90 giây.
    Khi chạy saga khi `iam-sim` `503`
    Và thử lại bước sau khi `iam-sim` bình thường
    Và chạy saga khi `iam-sim` trễ 90 giây
    Và bù trừ lần chạy `FAILED` sau `S03`
    Thì bước 1 `S03` `FAILED` với `ERR-20-107` ("Bước S03_REALM lỗi tại PH-12: 503."). Bước 2 `SUCCEEDED`, realm `dh-t94`, client `dh-console`, `dh-portal`, quản trị tỉnh đầu tiên. Bước 3 vẫn chờ, không `FAILED`, theo thời hạn bước. Bước 4 `iam-sim` nhận lệnh xóa realm còn `PROVISIONING`.

  @TC-20-205 @P1 @Dương @Âm
  Kịch bản: TC-20-205 S04_SECRETS, S05_BUCKETS: OpenBao, Ceph lỗi; bù trừ xóa đường dẫn, KEK chưa dùng, bucket rỗng
    # Truy vết: FR-20-008, 011 · API-20-018, 020 · NFR-20-024 · ERR-20-107, ERR-20-019
    Biết `T94`; `vault-sim`, `s3-sim`; `s3-sim` có bucket `dh-t94-files` chứa một tệp (bù trừ không xóa được).
    Khi chạy saga với `FAIL_ONCE` ở `S04`, thử lại
    Và chạy với `FAIL_ONCE` ở `S05`, thử lại
    Và bù trừ khi bucket `dh-t94-files` còn tệp
    Thì bước 1 đường dẫn `kv/dh/t94/...`, chính sách, KEK `dh-t94-pii` được tạo một lần (lũy đẳng), không bí mật nào vào CSDL hay Git. Bước 2 đủ bốn bucket `files`, `exports`, `backup`, `audit`. Bước 3 bucket còn tệp không bị xóa, lần bù `ERR-20-019`, cần xử lý tay.

  @TC-20-206 @P1 @Dương @Âm
  Kịch bản: TC-20-206 S06_EVENTING (bất đồng bộ): chờ báo, báo thành công, báo lỗi, hết hạn
    # Truy vết: FR-20-008, 009 · API-20-166 · BR-20-007 · ERR-20-105, ERR-20-106, ERR-20-107 · NFR-20-007
    Biết `S-PH10`; F-SAGA `OK`, `REPORT_FAILED`, `NO_REPORT`; `20.provision.step-timeout-minutes`, `20.provision.step-retry-max`; đồng hồ giả lập.
    Khi lần chạy 1 (`OK`): `S-PH10` báo `S06_EVENTING` `SUCCEEDED`
    Và lần chạy 2 (`REPORT_FAILED`): `S-PH10` báo `FAILED` kèm `errorCode`
    Và lần chạy 3 (`NO_REPORT`): tiến đồng hồ quá thời hạn bước
    Và quan sát tiến trình qua `GET P/provisioning-runs/{runId}/stream` (SSE)
    Thì bước 1 bước `WAITING` rồi `SUCCEEDED`. Bước 2 `FAILED` với `ERR-20-107`. Bước 3 sau `step-timeout` tự thử tối đa `step-retry-max` lần rồi `FAILED` với `ERR-20-106` ("Bước S06_EVENTING chưa nhận báo cáo từ PH-10 sau 15 phút."). Bước 4 sự kiện tiến độ trễ ≤ 2 giây (NFR-20-007).

  @TC-20-207 @P1 @Âm
  Kịch bản: TC-20-207 Báo lặp, báo sai bước, báo sai bên, báo khi lần chạy đã kết thúc
    # Truy vết: FR-20-009 · API-20-166 · ERR-20-105, ERR-20-104, ERR-20-004, ERR-20-002
    Biết `S-PH10`, `S-PH04`, `S-NOSCOPE`; lần chạy `RUNNING` đang chờ `S06`; lần chạy `FAILED`; F-SAGA `DUP_REPORT`.
    Khi `S-PH10` báo `S06_EVENTING` `SUCCEEDED` hai lần
    Và `S-PH10` báo `S09_GATEWAY` (bước của PH-03)
    Và `S-PH10` báo `S06_EVENTING` khi bước đã `FAILED` do hết hạn
    Và `S-NOSCOPE` báo
    Và báo `stepCode` không có (`S99_KHONG`); báo `runId` không có; thân thiếu `status`
    Thì bước 1 hai lần `200`, kết quả như nhau, tiến độ không đổi hai lần. Bước 2 `403` `ERR-20-104` (không phải bên thực hiện). Bước 3 `409` `ERR-20-105` ("Báo tiến độ bước S06_EVENTING không khớp trạng thái FAILED."). Bước 4 `403` `ERR-20-104`. Bước 5 `400` `ERR-20-004`, `404` `ERR-20-002`, `400` `ERR-20-004`.

  @TC-20-208 @P2 @Dương @Biên
  Kịch bản: TC-20-208 S07_DATABASE chỉ DEDICATED_DB: tạo cụm CNPG, bỏ qua với SHARED
    # Truy vết: FR-20-008, 007 · API-20-013 · BR-20-007 · ERR-20-107
    Biết `T93` `SHARED`, `T95` `DEDICATED_DB` (PostgreSQL thật, CNPG giả hợp đồng).
    Khi chạy saga `T93`
    Và chạy saga `T95` với `FAIL_ONCE` ở `S07`, thử lại
    Thì bước 1 `S07` `SKIPPED` (không áp dụng). Bước 2 cụm, migration, bảng định tuyến tạo một lần; bù trừ xóa cụm.

  @TC-20-209 @P1 @Dương @Âm
  Kịch bản: TC-20-209 S08_OBSERVABILITY đồng bộ, S09_GATEWAY bất đồng bộ đọc API-20-164
    # Truy vết: FR-20-008, 009, 065 · API-20-166, 164 · EVT-20-01 · ERR-20-107, ERR-20-106 · NFR-20-003
    Biết `obs-sim` (API-13-072, 073); `S-PH03`; F-SAGA.
    Khi chạy saga; `obs-sim` trả `409` một lần ở `S08`, thử lại
    Và `S-PH03` đọc `GET I/tenants/T94/enforcement`, rồi báo `S09_GATEWAY` `SUCCEEDED`
    Và bù trừ: kiểm đóng chuỗi kiểm toán (API-13-073) và PH-03 gỡ
    Thì bước 1 chuỗi kiểm toán, tổ chức Grafana, luật cảnh báo lập một lần. Bước 2 PH-03 nhận hạn mức hợp đồng và host, tiền tố; `S09` `SUCCEEDED`. Bước 3 đúng thứ tự bù ngược.

  @TC-20-210 @P2 @Dương @Âm
  Kịch bản: TC-20-210 S10_INTEGRATION, S11_SEED_RDM, S12_SEED_MDM: bật theo mẫu, lỗi, bù trừ
    # Truy vết: FR-20-008, 009 · API-20-166 · EVT-20-01 · ERR-20-107, ERR-20-106
    Biết `T94`; mẫu bật PH-04, PH-07, PH-06; `rdm-sim` API-07-073; `mod-sim` báo `S10`, `S12`.
    Khi chạy saga bình thường
    Và chạy với `rdm-sim` `503` ở `S11`, thử lại
    Và chạy với PH-06 không bật trong mẫu
    Thì bước 1 `S10`, `S12` `SUCCEEDED` qua báo; `S11` nạp gói danh mục nền. Bước 2 `S11` `FAILED`, thử lại thành công. Bước 3 `S12` `SKIPPED`.

  @TC-20-211 @P1 @Dương @Âm
  Kịch bản: TC-20-211 S13_ORG_SEED gieo tổ chức cấp tỉnh, S14_KPI kế thừa chỉ tiêu
    # Truy vết: FR-20-008 · API-20-013 · ERR-20-062, ERR-20-107 · EVT-20-13
    Biết `T94`; ĐVHC `COMMON` (UBND tỉnh, sở theo mẫu); `kpi-sim` `503` một lần (PH-16 bật).
    Khi chạy saga
    Và `kpi-sim` `503` ở `S14`, thử lại; chạy với PH-16 không bật
    Thì bước 1 `S13` tạo UBND tỉnh và các sở theo mẫu (số tổ chức khớp mẫu), phát EVT-20-13. Bước 2 `S14` `FAILED` rồi `SUCCEEDED`; không bật thì `SKIPPED`.

  @TC-20-212 @P1 @Dương @Âm
  Kịch bản: TC-20-212 S15_MODULES phát EVT-20-07 từng phân hệ bật và chờ báo
    # Truy vết: FR-20-008, 009, 034 · API-20-166 · EVT-20-07, EVT-20-08 · ERR-20-106
    Biết mẫu bật PH-19, PH-17; `mod-sim` PH-19 báo, PH-17 không báo.
    Khi chạy saga tới `S15`
    Và PH-19 báo `SUCCEEDED`; PH-17 không báo, quá hạn
    Và bù trừ lần chạy `FAILED`
    Thì bước 1 phát EVT-20-07 cho từng phân hệ. Bước 2 PH-19 `SUCCEEDED`; `S15` `FAILED` với `ERR-20-106` do PH-17. Bước 3 phát EVT-20-08 cho phân hệ đã bật.

  @TC-20-213 @P1 @Âm
  Kịch bản: TC-20-213 S16_SMOKE: ca khói lỗi dừng saga, tenant không ACTIVE
    # Truy vết: FR-20-008, 012 · BR-20-004 · API-20-022 · ERR-20-117, ERR-20-020
    Biết `T94`; `20.smoke.enabled = true`; bản giả làm ca "rò rỉ chéo tenant" lỗi.
    Khi chạy saga tới `S16`
    Và `GET P/tenants/T94`
    Và `POST P/tenants/T94:activate`
    Thì bước 1 `S16` `FAILED` với `ERR-20-117` ("Ca kiểm tra khói LEAK-CHECK lỗi: trả dữ liệu của T93."). Bước 2 tenant giữ `PROVISIONING` (hoặc `FAILED`). Bước 3 `422` `ERR-20-020`.

  @TC-20-214 @P1 @Dương @Âm
  Kịch bản: TC-20-214 S17_ACTIVATE: ACTIVE, thông báo đầu mối, đẩy KPI-12
    # Truy vết: FR-20-008, 013, 014 · API-20-023 · EVT-20-03 · ERR-20-062, ERR-20-021
    Biết `T94` đã qua `S16`; `ops-sim`; `kpi-sim` `503`.
    Khi chạy `S17`
    Và chạy lại với `kpi-sim` `503`
    Và đầu mối `TENANT_ADMIN` bị xóa trước khi kích hoạt
    Thì bước 1 `ACTIVE`, EVT-20-03, thư đến đầu mối, KPI-12 đẩy qua API-16-030. Bước 2 tenant vẫn `ACTIVE`, việc đẩy KPI-12 thử lại sau (không chặn). Bước 3 `422` `ERR-20-021`.

  @TC-20-215 @P2 @Biên
  Kịch bản: TC-20-215 Saga vượt tổng thời gian cho phép
    # Truy vết: FR-20-008 · BR-20-007 · ERR-20-108 · NFR-00-057
    Biết `20.provision.timeout-minutes = 60`; mọi bước trễ tổng 61 phút (đồng hồ giả lập).
    Khi chạy saga với bước trễ dần
    Thì lần chạy `FAILED` với `ERR-20-108` ("Khởi tạo vượt thời gian cho phép 60 phút."), EVT-20-02, các bước dở dang dừng; thử lại hoặc bù trừ được.
