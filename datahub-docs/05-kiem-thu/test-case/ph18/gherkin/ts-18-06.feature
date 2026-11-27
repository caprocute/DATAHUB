# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-06
Tính năng: TS-18-06 · Quản lý cờ tính năng và danh sách egress cho phép

  @TC-18-018 @P1 @Dương
  Kịch bản: TC-18-018 Khai báo, bật theo tenant, gỡ cờ tính năng
    # Truy vết: FR-18-009 · API-18-020, 021, 022, 023, 028 · BR-18-008 · EVT-18-03 · UI-18-10
    # Mục đích: Chứng minh vòng đời cờ `ff.{module}.{tính-năng}`: khai báo có chủ sở hữu, bật cho T90 không ảnh hưởng T91, gỡ sau khi mã bỏ nhánh cờ.
    Biết U-PA1; U-T90-TA1 (`PERM-18-config`); chủ sở hữu `PH-02`.
    Khi U-PA1 `POST /feature-flags` `ff.ph02.tim-kiem-moi`, chủ sở hữu PH-02, ngày gỡ sau 120 ngày.
    Và U-T90-TA1 `PATCH /feature-flags/ff.ph02.tim-kiem-moi` bật cho T90 kèm `If-Match`.
    Và S-PH02 đọc lô cờ cho T90 và T91.
    Và U-PA1 `POST /feature-flags/ff.ph02.tim-kiem-moi:retire`.
    Thì bước 1 `201`. Bước 2 `200`, EVT-18-03 `enabled = true`. Bước 3 T90 `true`, T91 `false`. Bước 4 `200`, cờ `RETIRED`, đọc lô trả giá trị mặc định và cờ không còn hiện ở UI-18-10.

  @TC-18-019 @P2 @Âm @Biên
  Kịch bản: TC-18-019 Cờ thiếu chủ sở hữu, ngày gỡ quá 365 ngày, trùng mã và quá ngày gỡ
    # Truy vết: FR-18-009 · API-18-021 · BR-18-008 · ERR-18-002, 021 · EVT-18-03
    # Mục đích: Chứng minh BR-18-008: cờ không có chủ sở hữu và ngày gỡ hợp lệ bị từ chối; quá ngày gỡ chỉ nhắc chủ sở hữu, không tự tắt.
    Biết T95 (đồng hồ giả); cờ `ff.ph04.mo-phong` đã có, ngày gỡ sau 10 ngày, đang bật.
    Khi khai báo cờ thiếu `owner`.
    Và khai báo cờ có ngày gỡ sau 400 ngày.
    Và khai báo lại `ff.ph04.mo-phong`.
    Và tua đồng hồ 11 ngày, chạy tác vụ nhắc.
    Thì bước 1 và 2 `422` ERR-18-021. Bước 3 `409` ERR-18-002. Bước 4 cờ vẫn bật, chủ sở hữu PH-04 nhận việc nhắc và thông báo; không có EVT-18-03 tắt cờ.

  @TC-18-020 @P2 @Dương
  Kịch bản: TC-18-020 Thêm và gỡ đích egress có hạn dùng, PH-13 nhận sự kiện
    # Truy vết: FR-18-010 · API-18-024, 025, 026, 028 · BR-18-009 · EVT-18-04 · UI-18-10
    # Mục đích: Chứng minh FR-18-010: đích FQDN công khai qua HTTPS được thêm có mục đích, hạn dùng, kiểu `LIST<HOST>`; gỡ cần lý do; EVT-18-04 phát cho PH-13 cập nhật chính sách egress.
    Biết T90; U-T90-TA1; `18.egress.max-entries = 200`.
    Khi `POST /egress-allowlist` `api.thuedientu.gdt.gov.vn:443`, mục đích `WEBHOOK`, hạn 180 ngày.
    Và `POST /egress-allowlist` `*.vnpt.vn:443`.
    Và S-PH04 đọc lô `18.egress.allowlist` của T90.
    Và `DELETE /egress-allowlist/{entryId}` kèm lý do.
    Thì bước 1 và 2 `201`, mỗi lần một EVT-18-04 `action = ADD`. Bước 3 hai đích có `expiresAt`. Bước 4 `204`, EVT-18-04 `action = REMOVE`; KT: có.

  @TC-18-021 @P2 @Âm @Bảo_mật
  Kịch bản: TC-18-021 Đích là IP, dải nội bộ, HTTP thường, ký tự đại diện hai cấp, trùng và vượt số mục
    # Truy vết: FR-18-010 · API-18-025 · BR-18-009 · ERR-18-002, 013, 022
    # Mục đích: Chứng minh BR-18-009 chặn mọi đích không phải tên miền công khai qua HTTPS và giới hạn số mục.
    Biết T92 có `18.egress.max-entries = 3` và đã có 3 mục; T90 trống.
    Khi Ở T90 thêm lần lượt `203.0.113.10:443`, `db.cluster.local:5432`, `http://example.vn`, `*.*.gov.vn:443`.
    Và thêm hai lần `api.example.vn:443`.
    Và Ở T92 thêm mục thứ tư hợp lệ.
    Thì bước 1 mỗi đích `422` ERR-18-022. Bước 2 lần hai `409` ERR-18-002. Bước 3 `422` ERR-18-013. Không có EVT-18-04 cho mục bị từ chối.
