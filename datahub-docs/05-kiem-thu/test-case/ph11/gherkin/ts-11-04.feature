# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-04
Tính năng: TS-11-04 · Ý định nghiệp vụ và hành động bù trừ

  @TC-11-024 @P1 @Dương
  Kịch bản: TC-11-024 Đăng ký ý định, ánh xạ luồng theo môi trường, ngừng dùng
    # Truy vết: FR-11-013 · API-11-034, 035, 036, 037, 038 · UI-11-09 · BR-11-002, 003 · PERM-11-model
    Biết IE1; luồng PH-04 `flow-bhyt-test` đã phát hành ở TEST.
    Khi IE1 `POST /intents` `{intentCode:"capTheBHYT", inputSchema, outputSchema, writesExternal:true, businessErrors:["BHXH_TU_CHOI"]}`
    Và IE1 `PUT /intents/capTheBHYT` gắn `bindings` `TEST → flow-bhyt-test`
    Và IE1 `GET /intents/capTheBHYT/bindings`
    Và IE1 `POST /intents/capTheBHYT:deprecate`
    Thì bước 1 `201`. Bước 2 `200`. Bước 3 trả ánh xạ theo môi trường, không chứa URL, giao thức, thông tin xác thực của HTTT. Bước 4 `DEPRECATED` khi không còn mô hình `PUBLISHED` dùng.

  @TC-11-025 @P1 @Âm
  Kịch bản: TC-11-025 Ý định trùng, sai mẫu, luồng chưa phát hành, còn tham chiếu
    # Truy vết: FR-11-013 · API-11-035, 036, 037 · ERR-11-002, 003, 012, 037 · BR-11-002, 003
    Biết `M-KS` v3 `PUBLISHED` dùng `capTheBHYT`; luồng `flow-bhyt-draft` chưa phát hành.
    Khi IE1 `POST /intents` với `capTheBHYT`
    Và IE1 `POST /intents` với `CapThe`
    Và IE1 gắn `bindings` TEST tới `flow-bhyt-draft`
    Và IE1 gắn `bindings` chứa `https://httt.example/api`
    Và IE1 `:deprecate` ý định đang dùng ở v3
    Thì bước 1 `409` ERR-11-002. Bước 2 và 4 `400` ERR-11-003. Bước 3 `422` ERR-11-012. Bước 5 `409` ERR-11-037.

  @TC-11-026 @P1 @Dương
  Kịch bản: TC-11-026 Đăng ký hành động bù trừ theo bước
    # Truy vết: FR-11-014 · API-11-039, 040 · UI-11-09 · BR-11-008, 009, 010 · PERM-11-model
    Biết v4 `DRAFT`; ý định `huyDangKyThuongTru`, `danhDauChoXuLy` `ACTIVE`.
    Khi IE1 `PUT /versions/4/compensations` cho `guiCuTru` (`AUTO`, `huyDangKyThuongTru`, ghi chú 40 ký tự) và `guiTuPhap` (`MANUAL`, `danhDauChoXuLy`, ghi chú 40 ký tự)
    Và IE1 `GET /compensations`
    Và IE1 `GET /versions/4/export?format=bpmn`
    Thì bước 1 `200`. Bước 3 XML có sự kiện bù trừ gắn hai bước và hai service task `isForCompensation`. Hành động do nghiệp vụ nhập, không suy máy móc từ bước xuôi (BR-11-009).

  @TC-11-027 @P1 @Âm
  Kịch bản: TC-11-027 Bù trừ trỏ chính bước xuôi, thiếu ghi chú, ý định lạ, thiếu bù trừ
    # Truy vết: FR-11-014 · API-11-040 · ERR-11-007, 011, 013, 044 · BR-11-008
    Biết v4 `DRAFT`; IE1.
    Khi IE1 đặt bù trừ của `guiCuTru` là `dangKyThuongTru`
    Và IE1 đặt ghi chú 8 ký tự
    Và IE1 đặt ý định bù trừ `khongCo`
    Và IE1 xóa bù trừ `guiTuPhap`, rồi `:validate`
    Thì bước 1 `422` ERR-11-044. Bước 2 `422` ERR-11-007. Bước 3 `422` ERR-11-011. Bước 4 `RISKY_NO_COMPENSATION` kèm ERR-11-013.
