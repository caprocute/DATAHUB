# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-24
Tính năng: TS-16-24 · Tự đăng ký, cập nhật vận hành và đối chiếu thành phần

  @TC-16-083 @P1 @Dương
  Kịch bản: TC-16-083 Tự đăng ký thành phần từ sự kiện nguồn và API CI
    # Truy vết: FR-16-044 · API-16-101, 096 · UI-16-14 · EVT-16-10 · BR-16-023 · NFR-16-015 · scope `arch.register`
    Biết T90; S-T90-CI; bộ phát PH-01, PH-02, PH-04, PH-10.
    Khi phát EVT-01-03 (HTTT `httt-moi-1` `ACTIVE`), EVT-02-05 (API `api-moi-1`), EVT-04-07 (luồng `flow-moi-1`), EVT-10-01 (topic `topic-moi-1`)
    Và phát lại EVT-01-03 cùng `eventId`
    Và S-T90-CI `POST /ingest/arch-components` `{components: [{componentCode: adapter-moi-1, componentType: ADAPTER, name: "Bộ điều hợp SOAP", version: "1.0.0", lifecycle: ACTIVE, sourceRef: "git:adapter-moi-1", dependsOn: [httt-moi-1], contentHash: <64 hex>}]}`
    Và gọi lại đúng lô
    Thì bước 1 bốn thành phần `origin = AUTO` xuất hiện ≤ 60 giây p95, `lifecycle = ACTIVE`, `sourceRef`, EVT: `arch-component.changed` (EVT-16-10) mỗi thành phần. Bước 2 không tạo trùng (loại theo `eventId`). Bước 3 `202`, `results[0].status = CREATED`, phụ thuộc `httt-moi-1` được nối. Bước 4 `UNCHANGED`. Trường do nguồn quản lý chỉ cập nhật từ nguồn (BR-16-023).

  @TC-16-084 @P1 @Âm
  Kịch bản: TC-16-084 Sự kiện thiếu trường, loại sai, thiếu scope
    # Truy vết: FR-16-044 · API-16-101 · ERR-16-119, ERR-16-039 · UI-16-14
    Biết S-T90-CI, S-T90-NOSCOPE; sự kiện thiếu thành phần cha `httt-khong-co`.
    Khi phát EVT-02-05 có `dependsOn = httt-khong-co`
    Và `POST /ingest/arch-components` với `componentType = "LOAI-LA"`
    Và `POST /ingest/arch-components` thiếu `componentCode`
    Và S-T90-NOSCOPE `POST /ingest/arch-components`
    Thì bước 1 ghi ERR-16-119, đưa vào hàng đối chiếu (tab lệch UI-16-14), không tạo thành phần hỏng. Bước 2, 3 `results[].status = REJECTED`, `code = ERR-16-039` (hoặc `422` ERR-16-039). Bước 4 `403` ERR-00-403.

  @TC-16-085 @P2 @Dương @Chịu @lỗi
  Kịch bản: TC-16-085 Cập nhật trạng thái vận hành từ PH-13 và mất tin
    # Truy vết: FR-16-046 · API-16-096 · UI-16-15 · ERR-16-121 · EVT-16-10
    Biết T90; thành phần `httt-hotich`; `notif-sim` (PH-13) phát trạng thái.
    Khi phát trạng thái `DEGRADED` cho `httt-hotich`
    Và phát `UP`
    Và ngừng phát tin 2 giờ
    Và `GET /arch/components/httt-hotich`
    Thì bước 1 `opsStatus = DEGRADED`, `opsStatusAt`, EVT: `arch-component.changed`. Bước 2 `UP`. Bước 3 sau thời gian quy định `opsStatus = UNKNOWN`, ghi ERR-16-121. Trạng thái vận hành là trường do PH-13 quản lý.

  @TC-16-086 @P2 @Dương
  Kịch bản: TC-16-086 Đối chiếu sổ kiến trúc: thiếu, mồ côi, lệch
    # Truy vết: FR-16-048 · API-16-111, 112, 113 · UI-16-14 · ERR-16-120, ERR-16-056
    Biết T90, F-KT có thành phần mồ côi `api-mo-coi` (không còn ở PH-02), 1 API ở PH-02 chưa có trong sổ, 1 thành phần lệch phiên bản.
    Khi `POST /arch/reconciliations` `{componentTypes: [API]}` khóa idempotent `tc-recon-1`
    Và `GET /arch/reconciliations/{reconId}`
    Và `POST /arch/reconciliations/{reconId}/items/{itemId}:resolve` `{resolution: <25 ký tự>}`
    Và `POST /arch/reconciliations` khi đang chạy
    Và `resolve` với `resolution` 5 ký tự
    Thì bước 1 `202`. Bước 2 `items[]` có đúng ba mục: `ORPHAN` (`api-mo-coi`), `MISSING`, `MISMATCH` với `diff`; tab lệch báo ERR-16-120. Bước 3 mục có `resolution`. Bước 4 `409` ERR-16-056. Bước 5 `400` ERR-16-003 (lược đồ `minLength` 20).
